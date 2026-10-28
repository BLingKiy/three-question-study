## 1. ArkWeb + vis-network 知识图谱

- [x] 1.1 创建 resources/rawfile/knowledge_graph.html，内嵌 vis-network JS 库和初始化代码
- [x] 1.2 HTML 中实现 initGraph(data) 函数，接收节点/边 JSON 创建 vis-network 实例
- [x] 1.3 HTML 中绑定 network.on('click') 回调，调用 graphBridge.onNodeClick(nodeId)
- [x] 1.4 创建 KnowledgeGraphWeb 组件，使用 Web 组件加载 knowledge_graph.html
- [x] 1.5 通过 javaScriptProxy 注册 graphBridge 对象，暴露 onNodeClick(nodeId) 方法
- [x] 1.6 页面加载后通过 webController.runJavaScript() 注入节点/边数据
- [x] 1.7 重新生成时通过 runJavaScript() 清空并重新注入数据

## 2. 节点详情面板

- [x] 2.1 创建 NodeDetailSheet 组件，使用 bindSheet 实现底部弹窗
- [x] 2.2 详情面板展示节点标签、类型徽章（概念/争议/证据）、内容文本
- [x] 2.3 展示入边列表（← 关联：源节点标签 + 关系类型）
- [x] 2.4 展示出边列表（→ 关联：目标节点标签 + 关系类型）
- [x] 2.5 无边时显示"暂无关联关系"占位文本
- [x] 2.6 展示来源链接列表（标题可点击，跳转系统浏览器打开 URL）
- [x] 2.7 LearningSpacePage 中 graphBridge.onNodeClick 回调调用 KnowledgeBaseManager.getNodeDetails() 加载数据并展示面板

## 3. 学习空间三区纵向布局

- [x] 3.1 重构 LearningSpacePage：移除 Tab 切换，改为 Scroll + Column 纵向布局
- [x] 3.2 顶部操作栏保留返回按钮、课程名称
- [x] 3.3 心智模型区：区域标题"心智模型" + KnowledgeGraphWeb 组件（固定高度 300vp）+ 空态占位 + "重新生成"按钮
- [x] 3.4 争议点区：区域标题"争议分析" + Swiper 包裹争议卡片 + 空态占位 + "重新生成"按钮
- [x] 3.5 资料区：区域标题"补充资料" + 材料列表（AI补充附来源链接+跳转）+ 空态占位 + 上传按钮
- [x] 3.6 协作讨论区：区域标题"协作讨论" + 讨论线程列表（每个争议点一个入口）+ 空态占位

## 4. 争议分析左右分栏视图

- [x] 4.1 重写 ControversyCard 为左右分栏布局：Row 包裹两个 Column
- [x] 4.2 左侧 Column 展示观点A标题、论点列表、证据列表，蓝色背景
- [x] 4.3 右侧 Column 展示观点B标题、论点列表、证据列表，橙色背景
- [x] 4.4 底部展示综合分析文本
- [x] 4.5 用 Swiper 包裹多个 ControversyCard，支持左右滑动切换争议主题
- [x] 4.6 Swiper 下方显示指示器（当前第几个/共几个）
- [x] 4.7 ControversyCard 添加"讨论"按钮，点击跳转讨论线程页面

## 5. 争议逻辑链图谱

- [x] 5.1 从 Controversy 数据构建逻辑链节点/边数据（争议→证据→结论）
- [x] 5.2 ControversyCard 底部添加可展开的逻辑链图谱区域，复用 vis-network Web 组件
- [x] 5.3 逻辑链图谱节点配色：争议节点灰色、左侧证据蓝色、右侧证据橙色、结论节点绿色
- [x] 5.4 逻辑链图谱节点点击高亮对应争议卡片内容区域
- [x] 5.5 无证据数据时显示"暂无证据链路"占位文本

## 6. 资料区来源区分

- [x] 6.1 从知识图谱节点提取 AI 补充资料（concept/evidence 类型节点），标记"AI 补充"标签
- [x] 6.2 从 FileService 获取用户上传资料，标记"用户上传"标签
- [x] 6.3 资料列表每项显示来源标签、标题/文件名、内容预览/文件类型图标
- [x] 6.4 AI 补充资料显示来源链接图标，点击跳转系统浏览器打开 URL
- [x] 6.5 添加上传按钮入口（调用系统文件选择器）

## 7. WebSearch 知识抓取

- [x] 7.1 DeepseekService 新增 webSearch(query: string) 方法，调用 /anthropic/v1/messages 端点
- [x] 7.2 请求格式：Anthropic Messages API（x-api-key header, tools: [{type: "web_search_20260209", name: "web_search"}], model: "deepseek-v4-flash"）
- [x] 7.3 解析响应：提取 web_search_tool_result 中的搜索结果（title + url）和 text block 中的 AI 整合内容
- [x] 7.4 新建 KnowledgeSource 数据模型（id, nodeId, title, url, type）
- [x] 7.5 RDBService 新建 knowledge_source 表 + CRUD 方法
- [x] 7.6 创建课程时调用 WebSearch，将搜索结果作为 AI 补充知识存入 KnowledgeNode + KnowledgeSource
- [x] 7.7 WebSearch 失败时降级：仅使用用户上传资料，显示警告提示

## 8. 协作讨论区

- [x] 8.1 新建 Discussion、DiscussionMessage、DiscussionSummary 数据模型
- [x] 8.2 RDBService 新建 discussion、discussion_message、discussion_summary 表 + CRUD 方法
- [x] 8.3 新建 DiscussionService 管理讨论数据（创建线程、发送消息、生成总结）
- [x] 8.4 Q2 执行后自动为每个争议点创建 Discussion 线程
- [x] 8.5 新建 DiscussionThreadPage 页面：消息列表（用户/AI 交替）+ 输入框 + 发送按钮
- [x] 8.6 用户发送消息后调用 DeepseekService.chatCompletion 生成 AI 回复（含争议上下文+历史消息）
- [x] 8.7 AI 回复失败时显示错误提示 + 重试按钮
- [x] 8.8 "生成总结"按钮调用 AI 生成讨论总结并展示
- [x] 8.9 学习空间协作讨论区展示各争议点讨论入口（争议主题 + 最新消息预览 + 消息数）

## 9. 构建验证

- [x] 9.1 运行构建确认无编译错误
