---
title: 一个jo厨程序员是如何看漫画的
date: 2019-06-12 13:19:16
tags:
---

![](https://imgs.react.mobi/Fi91glDZEi4JBsyIWiX9Jlr0y3xD)

追完动画，刚见到波波，战车这是咋了，啥是镇魂曲啊，怎么就完了，要等周六啊啊啊啊啊啊啊，act3附体，小嘴就像抹了蜜......

ヽ(。>д<)ｐ

于是想到看漫画版，但网页体验较差，一次只能看一页，一页只有一张图，还不能存缓。

╮(╯_╰)╭

行吧，没缓存，我自己做。

大致看了下该页面的结构，做的不错，结构清晰、代码整洁、可读性好，那爬取就很方便了。



### 初步想法

明确下目标，需要的是任意一本漫画的全部内容，也就是图片src列表，然后批量下载到本地。没想过要爬整站（我是良民），入口就设为漫画的详情页好了，目测需要如下几个步骤：

编号 => 基本信息 => 章节列表 => 页列表 => 图片地址

个人比较熟悉node，插件应有尽有，写起来比较顺手，实现如下：

```javascript
// 根据编号获取url地址
export async function getIndexUrl(number) {
  let url = `${baseUrl}/manhua/`;
  if (number) url += number;
  return url;
}

// 获取漫画基本信息和章节目录
export async function getData(url) {
  const html = await fetch(url).then(res => res.text());
  const $ = cheerio.load(html, { decodeEntities: false });

  //   获取title
  const title = await $('h1.comic-title').text();

  //   获取简介
  const description = await $('p.comic_story').text();

  //   获取creators
  const creators = [];
  function getCreators() {
    creators.push($(this).find('a').text());
  }
  await $('.creators').find('li').map(getCreators);

  //   获取卷
  const list = [];
  function getVlue() {
    const href = `${baseUrl}${$(this).find('a').attr('href')}`;
    list.push({
      href,
    });
  }
  await $('.active .links-of-books.num_div').find('li.sort_div').map(getVlue);

  //  获取数据
  const data = [];
  function getComicData() {
    const key = $(this).find('td').attr('class') || $(this).find('td a').attr('class');
    const value = key === 'comic-cover' ? $(this).find('td img').attr('src') : $(this).find('td').text();
    const label = $(this).find('th').text();
    data.push({
      key,
      label,
      value,
    });
  }
  await $('.table.table-striped.comic-meta-data-table').find('tr').map(getComicData);

  const detail = await $('article.comic-detail-section').html();

  return {
    title,
    creators,
    description,
    list,
    data,
    detail,
  };
}

// 获取章节内全部页
export async function getPageList(url) {
  const html = await fetch(url).then(res => res.text());
  const $ = cheerio.load(html, { decodeEntities: false });
  const list = [];
  function getPage2() {
    list.push(`${baseUrl}${$(this).attr('value')}`);
  }
  await $('select.form-control').eq(0).find('option').map(getPage2);
  return list;
}

// 获取页内图片地址
export async function getPage(url) {
  const html = await fetch(url).then(res => res.text());
  const $ = cheerio.load(html, { decodeEntities: false });
  const src = await $('img.img-fluid').attr('src');
  return `${baseUrl}${src}`;
}
```

先将写好的步骤组合起来：

```javascript
async function test(number) {
  const indexUrl = await getIndexUrl(number);
  const data = await getData(indexUrl);

  await Promise.all(data.list.map(async (i, idx) => {
    let pageList = await getPageList(i.href);
    const imgs = [];
    await Promise.all(pageList.map(async (pages, pdx) => {
      await Promise.all(pages.map(async (j, jdx) => {
        let src = await getPage(j);
        imgs.push(src);
      }));
    }));
  }));

  fs.writeFileSync(`../jojo/${number}.json`, JSON.stringify(data));
}
```

嗯，很简单嘛。就是看起来太暴力了，这样不好，别给人服务器太大压力。

### 串行promise

实现类似Promise.all，但不同点在于，如果是数组直接返回promise，众所周知promise在创建时就已经执行了，不可能串行。于是将数组改写，返回一个可执行函数的队列，在串行方法里去执行，这样就可以实现了。

```javascript
export function sequence(promises) {
  return new Promise((resolve, reject) => {
    let i = 0;
    const result = [];

    function callBack() {
      return promises[i]().then((res) => {
        i += 1;
        result.push(res);
        if (i === promises.length) {
          resolve(result);
        }
        callBack();
      }).catch(reject);
    }

    return callBack();
  });
}

// 使用方法
sequence([1, 2, 3, 4, 5].map(number => () => new Promise((resolve, reject) => {
  setTimeout(() => {
    console.log(`$${number}`);
    resolve(number);
  }, 1000);
}))).then((data) => {
  console.log('成功');
  console.log(data);
}).catch((err) => {
  console.log('失败');
  console.log(err);
});

```

### 分组并发

完全串行的话，和正常逐步浏览网页没什么区别，性能是没问题了，但那有什么意义，我们得加快速度。于是想到将200页分组，每10个一组，每组串行执行，组内并行执行，相当于10个用户同时访问网站，这总不可能扛不住吧，如此应该能兼顾效率和性能。

分组就没必要自己写了，使用lodash/chunk和Promise.all即可。

### 异常处理

考虑到爬取一个章节，至少都是200页，还是并行的，不敢保证中途不出任何意外，基本的异常处理还是要做的。

赶时间，直接将利用race来实现，只要没有结果，一律重试，实践起来还是比较稳的。

### 完整的爬取方法

```javascript
async function test(number) {
    const indexUrl = await getIndexUrl(number);
    const data = await getData(indexUrl);

    await sequence(data.list.map((i, idx) => async () => {
    await sleep(Math.random() * 1000);
    let pageList = await getPageList(i.href);

    pageList = pageList
        .map(src => ({ src, index: parseInt(src.substr(42, 3).replace('_', ''), 0) }))
        .sort((x, y) => x.index - y.index)
        .map(({ src }) => src);

    const imgs = [];
    const len = 5;

    // 分len一组，串行访问
    await sequence(chunk(pageList, len).map((pages, pdx) => async () => {
        await sleep(Math.random() * 5000);
        // 以len一组，并行访问
        await Promise.all(pages.map(async (j, jdx) => {
        let src;
        async function race() {
            await sleep(Math.random() * 1000);
            const res = await Promise.race([ getPage(j), sleep(5000) ]);
            if (res) {
            src = res;
            console.log(`拿到src: ${src}`);
            } else {
            console.log('重新加入队列');
            await race();
            }
        }
        await race();
        imgs.push(src);
        }));
    }));

    data.list[idx].list = imgs
        .map(src => ({ src, index: parseInt(src.substr(42, 3).replace('_', ''), 0) }))
        .sort((x, y) => x.index - y.index)
        .map(({ src }) => src);
    }));

    console.log('爬取成功！！！');

    fs.writeFileSync(`../jojo/${number}.json`, JSON.stringify(data));
}
```

### 批量下载

以上，已经拿到了所需的全部信息。

接下来只需要批量下载即可，这好办，先整一个promise化的下载方法：

```javascript
function downloadFile(url, filepath) {
  return new Promise((resolve, reject) => {
    // 块方式写入文件
    const ws = fs.createWriteStream(filepath);
    ws.on('open', () => {
      console.log('下载：', url, filepath);
    });
    ws.on('error', (err) => {
      console.log('出错：', url, filepath);
      reject(err);
    });
    ws.on('finish', () => {
      console.log('完成：', url, filepath);
      resolve(true);
    });
    request(url).pipe(ws);
  });
}
```

再如法炮制一套串行并行混合的下载规则：

```javascript
async function readJson() {
//   await checkPath('../jojo');
  const data = await readFile('../jojo/128.json');
  const json = JSON.parse(data);
  console.log(json.list[0].list.length);

  const cur = 10;
  await sequence(json.list.map((list, idx) => async () => {
    await sequence(chunk(list.list, cur).map((pages, pdx) => async () => {
      await sleep(Math.random() * 1000);
      console.log('正在获取:', `/jojo/${idx + 1}/`, ` 第${pdx + 1}批`);
      await Promise.all(pages.map(async (j, jdx) => {
        const dirpath = `../jojo/${idx + 1}`;
        const filepath = `../jojo/${idx + 1}/${cur * pdx + jdx + 1}.jpg`;
        await checkPath(dirpath);
        async function race() {
          await sleep(Math.random() * 1000);
          const res = await Promise.race([
            downloadFile(j, filepath),
            sleep(20000),
          ]);
          if (res) {
            console.log('下载成功');
          } else {
            console.log('重新加入队列');
            await race();
          }
        }
        await race();
      }));
    }));
  }));
  console.log('获取成功');
}
```

尝试一下，问题不大，图片会按章节下载到对应目录，速度比自己翻快多了，目标达成！

![](https://imgs.react.mobi/FpwOqDEBfMEg_FMIzmYL05yk-oVc)

折腾了几个小时，终于又可以愉快地在ipad上看漫画咯，我真是嗨到不行了~

[]~(￣▽￣)~*   (～￣▽￣)～

完整代码：[https://github.com/liumin1128/api.react.mobi/blob/master/server/crawler/jojo.js](https://github.com/liumin1128/api.react.mobi/blob/master/server/crawler/jojo.js)。

PS1：仅供学习，请在24小时内删除。
PS2：有机会请支持正版。

