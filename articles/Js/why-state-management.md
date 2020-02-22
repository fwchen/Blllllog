title: 为什么要做状态管理
date: 2019-08-04 17:26:54

---

# 谈一谈前端状态管理
在如今的前端开发领域，状态管理可能是最容易被误解的技术之一，也是滥用比较多的一门技术。

> 注：本篇文章

1. 状态管理是什么，
2. 常见的状态管理方案
3. 状态管理反模式

## 状态管理是什么

近年来，随着单页面应用的兴起，JavaScript 需要管理比任何时候都要多的 state （状态）。 这些 state 可能包括服务器响应、缓存数据、本地生成尚未持久化到服务器的数据，也包括 UI 状态，如激活的路由，被选中的标签，是否显示加载动效或者分页器等等。
<br />

但是其实，无论系统如何复杂，前端页面的所要完成的事其实很简单，就是把业务的信息渲染出来，反馈给人，并进行人机交互。

<br />

既然数据都会存储在服务器里，那么为什么还要在前端做状态管理呢，这是要在前端和服务器一样，要进行维护数据的工作吗。

<br />

答案其实是“是又不是”，在大多数情况下，客户端都要尽量避免跟服务器一样有相同的领域逻辑。这一点Uncle Bob's 在他的《架构整洁之道》中也有很多的论述，系统的业务逻辑应该是 High-Level policy的，<del>依赖于数据库，前端等</del>。

<br/>

几乎所有的 web 系统都不会把用户的一些数据和系统的状态维护在客户端，例如不会把用户的会员等级，新增的代办事项仅仅保存在浏览器，因为这些都是“转瞬即逝”的东西，用户换一个浏览器这些信息就会全然不见，所以这些数据（状态）必然会在服务器上存储起来，当用户重新登录的时候，页面会从服务器中重新拿到最新的数据，把页面渲染出来。

<br />

> 当然一些页面 UI 的状态，例如侧边栏的折叠，仅仅存储到浏览器（例如 localStore），也是一个比较常见的做法，这些页面相关的状态可以跟随浏览器的状态周期。

<br/>


实际上状态管理是一个十分笼统的说法，因为任何程序都会有状态，不管这个状态是
内部的，还是外部的，是局部的，还是全局的；还有各个控件、组建内的状态。

<br />


<br />

问题又来了，为什么只负责渲染和交互要处理一些相关的业务逻辑呢，我把服务器的数据拿回来组织好结构（如果使用服务器模板或者一些框架的SSR，这一步也省了，Dom内容会在服务器渲染好）不就行了吗，网页就是给人看就行了不是吗。

其实我觉得这个问题应该从 Ajax 这门技术开始讲起。

<br/>

> 传统的Web应用允许用户端填写表单（form），当提交表单时就向网页服务器发送一个请求。服务器接收并处理传来的表单，然后送回一个新的网页，但这个做法浪费了许多带宽，因为在前后两个页面中的大部分HTML码往往是相同的。由于每次应用的沟通都需要向服务器发送请求，应用的回应时间依赖于服务器的回应时间。这导致了用户界面的回应比本机应用慢得多。
-- 来自维基百科 https://zh.wikipedia.org/wiki/AJAX

<br/>

Ajax 的诞生，使得 web 应用不用大量和频繁跟服务器通信，原本需要服务器返回整个页面的数据，现在也只需要通过 Ajax 传递少量的信息，剩下的东西由 javascript 自己操作页面，对页面的元素修修改改。因为不用刷新整个页面，应用 ajax 的 web 应用用户体验非常好，给人非常快的感觉。

<br/>

而 javascript 对页面上的操作的总总过程，其实就是页面 UI 跟 javascript 变量的同步，也就是我们所说的状态管理 ，当然，这是广义说法的状态管理，在那个代码，其实并没有状态管理这么一说，仅仅有一些“数据同步”之类的说法。

### 广义状态管理

在 web 前端还没有变复杂之前，很多系统的网页用着纯 javascript 或者 jQuery 来做一些状态管理，或者说是一些数据管理吧，当然，这里边要做的事情其实很复杂，主要表现在状态的同步上，可以看下面的一个例子。

<br/>

#### javascript 无框架时代状态管理例子

