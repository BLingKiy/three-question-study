## Context

当前 LearningSpacePage 使用三个 Tab（知识图谱/争议分析/补充材料）切换展示，与需求书要求的三区纵向布局（顶部心智模型→中部争议→底部资料）不符。知识图谱 Canvas 组件的 `handleCanvasClick` 方法已定义但未绑定到 Canvas 的 `onTouch`/`onClick` 事件，导致节点点击无法触发。争议分析使用 ControversyCard 纵向列表，非需求书要求的左右分栏对比视图。创建课程时无 WebSearch 能力，知识库仅依赖用户上传资料。无协作讨论区功能。争议分析无逻辑链图谱。

现有可复用组件/服务：
- KnowledgeGraphCanvas：Canvas 绘制+onNodeClick 回调（将被 ArkWeb 替代）
- ControversyCard：争议卡片（需改为左右分栏布局）
- KnowledgeBaseManager.getNodeDetails()：返回节点+出入边（已有实现）
- FileService：文件上传/管理（已有实现）
- DeepseekService：已有 chatCompletion（OpenAI 格式），需新增 webSearch（Anthropic Messages 格式）

## Goals / Non-Goals

**Goals:**
- 重构为三区纵向滚动布局+讨论区，符合需求书描述
- 知识图谱使用 ArkWeb + vis-network 替代 Canvas，支持节点点击交互
- 节点详情面板展示来源链接，支持点击跳转浏览器
- 争议点区改为左右分栏对比视图，支持 Swiper 切换争议主题
- 每个争议点支持独立逻辑链图谱（争议→证据→结论）
- 资料区展示复合知识库列表，AI 补充资料附来源链接和跳转
- 创建课程时调用 WebSearch（DeepSeek Anthropic API）结合用户资料丰富知识库
- 协作讨论区：针对争议点的单用户评论式讨论，AI 参与对话回复+生成总结
- 保留"重新生成"操作入口（重新生成知识图谱/争议分析）
- 学习空间不保留"生成测评"按钮，该功能已移至评测中心页面

**Non-Goals:**

- 不实现知识图谱的动画效果（节点展开/收缩动画）
- 不实现材料语义融合（保持现有拼接式合并）
- 不实现数据导出功能
- 不实现多用户协作（仅单用户评论式）
- 不实现争议点筛选功能

## Decisions

### 1. 三区纵向布局使用 Scroll + Column

**决策**: 使用 `Scroll` 包裹 `Column`，三个区域+讨论区依次纵向排列，每个区域用标题+内容卡片分隔。

**理由**: 需求书明确要求"顶部→中部→底部"三区布局，Scroll 纵向滚动比 Tab 切换更符合阅读流。每个区域高度固定（知识图谱 300vp、争议区自适应、资料区自适应、讨论区自适应），避免单区过长。

**备选方案**: 继续用 Tab 但改为纵向 Tabs → 拒绝，Tab 本质是切换而非同时展示

### 2. 知识图谱节点详情用 bindSheet 底部弹窗

**决策**: 点击节点后使用 `bindSheet` 弹出底部 Sheet，展示节点内容、关联关系列表、来源链接（可点击跳转浏览器）。

**理由**: 底部 Sheet 是 HarmonyOS 推荐的详情展示模式，不遮挡知识图谱全貌，用户可快速关闭回到图谱。已有 `bindSheet` 使用先例（MainPage 创建课程弹窗）。

**备选方案**: 路由到新页面 → 拒绝，页面跳转打断学习流；弹窗 Dialog → 拒绝，Dialog 面积小不适合展示丰富内容

### 3. 知识图谱使用 ArkWeb + vis-network 替代 Canvas

**决策**: 使用 `Web` 组件加载本地 HTML，内嵌 vis-network JS 库渲染知识图谱。通过 `javaScriptProxy` 注册 ArkTS 对象，JS 端节点点击时调用 ArkTS 方法，实现 H5→ArkTS 通信。

**理由**: 
- vis-network 是成熟的关系图谱库，自带力导向布局、节点拖拽、缩放、点击事件，无需手动实现 Canvas 绘制和命中检测
- ArkWeb 是 HarmonyOS 推荐的 Web 容器，性能和兼容性有保障
- JS 端事件（节点点击、拖拽）天然支持，无需手动计算触摸坐标
- 可轻松扩展样式（节点颜色/大小/图标、边样式、动画效果）

**实现方案**:
1. 在 `resources/rawfile/` 下创建 `knowledge_graph.html`，内嵌 vis-network CDN 或本地 JS
2. Web 组件通过 `javaScriptProxy` 注册 `graphBridge` 对象，暴露 `onNodeClick(nodeId)` 方法
3. JS 端 vis-network 的 `network.on('click', ...)` 回调中调用 `graphBridge.onNodeClick(nodeId)`
4. ArkTS 侧收到 nodeId 后，调用 `KnowledgeBaseManager.getNodeDetails()` 加载数据，展示详情 Sheet
5. 页面加载时通过 `webController.runJavaScript()` 将节点/边数据注入 JS

**备选方案**: 修复 Canvas 事件绑定 → 拒绝，Canvas 手动绘制交互性差、扩展困难；使用 @ohos/Chart → 拒绝，该库不支持关系图谱

### 4. 争议区使用 Swiper + 左右分栏卡片

