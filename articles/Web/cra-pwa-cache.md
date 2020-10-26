title: CRA如何集成Workbox进行离线缓存
date: 2020-10-25 13:26:54
---

相信大部分开发者在React的学习或者工作中都有使用过 CRA(Create React App)，这是一个十分优秀的脚手架，基本能满足绝大部分前端开发的需求，CRA 生成出来的 React 初始代码中有一个十分方便的功能，就是 PWA，这个功能会注册 Service Worker，开启离线缓存。但是因为 Service Worker 太特殊了，一旦注册在用户的浏览器，全站的请求都会被 Service Worker 控制，一不留神，小问题也成了大问题了。

## CRA中PWA的问题
CRA默认的 service worker 其实是自动生成的，`src/registerServiceWorker.js` 这个文件其实只是用来注册，注销 service worker 用的，真正生成的是 workbox 的插件，**[workbox-webpack-plugin](https://developers.google.com/web/tools/workbox/modules/workbox-webpack-plugin)**。

而这个 workbox-webpack-plugin 里面有两个插件

**一个是 GenerateSW，另一个是 InjectManifest**

在插件的官方页面上有描述这个两个插件的区别：

![different_img](./cra-pwa-cache/WX20201026-232844@2x.png)

