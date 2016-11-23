---
title: npm更换国内源
date: 2016-11-10 00:41:53
tags:
- npm
- node
categories: git
comments: true
---

# npm更换国内源

>通过更换国内源来加速npm下载安装模块的速度

 ![](http://www.thebeijinger.com/files/u93526/greatfirewall1_616.jpg)

我曾一度苦恼于npm的下载速度实在是太慢，有时还会连接失败。原因众所周知，不再多数。

解决办法：更换npm的源到国内源，速度快的飞起。
废话不多说，设置淘宝源：

```
npm config set registry https://registry.npm.taobao.org 
npm info underscore （如果上面配置正确这个命令会有字符串response）
```

如果出现错误：
```
npm info retry will retry, error on last attempt: Error: CERT_UNTRUSTED
```

这是因为ssl验证问题，我们取消ssl验证:
```
npm config set strict-ssl false
```

享受刷屏的快感吧

