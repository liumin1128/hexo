---
title: dynamic-file 动态加载资源文件
date: 2019-03-22 11:13:52
tags: MongoDB
---

### 1. 概述

MongoDB 在>=3.2 版本中提供了类似连接的$lookup 聚合运算符。而在 Mongoose 中，有一个更强大的替代方法叫做 populate()，它允许你引用其它集合中的文档。

填充(Population)是使用来自其它集合中的文档自动替换文档中的指定路径的过程。填充可以是单个文档、多个文档、普通对象、多个普通对象或从查询返回的所有对象。来看一些例子：

```javascript
var mongoose = require("mongoose");
var Schema = mongoose.Schema;

var personSchema = Schema({
  _id: Schema.Types.ObjectId,
  name: String,
  age: Number,
  stories: [{ type: Schema.Types.ObjectId, ref: "Story" }],
});

var storySchema = Schema({
  author: { type: Schema.Types.ObjectId, ref: "Person" },
  title: String,
  fans: [{ type: Schema.Types.ObjectId, ref: "Person" }],
});

var Story = mongoose.model("Story", storySchema);
var Person = mongoose.model("Person", personSchema);
```

以上我们创建了两个 Model。其中，Person 模型有一个 stories 字段，其被设置为 ObjectId 数组。ref 选项会告诉 Mongoose 哪个 Model 会在填充的时候使用，在我们示例中为 Story 模型，所存储的\_id 必须是 Story 模型中的文档的\_id。

注意：ObjectId, Number, String 和 Buffer 都可以用于引用(ref)。但是，除非必要情况下，更推荐使用 ObjectId。

### 2. 保存引用

将 ref 保存到其他文档的与通常保存属性的方式相同，只需指定\_id 值：

```javascript
var author = new Person({
  _id: new mongoose.Types.ObjectId(),
  name: "Ian Fleming",
  age: 50,
});

author.save(function (err) {
  if (err) return handleError(err);

  var story1 = new Story({
    title: "Casino Royale",
    author: author._id, // assign the _id from the person
  });

  story1.save(function (err) {
    if (err) return handleError(err);
    // thats it!
  });
});
```

### 3. 填充

目前为止，我们所做的并没什么不同，只是创建了一个 Preson 和 Story。接下来看一下，怎样在查询绑定时填充 story 的 author：

```javascript
Story.findOne({ title: "Casino Royale" })
  .populate("author")
  .exec(function (err, story) {
    if (err) return handleError(err);
    console.log("The author is %s", story.author.name);
    // prints "The author is Ian Fleming"
  });
```

被填充的路径不再是原始的\_id，其值将被替换为从数据库返回的 mongoose 文档，此操作会在返回结果之前执行单独的查询。

ref 值是一个数组时同样可用，只需要在查询时调用 populate 方法，文档数组就会替换原有的\_id。

### 4. 设置填充字段

在 Mongoose>= 4.0 后，我们可以像下面这样手工设置填充字段：

```javascript
Story.findOne({ title: "Casino Royale" }, function (error, story) {
  if (error) {
    return handleError(error);
  }
  story.author = author;
  console.log(story.author.name); // prints "Ian Fleming"
});
```

### 5. 字段选择

如果我们只想返回填充的文档某些字段，该怎么操作呢？这时可以将所需的字段名称作为第二个参数传递给 populate 方法来实现：

```javascript
Story.findOne({ title: /casino royale/i })
  .populate("author", "name") // 仅返回 Person 的'name'字段
  .exec(function (err, story) {
    if (err) return handleError(err);

    console.log("The author is %s", story.author.name);
    // prints "The author is Ian Fleming"

    console.log("The authors age is %s", story.author.age);
    // prints "The authors age is null'
  });
```

### 6. 填充多个路径

需要填充多个路径时，只需要多次调用 populate()方法即可：

```javascript
Story.
  find(...).
  populate('fans').
  populate('author').
  exec();
```

但是，如果在同一个路径上多次调用 populate()方法，仅最后一次调用会生效：

```javascript
// The 2nd `populate()` call below overwrites the first because they
// both populate 'fans'.
Story.find()
  .populate({ path: "fans", select: "name" })
  .populate({ path: "fans", select: "email" });
// The above is equivalent to:
Story.find().populate({ path: "fans", select: "email" });
```

### 7. 查询条件与其它选项

接下来，我们想按年龄(age)来对的 fans 进行筛选，并且只返回他们的名字，并且最多返回其中的 5 个。这时，可以像下面这样操作：

```javascript
Story.
  find(...).
  populate({
    path: 'fans',
    match: { age: { $gte: 21 }},
    // Explicitly exclude `_id`, see http://bit.ly/2aEfTdB
    select: 'name -_id',
    options: { limit: 5 }
  }).
  exec();
```

