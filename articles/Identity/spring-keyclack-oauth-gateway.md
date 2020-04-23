title: 如何使用Spring Gateway和KeyCloak构建一个OAuth2系统
date: 2020-04-22
 13:31:26
---

# OIDC

// TODO OIDC

这篇文章介绍一下，如何搭建一个基于 Spring Gateway 和 Keycloak 的 OAuth2 资源保护系统，这里只介绍一些思路和核心代码，向有一定基础的读者分享思路

首先我们需要了解这个小系统需要的组件，分别是
- OAuth2 Server，这个我们选用的是 KeyCloak
- Api Gateway & OAuth2 Client，使用 Spring Gateway 作为 OAuth2 的客户端
- Resource Server (RS)，就是在 Api Gateway 后面隐藏的资源服务

整体的架构可以看下图

![](./spring-keyclack-oauth-gateway/demo.png)
> 图片出自 https://spring.io/blog/2019/08/16/securing-services-with-spring-cloud-gateway

认证流程是，客户端（浏览器）访问应用，此时没有认证状态，然后重定向到单点登录平台，也就是 KeyCloak，然后在 KeyCloak 上进行用户名密码认证，或者是其他认证，成功后，KeyCloak 返回认证后的信息，然后客户端（Gateway）通过这些信息，再生成一个 Token，传到被保护的 Resouce Server，Resouce Server 拿到这个 Token 再向 KeyCloak 进行权限的认证，如果认证都通过，则允许对资源进行操作

# Api Gateway 搭建

第一步我们可以先进行 Api Gateway 的搭建，然后再回过头来设置 KeyCloak

我们假设这个 Demo 应用的名字为 orange

然后我们要搭建 api gateway，使用 https://start.spring.io 来生成项目，十分方便

![](./spring-keyclack-oauth-gateway/start_spring1.png)

我们勾选了 Gateway 和 OAuth2 Client 这两个依赖，然后下载下来，在 IDE 中打开，尝试运行一下，成功的话应该会在 8080 端口运行。

# KeyCloak 搭建

搭建一个 KeyCloak demo 也是十分简单，可以直接从官方网站上下载 java 包，然后通过命令也是可以一键运行，不过这里还是推荐使用 Docker 来运行，十分方便和干净

这里给出 Docker KeyCloak 容器启动命名，我们把端口映射到 6180

``` bash
docker run -p 6180:8080 -e KEYCLOAK_USER=admin -e KEYCLOAK_PASSWORD=123456 -d jboss/keycloak
```

> 这个 Admin 密码设成 123456，在正式一点的环境肯定也是不行的，不过我们是 Demo，就不需要管那么多了

然后创建一个 Realm

![](./spring-keyclack-oauth-gateway/create-realm.png)

然后创建一个客户端 Client

![](./spring-keyclack-oauth-gateway/create-client.png)

![](./spring-keyclack-oauth-gateway/create-client-gateway.png)

接着创建一个用户
![](./spring-keyclack-oauth-gateway/create_user.png)

# 与 Gateway 集成
## 授权类型
然后我们需要在 Gateway 上集成 OAuth2，我们选择的授权类型是 Authorization Code Grant，虽然我们这个 Demo 的前端也是一个 SPA，可以直接用前端作为一个 OAuth2 客户端，然后选择 Implicit Grant 作为授权类型。
// TODO 优缺点

// TODO 贴流程图

## Maven 依赖
``` xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-gateway</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-oauth2-client</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.security</groupId>
    <artifactId>spring-security-oauth2-client</artifactId>
</dependency>
```

## Application.yaml DSL 配置
然后现在 application.yaml 中配置 OAuth2，只需要在 Provider 下面的 KeyCloak 中配置 `issuer-uri` 即可，这个地址可以在 keycloak 的 Admin 中找到

``` yaml
spring:
  security:
    oauth2:
      client:
        provider:
          keycloak:
            issuer-uri: http://192.168.50.251:6180/auth/realms/humpback_dev
        registration:
          keycloak:
            client-id: orange
            client-secret: a1246398-4c2f-46bd-b83d-9b1313f3378d
```


然后我们继续通过 yaml 文件配置 gateway 的配置，其中 `http://localhost:8260` 是我们接下来要创建 RS 服务。

``` yaml
spring:
  cloud:
    gateway:
      routes:
        - id: orange
          uri: http://localhost:8260
          predicates:
            - Path=/**
          filters:
#            - TokenRelay
            - TokenRelayWithTokenRefresh
            - RemoveRequestHeader=Cookie, Set-Cookie
```
注意上面被注释掉的 `TokenRelay`，这是一个 GatewayFilterFactory，不过这个 Filter 现在还有个比较大的问题，就是如果 Access Token 过期的话，还是会把请求发到 RS 那里，导致后续请求都是 401 的状态。

这个问题可以看 https://github.com/spring-cloud/spring-cloud-security/issues/175 这个 Github Issue

下面有一个现成的解决方案，就是自定义一个 TokenRelay，实现如下：

