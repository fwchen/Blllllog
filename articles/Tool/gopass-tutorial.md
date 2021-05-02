title: Gopass密码管理器教程
date: 2021-05-02 21:16:30
---

现在有非常多的密码管理器，例如非常火爆的“OnePassword”等，但是这些密码管理器要收钱，而且密钥存储在服务商的服务器，安全性还是会令人感到一些怀疑。

所以我之前尝试了一些开源的密码管理器，例如`Bitwarden`，`keeweb`，最后一直在使用自己搭建的 `passit`。

`passit` 也有自己的一套加密解密方案，而且对团队共享密钥这块做还不错，可以参考他们的官方文章 https://passit.io/documentation/security-model/ ，但是安全系数还不是很好，毕竟在网页上进行密码管理，可能以后有某浏览器安全漏洞等，还是有风险，而且一旦黑客获得了用户密码，那么所有的密钥也会泄露。

所以我最近使用了 `gopass` 来作为我的密码管理器，https://github.com/gopasspw/gopass ，这款开源的密码管理用 Golang 开发，基于命令行，但是有很多插件可以供你使用，包括连接 Chrome 等浏览器，`Gopass` 使用 GPG 作为加密解密方案，非常非常成熟，而且加密还多了一层保障，如果黑客获取了你的 GPG 密钥，那么没有 GPG 密码还获取不了你保存的密码，反之也一样，而且基于 GPG 的玩法还有很多，一些子密钥等，还有很多插件，社区也算比较成熟了。下面给大家介介绍一下 `Gopass` 这款密码管理的安装和使用。

## 安装
首先我们参考这篇官方的文档来进行安装
https://github.com/gopasspw/gopass/blob/master/docs/setup.md

安装 `GPG`，`git`，还有 `Gopass`

其中 `Gopass` 会有自动检测更新的功能，但是里面自带的更新功能并不支持 `go get -u` 这种方式的自动更新，所以还是建议使用二进制安装包来安装，以后更新会比较方便

需要注意的是，安装完 `GPG` 之后一定要检查是否能正确使用，不然后面有问题的话错误信息会比较奇怪

```
mkdir some-dir
cd some-dir
git init
touch foo
git add foo
git commit -S -m "test"
```

如果上面通过 git 来签名 commit 没有问题，就可以继续了， 在我的电脑里，需要额外配置 tty 
```
export GPG_TTY=$(tty)
```
还有 git 的配置才能正确使用

```
git config --global user.signingkey xxxxx
```

(使用`gpg2 --list-signatures`来获取`signingkey`)


## 使用
使用的话，也是参照官方的文档 https://github.com/gopasspw/gopass/blob/master/docs/features.md 来进行初始化，添加密码等

其实我使用下来发现 Gopass 在命令行行方面的还是有很多 Bug 的，有一些地方经常报错。如果是单机使用的话，问题倒不是很大，只是增删查找密钥就行。

但是如果你要保存在 git 上的话，尽量还是保存在私有仓库，正如官方提到的 https://github.com/gopasspw/gopass/blob/master/docs/security.md#gnu-privacy-guard 里讲到，`Gopass` 不保证用户名等元信息的加密，所以如果不小心放在了共有仓库上的话，一些信息还是有可能被泄露

另外需要注意的是：`Gopass` 不会把自动帮你把 GPG 私钥保存在 git 仓库里，私钥一定要自己保管好，不然如果私钥丢了，密码可能就找不回来了

另外的另外，如果你想跨多电脑使用，还要将私钥导出导入：

具体如下：

先找到你用来加密密码的私钥
```
gpg --list-secret-keys user@example.com
```

然后找到 `ABC12345`的字样，那就是这个密钥的ID
```
pub   4096R/ABC12345 2020-01-01 [expires: 2025-12-31]
uid                  Your Name <user@example.com>
sub   4096R/DEF67890 2020-01-01 [expires: 2025-12-31]
```

然后通过这个ID来导出私钥，私钥一定要保存好，保持高的警惕性
```
gpg --export-secret-keys YOUR_ID_HERE > private.key
```

然后在另外的电脑中导入即可
```
gpg --import private.key
```

## 团队使用
`Gopass` 这款工具在团队中使用也是可以的，但是正如官方的 [gnu-privacy-guard](https://github.com/gopasspw/gopass/blob/master/docs/security.md#gnu-privacy-guard) 中提到，为了保证这款密码管理器的 `Integrity`，密钥只能由一个私钥加密，所以在团队中使用的话，要不就是分发一个全部人都能使用的私钥，要不就由一个人来专门管理吗，其他人利用 recipients 开查看密码

至于如何增添 `recipients`，可以参考下面的命令:

首先你需要找到你自己的公钥ID

通过 `gpg --list-signatures` 出来的命令：

```
pub   rsa3072 2021-05-02 [SC] [expires: 2036-04-28]
      ABC123456
uid           [ unknown] chencanhao (a GnuPG secret for gopass) <user@example.com>
sig 3        ABC123456 2021-05-02  example (a GnuPG secret for gopass) <user@example.com>
sub   rsa3072 2021-05-02 [E] [expires: 2036-04-28]
sig          ABC123456 2021-05-02  example (a GnuPG secret for gopass) <user@example.com>
```

来找到 `ABC123456`

然后通过下面的命令来生成 `0xABC123456` 这个文件
```
gpg --armor --output 0xABC123456 --export user@example.com
```

然后把这个文件丢到 gopass store 里的 `.public-keys` 目录中

然后运行 `gopasss recipients add 0xABC123456` 来重新通过这个公钥加密，最后运行 `gopass sync` 同步到代码仓库中

那么公钥`0XABC123456`的主人就可以通过他的私钥来查看密码了

## 插件

`Gopass`社区提供了丰富的插件

- [gopassbridge](https://github.com/gopasspw/gopassbridge): Browser plugin for Firefox, Chrome and other Chromium based browsers
- [kubectl gopass](https://github.com/gopasspw/kubectl-gopass): Kubernetes / kubectl plugin to support reading and writing secrets directly from/to gopass.
- [gopass alfred](https://github.com/gopasspw/gopass-alfred): Alfred workflow to use gopass from the Alfred Mac launcher
- [git-credential-gopass](https://github.com/gopasspw/git-credential-gopass): Integrate gopass as an git-credential helper
- [gopass-hibp](https://github.com/gopasspw/gopass-hibp): haveibeenpwned.com leak checker
- [gopass-jsonapi](https://github.com/gopasspw/gopass-jsonapi): native messaging for browser plugins, e.g. gopassbridge
- [gopass-summon-prover](https://github.com/gopasspw/gopass-summon-provider): gopass as a summon provider
- [`terraform-provider-gopass`](https://github.com/camptocamp/terraform-provider-pass): a Terraform provider to interact with gopass
- [chezmoi](https://github.com/twpayne/chezmoi): dotfile manager with gopass support

还有 iOS 和 安卓的客户端 APP 可以下载，可以说是有十分丰富的功能了。最后，`Gopass` 这款密码管理器，应该会是喜欢的Geeks非常喜欢，不喜欢的人大概是因为这款密码管理器门槛太高，比较使用起来还是比较麻烦的，而且需要一点技术功底。