``` javascript
addBook(book) {
  // state logic
  this.books.push(book);
  
  // server logic
  this.callAddBookApi(book).then(this.ajustUIBook);

  // UI logic
  this.mayBeDoSomethingElse();

  const li = document.createElement('li');
  const span = document.createElement('span');
  span.innerText = book.name;

  this.$bookUl.appendChild(li);
  li.appendChild(span);
}
```

<br/>

这里例子中，我们通过某个表单增加了一本书，`addBook` 这个方法先是在本地的 `books` 变量中加进去，然后请求服务器，把新增加的 Book 信息传过去，当然结果可能成功也可能失败，所以要调用一个回调方法进行调整，然后再操作 Dom 来更新页面的展示。当然，还有更复杂的情况，例如在页面别的地方，可能有所有 Book 的计数，或者有“用户最近的 Books”的展示，程序需要找到那些元素的 Dom，并用特定的领域逻辑对 Dom 内容进行更新。

> 事实上，在 2019 年的今天，我在很多手机 App 上还能看到相识的 Bug，例如我在咸鱼(是的，我不必忌讳什么)上看到一条应用内消息，但是到消息页面查看，对应联系人消息框中却没有看到。

<br />

这样的问题在大型的 web 应用中会变得非常复杂，Facebook 的 web 应用就深受这样的问题的困扰。

<br/>

### Facebook 遇到的问题

Facebook 的站点是最早开始 Web App 这个概念的一批，在 Facebook 没有创造出 Flux 这种架构之前，Facebook 就有很多状态未同步的 bug，我在曾经很少使用的几次经历中，也目睹过这些 bug，就是当在 Facebook 逛着逛着，突然来了几条通知，但是点进去之后竟然没有了，过了一会儿，通知又来了，点进去看到了之前的消息，但是新的还是没有来。

