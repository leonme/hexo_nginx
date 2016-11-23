---
title: HTML5大数据可视化效果（二）可交互地铁线路图
date: 2016-11-07 15:51:58
comments: true
categories: HTML5
tags:
- HTML5
- 大数据



---

#HTML5大数据可视化效果（二）可交互地铁线路图

[HTML5大数据可视化效果](http://www.cnblogs.com/twaver/p/4547924.html)
”系列，以示鼓励（P.S. 其实还挺有压力的，后浪推前浪，新人赶旧人。我们这些老鸟也得注意，免得让00后给抢了饭碗）

![picture](http://images2015.cnblogs.com/blog/311983/201611/311983-20161103121614533-2062155906.jpg)
![picture](http://images2015.cnblogs.com/blog/311983/201611/311983-20161103121656721-376610979.jpg)



![picture](http://images2015.cnblogs.com/blog/311983/201611/311983-20161103121921361-1178958456.gif)



![picture](http://images2015.cnblogs.com/blog/311983/201611/311983-20161103122154049-1255275872.gif)

```javascript
twaver.Util.registerImage('station',{     
	w: linkWidth*1.6,     
	h: linkWidth*1.6,     
	v: function (data, view) {         
		var result = [];         
		if(data.getClient('focus')){             
			result.push({                 
				shape: 'circle',                 
				r: linkWidth*0.7,                 
				lineColor:  data.getClient('lineColor'),                 
				lineWidth: linkWidth*0.2,                 
				fill: 'white',             
			});             
			result.push({                 
				shape: 'circle',                 
				r: linkWidth*0.2,                 
				fill:  data.getClient('lineColor'),             
			});         
		}else{             
			result.push({                 
				shape: 'circle',                 
				r: linkWidth*0.6,                 
				lineColor: data.getClient('lineColor'),                 
				lineWidth: linkWidth*0.2,                 
				fill: 'white',             
			});         
		}         
	return result;     
} });  
```
 来看代码：
###1. 代码1
```javascript
twaver.Util.registerImage('rotateArrow', { 
w: 124, 
h: 124, 
v: [{ 
    shape: 'vector', 
    name: 'doubleArrow', 
    rotate: 360, 
    animate: [{ 
        attr: 'rotate', 
          to: 0, 
          dur: 2000, 
          reverse: false, 
          repeat: Number.POSITIVE_INFINITY 
      }] 
  }] 
}); 
```
       另外，在单击和双击站点时，还实现了selected和loading的动画效果，值得点赞！
       ![picture](http://images2015.cnblogs.com/blog/311983/201611/311983-20161103141545565-2010504104.gif)
       ![picture](http://images2015.cnblogs.com/blog/311983/201611/311983-20161103141605065-1237423734.gif)


​       
​       
       ![picture](http://images2015.cnblogs.com/blog/311983/201611/311983-20161103141731096-1466288424.gif)

​       
###2. 代码2
```js
 network.setZoomManager(new twaver.vector.MixedZoomManager(network)); 
 network.setMinZoom(0.2); 
 network.setMaxZoom(3); 
 network.setZoomVisibilityThresholds({ 
     label : 0.6, 6.    }); 
```
![picture](http://images2015.cnblogs.com/blog/311983/201611/311983-20161103141931643-856207231.gif)


![picture](http://images2015.cnblogs.com/blog/311983/201611/311983-20161103143834486-1796262740.gif)


![picture](http://images2015.cnblogs.com/blog/311983/201611/311983-20161103143940158-1173344247.gif)

来鉴赏下小弟的成果。

数据结构，按照站点、线路、杂项三大块来组织，结构清晰，利于遍历、查询等操作。

###3. 代码3
```json
{ 
   "stations":{ 
       "l01s01":{ }, 
       ………… 
   } 
   "lines":{ 
       "l01":{……}, 
       ………… 
   } 
     "sundrys":{ 
         "railwaystationshanghai":{……}, 
         ………… 
     } 
 } 
```
###4. 代码4
```json
"l01s01":{ 
      "id":"l01s01", 
          "name":"莘庄", 
          "loc":{"x":419,"y":1330}, 
          "label":"bottomright.bottomright", 
      }, 
```
###5. 代码5
```javascript
function loadJSON(path,callback){ 2.        var xhr = new XMLHttpRequest(); 3.        xhr.onreadystatechange = function(){ 4.            if (xhr.readyState === 4) { 5.                if (xhr.status === 200) { 6.                   dataJson = JSON.parse(xhr.responseText); 7.                   callback &amp;&amp; callback(); 8.               } 9.           } 10.       }; 11.       xhr.open("GET", path, true); 12.       xhr.send(); 13.    } 
```
###6. 代码6
```javascript
function init(){ 
loadJSON("shanghaiMetro.json", function(){ 
        initNetwork(dataJson); 
        initNode(dataJson); 
    }); 
} 
```
###7. 代码7
```javascript
for(staId in json.stations){ 
var station = json.stations[staId]; 
staNode = new twaver.Node({ 
    id: staId, 
    name: station.name, 
    image:'station', 
}); 
staNode.s('label.color','rgba(99,99,99,1)'); 
staNode.s('label.font','12px 微软雅黑'); 
 staNode.s('label.position',station.label); 
 staNode.setClient('location',station.loc); 
 box.add(staNode); 13.    } 
```
###8. 代码8
```js
for(lineId in json.lines) { 
   &hellip;&hellip; 
   for(staSn in line.stations) {
       &hellip;&hellip; 
       var link = new twaver.Link(linkId,prevSta,staNode); 
       link.s('link.color', line.color); 
       link.s('link.width', linkWidth);
       link.setToolTip(line.name); 
       box.add(link); 
    } 
} 
```
最后再加入图标，一张原始的地铁图就呈现出来了。
![picture](http://images2015.cnblogs.com/blog/311983/201611/311983-20161103144715205-1780446914.png)



![picture](http://images2015.cnblogs.com/blog/311983/201611/311983-20161103144816315-1456837843.png)



```javascript
var createTurnSta = function(line, staSn){     staTurn = new twaver.Node(staSn);     staTurn.setImage();     staTurn.setClient('lineColor',line.color);     staTurn.setClient('lines',[line.id]);     var loc = line.stations[staSn];     staTurn.setClient('location',loc);     box.add(staTurn);     return staTurn; } 
```


```javascript
var createFollowSta = function(json, line, staNode, staId){     staFollow = new twaver.Follower(staId);     staFollow.setImage();     staFollow.setClient('lineColor',line.color);     staFollow.setClient('lines',[line.id]);     staFollow.setHost(staNode);     var az = azimuth[staId.substr(6,2)];     var loc0 = json.stations[staId.substr(0,6)].loc;     var loc = {x:loc0.x+az.x, y:loc0.y+az.y};     staFollow.setClient('location',loc);     box.add(staFollow);     return staFollow; } 
```
![picture](http://images2015.cnblogs.com/blog/311983/201611/311983-20161103144955643-1549309486.png)


```javascript
var azimuth = {     bb: {x: 0, y: linkWidth*zoom/2},     tt: {x: 0, y: -linkWidth*zoom/2},     rr: {x: linkWidth*zoom/2, y: 0},     ll: {x: -linkWidth/2, y: 0},     br: {x: linkWidth*zoom*0.7/2, y: linkWidth*zoom*0.7/2},     bl: {x: -linkWidth*zoom*0.7/2, y: linkWidth*zoom*0.7/2},     tr: {x: linkWidth*zoom*0.7/2, y: -linkWidth*zoom*0.7/2},     tl: {x: -linkWidth*zoom*0.7/2, y: -linkWidth*zoom*0.7/2},     BB: {x: 0, y: linkWidth*zoom},     TT: {x: 0, y: -linkWidth*zoom},     RR: {x: linkWidth*zoom, y: 0},     LL: {x: -linkWidth, y: 0},     BR: {x: linkWidth*zoom*0.7, y: linkWidth*zoom*0.7},     BL: {x: -linkWidth*zoom*0.7, y: linkWidth*zoom*0.7},     TR: {x: linkWidth*zoom*0.7, y: -linkWidth*zoom*0.7},     TL: {x: -linkWidth*zoom*0.7, y: -linkWidth*zoom*0.7} }; 
```

最后，想要看程序，或者想玩“地铁拖拖乐”的各位，都可以给我留言和发邮件：tw-service@servasoft.com。