### 8. 引用子文档

在前面我们通过 story 引用到了 author，但我们可能会发现，如果是通过 author 对象则无法获取 story。因为没有任何 story 对象被“推送”到 author.stories。

首先，你可能希望 author 知道哪些 story 是他们的。通常，你的模式应该在“many”侧具有父指针来处理一对多(one-to-many)关系。或者，你可以有一个指向子对象的数组，并可以将文档 push()到数组，如下所示。

author.stories.push(story1);
author.save(callback);
这样我们就可以组合执行 find 和 populate：

```javascript
Person.findOne({ name: "Ian Fleming" })
  .populate("stories") // only works if we pushed refs to children
  .exec(function (err, person) {
    if (err) return handleError(err);
    console.log(person);
  });
```

值得考虑的是，我们是否确定需要两组指针，因为它们可能会失去同步。相反，我们也可以跳过填充而直接找到所需要的 stroy：

```javascript
Story.find({ author: author._id }).exec(function (err, stories) {
  if (err) return handleError(err);
  console.log("The stories are an array: ", stories);
});
```

通过查询填充所返回的文档是全功能的（是一个 Mongoose 文档），可 remove、可 save，除非指定了 lean 选项。不要将它们与子文档混淆。调用 remove 方法时要小心，因为这些文档会从数据库中删除，而不仅仅是数组。

### 9. 填充己存在的文档

如果我们已经有一个 mongoose 文档并想要填充它的一些路径，mongoose >= 3.6 的 document#populate()方法支持这一功能。

### 10. 填充多个己存在的文档

如果我们有一个或多个 mongoose 文档甚至普通对象(像 mapReduce 的输出)，可以使用 mongoose >= 3.6 所提供的 Model.populate()方法来填充。这也是 document#populate()和 query#populate 填充文档的方式。

### 11. 多层级填充

假设有如下一个 Schema，用于跟踪用户（user）的朋友（friend）：

```javascript
var userSchema = new Schema({
  name: String,
  friends: [{ type: ObjectId, ref: "User" }],
});
```

populate 使你有了一个用户的朋友列表，这时如果还想得到用户的朋友的朋友呢？可以指定 populate 选项来告诉 mongoose 填充所有用户朋友的 friends 数组：

```javascript
User.findOne({ name: "Val" }).populate({
  path: "friends",
  // Get friends of friends - populate the 'friends' array for every friend
  populate: { path: "friends" },
});
```

### 12. 跨数据库填充

假设有一个表示事件的模式（eventSchema），以及一个表示会话的模式（conversationSchema）。 每个事件都有一个对应的会话线程：

```javascript
var eventSchema = new Schema({
  name: String,
  // The id of the corresponding conversation
  // Notice there's no ref here!
  conversation: ObjectId
});
var conversationSchema = new Schema({
  numMessages: Number
});
此外，假设事件和会话存储在不同的MongoDB实例中。

var db1 = mongoose.createConnection('localhost:27000/db1');
var db2 = mongoose.createConnection('localhost:27001/db2');

var Event = db1.model('Event', eventSchema);
var Conversation = db2.model('Conversation', conversationSchema);
```

在这种情况下，将无法正常使用 populate()。conversation 字段将始终为 null，因为 populate()不知道要使用哪个模型。但是，可以显式指定模型：

```javascript
Event.find()
  .populate({ path: "conversation", model: Conversation })
  .exec(function (error, docs) {
    /* ... */
  });
```

这可以称为“跨数据库填充”，因为它使你能够跨 MongoDB 数据库，甚至跨 MongoDB 实例填充。

### 13. refPath 动态引用

Mongoose 还可以根据文档中属性的值从多个集合中填充。例如，构建一个用于存储评论（comment）的模式,用户可以评论博客文章或产品：

```javascript
const commentSchema = new Schema({
  body: { type: String, required: true },
  on: {
    type: Schema.Types.ObjectId,
    required: true,
    // Instead of a hardcoded model name in `ref`, `refPath` means Mongoose
    // will look at the `onModel` property to find the right model.
    refPath: "onModel",
  },
  onModel: {
    type: String,
    required: true,
    enum: ["BlogPost", "Product"],
  },
});

const Product = mongoose.model("Product", new Schema({ name: String }));
const BlogPost = mongoose.model("BlogPost", new Schema({ title: String }));
const Comment = mongoose.model("Comment", commentSchema);
```

refPath 选项是 ref 的更复杂的替代选择。ref 是一个字符串，Mongoose 将始终查询相同的模型以查找填充的子文件。而使用 refPath 时，你可以配置 Mongoose 每个文档所应使用的模型。

