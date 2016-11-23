---
title: 加快git传输速度
date: 2016-11-10 00:57:59
tags:
- git
categories: git
---

# 加快git传输速度

![](http://www.thebeijinger.com/files/u93526/greatfirewall1_616.jpg)

​    最近遇到了个比较棘手的事情。公司是外企，在公司github同步代码下载速度达到1.5-2.3M/S，但是每到家同步github的代码下载速度只有2-4kb/s，拉一套源码就几个小时的事情。

​    实在无法忍受这龟速，就自己办理的一个8M网速的宽带，10号以后自动提速到12M，，可是拉代码速度依旧只有70-160kb/s。

​    这下简直无法忍受，只好自己想办法。
方法很简单，就是用代理，用chrome+linux+goagent组合
折腾了半个小时，马上就能访问http://developer.android.com这个网站了，

在此吐槽一下中国网警们，不知道你们屏蔽这个网站是何用意？？？？
但是很github访问依旧慢，慢，慢，拉代码依旧需要很久很久。
于是去设置下github 代理。SO：
正文来了：



通过配置git的代理可以加速git上传和下载
```
git config --global https.proxy=socks5://127.0.0.1:1080
git config --global http.proxy=socks5://127.0.0.1:1080
```

端口号要根据ss的端口做相应调整，有同样困扰的小伙伴不妨试一试！