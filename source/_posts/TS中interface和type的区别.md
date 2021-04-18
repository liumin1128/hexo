---
title: TS中interface和type的区别
date: 2021-04-18 15:17:00
tags: ts
---

### 官方解释

> An interface can be named in an extends or implements clause, but a type alias for an object type literal cannot.
> An interface can have multiple merged declarations, but a type alias for an object type literal cannot.

### 相同点

1. 都可以描述一个对象或者函数



```javascript
// interface
interface User {
	name: string
  age: number
  (name: string, age; number): void
}
 
// type
type User = {
	name: string
  age: number
}
  
type setProps = (name: string, age: number) => void	
```

2. 都可以进行拓展
   
```javascript
// interface extends interface
interface Name { 
  name: string;  
}
  
interface User extends Name { 
  age: number; 
}
 
// type extends type
type Name = {
	name: string
}
type User = Name & { age: number }

// interface extends type
interface User extends Name
  
// type extends interface
interface Name {
	name: string
}
type user = Name & {
	age: number
}
```

### 不同点
1. type可以的而interface不行的

```javascript
// 基本类型别名
type Name = string

// 联合类型
interface Dog {
    wong();
}
interface Cat {
    miao();
}

type Pet = Dog | Cat

// 具体定义数组每个位置的类型
type PetList = [Dog, Pet]
```
2. type 语句中还可以使用 typeof 获取实例的 类型进行赋值

```javascript
// 当你想获取一个变量的类型时，使用 typeof
let div = document.createElement('div');
type B = typeof div 
```

3. interface 可以而 type 不行

```javascript
// interface能够声明合并
interface User {
  name: string
  age: number
}

interface User {
  sex: string
}

/*
User 接口为 {
  name: string
  age: number
  sex: string 
}
*/
```

![](https://cdn.nlark.com/yuque/0/2020/png/214411/1596882674175-a967ae56-4067-422b-b7f8-4c401929a767.png?x-oss-process=image%2Fresize%2Cw_746)

