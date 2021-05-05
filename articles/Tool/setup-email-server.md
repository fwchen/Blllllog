title: 如何部署一个简单的邮件服务器
date: 2021-05-05 12:57:09

---

如何在自己的服务器/VPS上部署一个简单的邮件服务器。

相信很多人也有自己的域名，那么用自己的域名来host一个邮箱地址是再好不过了，例如的我的邮箱就是me@xxx.com，这样的邮件地址十分有个性。而腾讯企业邮也有这样的功能，可以直接绑定域名作为企业邮箱，但是目前只支持com等几个域名，而且最近好像不是很好弄，不像以前只填个身份证的就行。

所以，如果想绑定一个其他域名的邮箱的话，只能花钱，使用 mailgun 等服务商的服务。

**或者，自己在服务器上搭建一个?**

当然，在一些VPS服务商商，是明文规定不允许搭建邮件服务器的，但是有一些却不管，例如搬瓦工，我就成功在搬瓦工的VPS上搭建了tech域名的邮箱服务器。

## 准备清单
需要准备的东西很少，就是一台服务器和一个域名
- 具有静态IP的服务器/VPS，规格不限
- 域名
- DNS服务商（这个一般买了域名就会自带的）

## 邮箱服务器选择
在 github 上面一搜，有很多的开源邮件服务器可以任君选择。

例如:
- [Mail-in-a-Box](https://mailinabox.email/)
- [Mailu](https://mailu.io/)
- [Mailcow](https://mailcow.email/)

但是这些开源产品都不适合简单邮箱服务器的场景，这些软件要求的配置太高了，像 Mailcow 就要求至少6G内存，要买一台高规格的服务器专门来跑这个太贵太不划算了，而且提供的 Web 界面和管理界面也不是我想要的。

所以像 **[Maddy](https://mailinabox.email/)** 这样的小巧邮件服务器就不错，支持 Docker， 并不会污染服务器的环境，资源占用也不多。

### **[Maddy](https://mailinabox.email/)**

这个 Moddy 并没有硬件要求，内存占用没有多少，而且也没有 web 界面，直接用邮件客户端登陆就行。

我们可以参考这个文档来搭建 https://maddy.email/tutorials/setting-up/#user-accounts-and-maddyctl

安装 docker 这些没有什么好说的，用官方的脚本一键就能弄好。

其实最重要的是 DNS 的配置：
```
; Basic domain->IP records, you probably already have them.
example.org.   A     10.2.3.4
example.org.   AAAA  2001:beef::1

; It says that "server mx1.example.org is handling messages for example.org".
example.org.   MX    10 mx1.example.org.
; Of course, mx1 should have an entry as well:
mx1.example.org.   A     10.2.3.4

; Use SPF to say that the servers in "MX" above are allowed to send email
; for this domain, and nobody else.
example.org.   TXT   "v=spf1 mx -all"

; Opt-in into DMARC with permissive policy and request reports about broken
; messages.
_dmarc.example.org.   TXT    "v=DMARC1; p=none; ruf=postmaster@example.org"
```

需要注意的是这个
```
default._domainkey.example.org    TXT   "v=DKIM1; k=ed25519; p=nAcUUozPlhc4VPhp7hZl+owES7j7OlEv0laaDEDBAqg="
```
需要在启动完 maddy 以后来获取那段字符串来进行配置。


### 证书配置