``` java
import java.time.Duration;

import org.springframework.cloud.gateway.filter.GatewayFilter;
import org.springframework.cloud.gateway.filter.factory.AbstractGatewayFilterFactory;
import org.springframework.security.core.Authentication;
import org.springframework.security.oauth2.client.OAuth2AuthorizeRequest;
import org.springframework.security.oauth2.client.OAuth2AuthorizedClient;
import org.springframework.security.oauth2.client.ReactiveOAuth2AuthorizedClientManager;
import org.springframework.security.oauth2.client.ReactiveOAuth2AuthorizedClientProvider;
import org.springframework.security.oauth2.client.ReactiveOAuth2AuthorizedClientProviderBuilder;
import org.springframework.security.oauth2.client.authentication.OAuth2AuthenticationToken;
import org.springframework.security.oauth2.client.registration.ReactiveClientRegistrationRepository;
import org.springframework.security.oauth2.client.web.DefaultReactiveOAuth2AuthorizedClientManager;
import org.springframework.security.oauth2.client.web.reactive.function.client.ServerOAuth2AuthorizedClientExchangeFilterFunction;
import org.springframework.security.oauth2.client.web.server.ServerOAuth2AuthorizedClientRepository;
import org.springframework.security.oauth2.core.OAuth2AccessToken;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;

import reactor.core.publisher.Mono;

/**
 * Token Relay Gateway Filter with Token Refresh. This can be removed when issue {@see https://github.com/spring-cloud/spring-cloud-security/issues/175} is closed.
 * Implementierung in Anlehnung an {@link ServerOAuth2AuthorizedClientExchangeFilterFunction}
 */
@Component
public class TokenRelayWithTokenRefreshGatewayFilterFactory extends AbstractGatewayFilterFactory<Object> {

    private final ReactiveOAuth2AuthorizedClientManager authorizedClientManager;

    private static final Duration accessTokenExpiresSkew = Duration.ofSeconds(3);

    public TokenRelayWithTokenRefreshGatewayFilterFactory(ServerOAuth2AuthorizedClientRepository authorizedClientRepository,
                                                          ReactiveClientRegistrationRepository clientRegistrationRepository) {
        super(Object.class);
        this.authorizedClientManager = createDefaultAuthorizedClientManager(clientRegistrationRepository, authorizedClientRepository);
    }

    private static ReactiveOAuth2AuthorizedClientManager createDefaultAuthorizedClientManager(
            ReactiveClientRegistrationRepository clientRegistrationRepository,
            ServerOAuth2AuthorizedClientRepository authorizedClientRepository) {

        final ReactiveOAuth2AuthorizedClientProvider authorizedClientProvider =
                ReactiveOAuth2AuthorizedClientProviderBuilder.builder()
                        .authorizationCode()
                        .refreshToken(configurer -> configurer.clockSkew(accessTokenExpiresSkew))
                        .clientCredentials(configurer -> configurer.clockSkew(accessTokenExpiresSkew))
                        .password(configurer -> configurer.clockSkew(accessTokenExpiresSkew))
                        .build();
        final DefaultReactiveOAuth2AuthorizedClientManager authorizedClientManager = new DefaultReactiveOAuth2AuthorizedClientManager(
                clientRegistrationRepository, authorizedClientRepository);
        authorizedClientManager.setAuthorizedClientProvider(authorizedClientProvider);

        return authorizedClientManager;
    }

    public GatewayFilter apply() {
        return apply((Object) null);
    }

    @Override
    public GatewayFilter apply(Object config) {
        return (exchange, chain) -> exchange.getPrincipal()
                // .log("token-relay-filter")
                .filter(principal -> principal instanceof OAuth2AuthenticationToken)
                .cast(OAuth2AuthenticationToken.class)
                .flatMap(this::authorizeClient)
                .map(OAuth2AuthorizedClient::getAccessToken)
                .map(token -> withBearerAuth(exchange, token))
                // TODO: adjustable behavior if empty
                .defaultIfEmpty(exchange).flatMap(chain::filter);
    }

    private ServerWebExchange withBearerAuth(ServerWebExchange exchange, OAuth2AccessToken accessToken) {
        return exchange.mutate().request(r -> r.headers(headers -> headers.setBearerAuth(accessToken.getTokenValue()))).build();
    }

    private Mono<OAuth2AuthorizedClient> authorizeClient(OAuth2AuthenticationToken oAuth2AuthenticationToken) {
        final String clientRegistrationId = oAuth2AuthenticationToken.getAuthorizedClientRegistrationId();
        return Mono.defer(() -> authorizedClientManager.authorize(createOAuth2AuthorizeRequest(clientRegistrationId, oAuth2AuthenticationToken)));
    }

    private OAuth2AuthorizeRequest createOAuth2AuthorizeRequest(String clientRegistrationId, Authentication principal) {
        return OAuth2AuthorizeRequest.withClientRegistrationId(clientRegistrationId).principal(principal).build();
    }
}
```

## SecurityConfig
接下来就是 Spring Security 的设置了，具体可以看这个方法