虽然 Facebook 在的客户端结构跟流行的 MVC 架构或者 MVP 架构不一样，但是他们问题的原因大概就是在 [http://fluxxor.com/what-is-flux.html](http://fluxxor.com/what-is-flux.html) 描述的这样

> http://fluxxor.com/what-is-flux.html
为了最好地描述流量，我们将其与领先的客户端架构之一：MVC进行比较。在客户端MVC应用程序中，用户交互会触发控制器中的代码。控制器知道如何通过调用模型上的方法来协调对一个或多个模型的更改。当模型更改时，它们会通知一个或多个视图，这些视图又从模型中读取新数据并进行相应的更新，以便用户可以看到该新数据。
![](/api/file/getImage?fileId=5da529fe3ca5440036000035)
一个简单的MVC流程
<br/>
随着MVC应用程序的增长以及控制器，模型和视图的添加，依赖性变得越来越复杂。

> 
![](/api/file/getImage?fileId=5da529fe3ca5440036000036)
<br/>
仅添加三个视图，一个控制器和一个模型，就已经很难跟踪依赖图。当用户与UI交互时，将执行多个分支代码路径，并且在弄清楚这些潜在代码路径中的一个（或多个）中的哪个模块（或多个模块）包含错误的情况下，在应用程序状态下进行调试成为一种练习。在最坏的情况下，用户交互将触发更新，进而触发其他更新，从而导致沿其中一些路径（有时是重叠的路径）的易于出错且难以调试的级联效应。
<br/>
> Flux避开此设计，而采用单向数据流。视图中的所有用户交互都将调用操作创建者，这将导致从单例调度程序中发出操作事件。调度程序是通量应用程序中所有动作的单发射点。该操作从调度程序发送到存储，存储根据响应更新自身。

事实上，在同一时期，Facebook 的 React 跟 Flux 一起设计出来，光芒四射的 React 席卷了整个前端，同时在 Flux 的启发下，状态管理也正式走进了众多开发者的眼前。

Single source of truth

（举个例子，页面买书）



在《领域驱动设计》(Eric Evans) 一书中，作者指出 SMART UI（智能用户界面）

关注点分离




> (对比 snapseed ， react native 本地应用，状态保存在)

ajax

### 现代 web 状态管理

https://en.wikipedia.org/wiki/State_management


web 技术发展至今，基本上已经进入了框架的时代，随着 SPA 和 Ajax 技术流行，还有业务对界面的要求越来越高，前端开发已经变得非常复杂，尤其在状态管理这一块上，现在谈及状态管理，虽然概念还是很很宽泛，但是还是能收敛到几个点上。

1. 数据流的方向性管理，如 Flux
2. 系统状态的框架性工具管理，例如 Redux，Mobx
3. 组件生命周期内的状态管理
...

----------


## 常见状态管理技术栈

### **Redux**
Redux 在他们[文档](https://www.redux.org.cn/docs/faq/General.html)中反复提到：

> React 早期贡献者之一 Pete Hunt 说：

> > “你应当清楚何时需要 Flux。如果你不确定是否需要它，那么其实你并不需要它。”

> Redux 的创建者之一 Dan Abramov 也曾表达过类似的意思:

> > “我想修正一个观点：当你在使用 React 遇到问题时，才使用 Redux。”

**但，如果你了解 Redux，我认为你可能不知道什么叫状态管理。**

Redux 在状态管理百花齐放之前起了非常大的启发作用，作为 Flux 思想的流行实现者，在绝大多数的 React 应用中都能看到他的身影。


#### **Redux 的三大原则**
1. 单一数据源
2. State 是只读的
3. 使用纯函数来执行修改


#### **Redux小例子**

下面的例子是官方 Github 仓库的一个简单的例子，包含 Component，Container，reducer，action。

[https://github.com/reduxjs/redux/tree/master/examples/todos](https://github.com/reduxjs/redux/tree/master/examples/todos)

这个例子可以说是 Redux 的广泛用法了，当然每个项目不一样，也有可能用出花来，这里也谈几个点。

<br/>

- Flux 为人诟病的地方，就是模版代码太多，用 [redux-utilities/redux-actions](https://github.com/redux-utilities/redux-actions) 这样的开发库能大大减轻代码量。
- Redux 描述的架构是美好的，标榜着纯函数的美妙，但是 redux 把最肮脏的事情留给了社区，那就是副作用的处理。副作用的处理通常表现为，对 Api 的调用，存取数据等，一旦数据流中产生了副作用，那么 Flux 中所说单向数据流就会失去意义，当然，社区中有不少的副作用库，副作用后产生的结果可以看作是急于 Action 的分发，有 [edux-thunk](https://github.com/reduxjs/redux-thunk)，[redux-observable](https://github.com/redux-observable/redux-observable) ，[redux-saga](https://github.com/redux-saga/redux-saga)，个人比较推荐 redux-observable，虽然形式不太一样，但是对于 action 的数据流有着更为丰富的控制功能，而且无侵入式的写法会十分舒服。
-  Redux 的状态连接 Container 并不是很好，会加大对代码上下文的理解难度，并且 HOC 对 Typescript 的并不友好，要写好 HOC 的类型实在是有点难度。现在更推荐 hook 的写法，当然，hook 的使用也是见仁见智，很多人无脑推崇 hook 也是令人心烦，

### **Mobx**

### **Rx**


----------


## 状态管理反模式


- action reducer 两边逻辑
基础是文档化，重要内容白纸黑字记录下来，用书面语避免歧义，用模板提高编写和阅读效率。然后文档应该有编写（文档负责人）、校对（文档 负责人）、审核（文档使用者）和审批（文档负责人的上级）一系列验证流程，最终一定要正式发布，否则谁也不知道那么多草稿哪一份是有用的。文档化的好处，是在空间上可以让素未谋面的人有机会拿到正式的信息，在时间上避免人员流动和记忆模糊带来的信息损失 。

作者：Henry Li
链接：https://www.zhihu.com/question/20983336/answer/153840178
来源：知乎
著作权归作者所有。商业转载请联系作者获得授权，非商业转载请注明出处。

----------


## 参考
- [https://zhuanlan.zhihu.com/p/20263396](https://zhuanlan.zhihu.com/p/20263396)
- [https://zhuanlan.zhihu.com/p/37090152](https://zhuanlan.zhihu.com/p/37090152)
- [https://www.redux.org.cn/docs/introduction/Motivation.html](https://www.redux.org.cn/docs/introduction/Motivation.html)

