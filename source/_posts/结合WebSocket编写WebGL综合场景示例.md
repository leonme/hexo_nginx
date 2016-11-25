---
title: 结合WebSocket编写WebGL综合场景示例
date: 2016-11-07 15:52:35
comments: true
categories: HTML5
tags:
- WebGL
- HTML5
- WebSocket



---

#结合WebSocket编写WebGL综合场景示例
在WebGL场景中导入多个Babylon骨骼模型，在局域网用WebSocket实现多用户交互控制。
首先是场景截图：
![picture](http://images2015.cnblogs.com/blog/657116/201611/657116-20161104092432330-1844981251.png)
上图在场景中导入一个Babylon骨骼模型，使用asdw、空格、鼠标控制加速度移动，在移动时播放骨骼动画。
![picture](http://images2015.cnblogs.com/blog/657116/201611/657116-20161104092921783-1111568630.png)
上图在场景中加入更多的骨骼模型（兔子），兔子感知到人类接近后会加速远离人类。
![picture](http://images2015.cnblogs.com/blog/657116/201611/657116-20161104093417315-1396209353.png)
上图，一个局域网中的新玩家进入场景，（他们头上的数字是WebSocket分配的session id），兔子们受到0和1的叠加影响。
&nbsp;
具体实现：

## 一、工程结构：

&nbsp;前台WebStorm工程：
![picture](http://images2015.cnblogs.com/blog/657116/201611/657116-20161104094056596-1505476394.png)
其中map.jpg是地形高度图，tree.jpg不是树而是地面泥土的纹理。。。
LIB文件夹里是引用的第三方库（babylon.max.js是2.4版），MYLIB文件夹里是我自己编写或整理修改的库，PAGE里是专用于此网页的脚本文件
　　其中FileText.js是js前台文件处理库（这里只用到了其中的产生日期字符串函数）
　　MoveWeb.js是加速度计算库
　　Sdyq.js里是对物体对象的定义和操作监听
　　Player.js里是继承了物体对象的玩家对象和动物对象的定义
　　utils是一些其他工具
　　View是页面控制库
MODEL文件夹里是人物和兔子的骨骼模型文件。
后台MyEclipse工程：
![picture](http://images2015.cnblogs.com/blog/657116/201611/657116-20161104094910408-100628683.png)
使用JDK1.7，因为Tomcat v8.0里包含了WebSocket所用的库，所以不需要引入额外jar包，只写了一个类。

## 二、基本场景构建和骨骼模型导入：

html页面文件：

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>使用websocket联网进行数据传递，这个节点应该既可以做主机也可以加入他人的主机</title>
</head>
<body>
<div id="all_base" style="position:fixed;top:0px;left: 0px;">
    <div id="div_canvas" style="float: left;width: 75%;border: 1px solid">
        <canvas id="renderCanvas" style="width: 100%;height: 100%"></canvas>
    </div>
    <div id="div_log" style="float: left;border: 1px solid;overflow-y: scroll">
    </div>
    <div id="div_bottom" style="float: left;width: 100%;height: 100px;padding-top: 10px;padding-left: 10px">
        <input style="width: 200px" id="str_ip" value="localhost">
        <input id="str_name">
        <button id="btn_create" onclick="createScene()" disabled=true>启动场景</button>
        <button id="btn_connect" onclick="Connect()" >websocket连接</button>
        <button id="btn_close" onclick="Close()" disabled=true>关闭连接</button>
        <span id="str_id" style="display: inline-block"></span><br><br>
        <input style="width: 400px" id="str_message">
        <button id="btn_send" onclick="Send()">发送</button>
    </div>
</div>
<script src="../JS/LIB/babylon.max.js"></script>
<script src="../JS/MYLIB/View.js"></script>
<script src="../JS/LIB/jquery-1.11.3.min.js"></script>
<script src="../JS/MYLIB/FileText.js"></script>
<script src="../JS/MYLIB/Sdyq.js"></script>
<script src="../JS/MYLIB/player.js"></script>
<script src="../JS/MYLIB/MoveWeb.js"></script>
<script src="../JS/MYLIB/utils.js"></script>
<script src="../JS/PAGE/scene_link.js"></script>
<script src="../JS/PAGE/WebSocket.js"></script>
</body>
<script>
    var username="";
    window.onload=BeforeLog;
    window.onresize=Resize_Pllsselect;
    function BeforeLog()
    {
        Resize_Pllsselect();
        //DrawYzm();
        //createScene();
    }
    var str_log=document.getElementById("div_log");
    function Resize_Pllsselect()
    {
        var size=window_size();
        document.getElementById("all_base").style.height=(size.height+"px");
        document.getElementById("all_base").style.width=(size.width+"px");
        document.getElementById("div_canvas").style.height=(size.height-100+"px");
        str_log.style.height=(size.height-100+"px");
        str_log.style.width=((size.width/4)-4+"px");
        if(engine!=undefined)
        {
            engine.resize();
        }
    }

    var state="offline";

    var arr_myplayers=[];
    var arr_webplayers=[];
    var arr_animals=[];
    var arr_tempobj=[];//暂存对象初始化信息
    var tempobj;

    var canvas = document.getElementById("renderCanvas");
    var ms0=0;//上一时刻毫秒数
    var mst=0;//下一时刻毫秒数
    var schange=0;//秒差

    var skybox,
            scene,
            sceneCharger = false,
            meshOctree,
            cameraArcRotative = [],//弧形旋转相机列表
            octree;
    var engine;
    var shadowGenerator ;

</script>
</html>
```

View Code其中包含对页面尺寸大小变化的响应和一些全局变量的定义
scene_link.js文件中包含场景的构建和模型导入：

### 1、在createScene()方法的开头部分建立了一个基本的PlayGround场景：

```js
engine = new BABYLON.Engine(canvas, true);
    engine.displayLoadingUI();
    scene = new BABYLON.Scene(engine);

    //在场景中启用碰撞检测
    scene.collisionsEnabled = true;
    //scene.workerCollisions = true;//启动webworker进程处理碰撞，确实可以有效使用多核运算，加大帧数！！
    //但是worker是异步运算的，其数据传输策略会导致movewithcollition执行顺序与期望的顺序不符

    //定向光照
    var LightDirectional = new BABYLON.DirectionalLight("dir01", new BABYLON.Vector3(-2, -4, 2), scene);
    LightDirectional.diffuse = new BABYLON.Color3(1, 1, 1);//散射颜色
    LightDirectional.specular = new BABYLON.Color3(0, 0, 0);//镜面反射颜色
    LightDirectional.position = new BABYLON.Vector3(250, 400, 0);
    LightDirectional.intensity = 1.8;//强度
    shadowGenerator = new BABYLON.ShadowGenerator(1024, LightDirectional);//为该光源建立阴影生成器，用在submesh上时一直在报错，不知道为了什么

    //弧形旋转相机
    cameraArcRotative[0] = new BABYLON.ArcRotateCamera("CameraBaseRotate", -Math.PI/2, Math.PI/2.2, 12, new BABYLON.Vector3(0, 5.0, 0), scene);
    cameraArcRotative[0].wheelPrecision = 15;//鼠标滚轮？
    cameraArcRotative[0].lowerRadiusLimit = 2;
    cameraArcRotative[0].upperRadiusLimit = 22;
    cameraArcRotative[0].minZ = 0;
    cameraArcRotative[0].minX = 4096;
    scene.activeCamera = cameraArcRotative[0];
    cameraArcRotative[0].attachControl(canvas);//控制关联

    //地面
    //name,url,width,height,subdivisions,minheight,maxheight,updateble,onready,scene
    ground = BABYLON.Mesh.CreateGroundFromHeightMap("ground", "../IMAGE/map.jpg", 1000, 1000, 100, 0, 60, scene, true);//地面类型的网格
    var groundMaterial = new BABYLON.StandardMaterial("groundMat", scene);//泥土材质
    groundMaterial.diffuseTexture = new BABYLON.Texture("../IMAGE/tree.png", scene);//地面的纹理贴图
    groundMaterial.diffuseTexture.uScale = 50.0;//纹理重复效果
    groundMaterial.diffuseTexture.vScale = 50.0;
    ground.material = groundMaterial;
    ground.checkCollisions = true;//检测碰撞
    ground.receiveShadows = true;//接收影子

    //墙
    var Mur = BABYLON.Mesh.CreateBox("Mur", 1, scene);
    Mur.scaling = new BABYLON.Vector3(15, 6, 1);
    Mur.position.y = 20;
    Mur.position.z = 20;
    Mur.checkCollisions = true;
```
其中各个方法的具体用法可以参考官方的基础教程

### 2、接下来是在场景中导入第一个人物的骨骼模型：

```js
//角色导入，加载哪个mesh、文件目录、文件名、加入场景、回调函数
    BABYLON.SceneLoader.ImportMesh("", "../MODEL/him/", "him.babylon", scene, function (newMeshes, particleSystems, skeletons)
    {//载入完成的回调函数
        var Tom=new Player;
        var obj_p={};//初始化参数对象
        obj_p.mesh=newMeshes[0];//网格数据
        obj_p.scaling=new BABYLON.Vector3(0.05, 0.05, 0.05);//缩放
        obj_p.position=new BABYLON.Vector3(-5.168, 30.392, -7.463);//位置
        obj_p.rotation=new BABYLON.Vector3(0, 3.9, 0);// 旋转
        obj_p.checkCollisions=true;//使用默认的碰撞检测
        obj_p.ellipsoid=new BABYLON.Vector3(0.5, 1, 0.5);//碰撞检测椭球
        obj_p.ellipsoidOffset=new BABYLON.Vector3(0, 2, 0);//碰撞检测椭球位移
        obj_p.skeletonsPlayer=skeletons;
        obj_p.methodofmove="controlwitha";
        obj_p.name=username;
        obj_p.id=id;
        obj_p.p1="";
        obj_p.p2="../MODEL/him/";
        obj_p.p3="him.babylon";
        var len=newMeshes.length;//对于复杂的模型来说newMeshes的其他部分也必须保存下来
        var arr=[];
        for(var i=1;i<len;i++)
        {
            arr.push(newMeshes[i]);
        }
        obj_p.submeshs=arr;

        Tom.init(
            obj_p
        );
        arr_myplayers[username]=Tom;

        if(state=="online")
        {
            var arr=[];
            arr.push("addnewplayer");
            arr.push(Tom.mesh.scaling.x);
            arr.push(Tom.mesh.scaling.y);
            arr.push(Tom.mesh.scaling.z);
            arr.push(Tom.mesh.position.x);
            arr.push(Tom.mesh.position.y);
            arr.push(Tom.mesh.position.z);
            arr.push(Tom.mesh.rotation.x);
            arr.push(Tom.mesh.rotation.y);
            arr.push(Tom.mesh.rotation.z);
            arr.push(Tom.p1);
            arr.push(Tom.p2);
            arr.push(Tom.p3);
            arr.push(Tom.meshname);
            var dt=new Date();
            console.log(dt.getTime()+"send addnewplayer"+id);
            doSend(arr.join("@"));
        }

        cameraArcRotative[0].alpha = -parseFloat(arr_myplayers[username].mesh.rotation.y) - 4.69;//初始化相机角度

    });
```

   其中BABYLON.SceneLoader.ImportMesh是一个异步的把服务器端场景文件导入本地内存的方法，第一个参数表示导入场景文件中的哪一个Mesh，为空表示都导入（一个场景文件里可能包含多个模型，但该示例中的场景文件里只有一个模型，所以也叫做模型文件），第二个参数是文件所在的相对路径，第三个参数是文件名，第四个参数是文件加入的场景，第五个参数是导入完成后的回调函数。
　　回调函数的newMeshes参数是所有导入的Mesh组成的数组，skeletons参数是所有导入的骨骼动画数组。事实上一个模型可能由多个mesh组合而成，比如示例中的him模型的newMeshes[0]只是一个空壳，newMeshes[1]到newMeshes[5]才是模型各个部分的实际Mesh，后五个Mesh是newMeshes[0]的“submesh”，newMeshes[0]是后五个Mesh的parent，在理想情况下这些Mesh之间的关系和Mesh与骨骼动画（skeleton）之间的关系由Babylon引擎自动管理。
　　在回调函数中，定义Tom为一个Player“类”对象，第五行定义的obj_p对象是Player对象的初始化参数对象，Player.init()方法定义在player.js文件中：
```js
//玩家对象
Player=function()
{
    sdyq.object.call(this);
}
Player.prototype=new sdyq.object();
Player.prototype.init=function(param)
{
    param = param || {};
    sdyq.object.prototype.init.call(this,param);//继承原型的方法
    this.flag_standonground=0;//是否接触地面
    this.keys={w:0,s:0,a:0,d:0,space:0,ctrl:0,shift:0};//按键是否保持按下，考虑到多客户端并行，那么势必每个player都有自己的keys！！
    this.flag_runfast=1;//加快速度
    this.name=param.name;
    this.id=param.id;
    this.p1=param.p1;
    this.p2=param.p2;
    this.p3=param.p3;
```
　　可以看到Player对象继承自sdyq.object对象，Player对象的原型是sdyq.object对象，在Player对象的init方法中，先初始化属于原型的属性，再初始化自己这个“类”新添加的属性。
　　sdyq.object对象的定义在Sdyq.js文件中：
```js
//物体本身的属性和初始化
sdyq={};//3D引擎
sdyq.object=function()
{//在地面上加速度运动的物体

}
sdyq.object.prototype.init = function(param)
{
    this.keys={w:0,s:0,a:0,d:0,space:0,ctrl:0,shift:0};//按键是否保持按下
    this.witha0={forward:0,left:0,up:-9.82};//非键盘控制产生的加速度
    this.witha={forward:0,left:0,up:-9.82};//环境加速度，包括地面阻力和重力，现在还没有风力
    this.witha2={forward:0,left:0,up:0};//键盘控制加速度与物体本身加速度和非键盘控制产生的加速度合并后的最终加速度
    this.v0={forward:0,left:0,up:0};//上一时刻的速度
    this.vt={forward:0,left:0,up:0};//下一时刻的速度
    this.vm={forward:15,backwards:5,left:5,right:5,up:100,down:100};//各个方向的最大速度
    //this.flag_song=0;//是否接触地面
    this.flag_runfast=1;//加快速度
    this.ry0=0;//上一时刻的y轴转角
    this.ryt=0;//下一时刻的y轴转角
    this.rychange=0;//y轴转角差
    this.mchange={forward:0,left:0,up:0};//物体自身坐标系上的位移
    this.vmove=new BABYLON.Vector3(0,0,0);//世界坐标系中每一时刻的位移和量
    this.py0=0;//记录上一时刻的y轴位置，和下一时刻比较确定物体有没有继续向下运动！！

    param = param || {};
    this.mesh=param.mesh;
    this.mesh.scaling=param.scaling;
    this.mesh.position=param.position;
    this.mesh.rotation=param.rotation;
    this.mesh.checkCollisions=param.checkCollisions;
    this.mesh.ellipsoid=param.ellipsoid;
    this.mesh.ellipsoidOffset=param.ellipsoidOffset;
    this.meshname=this.mesh.name;
    this.skeletonsPlayer=param.skeletonsPlayer||[];
    this.submeshs=param.submeshs;
    this.ry0=param.mesh.rotation.y;
    this.py0=param.mesh.position.y;
    this.countstop=0;//记录物体静止了几次，如果物体一直静止就停止发送运动信息

    this.PlayAnnimation = false;

    this.methodofmove=param.methodofmove||"";
    switch(this.methodofmove)
    {
        case "controlwitha":
        {
            window.addEventListener("keydown", onKeyDown, false);//按键按下
            window.addEventListener("keyup", onKeyUp, false);//按键抬起
            break;
        }
        default :
        {
            break;
        }
    }
}
```
　　sdyq.object对象的初始化方法中包含了对mesh姿态的详细设定、对键盘操作的监听设定和适用于加速度运动的各项参数设定，各种加速度运动的物体都可以用sdyq.object对象来扩展产生。
　　在Player对象的初始化方法中还为每个玩家添加了id显示（头上的那个数字）：
```js
//在玩家头上显示名字，clone时这个也会被clone过去，要处理一下！！！！
    var lab_texture=new BABYLON.Texture.CreateFromBase64String(texttoimg2(this.id),"datatexture"+this.id,scene);//使用canvas纹理！！
    var materialSphere1 = new BABYLON.StandardMaterial("texture1"+this.id, scene);
    materialSphere1.diffuseTexture = lab_texture;
    var plane = BABYLON.Mesh.CreatePlane("plane"+this.id, 2.0, scene, false, BABYLON.Mesh.FRONTSIDE);
    //You can also set the mesh side orientation with the values : BABYLON.Mesh.FRONTSIDE (default), BABYLON.Mesh.BACKSIDE or BABYLON.Mesh.DOUBLESIDE
    materialSphere1.diffuseTexture.hasAlpha = true;//应用纹理的透明度

    plane.position=new BABYLON.Vector3(0,75,0);//其父元素应用过0.05之缩放，故而这里位移量要*20
    plane.rotation.y = Math.PI;
    plane.scaling.x=20;
    plane.scaling.y=4;
    plane.parent=this.mesh;

    plane.material=materialSphere1;
    this.lab=plane;
```
　　在这里使用了canvas现场产生纹理（术语叫“程序贴图”），其中texttoimg2（）方法的定义在utils.js文件中：
```js
//把文字转变为图片jpeg
function texttoimg(str)
{
    var c=document.createElement("canvas");
    c.height=20;
    c.width=100;
    var context = c.getContext('2d');
    context.font="normal 15px sans-serif";
    context.clearRect(0, 0, canvas.width, canvas.height);
    context.fillStyle="rgb(255,255,255)";
    context.fillRect(0,0,canvas.width,canvas.height);
    context.fillStyle = "rgb(0,0,0)";
    context.textBaseline = 'top';
    context.fillText(str,(c.width-str.length*15)/2,0, c.width*0.9);
    var str_src=c.toDataURL("image/jpeg");
    return str_src;
    //return c;
}
//把文字转变为图片PNG
function texttoimg2(str)
{
    var c=document.createElement("canvas");
    c.height=20;
    c.width=100;
    var context = c.getContext('2d');
    context.font="normal 20px sans-serif";
    context.clearRect(0, 0, canvas.width, canvas.height);
    //context.fillStyle="rgb(255,255,255)";
    //context.fillRect(0,0,canvas.width,canvas.height);
    context.fillStyle = "rgb(255,255,255)";
    context.textBaseline = 'middle';//
    context.fillText(str,(c.width-str.length*20)/2,10, c.width*0.9);
    var str_src=c.toDataURL("image/png");
    return str_src;
    //return c;
}
```
　　该代码综合网上多个教程修改而来，其中生成jpeg的难点在于canvas默认生成四通道图像，而jpeg在去除透明度通道时会自动将透明度通道变成黑色，于是jpeg一片漆黑，解决方法是先画一个不透明的白色矩形背景，挡住所有透明通道，再在白色背景上画图。
　　在模型导入完毕后把Tom设为玩家列表对象arr_myplayers的一个属性，如果当前玩家处于在线状态，则还要把其加载状态同步给其他玩家，具体同步方式稍后介绍。
　　最后把玩家的相机定位到玩家模型的身后，做第三方跟随视角状。

## 三、加速度运动控制

在scene_link.js文件的中部可以看到scene.registerBeforeRender()方法，这个方法的作用是在每次渲染前调用作为它的参数的方法，我们通过这个方法在每次渲染前对物体的下一步运动情况进行计算：

```js
scene.registerBeforeRender(function()
    {//每次渲染前
        if(scene.isReady() &amp;&amp; arr_myplayers)
        {//场景加载完毕
            if(sceneCharger == false) {
                engine.hideLoadingUI();//隐藏载入ui
                sceneCharger = true;
            }
            if(ms0==0)
            {//最开始，等一帧
                ms0=new Date();//设置初始时间
                schange=0;//初始化时间差
            }
            else
            {
                mst = new Date();//下一时刻
                schange = (mst - ms0) / 1000;
                ms0=mst;//时间越过
                //对于这段时间内的每一个物体
                for (var key in arr_myplayers)//该客户端所控制的物体
                {
                    var obj = arr_myplayers[key];
                    switch(obj.methodofmove)
                    {
                        case "controlwitha":
                        {
                            movewitha(obj);
                            //这里加上dosend！！！！，原地不动也发送吗？
                            if (state == "online")
                            {
                                if(obj.vmove.x==0&amp;&amp;obj.vmove.y==0&amp;&amp;obj.vmove.z==0&amp;&amp;obj.rychange==0)
                                {//如果位置和姿态不变
                                    if(obj.countstop>0)
                                    {//一直静止则不发送运动信息

                                    }
                                    else
                                    {
                                        obj.countstop+=1;
                                        //当前位置，当前角度，当前移动，当前姿态变化
                                        var arr = [];
                                        arr.push("updatemesh");
                                        arr.push(obj.mesh.position.x);
                                        arr.push(obj.mesh.position.y);
                                        arr.push(obj.mesh.position.z);
                                        arr.push(obj.mesh.rotation.x);
                                        arr.push(obj.mesh.rotation.y);
                                        arr.push(obj.mesh.rotation.z);
                                        arr.push(obj.vmove.x);
                                        arr.push(obj.vmove.y);
                                        arr.push(obj.vmove.z);
                                        arr.push(obj.rychange);
                                        doSend(arr.join("@"));
                                    }
                                }
                                else
                                {
                                    obj.countstop=0;
                                    //当前位置，当前角度，当前移动，当前姿态变化
                                    var arr = [];
                                    arr.push("updatemesh");
                                    arr.push(obj.mesh.position.x);
                                    arr.push(obj.mesh.position.y);
                                    arr.push(obj.mesh.position.z);
                                    arr.push(obj.mesh.rotation.x);
                                    arr.push(obj.mesh.rotation.y);
                                    arr.push(obj.mesh.rotation.z);
                                    arr.push(obj.vmove.x);
                                    arr.push(obj.vmove.y);
                                    arr.push(obj.vmove.z);
                                    arr.push(obj.rychange);
                                    doSend(arr.join("@"));
                                }
                            }

                            if((obj.vmove.x!=0||obj.vmove.y!=0||obj.vmove.z!=0||obj.rychange!=0)&amp;&amp;obj.PlayAnnimation==false)
                            {//如果开始运动，启动骨骼动画
                                obj.PlayAnnimation=true;
                                obj.beginSP(0);
                            }
                            else if(obj.vmove.x==0&amp;&amp;obj.vmove.y==0&amp;&amp;obj.vmove.z==0&amp;&amp;obj.rychange==0&amp;&amp;obj.PlayAnnimation==true)
                            {//如果运动结束，关闭骨骼动画
                                obj.PlayAnnimation=false;
                                scene.stopAnimation(obj.skeletonsPlayer[0]);
                            }
                            break;
                        }
                        default :
                        {
                            break;
                        }
                    }
                }
。。。
```
　　这里的意思是说如果玩家列表里的玩家的运动方式(methodofmove)是"controlwitha"，则使用movewitha(obj)方法计算其在这一时间段中的运动，当然，如果编写出了其他的运动方法也可以类似的扩展进来。
　　movewitha(obj)方法定义在MoveWeb.js文件中：

### 1、初速度投影

```js
function movewitha(obj)//地面上带有加速度的运动，必须站在地上才能加速，与宇宙空间中的喷气式加速度相比较
{
    obj.ryt=obj.mesh.rotation.y;
    obj.rychange=parseFloat(obj.ryt - obj.ry0);
    obj.ry0=obj.ryt;
    //将上一时刻的速度投影到下一时刻的坐标里
    var v0t = {forward: 0, left: 0, up: 0};
    v0t.forward = obj.v0.forward * parseFloat(Math.cos(obj.rychange)) + (-obj.v0.left * parseFloat(Math.sin(obj.rychange)));
    v0t.left = (obj.v0.forward * parseFloat(Math.sin(obj.rychange))) + (obj.v0.left * parseFloat(Math.cos(obj.rychange)));
    v0t.up = obj.v0.up;
    obj.v0 = v0t;
```
　　物体在这一小段时间内可能绕y轴转过了一定角度，所以要把物体在上一时刻的自身坐标系速度投影到经过变化之后的自身坐标系中。

### 2、计算水平加速度，与水平位移

```js
//计算水平加速度
    if(obj.flag_standonground==1)//在地面上才能使用水平加速度
    {
        //移动速度产生的阻力，只考虑地面阻力，不考虑空气阻力
        if (obj.v0.forward == 0) {
            obj.witha.forward = 0;
        }
        else if (obj.v0.forward > 0) {
            obj.witha.forward = -0.5;
        }
        else {
            obj.witha.forward = 0.5;
        }
        if (obj.v0.left == 0) {
            obj.witha.left = 0;
        }
        else if (obj.v0.left > 0) {
            obj.witha.left = -0.5;
        }
        else {
            obj.witha.left = 0.5;
        }
        //最终加速度由环境加速度和物体自身加速度叠加而成
        obj.witha2.forward = obj.witha.forward+obj.witha0.forward;
        obj.witha2.left = obj.witha.left+obj.witha0.left;
        //根据键盘操作设置加速度
        //处理前后
        if (obj.keys.w != 0) {
            obj.witha2.forward += 5;
        }
        else if (obj.keys.s != 0) {
            obj.witha2.forward -= 2;
        }
        //处理左右
        if (obj.keys.a != 0 &amp;&amp; obj.keys.d != 0) {//同时按下左右键则什么也不做

        }
        else if (obj.keys.a != 0) {
            obj.witha2.left += 2;
        }
        else if (obj.keys.d != 0) {
            obj.witha2.left -= 2;
        }
    }
    else
    {
        obj.witha2.forward=0;
        obj.witha2.left=0;
    }
    //根据水平加速度计算水平运动
    if(obj.witha2.forward!=0)
    {
        obj.vt.forward = obj.v0.forward + obj.witha2.forward * schange;//速度变化
        if((0 < obj.vt.forward &amp;&amp; obj.vt.forward < obj.vm.forward) || (0 > obj.vt.forward &amp;&amp; obj.vt.forward > -obj.vm.backwards))
        {//在最大速度范围内
            obj.mchange.forward = obj.witha2.forward * schange * schange + obj.v0.forward * schange;//加速度产生的距离变化
        }
        else if (obj.vm.forward <= obj.vt.forward) {//超出最大速度则按最大速度算
            obj.vt.forward = obj.vm.forward;
            obj.mchange.forward = obj.vt.forward * schange;
        }
        else if (-obj.vm.backwards >= obj.vt.forward) {
            obj.vt.forward = -obj.vm.backwards;
            obj.mchange.forward = obj.vt.forward * schange;
        }
    }
    else {//无加速度时匀速运动
        obj.mchange.forward = obj.v0.forward * schange;
    }
    if(obj.witha2.left!=0)
    {
        obj.vt.left = obj.v0.left + obj.witha2.left * schange;//速度变化
        if((0 < obj.vt.left &amp;&amp; obj.vt.left < obj.vm.left) || (0 > obj.vt.left &amp;&amp; obj.vt.left > -obj.vm.right))
        {//在最大速度范围内
            obj.mchange.left = obj.witha2.left * schange * schange + obj.v0.left * schange;//加速度产生的距离变化
        }
        else if (obj.vm.left <= obj.vt.left) {
            obj.vt.left = obj.vm.left;
            obj.mchange.left = obj.vt.left * schange;
        }
        else if (-obj.vm.right >= obj.vt.left) {
            obj.vt.left = -obj.vm.right;
            obj.mchange.left = obj.vt.left * schange;
        }
    }
    else {
        obj.mchange.left = obj.v0.left * schange;
    }
```
### 3、计算垂直加速度、垂直位移：

```js
//垂直加速度单独计算

    //正在下落，但没有下落应有的距离
    if(obj.v0.up<0&amp;&amp;obj.flag_standonground==0&amp;&amp;((obj.py0-obj.mesh.position.y)<(-obj.mchange.up)/5))
    {
        obj.v0.up=0;
        obj.flag_standonground=1;//表示接触地面
        obj.witha.up=-0.5;//考虑到下坡的存在，还要有一点向下的分量，使其能够沿地面向下但又不至于抖动过于剧烈
        obj.vm.up=5;
        obj.vm.down=5;
    }
    else if(obj.flag_standonground==1&amp;&amp;((obj.py0-obj.mesh.position.y)>(-obj.mchange.up)/5))//遇到了一个坑
    {
        obj.flag_standonground=0;
        obj.witha.up=-9.82;
        obj.vm.up=100;
        obj.vm.down=100;
    }
    obj.witha2.up = obj.witha.up;
    if (obj.witha2.up != 0&amp;&amp;(obj.flag_standonground==0||(obj.flag_standonground==1&amp;&amp;(obj.mchange.left!=0||obj.mchange.forward!=0)))) {//不在地面或者有水平位移才考虑上下加速移动

        obj.vt.up = obj.v0.up + obj.witha2.up * schange;//速度变化
        if ((0 < obj.vt.up &amp;&amp; obj.vt.up < obj.vm.up) || (0 > obj.vt.up &amp;&amp; obj.vt.up > -obj.vm.down)) {
            obj.mchange.up = obj.witha2.up * schange * schange + obj.v0.up * schange;//加速度产生的距离变化
        }
        else if (obj.vm.up <= obj.vt.up) {
            obj.vt.up = obj.vm.up;
            obj.mchange.up = obj.vt.up * schange;
        }
        else if (-obj.vm.down >= obj.vt.up) {
            obj.vt.up = -obj.vm.down;
            obj.mchange.up = obj.vt.up * schange;
        }
    }
    else {
        obj.mchange.up = obj.v0.up * schange;
    }
```
　　Babylon初级教程中提供了两种现成的碰撞检测方法，其中一种能够较精确的检测到物体掉落在地面上，但不支持事件响应或者回调函数；另一种支持事件响应，但物体的碰撞检测边界太过粗糙，无法精确检测碰撞。所以我只好用“有没有在该方向上移动应有的距离”来暂时代替碰撞检测。

### 4、应用位移：

```js
//旧的当前速度没用了，更新当前速度
    obj.v0.forward = obj.vt.forward;
    obj.v0.left = obj.vt.left;
    obj.v0.up = obj.vt.up;
    //取消过于微小的速度和位移
    if (obj.v0.forward < 0.002 &amp;&amp; obj.v0.forward > -0.002) {
        obj.v0.forward = 0;
        obj.mchange.forward=0;
    }
    if (obj.v0.left < 0.002 &amp;&amp; obj.v0.left > -0.002) {
        obj.v0.left = 0;
        obj.mchange.left=0;
    }
    if (obj.v0.up < 0.002 &amp;&amp; obj.v0.up > -0.002) {
        obj.v0.up = 0;
        obj.mchange.up=0;
    }
    if(obj.mchange.forward<0.002&amp;&amp; obj.mchange.forward > -0.002)
    {
        obj.mchange.forward=0;
    }
    if(obj.mchange.left<0.002&amp;&amp; obj.mchange.left > -0.002)
    {
        obj.mchange.left=0;
    }
    if(obj.mchange.up<0.002&amp;&amp; obj.mchange.up > -0.002)
    {
        obj.mchange.up=0;
    }
    //实施移动，未来要考虑把这个实施移动传递给远方客户端
        obj.py0=obj.mesh.position.y;
        var vectir1=(new BABYLON.Vector3(parseFloat(Math.sin(parseFloat(obj.mesh.rotation.y))) * obj.mchange.forward * obj.flag_runfast,
            0, parseFloat(Math.cos(parseFloat(obj.mesh.rotation.y))) * obj.mchange.forward * obj.flag_runfast)).negate();
        var vectir2=new BABYLON.Vector3(-parseFloat(Math.cos(parseFloat(obj.mesh.rotation.y))) * obj.mchange.left * obj.flag_runfast,
            0, parseFloat(Math.sin(parseFloat(obj.mesh.rotation.y))) * obj.mchange.left * obj.flag_runfast).negate();
        var vectir3=new BABYLON.Vector3(0, obj.mchange.up * obj.flag_runfast, 0);
        obj.vmove = vectir1.add(vectir2).add(vectir3);

        if((obj.vmove.x!=0||obj.vmove.y!=0||obj.vmove.z!=0))
        {
            obj.mesh.moveWithCollisions(obj.vmove);//似乎同一时刻只有一个物体能够使用这个方法！！
            
        }
```
　　这里把物体坐标系位移向世界坐标系位移投影的方法参考了Babylon教程示例。这里有一个思维上的难点：对于一个物体来说“模型的正向”、“mesh的正向”和“骨骼动画的正向”可能不是一个方向！这是模型绘制者使用3D模型绘制工具时的习惯造成的，如果有条件的话可以在使用3D模型前用绘制工具把模型调整一下。

## 四、数据发送：

### 1、Java后台的Websocket代码：

```java
import java.io.IOException;
import java.util.Date;
import java.util.concurrent.CopyOnWriteArraySet;

import javax.websocket.OnClose;
import javax.websocket.OnError;
import javax.websocket.OnMessage;
import javax.websocket.OnOpen;
import javax.websocket.Session;
import javax.websocket.server.ServerEndpoint;

@ServerEndpoint("/websocket3")
public class Practice {
    private static int onlineCount = 0;
    private static CopyOnWriteArraySet<Practice> webSocketSet = new CopyOnWriteArraySet<Practice>();
    private static String admin="";
    private Session session;
    private String name="";
    private String id="";
    @OnOpen
    public void onOpen(Session session)
    {
        this.session = session;
        webSocketSet.add(this);     //加入set中
        addOnlineCount();           //在线数加1
        //System.out.println("有新连接加入！当前在线人数为" + getOnlineCount());
        try 
        {
            this.sendMessage("@id:"+this.session.getId());//这个id是按总连接数来算的，可以避免重复
            this.id=this.session.getId();
        } catch (IOException e) {
            e.printStackTrace();
        }
        for(Practice item: webSocketSet)
        {   
            if(!item.id.equals(this.id))
            {
                try {
                    item.sendMessage("[getonl]"+this.id);
                } catch (IOException e) {
                    e.printStackTrace();
                    continue;
                }
            }
        }
    }
    @OnClose
    public void onClose()
    {
        for(Practice item: webSocketSet)
        {   
            if(!item.id.equals(this.id))
            {
                try {
                    item.sendMessage("[getoff]"+this.id);
                } catch (IOException e) {
                    e.printStackTrace();
                    continue;
                }
            }
        }
        if(this.id.equals(Practice.admin))//如果是admin下线了
        {
            webSocketSet.remove(this);  //从set中删除
            subOnlineCount();           //在线数减1
            if(webSocketSet.size()>0)
            {
                int i=0;
                for(Practice item: webSocketSet)
                { //挑选剩余队列中的下一个玩家作为admin
                    if(i==0)
                    {
                        i++;
                        item.name="admin";
                        Practice.admin=item.id;
                        try {
                            item.sendMessage("@name:admin");//任命
                        } catch (IOException e) {
                            e.printStackTrace();
                        }
                    }
                    
                }
            }
            else
            {
                Practice.admin="";//可能所有用户都下线了，但这个服务还在
            }
        }
        else
        {
            webSocketSet.remove(this);  //从set中删除
            subOnlineCount();           //在线数减1
        }
        
        //System.out.println("有一连接关闭！当前在线人数为" + getOnlineCount());
    }
    @OnMessage
    public void onMessage(String message, Session session) 
    {
        //System.out.println("来自客户端的消息:" + message);
        if((message.length()>6)&amp;&amp;(message.substring(0,6).equals("@name:")))//这个是命名信息//如果message不足6竟然会报错！！
        {
            String str_name=message.split(":")[1];    
            if(str_name.equals("admin"))//如果这个玩家的角色是admin
            {
                if(Practice.admin.equals(""))
                {//如果还没有admin
                    this.name=str_name;
                    Practice.admin=this.id;
                    try {
                        this.sendMessage("@name:admin");//任命
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                }
                else
                {//如果已经有了admin
                    this.name=this.id;
                    try {
                        this.sendMessage("@name:"+this.session.getId());
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                }
            }
        }
        else if((message.length()>6)&amp;&amp;(message.substring(0,7).equals("privat:")))
        {//私聊信息
            for(Practice item: webSocketSet)
            { 
                if(item.id.equals(message.split("#")[0].split(":")[1]))
                {
                    try {
                        item.sendMessage(this.id+"@"+message.split("#")[1]);
                    } catch (IOException e) {
                        e.printStackTrace();
                        continue;
                    }
                    break;
                }
            }            
        }
        else if((message.length()>6)&amp;&amp;(message.substring(0,8).equals("[admins]"))&amp;&amp;this.name.equals("admin"))
        {//由adminserver向其他server广播的信息
            for(Practice item: webSocketSet)
            {   
                if(!item.id.equals(this.id))
                {
                    try {
                        item.sendMessage(message);
                    } catch (IOException e) {
                        e.printStackTrace();
                        continue;
                    }
                }
            }            
        }
        else
        {
            //广播信息，不发给自己
            for(Practice item: webSocketSet)
            {   
                if(!item.id.equals(this.id))
                {
                    try {
                        item.sendMessage(this.id+"@"+message);
                    } catch (IOException e) {
                        e.printStackTrace();
                        continue;
                    }
                }
            }
        }               
    }
    @OnError
    public void onError(Session session, Throwable error){
        System.out.println("发生错误，关闭连接");
        for(Practice item: webSocketSet)
        {   
            if(!item.id.equals(this.id))
            {
                try {
                    item.sendMessage("[geterr]"+this.id);
                } catch (IOException e) {
                    e.printStackTrace();
                    continue;
                }
            }
        }
        if(this.id.equals(Practice.admin))//如果是admin下线了
        {
            webSocketSet.remove(this);  //从set中删除
            subOnlineCount();           //在线数减1
            if(webSocketSet.size()>0)
            {
                int i=0;
                for(Practice item: webSocketSet)
                { //挑选剩余队列中的下一个玩家作为admin
                    if(i==0)
                    {
                        i++;
                        item.name="admin";
                        Practice.admin=item.id;
                    }
                    try {
                        item.sendMessage("@name:admin");//任命
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                }
            }
            else
            {
                Practice.admin="";//可能所有用户都下线了，但这个服务还在
            }
        }
        else
        {
            webSocketSet.remove(this);  //从set中删除
            subOnlineCount();           //在线数减1
        }
        //webSocketSet.remove(this);
        //subOnlineCount(); 
        error.printStackTrace();
    }
    public synchronized void sendMessage(String message) throws IOException{//此为同步阻塞的发送方式（单发）
        this.session.getBasicRemote().sendText(message);
        Date dt=new Date();
        //System.out.println(dt.getTime()+"==>>"+message);
        //this.session.getAsyncRemote().sendText(message);
    }
    public void sendMessage2(String message) throws IOException{//此为异步非阻塞的发送方式（单发）
        this.session.getAsyncRemote ().sendText(message);
        Date dt=new Date();
        //System.out.println(dt.getTime()+"==>>"+message);
        //this.session.getAsyncRemote().sendText(message);
    }
    
    public static synchronized int getOnlineCount() {
        return onlineCount;
    }
    public static synchronized void addOnlineCount() {
        Practice.onlineCount++;
    }
    public static synchronized void subOnlineCount() {
        Practice.onlineCount--;
    }
}
```
　　这个方法参考网上的一篇WebSocket教程编写而成，其大意是为每个上线的用户分配id，并把第一个自称是admin的用户设为主机，在主机用户下线后再任命另一个用户为主机。在数据同步方面提供“私聊”、“admin广播”、“普通广播”三种方式。在传输数据时遇到多个异步传输需求对this.session.getAsyncRemote ()争抢导致报错的问题，经过试验使用同步模式的sendMessage方法可以避免这一错误，至于用户量提升后同步方法能否提供足够的传输效率还要进一步研究。

### 2、前台的WebSocket代码位于WebSocket.js中：

```js
var wsUri="";
var websocket;
var id="";//这个是sessionid！！

//建立连接
function Connect()
{//
    var location = (window.location+'').split('/');
    var IP=location[2];
    //wsUri="ws://"+IP+"/JUMP/websocket3";
    wsUri="ws://"+$("#str_ip")[0].value+":8081/PRACTICE/websocket3";
    try
    {
        websocket = new WebSocket(wsUri);//建立ws连接
        $("#str_ip")[0].disabled=true;
        $("#str_name")[0].disabled=true;
        username=$("#str_name")[0].value;
        $("#btn_create")[0].disabled=false;

        websocket.onopen = function(evt) //连接建立完毕
        {
            onOpen(evt)
        };
        websocket.onmessage = function(evt) {//收到服务器发来的信息
            onMessage(evt)
        };
        websocket.onclose = function(evt) {
            onClose(evt)
        };
        websocket.onerror = function(evt) {
            onError(evt)
        };
    }
    catch(e)
    {
        alert(e);
        $("#str_ip")[0].disabled=false;
        $("#str_name")[0].disabled=false;
    }
}
//连接建立完成的回调函数
function onOpen(evt) {
    state="online";
    doSend("@name:"+$("#str_name")[0].value);//连接建立后把浏览器端的用户信息传过去
}
//关闭连接
function Close()
{
    websocket.close();//浏览器端关闭连接

}
function onClose(evt) {
    writeToScreen('<span style="color: red;">本机连接关闭</span>');
    $("#str_ip")[0].disabled=false;
    $("#str_name")[0].disabled=false;
    state="offline";
}
//收到服务器端发来的消息
function onMessage(evt) {
    var str_data=evt.data;
    if(str_data.substr(0,4)=="@id:")//从服务端返回了sessionid
    {
        id=str_data.split(":")[1];
        $("#str_id")[0].innerHTML=id;
    }
    else if(str_data.substr(0,6)=="@name:")//从服务端返回了任命信息
    {
        username=str_data.split(":")[1];
        if(username=="admin")
        {
            $("#str_name")[0].value=username;
            writeToScreen('<span style="color: blue;">本机被任命为admin</span>');
        }
        else
        {
            $("#str_name")[0].value=username;
            writeToScreen('<span style="color: blue;">已存在admin，本机被重命名为'+username+'</span>');
        }
    }
。。。
    
//发生错误
function onError(evt) {
    writeToScreen('<span style="color: red;">ERROR:</span> '+ evt.data);
    $("#str_ip")[0].disabled=false;
    $("#str_name")[0].disabled=false;
    state="offline";
}
//发送命令行信息
function Send()
{
    doSend($("#str_message")[0].value);
}
//向服务端发送信息
function doSend(message)
{
    websocket.send(message);
}
//写入操作日志
function writeToScreen(message)
{
    var pre = document.createElement("p");
    pre.style.wordWrap = "break-word";
    pre.innerHTML = MakeDateStr()+"->"+message;
    str_log.appendChild(pre);
}
```
　　参考网上教程编写的常规WebSocket通信代码

### 3、建立一些“NPC物体”，也要对他们的状态进行同步

NPC物体的建立代码在scene_link.js文件的110行：
![picture](http://images.cnblogs.com/OutliningIndicators/ContractedBlock.gif)
![picture](http://images.cnblogs.com/OutliningIndicators/ExpandedBlockStart.gif)

```js
//一次引入十个物体
    BABYLON.SceneLoader.ImportMesh("Rabbit", "../MODEL/Rabbit/", "Rabbit.babylon", scene, function (newMeshes, particleSystems, skeletons)
    {

        var rabbitmesh = newMeshes[1];
        //shadowGenerator.getShadowMap().renderList.push(rabbitmesh);//加入阴影渲染队列
        var rabbit=new Animal;
        var obj_p={
            mesh:rabbitmesh,
            scaling:new BABYLON.Vector3(0.04, 0.04, 0.04),//缩放
            position:new BABYLON.Vector3(Math.random()*100, 30, Math.random()*100),//位置
            rotation:new BABYLON.Vector3(0, Math.random()*6.28, 0),// 旋转
            //rotation:new BABYLON.Vector3(0, 0, 0),
            checkCollisions:true,//使用默认的碰撞检测
            ellipsoid:new BABYLON.Vector3(1, 1, 1),//碰撞检测椭球
            ellipsoidOffset:new BABYLON.Vector3(0, 0, 0),//碰撞检测椭球位移
            fieldofvision:50,//视野
            powerofmove:1,//移动力量
            methodofmove:"controlwitha",
            state:"eat",
            id:"rabbit"
        };
        rabbit.init(obj_p);
        arr_animals["rabbit"]=rabbit;
        scene.beginAnimation(rabbitmesh.skeleton, 0, 72, true, 0.8);
        console.log("rabbit");

        for(i=0;i<9;i++)
        {
            var rabbitmesh2 = rabbitmesh.clone("rabbit2"+(i+2));
            rabbitmesh2.skeleton = rabbitmesh.skeleton.clone("clonedSkeleton");
            var rabbit2=new Animal;
            var obj_p2={
                mesh:rabbitmesh2,
                scaling:new BABYLON.Vector3(0.04, 0.04, 0.04),//缩放
                position:new BABYLON.Vector3(Math.random()*100, 30, Math.random()*100),//位置
                rotation:new BABYLON.Vector3(0, Math.random()*6.28, 0),// 旋转
                //rotation:new BABYLON.Vector3(0, 0, 0),// 旋转
                checkCollisions:true,//使用默认的碰撞检测
                ellipsoid:new BABYLON.Vector3(1, 1, 1),//碰撞检测椭球
                ellipsoidOffset:new BABYLON.Vector3(0, 0, 0),//碰撞检测椭球位移
                fieldofvision:50,//视野
                powerofmove:1,//移动力量
                methodofmove:"controlwitha",
                state:"eat",
                id:"rabbit"+(i+2)
            };
            rabbit2.init(obj_p2);
            arr_animals["rabbit"+(i+2)]=rabbit2;
            scene.beginAnimation(rabbitmesh2.skeleton, 0, 72, true, 0.8);
            console.log("rabbit"+(i+2));
            //shadowGenerator.getShadowMap().renderList.push(rabbitmesh2);//报错
        }

    });
```
View Code　　这里建立了十个物体，其中只有第一个物体的骨骼模型是从模型文件中导入内存的，其他的物体都在内存中从第一个物体“克隆”而来。注意，在Babylon看来骨骼也是一种特殊的网格（Mesh），所以对网格和骨骼的克隆是分别进行的，再把骨骼克隆的结果作为网格克隆结果的骨骼属性。
　　十个物体被初始化为Animal对象，Animal对象与Player对象类似，都是从sdyq.object对象派生而来。
NPC物体的运动控制和运动同步代码在317行：
```js
if(username=="admin")//由主机对所有NPC物体的相互作用进行计算，再把作用结果同步到各个分机
                {
                    //计算每个动物和所有玩家的交互效果
                    var arr_rabbitmove=[];
                    for(var key in arr_animals)
                    {
                        var rabbit=arr_animals[key];
                        var v_face=new BABYLON.Vector3(0,0,0);
                        var newstate="eat";
                        for(var key2 in arr_myplayers)
                        {
                            var obj=arr_myplayers[key2];
                            var v_sub=rabbit.mesh.position.subtract(obj.mesh.position);
                            var distans=v_sub.length();//兔子与人类之间的距离
                            if(distans<rabbit.fieldofvision)//在视野内发现了人类
                            {
                                newstate="run";
                                v_face.addInPlace(v_sub.normalize().scaleInPlace(1/distans));//越近则影响越大
                            }
                        }
                        for(var key2 in arr_webplayers)
                        {
                            var obj=arr_webplayers[key2];
                            var v_sub=rabbit.mesh.position.subtract(obj.mesh.position);
                            var distans=v_sub.length();
                            if(distans<rabbit.fieldofvision)//在视野内发现了人类
                            {
                                newstate="run";
                                v_face.addInPlace(v_sub.normalize().scaleInPlace(1/distans));
                            }
                        }
                        if(newstate=="run"&amp;&amp;rabbit.state=="eat")
                        {//从eat状态变为run状态
                            rabbit.state="run";
                            rabbit.powerofmove=3;
                            scene.beginAnimation(rabbit.mesh.skeleton, 0, 72, true, 2.4);
                        }
                        else if(newstate=="eat"&amp;&amp;rabbit.state=="run")
                        {//从run状态变为eat状态
                            rabbit.state="eat";
                            rabbit.powerofmove=1;
                            scene.beginAnimation(rabbit.mesh.skeleton, 0, 72, true, 0.8);
                        }

                        var num_pi=Math.PI;
                        if(rabbit.state=="eat")//一直没有见到人类
                        {
                            rabbit.waitforturn+=schange;
                            if(rabbit.waitforturn>3)
                            {//每3秒随机决定一个运动方向
                                rabbit.waitforturn=0;
                                rabbit.witha0={forward:(Math.random()-0.5)*2*rabbit.powerofmove,up:0,left:(Math.random()-0.5)*2*rabbit.powerofmove};
                                rabbit.mesh.rotation.y=Math.random()*6.28;
                            }
                            movewitha(rabbit);
                            //这些兔子的数据汇总起来一起传
                            arr_rabbitmove.push([key,rabbit.mesh.position,rabbit.mesh.rotation,rabbit.vmove,rabbit.rychange,rabbit.state]);
                        }
                        else if(rabbit.state=="run")
                        {//奔跑远离人类
                            rabbit.witha0={forward:-rabbit.powerofmove,up:0,left:0};//这个是兔子的“自主加速度”！！不是世界加速度，也不是键盘控制产生的加速度
                            rabbit.mesh.rotation.y=(Math.atan(v_face.z/v_face.x)+num_pi*1/2);
                            movewitha(rabbit);
                            arr_rabbitmove.push([key,rabbit.mesh.position,rabbit.mesh.rotation,rabbit.vmove,rabbit.rychange,rabbit.state]);
                        }
                    }
                    var str_data="[admins]"+JSON.stringify(arr_rabbitmove);
                    doSend(str_data);
                }
```
　　在这个模式中，由主机承担所有的NPC物体运动计算工作，再把所有计算结果同步到分机，&nbsp;
　　起初对于不太复杂的玩家信息数据，我简单的用分隔符“@”将各个字段拼接成一个字符串向其他客户端传递，后来随着数据结构的复杂化，我改用JSON传递结构化的数据。

### 4、客户端对服务器端传来的信息进行处理：

#### a、添加新玩家，代码位于WebSocket.js184行：

```js
case "addnewplayer":
                    {//感知到加入了一个新的玩家，把新玩家加入到自己的场景里,先查询场景中是否已经有同名的mesh，如果有则使用clone方法同步加载，如果没有再使用import异步导入，这样做的根本原因在于import方法导入模型的返回函数里无法自定义参数
                        var dt=new Date();
                        console.log(dt.getTime()+"get addnewplayer"+arr[0]);
                        var flag=0;//加载完成标志
                        for(var key in arr_myplayers)//先在本机的玩家列表里找
                        {
                            if(arr_myplayers[key].meshname==arr[14])//如果与主控物体的meshname相同
                            {

                                var obj_key=arr_myplayers[key];
                                arr_webplayers[arr[0]] = MyCloneplayer(obj_key,arr);
                                shadowGenerator.getShadowMap().renderList.push(arr_webplayers[arr[0]].mesh);//阴影生成器似乎对含有submesh的Mesh不起作用
                                writeToScreen('<span style="color: blue;">addnewplayer: ' + arr[0] + '</span>');
                                flag=1;

                                //异步加入新玩家之后，还要把自己的信息发给新玩家，让新玩家添加自己（私聊）
                                addoldplayer(arr[0]);
                                break;
                            }
                        }
                        if(flag==0)//再在网络玩家列表里查找
                        {
                            for(var key in arr_webplayers)
                            {
                                if(arr_webplayers[key].meshname==arr[14])//如果与主控物体的meshname相同
                                {
                                    var obj_key=arr_webplayers[key];
                                    arr_webplayers[arr[0]] = MyCloneplayer(obj_key,arr);
                                    shadowGenerator.getShadowMap().renderList.push(arr_webplayers[arr[0]].mesh);
                                    writeToScreen('<span style="color: blue;">addnewplayer: ' + arr[0] + '</span>');
                                    flag=1;
                                    //异步加入新玩家之后，还要把自己的信息发给新玩家，让新玩家添加自己（私聊）
                                    addoldplayer(arr[0]);
                                    break;
                                }
                            }
                        }
                        if(flag==0)//都没找着，就新建
                        {
                            //arr[14]保存着meshname可以作为异步方法间的纽带,如果发生同时加载两个一样的不存在的mesh时，让后来的那个通过websocket延时重发
                            if(tempobj[arr[14]]&amp;&amp;tempobj[arr[14]]!="OK")//这个暂存位正在被占用
                            {
                                doSend("privat:" + id + "#" + str_data);//请求websocket服务器再次把这个指令发给自己，以等待占用者完成操作
                            }
                            else
                            {
                                tempobj[arr[14]] = arr;//用tempobj暂存该物体的初始化参数
                                BABYLON.SceneLoader.ImportMesh(arr[11], arr[12], arr[13], scene, function (newMeshes, particleSystems, skeletons) {//载入完成的回调函数
                                    var Tom = new Player;
                                    var obj_p = {};
                                    obj_p.mesh = newMeshes[0];//网格数据
                                    var arr = tempobj[obj_p.mesh.name];
                                    obj_p.scaling = new BABYLON.Vector3(parseFloat(arr[2]), parseFloat(arr[3]), parseFloat(arr[4]));//缩放
                                    obj_p.position = new BABYLON.Vector3(parseFloat(arr[5]), parseFloat(arr[6]), parseFloat(arr[7]));//位置
                                    obj_p.rotation = new BABYLON.Vector3(parseFloat(arr[8]), parseFloat(arr[9]), parseFloat(arr[10]));// 旋转
                                    obj_p.checkCollisions = true;//使用默认的碰撞检测
                                    obj_p.ellipsoid = new BABYLON.Vector3(0.5, 1, 0.5);//碰撞检测椭球
                                    obj_p.ellipsoidOffset = new BABYLON.Vector3(0, 2, 0);//碰撞检测椭球位移
                                    obj_p.skeletonsPlayer = skeletons;
                                    obj_p.methodofmove = "controlwitha";
                                    obj_p.id = arr[0];
                                    obj_p.name = arr[0];
                                    obj_p.p1 = arr[11];
                                    obj_p.p2 = arr[12];
                                    obj_p.p3 = arr[13];
                                    var len=newMeshes.length;//对于复杂的模型来说newMeshes的其他部分也必须保存下来
                                    var arr=[];
                                    for(var i=1;i<len;i++)
                                    {
                                        arr.push(newMeshes[i]);
                                    }
                                    obj_p.submeshs=arr;
                                    Tom.init(
                                        obj_p
                                    );
                                    tempobj[obj_p.mesh.name] = "OK";
                                    arr_webplayers[arr[0]] = Tom;
                                    shadowGenerator.getShadowMap().renderList.push(arr_webplayers[arr[0]].mesh);

                                    writeToScreen('<span style="color: blue;">addnewplayer: ' + arr[0] + '</span>');
                                    flag=1;
                                    //异步加入新玩家之后，还要把自己的信息发给新玩家，让新玩家添加自己（私聊）
                                    addoldplayer(arr[0]);

                                });
                            }
                        }
                        break;
                    }

                    case "addoldplayer":
                    {//添加一个前辈玩家，此时默认前辈的网络玩家列表里已经有了本元素，所以不需要再通知前辈玩家添加本玩家，多个前辈玩家同时返回如何处理？用出入栈方式？能保证先进先出？
                         var dt=new Date();
                         console.log(dt.getTime()+"get addoldplayer"+arr[0]);
                         var flag=0;
                         for(var key in arr_myplayers)
                         {
                             if(arr_myplayers[key].meshname==arr[14])//如果与主控物体的meshname相同
                             {
                                 var obj_key=arr_myplayers[key];
                                 arr_webplayers[arr[0]] =MyCloneplayer(obj_key,arr);
                                 shadowGenerator.getShadowMap().renderList.push(arr_webplayers[arr[0]].mesh);
                                 writeToScreen('<span style="color: blue;">addoldplayer: ' + arr[0] + '</span>');
                                 flag=1;
 
                                 break;
                             }
                         }
                         if(flag==0)//再在网络元素里查找
                         {
                             for(var key in arr_webplayers)
                             {
                                 if(arr_webplayers[key].meshname==arr[14])//如果与主控物体的meshname相同
                                 {
                                     var obj_key=arr_webplayers[key];
                                     arr_webplayers[arr[0]] =  MyCloneplayer(obj_key,arr);
                                     shadowGenerator.getShadowMap().renderList.push(arr_webplayers[arr[0]].mesh);
                                     writeToScreen('<span style="color: blue;">addoldplayer: ' + arr[0] + '</span>');
                                     flag=1;
                                     break;
                                 }
                             }
                         }
                         if(flag==0)//都没找着，就新建
                         {
                             //arr[14]保存着meshname可以作为异步方法间的纽带,如果发生同时加载两个一样的不存在的mesh时，让后来的那个通过websocket延时重发
                             if(tempobj[arr[14]]&amp;&amp;tempobj[arr[14]]!="OK")//这个暂存位正在被占用
                             {
                                 doSend("privat:" + id + "#" + str_data);//请求websocket服务器再次把这个指令发给自己，以等待占用者完成操作
                             }
                             else
                             {
                                 tempobj[arr[14]] = arr;
                                 BABYLON.SceneLoader.ImportMesh(arr[11], arr[12], arr[13], scene, function (newMeshes, particleSystems, skeletons) {//载入完成的回调函数
                                     var Tom = new Player;
                                     var obj_p = {};
                                     obj_p.mesh = newMeshes[0];//网格数据
                                     var arr = tempobj[obj_p.mesh.name];
                                     obj_p.scaling = new BABYLON.Vector3(parseFloat(arr[2]), parseFloat(arr[3]), parseFloat(arr[4]));//缩放
                                     obj_p.position = new BABYLON.Vector3(parseFloat(arr[5]), parseFloat(arr[6]), parseFloat(arr[7]));//位置
                                     obj_p.rotation = new BABYLON.Vector3(parseFloat(arr[8]), parseFloat(arr[9]), parseFloat(arr[10]));// 旋转
                                     obj_p.checkCollisions = true;//使用默认的碰撞检测
                                     obj_p.ellipsoid = new BABYLON.Vector3(0.5, 1, 0.5);//碰撞检测椭球
                                     obj_p.ellipsoidOffset = new BABYLON.Vector3(0, 2, 0);//碰撞检测椭球位移
                                     obj_p.skeletonsPlayer = skeletons;
                                     obj_p.methodofmove = "controlwitha";
                                     obj_p.id = arr[0];
                                     obj_p.name = arr[0];
                                     obj_p.p1 = arr[11];
                                     obj_p.p2 = arr[12];
                                     obj_p.p3 = arr[13];
                                     var len=newMeshes.length;//对于复杂的模型来说newMeshes的其他部分也必须保存下来
                                     var arr=[];
                                     for(var i=1;i<len;i++)
                                     {
                                         arr.push(newMeshes[i]);
                                     }
                                     obj_p.submeshs=arr;
                                     Tom.init(
                                         obj_p
                                     );
                                     tempobj[obj_p.mesh.name] = "OK";
                                     arr_webplayers[arr[0]] = Tom;
                                     shadowGenerator.getShadowMap().renderList.push(arr_webplayers[arr[0]].mesh);
                                     writeToScreen('<span style="color: blue;">addoldplayer: ' + arr[0] + '</span>');
                                     flag=1;
 
                                 });
                             }
                         }
                         break;
                     }
```
　　这里的主要难点是如何处理多个异步的添加玩家请求，经过思考和实验部分的解决了问题。

#### b、多个客户端之间同步玩家的状态：

```js
case "updatemesh":
                    {
                        var dt=new Date();
                        console.log(dt.getTime()+"get updatemesh"+arr[0]);
                        var obj = arr_webplayers[arr[0]];//从网络玩家列表里找到这个玩家
                        if(obj)
                        {
                            var mesh = obj.mesh;
                            mesh.position.x = parseFloat(arr[2]);//这里已经产生了位移效果！！
                            mesh.position.y = parseFloat(arr[3]);
                            mesh.position.z = parseFloat(arr[4]);
                            mesh.rotation.x = parseFloat(arr[5]);
                            mesh.rotation.y = parseFloat(arr[6]);
                            mesh.rotation.z = parseFloat(arr[7]);
                           
                            obj.vmove.x=parseFloat(arr[8]);
                            obj.vmove.y=parseFloat(arr[9]);
                            obj.vmove.z=parseFloat(arr[10]);
                           
                            obj.rychange= parseFloat(arr[11]);
                            obj.countstop=0;//唤醒该物体的运动
                            if(obj.PlayAnnimation == false&amp;&amp;(obj.vmove.x != 0 || obj.vmove.y != 0 || obj.vmove.z != 0 || obj.rychange != 0))
                            {
                                obj.PlayAnnimation = true;
                                obj.beginSP(0);
                            }
                        }
                        break;
                    }
```
另一部分控制网络玩家的代码在
scene.registerBeforeRender（）中：
```js
for (var key2 in arr_webplayers)//对于由其他客户端控制的物体
                {
                    var obj = arr_webplayers[key2];
                    switch(obj.methodofmove)
                    {
                        case "controlwitha":
                        {
                            obj.lab.rotation.y=(-1.55 - cameraArcRotative[0].alpha)-obj.mesh.rotation.y;
                            if(obj.countstop<=4)
                            {
                                if ((obj.vmove.x != 0 || obj.vmove.y != 0 || obj.vmove.z != 0 || obj.rychange != 0)&amp;&amp; obj.PlayAnnimation == false) {
                                    obj.PlayAnnimation = true;
                                    obj.beginSP(0);
                                    obj.mesh.moveWithCollisions(obj.vmove);
                                }
                                else if (obj.vmove.x == 0 &amp;&amp; obj.vmove.y == 0 &amp;&amp; obj.vmove.z == 0 &amp;&amp; obj.rychange == 0 &amp;&amp; obj.PlayAnnimation == true) {
                                    obj.countstop++;
                                    if (obj.countstop > 4)//连续4帧没有该对象的运动信息传过来，则该物体的运动计算进入休眠
                                    {
                                        obj.PlayAnnimation = false;
                                        obj.stopSP(0);
                                    }
                                }
                            }
                            break;
                        }
                        default :
                        {
                            break;
                        }
                    }
                }
```
#### c、最后是对NPC物体运动同步的处理：

```js
case "[admins]":
            {
                if(username=="admin")
                {//adminserver不处理admin广播

                }
                else
                {
                    if(!scene.isReady() || !arr_myplayers)
                    {
                        return;
                    }
                    var arr_rabbitmove=JSON.parse(str_data.substr(8));
                    var len=arr_rabbitmove.length;
                    for(var i=0;i<len;i++)
                    {
                        var arr=arr_rabbitmove[i];
                        var rabbit=arr_animals[arr[0]];
                        var rabbitmesh=rabbit.mesh;
                        rabbitmesh.position=arr[1];
                        rabbitmesh.rotation=arr[2];
                        rabbit.vmove=arr[3];
                        rabbit.rychange=arr[4];

                        if(arr[5]=="run"&amp;&amp;rabbit.state=="eat")
                        {
                            rabbit.state="run";
                            rabbit.powerofmove=3;
                            scene.beginAnimation(rabbitmesh.skeleton, 0, 72, true, 2.4);
                        }
                        else if(arr[5]=="eat"&amp;&amp;rabbit.state=="run")
                        {
                            rabbit.state="eat";
                            rabbit.powerofmove=1;
                            scene.beginAnimation(rabbitmesh.skeleton, 0, 72, true, 0.8);
                        }
                    }
                }
                break;
            }
```
解开JSON，对每一个NPC物体分别处理。

## 五、部署和使用：

程序完整代码在可以在https://github.com/ljzc002/WebGL2下载，我编写的代码基于MIT协议发布，使用的第三方库文件按其原有的发布协议发布。
部署：把PRACTICE/WebRoot/下的所有文件复制到PRACTICE3/目录下，将PRACTICE3/复制到Tomcat的WebApps/目录下，把PRACTICE3/改名为PRACTICE/，启动Tomcat，访问scene_link.html页面。
使用：第一个input输入Websocket所在IP，第二个input输入用户名（输入admin表示申请作为主机），点击“websocket连接”建立连接，点击“启动场景”启动WebGL场景。

## 六、写在后面的话：

限于时间和编程水平，程序中还有很多bug和缺陷，欢迎大家批评指正。
音乐、美术、文学等常规的人类自我表达方式都要求人不断的在很短的时间片内对事物产生足够充分的认识，非有过人之天赋与辛苦之训练而不可成就；相对而言编程可以通过分解、封装、复用将空间复杂度转化为时间复杂度，任何普通人经过努力都能有所收获。