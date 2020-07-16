title: 用户行为分析
date: 2020-06-26 17:26:54
---
# 用户行为分析

## 什么是用户行为分析
用户行为分析是对用户在产品上的产生的行为及行为背后的数据进行分析，通过构建用户行为模型和用户画像，来改变产品决策，实现精细化运营，指导业务增长。

在产品运营过程中，对用户行为的数据进行收集、存储、跟踪、分析与应用等，可以找到实现用户自增长的病毒因素、群体特征与目标用户。从而深度还原用户使用场景、操作规律、访问路径及行为特点等。

## 为什么要做用户行为分析
对于互联网金融、新零售、供应链、在线教育、银行、证券等行业的产品而言，以数据为驱动的用户行为分析尤为重要。用户行为分析的目的是：推动产品迭代、实现精准营销，提供定制服务，驱动产品决策。主要体现在以下几个方面：

- 对产品而言，帮助验证产品的可行性，研究产品决策，清楚地了解用户的行为习惯，并找出产品的缺陷，以便需求的迭代与优化。
- 对设计而言，帮助增加体验的友好性，匹配用户情感，细腻地贴合用户的个性服务，并发现交互的不足，以便设计的完善与改进。
- 对运营而言，帮助裂变增长的有效性，实现精准营销，全面地挖掘用户的使用场景，并分析运营的问题，以便决策的转变与调整。

# 数据采集
数据采集其实不一定要埋点，下面是几种比较常用得方式。

1. 问卷调查
2. 访谈观察
3. 数据埋点

其中问卷调查，访谈观察一般是对现有系统进行大改版的时候会做，并且一般是第三方服务做的比较多。例如 Thoughtworks 的 Inception，如果计划对现有系统进行梳理和改造，会对现有系统进行用户问卷调查，并且会做访谈，了解用户对系统的真实需求，反馈，使用操作等，从一个大的角度了解用户行为，以便改善和改进。

## 数据埋点
接下来看下数据埋点的几种方式

1. 埋点
2. 无埋点
3. 可视化埋点
4. 其他

### 埋点 (Event Tracking)
一种非常传统、非常普遍的方式就是通过写代码去定义这个事件。在网站需 要监测用户行为数据的地方加载一段代码，比如说注册按钮、下单按钮等。 加载了监测代码，我们才能知道用户是否点击了注册按钮、用户下了什么订 单。 
所有这些通过写代码来详细描述事件和属性的方式，国内都统称为“埋 点”。这是一种非常耗费人力的工程，并且过程非常繁琐重复。

![x](./event-tracking/5.png)

> ### 前端埋点和后端埋点
> 在埋点当中，也分为前端埋点和后端埋点。
> 后端埋点大多数为服务端日志数据，这是一种“结果型”数据，它告诉我们用户完成 了注册、下载、购买都结果型事件。但是为什么有部分用户会流失，为什么 用户下单了却不支付，为什么用户浏览了商品页面后直接就走了等等，这些 “过程型”的原因是交易数据和服务端日志数据提供不了的。
>  
> 而前端埋点更多记录的是用户行为数据，记录用户在产品上的每一次访问、每一次浏览、每一次点击， 这些过程型的数据可以告诉我们用户在你的产品上都发生了什么，可以用来 很好的解释用户为什么会流失。比如最简单的一个搜索行为：某一个 ID 在 什么时间搜索了关键词、看了哪一页、哪几个结果，同时这个 ID 在哪个时 间下单购买了，整个行为都非常重要。如果用户对搜索结果不满意，他肯定 会再搜一次，把关键词换成别的，然后才能够搜索到结果。 


### 无埋点 (Codeless Tracking)
无埋点无差别地记录用户在前端页面上的行为，对应的英文是Codeless Tracking。无埋点并不是说不要添加代码，而是不需要开发人员添加额外代码。无论是埋点的方法，还是不埋点的方法，都必须要添加基础代码。

无埋点直接对页面中所有的用户行为进行监听，因此即使你不需要监测某个部分，它也仍然会将这部分的用户行为数据和对应发生的信息全收录下来。

缺点：
1. 怕改版
2. 采集的数据没有埋点的多
3. 需要清洗和过滤事件数据
 
### 可视化埋点
即可视化事件监测部署，指通过可视化工具快速配置采集节点（圈点），在前端自动解析配置，并根据配置上传埋点数据。

可视化埋点和无埋点非常相似，两者的区别在于：可视化埋点先通过界面配置哪些控件的操作数据需要收集，而无埋点则是先尽可能收集所有的控件的操作数据，然后再通过界面配置哪些数据需要在系统里面进行分析。

在Web页面/App的界面上进行圈选，配置需要监测界面上哪一个元素，然后保存这个配置，当App启动时会从后台服务器获得产品/运营预先圈选好的配置，然后根据这份配置查找并监测App界面上的元素，当某一个元素满足条件时，就会上报行为数据到后台服务器。

缺点：
1. 可视化埋点能够覆盖的功能有限，只能采集到用户肉眼可见的数据。

![x](./event-tracking/4.png)

# 用户行为分析模型
![x](./event-tracking/1.jpeg)


## 漏斗模型分析
![x](./event-tracking/2.jpeg)

## 行为路径分析
行为路径分析就是分析用户在产品使用过程中的访问路径。通过对行为路径的数据分析，可以发现用户最常用的功能和使用路径。并从页面的多维度分析，追踪用户转化路径，提升产品用户体验。

不管是产品冷启动，还是日常活动营销，做行为路径分析首先要梳理用户行为轨迹。用户行为轨迹包括认知、熟悉、试用、使用到忠诚等。轨迹背后反映的是用户特征，这些特征对产品运营有重要的参考价值。

以用户投标的行为路径为例，我们可以记录用户从注册、认证、开户、充值到投资的行为轨迹。通过分析用户的这些行为轨迹数据，来验证访问路径是否和预期指标的一致。

![x](./event-tracking/3.jpeg)


## 用户留存分析模型
留存分析是一种用来分析用户参与情况/活跃程度的分析模型，考察进行初始行为的用户中，有多少人会进行后续行为。这是用来衡量产品对用户价值高低的重要方法。

留存分析可以帮助回答以下问题：

一个新客户在未来的一段时间内是否完成了您期许用户完成的行为？如支付订单等；
某个社交产品改进了新注册用户的引导流程，期待改善用户注册后的参与程度，如何验证？
想判断某项产品改动是否奏效，如新增了一个邀请好友的功能，观察是否有人因新增功能而多使用产品几个月？
二、为什么要做留存分析，直接看活跃用户百分比不行吗？
对此疑惑，答案显然是，当然不行！

如果产品目前处于快速增长阶段，很有可能新用户中的活跃用户数增长掩盖了老用户活跃度的变化。按初始行为时间分组的留存分析可以消除用户增长对用户参与数据带来的影响。通过留存分析，你可以将用户按照注册时间分段查看，得出类似如下结论：

“三月份改版前，该月注册的用户 7 天留存只有 15%；但是四月份改版后，该月注册的用户 7 天留存提高到了 20%。”

# 数据指标体系

## OSM 模型

https://www.cnblogs.com/HuZihu/p/11446571.html

Google Analytics

https://my.oschina.net/u/3721535/blog/1612630?utm_source=debugrun&utm_medium=referral

https://www.jianshu.com/p/a0ea0df0eedb

https://blog.csdn.net/c_air_c/article/details/100095970

http://www.woshipm.com/user-research/3236774.html

http://www.mysecretrainbow.com/report/12611.html

https://www.jianshu.com/p/225f220b976f

https://pickydigest.com/digital-marketing/google-analytics-getting-started/