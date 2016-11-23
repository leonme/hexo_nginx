---
title: html5+jqueryMobile编写App推广注册页
date: 2016-11-07 15:52:29
comments: true
categories: HTML5
tags:
- HTML5


---

#html5+jqueryMobile编写App推广注册页
 data-role="page"、  data-role="header" 、data-role="content"、 data-role="footer",  为什么html5会增加这几个特征，我觉得多是为支持web版手机app开发而出的，因为html5提倡开发web版app只创建一个html页，然后每个段落=一个新页面，下面我贴一段几个div标签组合成的一个整体页面，当然它们都各自加了上面的特性。

```html
<!--data-role="page"表示这个是一个html5单独页面，可以从另外一个加了page特性的div打开它 -->
<!--data-role="header"这个特性你想成APP的navigationbar -->
<!--data-role="content"内容里面展示页面内容的，必入你放一张表在这个标签里面展示 -->
<!--data-role="footer"这个特性你想成APP的tabbar -->
</div>

<div data-role="page" id="phoneRegister">
<!--data-role="header"这个特性你想成APP的navigationbar -->
<div data-role="header" id="heardId"></div>
<!--data-role="content"内容里面展示页面内容的，必入你放一张表在这个标签里面展示 -->
<div data-role="content"> </div>
<!--data-role="footer"这个特性你想成APP的tabbar -->
<div data-role="footer"> </div>
</div>
```

##1. 首先html5标准页面申明，页面中的第一行代码与html4不一样,
```xml
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd"> 
```
此标签的作用是告诉浏览器支持什么html规范。