这个是 WebFlux 的 Security 配置，跟 Spring MVC 的配置还是挺不一样的
``` java
@Bean
public SecurityWebFilterChain springSecurityFilterChain(ServerHttpSecurity http,
                                                        ReactiveClientRegistrationRepository clientRegistrationRepository) {
    http.cors();

    http.oauth2Login().authenticationSuccessHandler(myServerAuthenticationSuccessHandler);

    http.logout(logout -> logout.logoutSuccessHandler(
            new OidcClientInitiatedServerLogoutSuccessHandler(clientRegistrationRepository)));
    http.logout().logoutUrl("/auth/logout");

    http.authorizeExchange().anyExchange().authenticated();

    // http.exceptionHandling().accessDeniedHandler(myAccessDeniedHandlerWebFlux).authenticationEntryPoint((exchange, exception) -> Mono.error(exception));

    http.headers().frameOptions().disable().xssProtection().disable();
    http.csrf().disable();
    http.httpBasic().disable();
    http.formLogin().disable();
    return http.build();
}
```
这个配置先设置了 OAuth2，包括 login，logout 等，然后把一些安全保护方法都去掉，不然等会在前端调用会十分麻烦

> 当然在生产环境还是要老老实实配置好 csrf，xss 这些参数。

## 处理重定向问题
最后我们还有一个问题需要考虑

因为 orange 这个应用的 OAuth2 客户端是在 Gateway，前端也有多种方法可以构造授权 Url 到 KeyCloak 进行登陆授权，但是我们选择一种比较简单的方法，那就是在页面中直接重定向到我们的 Gateway

假设我们前端运行在 `http://localhost:3000` 这个域名端口下，然后我们打开了 `http://localhost:3000/orange_list` 这页面，在这个页面进行登陆授权

然后我们 redirect 重定向到我们的 gateway 地址 `http://localhost:8080`，因为我们并没有授权过的 session，所以 gateway 会构造 Url 到 KeyCloak 中授权，这个 URL 大概长这样

// TODO url

可以看到这个 URL 中的 redirect_url 指的是 gateway 地址，因为在 keycloak 授权完成之后，keycloak 会生成 // TODO，然后 gateway 会再次请求 OAuth Server（也就是 KeyCloak）获取 Access Token

> 当然，如果 Imp 的话，就不需要这么麻烦，直接用前端作为 OAuth 客户端即可，也不需要 Server 端处理 OAuth 流程了

这个时候，作为登录这个用例来看，已经是登录成功了，那么 Gateway 就需要重定向回我们的前端页面了，不过这个时候 Gateway 并不知道之前来的 `http://localhost:3000/orange_list`


当然也是做到 redirect 回之前的页面的，但是十分麻烦，思路是前端重定向到 Gateway 的时候带上 redirect_url，例如 http://localhost:8080/oauth/keycloak?redirect_url=http://localhost:3000/orange_list ，然后把 `http://localhost:3000/orange_list` 保存到 Session 中，登录完成后从 session 中拿到 `http://localhost:3000/orange_list` 进行重定向

这种方法在 server 端带来了额外的状态，而且这个逻辑会跟正常的 API 请求有冲突，所以 gateway 索性把这个重定向功能还给前端，让前端通过 session storage 或者其他方法来处理

最后，登录成功之后，通过自定义的 `SuccessHandler` 重定向回前端页面，下面是 `ServerAuthenticationSuccessHandler` 的实现代码

``` java
@Component
public class MyServerAuthenticationSuccessHandler implements ServerAuthenticationSuccessHandler {
    private ServerRedirectStrategy redirectStrategy = new DefaultServerRedirectStrategy();

    @Value("${application.frontend_url}")
    private String DEFAULT_LOGIN_SUCCESS_URL; // http://localhost:3000

    @Override
    public Mono<Void> onAuthenticationSuccess(WebFilterExchange webFilterExchange, Authentication authentication) {
        URI url = URI.create(DEFAULT_LOGIN_SUCCESS_URL);
        return this.redirectStrategy
                .sendRedirect(webFilterExchange.getExchange(), url);
    }
}
```

# Resource Service 搭建
Resource Service 就是被保护的资源，当然也可以是其他类型的服务。

# 前端
// sessionStorage


# 结论
总的来说，现在 Spring 的 WebFlux 技术栈虽然说已经发展挺久的，但是相对来说资料还是比较少，而且看上起问题还不少，特别是 WebFlux + Spring Security OAuth，所以没有特殊要求还是选择 Zuul 作为 Gateway 比较省心。



# 参考资料
- [Securing Services with Spring Cloud Gateway](https://spring.io/blog/2019/08/16/securing-services-with-spring-cloud-gateway)
- [An OAuth 2.0 introduction for beginners](https://itnext.io/an-oauth-2-0-introduction-for-beginners-6e386b19f7a9)
- [Spring Security 5 – OAuth2 Login](https://www.baeldung.com/spring-security-5-oauth2-login)
- [Spring Cloud Gateway with OpenID Connect and Token Relay](https://blog.jdriven.com/2019/11/spring-cloud-gateway-with-openid-connect-and-token-relay/)