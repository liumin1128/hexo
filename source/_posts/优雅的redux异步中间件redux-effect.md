---
title: 优雅的redux异步中间件redux-effect
date: 2019-03-25 18:14:19
tags: [redux, react]
---

> 不吹不黑，redux蛮好用。只是有时略显繁琐，叫我定义每一个action、action type、使用时还要在组件上绑定一遍，臣妾做不到呀！下面分享一种个人比较倾向的极简写法，仍有待完善，望讨论。

Github: https://github.com/liumin1128/redux-effect

基于redux、async/await、无侵入、兼容性良好的异步状态管理器。

## install

```
npm i -S redux-effect

// or
yarn add redux-effect
```

## use


```Javascript
import { createStore, applyMiddleware, combineReducers } from 'redux';
import { reduxReduers, reduxEffects } from 'redux-effect';

const models = [ test1, test2, ...];

const reducers = combineReducers(reduxReduers(models));
const middlewares = [ reduxEffects(models) ];

const store = createStore(
    reducers,
    initialState,
    middlewares
  );
```

从代码可以看出，从reduxReduers, reduxEffects中得到的就是标准的reducer和middleware，完美兼容其他redux插件，也可以轻松整合进老项目中。

完整例子：[example](example/src/store.js)

## model

在redux-effect中，没有action的概念，也不需要定义action type。

所有关于某个state的一切声明在一个model中，本质就是一个对象。

```Javascript
export default {
  namespace: 'test',
  state: { text: 'hi!' },
  reducers: {
    save: (state, { payload }) => ({ ...state, ...payload }),
    clear: () => ({})
  },
  effects: {
    fetch: async ({ getState,dispatch }, { payload }) => {
      await sleep(3000);
      await dispatch({ type: 'test/clear' });
      await sleep(3000);
      await dispatch({ type: 'test/save', payload: { text: 'hello world' } });
    }
  }
};

```

**namespace：**

model的命名空间，对应state的名字，必填，只接受一个字符串。

**state：**

state的初始值，非必填，默认为空对象

**reducers：**

必填，相当于同步执行的action方法，接受两个参数state和action，合并后返回新的state状态值。

**effects：**

非必填，相当于异步执行的action方法，接受两个参数store和action，store里包括redux自带的getState和dispatch方法，action为用户dispatch时带的参数。

## dispatch

这里的dispatch就是redux中的dispatch，但有几个约定。

1. 不传定义好的action，而是直接传一个普通对象。
2. type的组织形式：namespace + '/' + reducer或effect方法名
3. 参数的传递：需要合并的参数用payload包裹

定义每一个action，并将其绑定到视图层过于繁琐，去action化则让事件的触发变的灵活。

**普通事件**

发送事件时，不区分同步还是异步，只管dispatch，一切都已在model中定义好。

```javascript
// 同步
dispatch({ type: 'test/save', payload: { text: "hello world" } })
// 异步
dispatch({ type: 'test/fetch' })
```

**等待**

等待一个事件完成再执行逻辑，dispatch方法是可以被await的，十分轻松。

```javascript
async function test() {
  await dispatch({ type: 'test/fetch' })
  await console.log('hello world')
}
```

**回调**

等待某个事件，再执行外部定义的某个回调函数，只需要在action字段里加上callback方法，在effect中调用即可。

相比较await，回调可以拿到某些返回值，也可以在effect流程的中间部分执行。

```javascript

dispatch({ type: 'test/fetch', callback1, callback2 })

{
  effects: {
    fetch: async ({ getState,dispatch }, { payload, callback, callback2 }) => {
      const state = await getState()
      await sleep(3000);
      await callback1(state)
      await sleep(3000);
      await callback2(state)
    }
  }
}
```
**自定义reducer**

reducer其实就是redux中的reducer，用法完全一样。比如定义一个push方法，将后续数据，压入到原有数据后面，可以这样写。


```
export default {
  namespace: 'test',
  state: { data: [] },
  reducers: {
    save: (state, { payload }) => ({ ...state, ...payload }),
    clear: () => ({}),
    push: (state, { payload = {} }) => {
      const { key = 'data', data } = payload;
      return { ...state, [key]: state[key].concat(data) };
    }
  },
};
```

**自定义effect**

effect其实就是一个普通async函数，接受store和action两个参数，可以使用async/await，可以执行任意异步方法，可以随时拿到state的值，可以dispatch触发另一个effect或者reducer。

## loading

  也许你会想监听某个effect，拿到loading状态，以便在ui给用户一个反馈。一般情况下监听一个异步方法，只需要在effect的开头和结束，各自设定状态即可，与常规写法无异。
  
  但这里也提供一种model级别的loading状态，新增一个名为loading的model，再使用reduxEffectsWithLoading包裹需要监听的model即可。

## 关于model-creator

以上所做的事情，是将redux核心规范为model，得到了统一且可以复用的数据模型，这为自动生成model创造了可能性，如果能通过工厂模式，自动化创建具有类似功能，且可以随意装配的model，一切将变得更加美好。

Coming Soon

<!-- 了解更多请移步：[redux-model-creator](https://github.com/liumin1128/redux-model-creator) -->