**决策**: 争议区用 `Swiper` 组件包裹多个争议卡片，每个卡片内部用 `Row` 左右分栏展示观点A/观点B，底部展示综合分析。

**理由**: Swiper 支持左右滑动切换争议主题，符合需求书"支持切换不同争议主题"。左右分栏用 Row + 两个 Column 实现，左蓝右橙配色区分观点。

### 5. 资料区区分来源标签

**决策**: 资料列表每项显示来源标签（"AI 补充" / "用户上传"），AI 补充资料为知识图谱节点内容提取+WebSearch 来源，用户上传资料来自 FileService。

**理由**: 需求书要求"包含 AI 补充资料与用户上传资料"，需视觉区分来源。AI 补充资料附带来源链接，点击可跳转浏览器打开原始网页。

### 6. WebSearch 使用 DeepSeek Anthropic API

**决策**: 在 DeepseekService 中新增 `webSearch` 方法，调用 `https://api.deepseek.com/anthropic/v1/messages` 端点，使用 Anthropic Messages API 格式，携带 `web_search` server tool。同一个 DeepSeek API Key，无需额外配置。

**理由**: 
- DeepSeek 提供 Anthropic 兼容 API，支持 WebSearch server tool，服务端自动执行搜索
- 同一个 API Key，用户无需额外配置
- 响应中包含 `web_search_tool_result`，提供搜索结果的 title + url
- 最终答案在 `type: "text"` 的 content block 中

**实现方案**:
1. DeepseekService 新增 `webSearch(query: string)` 方法
2. 请求格式：Anthropic Messages API（`x-api-key` header，`tools: [{type: "web_search_20260209", name: "web_search"}]`）
3. 解析响应：提取 `web_search_tool_result` 中的搜索结果（title + url）和 `text` block 中的 AI 整合内容
4. 创建课程时：先用 WebSearch 搜索主题，将搜索结果作为 AI 补充资料存入 KnowledgeSource 表
5. AI 补充知识点附带来源链接，在节点详情面板和资料区可点击跳转

**备选方案**: 使用第三方搜索 API → 拒绝，DeepSeek WebSearch 已集成，无需额外服务

### 7. 协作讨论区为单用户评论式 + AI 参与

**决策**: 每个争议点对应一个讨论线程，用户发表观点后 AI 自动回复，用户可随时请求 AI 生成讨论总结。

**理由**: 
- 单机应用无多用户需求，单用户评论式最简单
- AI 参与对话可引导用户深入思考，提供不同视角
- 讨论总结帮助用户回顾和整合观点

**实现方案**:
1. 新建 Discussion、DiscussionMessage、DiscussionSummary 数据表
2. 新建 DiscussionService 管理讨论数据
3. 讨论区 UI：讨论线程列表 → 进入线程 → 消息列表（用户/AI 交替）+ 输入框
4. 用户发送消息后，调用 DeepseekService.chatCompletion 生成 AI 回复
5. "生成总结"按钮调用 AI 生成讨论总结并存储

**备选方案**: 实时多用户讨论 → 拒绝，单机应用无后端；纯本地笔记式 → 拒绝，缺乏 AI 互动价值

### 8. 争议逻辑链图谱复用 vis-network

**决策**: 每个争议点用独立的 vis-network 实例渲染逻辑链图谱，复用 knowledge_graph.html 模板，注入争议专属数据（争议节点→证据节点→结论节点）。

**理由**: vis-network 已在知识图谱中验证可用，复用同一模板减少开发量。每个争议点的逻辑链数据量小（3-10 节点），渲染性能无忧。

**实现方案**:
1. 复用 knowledge_graph.html，通过 runJavaScript 注入不同数据
2. 从 Controversy 数据构建逻辑链节点/边：争议节点→证据节点（leftView.evidence + rightView.evidence）→结论节点（synthesis）
3. 在争议卡片下方或展开区域嵌入 Web 组件渲染逻辑链

### 9. 知识来源使用独立 KnowledgeSource 表

**决策**: 新建 `KnowledgeSource` 表（id, nodeId, title, url, type），一个知识点可关联多个来源链接。

**理由**: 一个知识点可能综合多个网页来源，独立表支持一对多关系。来源链接在节点详情面板和资料区均可展示和跳转。

## Risks / Trade-offs

- [纵向滚动性能] 知识图谱 Web 组件在 Scroll 内可能有渲染性能问题 → 知识图谱区域固定高度 300vp，不在视口内时不影响性能
- [Swiper 嵌套 Scroll] Swiper 在 Scroll 内可能有手势冲突 → Swiper 设置 `.disableSwipe(true)` 仅用指示器切换，或用自定义左右箭头按钮切换
- [节点详情数据加载] getNodeDetails() 需要额外数据库查询 → 查询量小（单节点+边），可接受
- [ArkWeb 离线可用性] vis-network CDN 需要网络 → 将 vis-network JS 文件放在 rawfile 本地加载，无需网络
- [WebSearch API 可用性] DeepSeek Anthropic API 端点可能不稳定 → 添加降级逻辑，WebSearch 失败时仍可基于用户资料创建课程
- [讨论区 AI 调用频率] 每条用户消息都触发 AI 回复，消耗 token → 可添加"手动触发 AI 回复"选项，避免自动回复消耗过多
- [逻辑链图谱数据构建] 需从 Controversy 结构提取证据/结论构建图谱数据 → 数据量小，可在前端直接构建