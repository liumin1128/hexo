---
title: 详解AMD、CommonJS和UMD模块化规范
date: 2019-03-21 16:27:00
tags: js
---

## CommonJS

CommonJS模块可以说是当前最流行的模块定义规范。相比于AMD，它的工作效率更高、语法更简单。一开始，CommonJS模块是JavaScript服务器模块的规范。

**基本原理**

实现编译代码，创建一个比原先更大的代码包，其中包含了所有应用运行所需的代码。

**语法**

```
const $ = require('jquery'); //将依赖加载到当前文件
exports.init = function(){
    ...
};
```
**特点**

* 没有回调函数
* 同步加载，每个require语句会短暂阻塞代码的运行，知道模块加载完毕。不过这个加载不是通过网络加载，而是从内存或者文件系统中加载，所以这个过程很快。
* 代码简单易懂
* CommonJS模块不适合浏览器，因为浏览器的加载机制不支持同步。需要用打包工具把所有CommonJS模块打包成一个js文件。

## AMD

AMD：Asynchronous Module Definition（异步模块规范），最老的方式之一，专为浏览器而设计。

**基本原理**

用异步加载技术来定义模块和依赖。提供define方法和require方法来定义和加载模块。

**语法**

define方法：
```
define(
    '模块id',
    ['依赖数组']，
    function([依赖数组]){ //工厂函数
        ...
    }
);
```

工厂函数内部包含了模块代码，工厂函数最后返回的结果，就是要暴露给其他模块的功能。

**特点**

* 用AMD定义的模块至少需要一个工厂函数来暴露API给其他模块使用。
* 依赖数组中的依赖会被异步加载。
* 模块的加载通过客户端（浏览器）向服务器发送HTTP请求来完成的，这个传输过程需要大量时间。
* 可以定义具名模块，也可以定义匿名模块。具名模块通过开发者定义的名字加载，匿名模块隐式的以文件名加载。


require方法：

```
require(['jquery']，
    function($){ //回调函数
    ...
    }
);
```

require方法与define方法相对应，用来显示的加载模块。

**特点**

* 可以在代码的任何地方使用require加载另一个模块。
* require调用会发送一个请求来下载模块。
* 异步加载，只有在回调函数里才能获取新拿到的API。
    
AMD模块加载流程示意图 
![](media/15531572931570.jpg)


## UMD

UMD：Universal Module Definition（通用模块规范）是由社区想出来的一种整合了CommonJS和AMD两个模块定义规范的方法。

**基本原理**

用一个工厂函数来统一不同的模块定义规范。

**原则**

* 所有定义模块的方法需要单独传入依赖
* 所有定义模块的方法都需要返回一个对象，供其他模块使用

例如，利用UMD定义一个toggler模块：


```
(function (global, factory) {
    if (typeof exports === 'object' && typeof module !== undefined) { //检查CommonJS是否可用
        module.exports = factory(require('jquery'));
    } else if (typeof define === 'function' && define.amd) {      //检查AMD是否可用
        define('toggler', ['jquery', factory])
    } else {       //两种都不能用，把模块添加到JavaScript的全局命名空间中。
        global.toggler = factory(global, factory);
    }
})(this, function ($) {
    function init() {

    }
    return {
        init: init
    }
});
```

原文：https://blog.csdn.net/weixin_40817115/article/details/81229337 