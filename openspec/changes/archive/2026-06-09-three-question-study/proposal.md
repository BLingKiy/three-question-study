## Why

当前学习类应用普遍存在两大问题：**信息过载**（预置课程内容固定，无法按需学习）和**认知效率低**（缺乏系统化学习方法论）。

"三问高效学习机"通过**提问触发生成**机制，让用户真正实现"学什么、建什么"，避免信息过载。同时基于"三问认知引擎"（心智模型提取 → 学术分歧挖掘 → 深度测评生成），帮助用户快速建立学科框架、理解争议点、验证学习深度，显著提升认知效率。

现在开发此应用的时机成熟：HarmonyOS生态快速发展，ArkTS框架成熟稳定，Deepseek等大模型API成本可控。

## What Changes

构建一个完整的"三问高效学习机"应用，包含以下核心能力：

**新增功能：**
- 柔性课程生成系统：用户提问触发生成专属课程包
- 三问认知引擎：
  - 第一问：心智模型提取 → 动态知识图谱可视化
  - 第二问：学术分歧挖掘 → 争议点列表与证据链
  - 第三问：深度测评生成 → 布鲁姆认知六维度测评
- 复合知识库管理：AI智能补充 + 用户自主上传资料
- 学习进度追踪：课程卡片、进度条、能力雷达图
- Deepseek API集成：为三问引擎提供AI能力
- 本地数据持久化：RDB + Preferences + File混合存储

**交互规则：**
- 第一、二问：创建课程时自动执行，可手动重新生成
- 第三问：用户主动触发，每次生成不同题目

## Capabilities

### New Capabilities

- `course-management`: 柔性课程生成、生命周期管理、多课程并行支持
- `three-question-engine`: 三问认知引擎核心逻辑与流程控制
- `knowledge-graph`: 知识图谱数据结构、Canvas可视化、力导向布局
- `controversy-analysis`: 学术分歧挖掘、争议点展示、证据链管理
- `assessment-system`: 布鲁姆认知测评、题库生成、答题与评分
- `knowledge-base`: 复合知识库管理、AI补充资料、用户资料上传
- `progress-tracking`: 学习进度追踪、可视化展示、能力雷达图
- `ai-integration`: Deepseek API封装、三问Prompt设计、错误处理
- `data-persistence`: RDB数据库设计、Preferences配置、文件存储

### Modified Capabilities

<!-- 无现有capabilities需要修改 -->

## Impact

**新增代码模块：**
- `ets/pages/`: 4个主界面（主界面、学习空间、测评中心、个人中心）
- `ets/components/`: 知识图谱Canvas组件、雷达图组件、课程卡片组件等
- `ets/services/`: Deepseek API服务、三问引擎服务、数据持久化服务
- `ets/model/`: 数据模型定义（Course、KnowledgeNode、Assessment等）

**依赖项：**
- 新增：`@ohos/axios`（HTTP客户端）
- 新增：Deepseek API密钥配置
- 使用：HarmonyOS RDB API、Preferences API、File API

**权限需求：**
- `ohos.permission.INTERNET`：访问Deepseek API
- `ohos.permission.READ_USER_STORAGE`：读取用户上传资料
- `ohos.permission.WRITE_USER_STORAGE`：保存导出文件

**性能要求：**
- 课程生成响应 ≤ 2秒
- 知识图谱加载 ≤ 2秒
- 支持至少100个知识节点的流畅渲染
