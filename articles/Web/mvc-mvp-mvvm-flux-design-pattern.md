title: Http缓存介绍
date: 2020-02-23 17:26:54
---

# 谈谈 Web 前端 MVC, MVP， MVVM 和 FLUX 设计模式

MVC，MVP，MVVM一直都是 GUI 领域常见的设计模式，这三个每个都在各自独特的领域独占一方。例如 MVC 一直都是一些后端应用框架标榜的设计模式，而安卓应用开发更多在使用 MVP 设计模式，而 MVVM 的思想或者 MVVM 的变体一直活跃在现在 Web 前端开发框架中。

## 什么是 Model（模型）

## View

## Controller

# MVC
MVC 可以说是一个很老的技术了，最早在 1978 被提出来，现在主要活跃在 Web 领域，尤其在后端代码对页面渲染这一块上，其中，在 Java 中的 SpringMVC 尤为著名。

![mvc](./mvc-mvp-mvvm-flux-design-pattern/mvc.jpg)

如上面，MVC 中，model 模型代表者后端代码中的业务模型抽象，范畴比较大，可以是 DDD 领域模型，服务等，也可以是一些具体的 Class，例如 Book Class 等，甚至是一些“事物脚本”中的事物对象。因为 MVC 只是一种设计模式，一种分层模型，跟代码架构不冲突，就是代表后端的业务模型。

Model 模型表示着业务逻辑和书籍，模型把这些数据逻辑渲染到 View 中，比较常见的做法是后端的模版技术，例如 jsp 之类的，把预期的数据填入 jsp 模版中，返回给浏览器。当然，像现在的 restful 应用中，前端都为 SPA 单页面应用，那么 api 返回的 json 数据也相当于为 View。

一般来说，MVC 中的数据流动是单向的，Model 用数据来渲染 View，View 用户界面交互完成后更新数据，然后 Controller 做分发和控制。但是从交互的角度来看并不是单向的，如上图中的红线，当收到更新数据请求的时候，Controller 会更新数据，更新完就会重定向到的 View ，View 拿到更新完的 Model 数据，进行渲染。


# MVP 

MVP 属于 MVC 的变体，这个设计模式在安卓开发上比较常见，如下图所示，Presenter 跟 View 层交互，完全阻隔了 Model -> View 或 View -> Model 的数据流。 Presenter 负责将一个或多个 Model 的数据组装起来，返回给 View 界面，同时 View 界面的一些交互，验证等逻辑操作都委托给 Presenter，Presenter 负责更新数据或者发送 Api 请求等，View 专注于界面和人机交互，更能清楚划分层的职能。

一般来说，MVP 架构中，一个 View 对应一个 Presenter，这跟 MVC 中的 Controller 不同，因为 Controller 负责分发请求，一个 Controller 可能会对应多个 View，从这点上看，Presenter 跟 View 的关系更密切一些，Presenter 更像是一个操控 View 的角色，View 则是像傻鸭子一样，没有自己的思想，只负责 UI 和交互，被 Presenter 操控着，这样做能够分离职责。
 
![mvp](./mvc-mvp-mvvm-flux-design-pattern/mvp.jpg)

MVP 虽然于 MVC 在思想上差不了多少，但是从这两种设计的定位上看，有很大的区别。首先，MVP 属于纯客户端的

# MVVM


# 参考
[stackoverflow what-are-mvp-and-mvc-and-what-is-the-difference](https://stackoverflow.com/questions/2056/what-are-mvp-and-mvc-and-what-is-the-difference)

[MVC，MVP 和 MVVM 的图示-阮一峰](http://www.ruanyifeng.com/blog/2015/02/mvcmvp_mvvm.html)