```javascript
const book = await Product.create({ name: "The Count of Monte Cristo" });
const post = await BlogPost.create({ title: "Top 10 French Novels" });

const commentOnBook = await Comment.create({
  body: "Great read",
  on: book._id,
  onModel: "Product",
});

const commentOnPost = await Comment.create({
  body: "Very informative",
  on: post._id,
  onModel: "BlogPost",
});

// The below `populate()` works even though one comment references the
// 'Product' collection and the other references the 'BlogPost' collection.
const comments = await Comment.find().populate("on").sort({ body: 1 });
comments[0].on.name; // "The Count of Monte Cristo"
comments[1].on.title; // "Top 10 French Novels"
```

另一种方法是在 commentSchema 上定义单独的 blogPost 和 product 属性，然后在两个属性上 populate()：

```javascript
const commentSchema = new Schema({
  body: { type: String, required: true },
  product: {
    type: Schema.Types.ObjectId,
    required: true,
    ref: "Product",
  },
  blogPost: {
    type: Schema.Types.ObjectId,
    required: true,
    ref: "BlogPost",
  },
});

// ...

// The below `populate()` is equivalent to the `refPath` approach, you
// just need to make sure you `populate()` both `product` and `blogPost`.
const comments = await Comment.find()
  .populate("product")
  .populate("blogPost")
  .sort({ body: 1 });
comments[0].product.name; // "The Count of Monte Cristo"
comments[1].blogPost.title; // "Top 10 French Novels"
```

定义单独的 blogPost 和 product 属性适用于这个简单示例。但是，如果也允许用户对文章或其他评论发表评论，则需要向模式添加更多属性。除非你使用 mongoose-autopopulate，否则你还需要对每个属性进行额外的 populate()调用。使用 refPath 意味着你只需要 2 个模式路径和一个 populate()调用，而无论 commentSchema 可以指向多少个模型。

### 14. 虚拟（virtual）属性/路径填充

目前为止，我们都是基于\_id 字段进行的填充，但在某些情况下，这并不适用。特别是，无限制增长的数组是 MongoDB 反模式(One-to-Many)。使用 mongoose 虚拟属性，可以在文档之间定义更复杂的关系。

```javascript
var PersonSchema = new Schema({
  name: String,
  band: String,
});

var BandSchema = new Schema({
  name: String,
});
BandSchema.virtual("members", {
  ref: "Person", // The model to use
  localField: "name", // Find people where `localField`
  foreignField: "band", // is equal to `foreignField`
  // If `justOne` is true, 'members' will be a single doc as opposed to
  // an array. `justOne` is false by default.
  justOne: false,
  options: { sort: { name: -1 }, limit: 5 }, // Query options, see http://bit.ly/mongoose-query-options
});

var Person = mongoose.model("Person", PersonSchema);
var Band = mongoose.model("Band", BandSchema);

/**
 * Suppose you have 2 bands: "Guns N' Roses" and "Motley Crue"
 * And 4 people: "Axl Rose" and "Slash" with "Guns N' Roses", and
 * "Vince Neil" and "Nikki Sixx" with "Motley Crue"
 */
Band.find({})
  .populate("members")
  .exec(function (error, bands) {
    /* `bands.members` is now an array of instances of `Person` */
  });
```

需要注意，虚拟属性默认并不包含在 toJSON()的输出中。如果要在使用依赖于 JSON.stringify()的函数（如：Express 的 res.json()函数）中显示虚拟属性填充，则需要在模式的的 toJSON 选项上设置 virtuals:true 选项：

```javascript
// Set `virtuals: true` so `res.json()` works
var BandSchema = new Schema({
  name: String
}, { toJSON: { virtuals: true } });
如果您正在使用填充投影（projection），应确保在投影中包含foreignField：

Band.
  find({}).
  populate({ path: 'members', select: 'name' }).
  exec(function(error, bands) {
    // Won't work, foreign field `band` is not selected in the projection
  });

Band.
  find({}).
  populate({ path: 'members', select: 'name band' }).
  exec(function(error, bands) {
    // Works, foreign field `band` is selected
  });
```

### 15. 中间件中填充

还可以 pre 或 post 勾子中使用填充。如果始终要填充某个字段，请查看 mongoose-autopopulate 插件。

```javascript
// Always attach `populate()` to `find()` calls
MySchema.pre("find", function () {
  this.populate("user");
});
// Always `populate()` after `find()` calls. Useful if you want to selectively populate
// based on the docs found.
MySchema.post("find", async function (docs) {
  for (let doc of docs) {
    if (doc.isPublic) {
      await doc.populate("user").execPopulate();
    }
  }
});
// `populate()` after saving. Useful for sending populated data back to the client in an
// update API endpoint
MySchema.post("save", function (doc, next) {
  doc
    .populate("user")
    .execPopulate()
    .then(function () {
      next();
    });
});
```
