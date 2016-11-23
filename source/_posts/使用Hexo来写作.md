---
title: 使用Hexo来写作
tags: 
 - Hexo
 - 博客
 - 写作
Comments: true
categories: 博客
date: 2016-08-27 19:59:55
---

![](http://ockhcbepk.bkt.clouddn.com/hexo_pic.png?watermark/2/text/QOmbtuWjueWNmuWuog==/font/5a6L5L2T/fontsize/700/fill/I0VGRUZFRg==/dissolve/100/gravity/SouthEast/dx/20/dy/20)

>如果一件事成为一种生活的惯性，那是非常可怕的。就像当你徜徉在Windows的各种炫酷的可视化界面中时，你却失去了类似于Linux命令那样的自由。

# 从Wordpress到Hexo
***
这是我的博客建立起来之后自己动手写的第一篇博客，也是第一次使用Markdown语法进行写作，所以仅以此篇博客开启我的Hexo博客之路（不归之路）。

其实在这个博客是我的博客的2.0版本。和很多人预料的一样，1.0版本是用Wordpress做的，原因很简单，因为那时候刚刚学会PHP，还不会Node.js。真正接触Node.js正是通过Hexo，所以从某种意义上，Hexo也可以算是启蒙老师。

真正进入到Hexo中才发现，原来写博客可以做到这么完美。当然，这么说也并不代表我在说Wordpress的坏话，而是我觉得Hexo更适合我的口味，所以也没有再犹豫什么。

# Markdown写作体验
***
初次尝试使用Markdown写作，体验还是很不错的。我认为这也是作为一名程序员，应该是用的方式。
具体体现在：
* 使用简单的代码指令来控制文本输出格式
* 自由的形式
* 统一的文本格式特别适合博客写作

# 写作
***
以下内容非本人原创，均摘自[官网文档](https://hexo.io/zh-cn/docs/writing.html)，特此声明。
你可以执行下列命令来创建一篇新文章。
`$ hexo new [layout] <title>`

您可以在命令中指定文章的布局（layout），默认为 **post**，可以通过修改 **_config.yml** 中的 **default_layout** 参数来指定默认布局。

## 布局（Layout）
Hexo 有三种默认布局：**post**、**page** 和 **draft**，它们分别对应不同的路径，而您自定义的其他布局和 **post** 相同，都将储存到 **source/_posts** 文件夹。

| 布局    |       路径       |
| ----- | :------------: |
| post  | source/_posts  |
| page  |     source     |
| draft | source/_drafts |

## 文件名称
Hexo 默认以标题做为文件名称，但您可编辑 new_post_name 参数来改变默认的文件名称，举例来说，设为 :year-:month-:day-:title.md 可让您更方便的通过日期来管理文章。

| 变量       |         描述         |
| -------- | :----------------: |
| :title   | 标题（小写，空格将会被替换为短杠）  |
| :year    |   建立的年份，比如， 2015   |
| :month   | 建立的月份（有前导零），比如， 04 |
| :i_month | 建立的月份（无前导零），比如， 4  |
| :day     | 建立的日期（有前导零），比如， 07 |
| :i_day   | 建立的日期（无前导零），比如， 7  |

## 草稿
刚刚提到了 **Hexo** 的一种特殊布局：**draft**，这种布局在建立时会被保存到 **source/_drafts** 文件夹，您可通过 **publish** 命令将草稿移动到 **source/_posts** 文件夹，该命令的使用方式与 **new** 十分类似，您也可在命令中指定 **layout** 来指定布局。
`$ hexo publish [layout] <title>`

草稿默认不会显示在页面中，您可在执行时加上 **--draft** 参数，或是把 **render_drafts** 参数设为 true 来预览草稿。

## 模版（Scaffold）
在新建文章时，**Hexo** 会根据 **scaffolds** 文件夹内相对应的文件来建立文件，例如：
`$ hexo new photo "My Gallery"`

在执行这行指令时，**Hexo** 会尝试在 **scaffolds** 文件夹中寻找 **photo.md**，并根据其内容建立文章，以下是您可以在模版中使用的变量：

| 变量     |   描述   |
| ------ | :----: |
| layout |   布局   |
| title  |   标题   |
| date   | 文件创建日期 |

# 写在最后
以上内容仅供参考。