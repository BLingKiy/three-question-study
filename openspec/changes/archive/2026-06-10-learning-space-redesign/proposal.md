## Why

当前学习空间界面采用 Tab 切换方式（知识图谱/争议分析/补充材料三个独立 Tab），与需求书要求的"心智模型区（顶部）→ 争议点区（中部）→ 资料区（底部）"三区纵向布局不符。此外存在核心缺陷：(1) 知识图谱 Canvas 的 onClick 事件未绑定，节点点击无法触发交互；(2) 节点点击后无详情面板展示（关联边、关联材料）；(3) 争议点区仅简单列表渲染，无左右分栏对比视图，不支持切换争议主题；(4) 创建课程时无 WebSearch 能力，知识库仅依赖用户上传资料，缺乏网络补充；(5) 无协作讨论区，用户无法针对争议点发表观点并与 AI 互动；(6) 争议分析无逻辑链图谱，无法可视化争议→证据→结论的推理链路。

## What Changes

- 学习空间页面从 Tab 切换布局改为三区纵向滚动布局：顶部心智模型区（知识图谱）、中部争议点区（左右分栏对比+逻辑链图谱）、底部资料区（复合知识库列表）
- 知识图谱使用 ArkWeb + vis-network 替代 Canvas，支持节点点击交互
- 新增节点详情面板：点击节点弹出底部 Sheet，展示节点内容、关联关系、来源链接
- 争议点区改为左右分栏对比视图+Swiper 切换争议主题
- 每个争议点支持独立逻辑链图谱（争议→证据→结论），使用 vis-network 渲染
- 资料区展示复合知识库列表，区分 AI 补充资料和用户上传资料，AI 补充资料附来源链接和跳转
- 新增 WebSearch 知识抓取：创建课程时调用 DeepSeek Anthropic API（/anthropic/v1/messages + web_search 工具），结合用户上传资料丰富知识库，AI 补充知识点附带来源链接
- 新增协作讨论区：针对争议点设置讨论线程，用户发表观点，AI 参与对话回复，AI 生成讨论总结
- 顶部操作栏保留"重新生成"按钮（不保留"生成测评"按钮，该功能已移至评测中心页面）

## Capabilities

### New Capabilities
- `node-detail-panel`: 知识图谱节点详情面板——展示节点内容、关联关系、来源链接，底部 Sheet 形式
- `web-search-knowledge`: WebSearch 知识抓取——创建课程时调用 DeepSeek Anthropic API WebSearch，结合用户资料丰富知识库，AI 补充资料附来源链接
- `discussion-zone`: 协作讨论区——针对争议点的单用户评论式讨论，AI 参与对话回复和生成讨论总结
- `controversy-logic-chain`: 争议逻辑链图谱——每个争议点独立小型 vis-network 图谱，展示争议→证据→结论推理链路

### Modified Capabilities
- `knowledge-graph`: Canvas 替换为 ArkWeb + vis-network，节点点击触发回调，知识图谱区域适配纵向布局
- `three-question-engine`: 争议分析展示改为左右分栏对比视图+Swiper 切换争议主题+逻辑链图谱

## Impact

- **UI层**: LearningSpacePage 完全重构（Tab→纵向三区+讨论区）；新增 NodeDetailSheet、DiscussionThread、ControversyLogicChain 组件；ControversyCard 改为左右分栏布局
- **组件层**: KnowledgeGraphCanvas 被 ArkWeb 替代；新增 Swiper 包裹争议卡片；新增讨论区组件
- **服务层**: DeepseekService 新增 webSearch 方法（Anthropic Messages API 格式）；新增 DiscussionService；KnowledgeBaseManager 扩展来源链接支持
- **数据层**: 新增 KnowledgeSource 表（节点来源链接）；新增 Discussion、DiscussionMessage、DiscussionSummary 表