引入jquery和jquerymobile的支持库
##2.引入jquery和jquerymobile的支持库
```xml
<meta name="viewport" content="width=device-width,initial-scale=1.0,maximum-scale=1.0,user-scalable=0" />
  <link rel="stylesheet" href="http://code.jquery.com/mobile/1.3.2/jquery.mobile-1.3.2.min.css">
   <script src="http://code.jquery.com/jquery-1.8.3.min.js"></script>
  <script src="http://code.jquery.com/mobile/1.3.2/jquery.mobile-1.3.2.min.js"></script>
```
```html
 <!DOCTYPE>
 <html>
 <head>
  <meta name="viewport" content="width=device-width,initial-scale=1.0,maximum-scale=1.0,user-scalable=0" />
 <meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1">
  <link rel="stylesheet" href="http://code.jquery.com/mobile/1.3.2/jquery.mobile-1.3.2.min.css">
  <script src="http://code.jquery.com/jquery-1.8.3.min.js"></script>
  <script src="http://code.jquery.com/mobile/1.3.2/jquery.mobile-1.3.2.min.js"></script>
 
 <title>Insert title here</title>
 <script type="text/javascript">
 $(document).on("pagecreate", function () {
     var contentHeight = document.body.clientHeight;
     var header = contentHeight * 0.1;
     var content = contentHeight * 0.75;
     var footer = contentHeight * 0.15;
     $("#phoneRegister #heardId").css({ 'height': header + 'px', 'background': '#4dbb49', 'line-height': header + 'px' });
     $("#phoneRegister #contentId").css({ 'height': content + 'px' });
     $("#phoneRegister #footerId").css({ 'height': footer + 'px', ' font-size': '70px', 'line-height': footer + 'px' });

    var flag = false;
    setInterval(function () {
        if (flag == false) {
            $("#presentGiftTitle").css({ 'color': 'rgb(255, 0, 0)' });
            flag = true;
            return;
        }
        if (flag == true) {
            $("#presentGiftTitle").css({ 'color': 'rgb(255, 102, 0)' });
             flag = false;
             return;
         }
     }, 100);
 
 });
 //当页面初始化完毕后
 
 $(document).on("pageshow", "#commonRegister", function () { // 当进入页面二时

    var contentHeight = document.body.clientHeight;
    var header = contentHeight * 0.1;
    var content = contentHeight * 0.75;
    var footer = contentHeight * 0.15;

    $("#commonRegister #heardId").css({ 'height': header + 'px', 'background': '#4dbb49', 'line-height': header + 'px' });
    $("#commonRegister #contentId").css({ 'height': content + 'px' });
     $("#commonRegister #footerId").css({ 'height': footer + 'px', 'font-size': '70px', 'line-height': footer + 'px' });
 
 
 });
 
 
 
  
 $(document).on("pageinit", "#phoneRegister", function () {
     $("#phoneRegisterClick").on("tap", function () {
 
         var name = $("#phoneRegister #name").val();
         var password = $("#phoneRegister #password").val();
 
         var re = /^(13[0-9]{9})|(15[89][0-9]{8})$/;
         if (!re.test(name)) {
             alert("请输入正确的手机号!")
             return;
         }
         if (password.length < 6) {
             alert("密码不能小于6位数")
             return;
         }
         var checkBox = $("#phoneRegister #Checkbox1");
         if (!checkBox.is(":checked")) {
             alert("请阅读条例!")
             return;
         }
 
 
         //开始发送手机验证
 
         alertVerifyCodeMethod();
 
 
 
     });
 });
 
 
 
 
 $(document).on("pageinit", "#commonRegister", function () {
     $("#commonRegisterClick").on("tap", function () {
 
         var name = $("#commonRegister #name").val();
         var password = $("#commonRegister #password").val();
         var phonenumber = $("#commonRegister #phoneNumber").val();
         var safemail = $("#commonRegister #safeMail").val();
 
         var re = /^(13[0-9]{9})|(15[89][0-9]{8})$/;
         var mre = /\w@\w*\.\w/;
         if (name.length < 6) {
             alert("注册用户名不能小于6位数!")
             return;
         }
         if (password.length < 10) {
 
             alert("密码不能小于10位数")
             return;
         }
         if (!re.test(phonenumber)) {
 
             alert("请输入正确的手机号!")
             return;
         }
 
         if (!mre.test(safemail)) {
             alert("请输入正确的邮箱!")
             return;
         }
 
         var checkBox = $("#commonRegister #Checkbox1");
         if (!checkBox.is(":checked")) {
             alert("请阅读条例!")
             return;
         }
 
 
         shareAjaxMethord(0, name, password, phonenumber, safemail);
 
 
 
 
 
     });
 });
 
  
 
 function alertVerifyCodeMethod() {
 
     if (document.all) {
         document.getElementById("alertVerifyCodeBox").click();
     }
     else {
         var e = document.createEvent("MouseEvents");
         e.initEvent("click", true, true);
         document.getElementById("alertVerifyCodeBox").dispatchEvent(e);
     }
 }
  
  
 
 function shareAjaxMethord(index, name, password, phone, email) {
 
   
     $.ajax({
         type: "POST",
         async: false,
         dataType: "text",
         data: "&amp;sgin=" + index + "&amp;name=" + name + "&amp;password=" + password + "&amp;phone=" + phone + "&amp;email=" + email,
         url: "ajaxMediumPage.ashx",
         success: function (returnDate) {
 
             if (index == 0) {
                 if(returnDate=="1")
                 {
                     alert("注册成功!");
 
                 }
                 else
                 {
                     alert("注册失败!");
                 }
             }
             else if (inedx == 1) {
 
             }
             else {
 
             }
 
         }
     });
 }
 
 
 </script>
 </head>
 <body>
 
     <!-- 这个div data-role="page"表明它是一个页面 -->
     <div data-role="page" id="phoneRegister">
         <div data-role="header" id="heardId">
         
    <div style="margin-left:20px; font-size:17px;   font-weight:bold"><a href="#pagetwo" style="color:white; text-decoration:none;">首页>手机在线注册</a></div>
 
         </div>
 
         <div data-role="content" id="contentId">
          
 
                 <section id="posts">
 
                     <article class="post">
 
                         <header>
                             <h4 id="presentGiftTitle">使用手机后注册后立刻赠送100乐币!</h4>
                         </header>
                         <aside>
                             手机号:
                             <input id="name" type="text" placeholder="请输入注册帐号!" />
                         </aside>
                         <aside>
                             密&amp;nbsp;&amp;nbsp;码:
                             <input id="password" type="password" placeholder="请输入注册密码!" />
 
                         </aside>
 
                         <aside>
                             <div style="margin-left:-15px;">
                                 <div style="width: 20px;   height: 20px; float:left;  margin-top:5px;"> <input id="Checkbox1" style="width: 18px; height: 18px;" type="checkbox" /></div>
220                                 <div style="margin-left:40px;"><h5>打勾注册表示你同意本公司的服务条例!</h5></div>
                             </div>
 
                         </aside>
 
 
                         <aside style="margin-top:20px;">
 
                             <div id="phoneRegisterClick" style="text-align: center; border: 1px solid #666666; background: #4dbb49; color: white; height: 30px; width: 100px; line-height: 30px; ">立即注册<a href="#dialog" id="alertVerifyCodeBox" data-rel="dialog" style="display:none"></a>  </div>
                         </aside>
 
 
                         <aside style="margin-top:20px;">
                             <div style="float:right"><a href="#commonRegister" data-transition="flip">普通注册(非手机)</a></div>
 
                         </aside>
 
                         <footer></footer>
 
                     </article>
 
                 </section>
 
            
             
 
  
         </div>
 
         <div data-role="footer" id="footerId" style="background:#666666;">
 
             <div style="width:100%;height:90%;text-align:center;">
 
                 <div style="font-size:13px; height:25%;text-decoration:none;margin-top:0px;padding-top:0px; line-height:16px;">电话:400-900-8000</div>
                 <div style="font-size: 13px; height: 25%; text-decoration:none;margin-top: 0px; padding-top: 0px; line-height:16px;">渝ICP备000000-c号</div>
                 <div style="font-size: 13px; height: 25%;text-decoration:none; margin-top: 0px; padding-top: 0px; line-height: 16px;">版权所有</div>
 
             </div>
 
         </div>
 
 
     </div>
     
     
 
 
 
 
 <!-- 这个div data-role="page"表明它是一个页面 -->
     <div data-role="page" id="commonRegister">
         <div data-role="header" id="heardId">
 
             <div style="margin-left:20px; font-size:17px;   font-weight:bold"><a href="#pagetwo" style="color:white; text-decoration:none;">首页>普通用户在线注册</a></div>
 
         </div>
 
         <div data-role="content" id="contentId">
 
 
 
  
 
                 <section id="posts">
 
                     <article class="post">
 
 
                         <aside>
                             帐 号:
                             <input id="name" type="text" placeholder="请输入注册帐号!" />
                         </aside>
                         <aside>
                             密&amp;nbsp;&amp;nbsp;码:
                             <input id="password" type="password" placeholder="请输入注册密码!" />
 
                         </aside>
                         <aside>
                             手机号:
                             <input id="phoneNumber" type="text" placeholder="请输入手机号!" />
 
                         </aside>
 
                         <aside>
                             安全邮箱:
                             <input id="safeMail" type="text" placeholder="请输入安全邮箱!" />
 
                         </aside>
                         <aside>
                             <div style="margin-left:-15px;">
                                 <div style="width: 20px;   height: 20px; float:left;  margin-top:5px;"> <input id="Checkbox1" style="width: 18px; height: 18px;" type="checkbox" /></div>
311                                 <div style="margin-left:40px;"><h5>打勾注册表示你同意本公司的服务条例!</h5></div>
                            </div>

                        </aside>


                        <aside style="margin-top:20px;">

                            <div id="commonRegisterClick" style="text-align:center;border:1px solid #666666; background:#4dbb49;color:white;height:30px;width:100px; line-height:30px;">立即注册 </div>
                         </aside>
 
 
                         <aside style="margin-top:20px;">
                             <div style="float:right"><a href="#phoneRegister" data-transition="flip">手机注册(手机号)</a></div>
 
                         </aside>
 
                         <footer></footer>
 
                     </article>
                     </section>
                     
                   
 
         </div>
 
         <div data-role="footer" id="footerId" style="background:#666666;">
 
             <div style="width:100%;height:90%;text-align:center;">
 
                 <div style="font-size:13px; height:25%;text-decoration:none;margin-top:0px;padding-top:0px; line-height:16px;">电话:400-900-8000</div>
                 <div style="font-size: 13px; height: 25%;text-decoration:none; margin-top: 0px; padding-top: 0px; line-height:16px;">渝ICP备000000-c号</div>
                 <div style="font-size: 13px; height: 25%;text-decoration:none; margin-top: 0px; padding-top: 0px; line-height: 16px;">版权所有</div>
 
             </div>
 
         </div>
 
 
     </div>
  
    
 
 
 
 
 
 
 
     <div data-role="page" id="dialog" style="padding-top:auto">
         <div data-role="header" id="heardId" style="background:#4dbb49">
            <h1>输入验证码</h1>
        </div>

        <div data-role="content" id="contentId">

            <aside>
                验证码:
                <input id="verifyCode" type="text" placeholder="请输入验证码!" />
 
             </aside>
             <aside>
 
                 <div id="inputVerifyCodeDiv" style="width: 100px; height: 30px; background: #4dbb49; color:white; line-height:30px; float:right; text-align:center">确 定</div>
 
             </aside>
         </div>
 
         <div data-role="footer" id="footerId" style="background:#4dbb49">
             <h1></h1>
         </div>
     </div>
 
 
    
 </body>
 </html>
```
上面的代码直接copy到一个html页面可以运行。

