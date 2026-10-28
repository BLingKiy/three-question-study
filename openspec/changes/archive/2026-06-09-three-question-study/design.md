## Context

**项目背景：**
这是一个全新的HarmonyOS应用开发项目，目标是构建"三问高效学习机"——一个以提问为核心触发机制的智能学习工具。

**当前状态：**
- 项目为空白模板，仅有基础Hello World页面
- 需要从零构建完整应用架构
- 技术栈已确定：HarmonyOS ArkTS + ArkUI + Deepseek API

**约束条件：**
- HarmonyOS API 9+ 兼容性
- 性能要求：课程生成≤2秒，知识图谱加载≤2秒
- 离线场景需要优雅降级
- 内存限制：移动端需控制Canvas节点数量

**利益相关者：**
- 终端用户：学习者，需要简单易用的学习工具
- 开发团队：需要清晰的架构和可维护的代码

## Goals / Non-Goals

**Goals:**
- 构建模块化、可扩展的应用架构
- 实现三问认知引擎的核心流程
- 提供流畅的知识图谱可视化体验
- 确保数据持久化的可靠性
- 支持AI能力的优雅集成与降级

**Non-Goals:**
- 不支持多用户/账号系统（单机应用）
- 不实现社交/协作功能（后期迭代）
- 不支持视频资料上传（仅PDF/Word/Markdown）
- 不实现跨设备同步（本地存储）

## Decisions

### 1. 整体架构设计

**决策：** 采用分层模块化架构

```
┌─────────────────────────────────────────┐
│  Presentation Layer (UI Components)     │
│  - Pages (4个主界面)                    │
│  - Components (可复用组件)              │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│  Business Logic Layer (Services)        │
│  - ThreeQuestionEngine                  │
│  - CourseManager                        │
│  - KnowledgeBaseManager                 │
│  - AssessmentManager                    │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│  Data Layer (Persistence)               │
│  - RDBService (关系数据)                │
│  - PreferencesService (配置)            │
│  - FileService (文件)                   │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│  External Integration Layer             │
│  - DeepseekAPIService                   │
└─────────────────────────────────────────┘
```

**理由：** 
- 清晰的职责分离，便于测试和维护
- 业务逻辑与UI解耦，支持未来扩展
- 数据层抽象，便于切换存储方案

**替代方案：**
- 单体架构：不适合复杂应用，难以维护
- 微服务架构：过度设计，HarmonyOS应用不需要

### 2. AI集成方案

**决策：** 使用 `@ohos/axios` + Deepseek API

```typescript
class DeepseekService {
  private axios: AxiosInstance
  private apiKey: string
  
  async chat(prompt: string): Promise<string> {
    const response = await this.axios.post('/chat/completions', {
      model: 'deepseek-chat',
      messages: [{ role: 'user', content: prompt }]
    })
    return response.data.choices[0].message.content
  }
}
```

**理由：**
- axios API熟悉，开发效率高
- 支持拦截器，便于统一错误处理
- TypeScript类型支持完善

**降级策略：**
- 网络失败：显示友好错误，支持重试
- API超时：使用本地缓存数据（如有）
- 离线模式：禁用AI功能，提示用户联网

**替代方案：**
- 原生@ohos/http：需要更多封装
- Web组件+ECharts：性能开销大

### 3. 知识图谱可视化方案

**决策：** Canvas自绘 + 力导向布局算法

```typescript
@Component
struct KnowledgeGraphCanvas {
  private ctx: CanvasRenderingContext2D
  @State nodes: KnowledgeNode[] = []
  @State edges: KnowledgeEdge[] = []
  
  // 力导向布局
  private applyForceLayout() {
    // 斥力：节点间排斥
    // 引力：边的连接
    // 迭代直到收敛
  }
  
  build() {
    Canvas(this.ctx)
      .onReady(() => this.render())
      .onTouch((e) => this.handleInteraction(e))
  }
}
```

**理由：**
- 完全控制渲染，性能最优
- 支持自定义交互（拖拽、点击、缩放）
- 无第三方依赖，代码可控

**性能优化：**
- 只渲染可见区域节点（视口裁剪）
- 使用四叉树加速碰撞检测
- 节点>100时提供聚合视图

**替代方案：**
- Tree组件：无法展示复杂关系
- Web+ECharts：性能差，体验不原生

### 4. 数据持久化方案

**决策：** 混合存储（RDB + Preferences + File）

```typescript
// RDB：结构化关系数据
interface CourseTable {
  id: string
  name: string
  question: string
  status: string
  mentalModelGenerated: boolean
  controversyGenerated: boolean
}

// Preferences：简单配置
preferences.put('theme', 'dark')
preferences.put('apiTimeout', '30000')

// File：大文件存储
const filePath = `${filesDir}/materials/${courseId}/${filename}`
await fs.write(filePath, fileContent)
```

**理由：**
- RDB：支持复杂查询（课程列表、知识节点关联）
- Preferences：配置读写极快，代码简洁
- File：适合大文件，支持预览/分享

**数据模型设计：**
```
courses (课程表)
├─ id, name, question, status
├─ mentalModelGenerated, controversyGenerated
└─ createdAt, updatedAt

knowledge_nodes (知识节点表)
├─ id, courseId, type, content
└─ position (JSON: {x, y})

knowledge_edges (知识关系表)
├─ id, fromNodeId, toNodeId
└─ type, weight

assessments (测评记录表)
├─ id, courseId, bloomLevel
└─ question, answer, isCorrect
```

**替代方案：**
- 纯RDB：大文件存储性能差
- 纯Preferences：无法复杂查询
- 纯File：无查询能力

### 5. 三问引擎流程设计

**决策：** 状态机模式 + 异步执行

```typescript
class ThreeQuestionEngine {
  private state: 'idle' | 'q1' | 'q2' | 'q3' = 'idle'
  
  async executeQuestion1(course: Course): Promise<KnowledgeGraph> {
    this.state = 'q1'
    const prompt = this.buildQ1Prompt(course.knowledgeBase)
    const result = await deepseek.chat(prompt)
    const graph = this.parseKnowledgeGraph(result)
    await this.saveGraph(graph)
    return graph
  }
  
  async regenerateQuestion1(course: Course): Promise<KnowledgeGraph> {
    // 删除旧图谱，重新生成
    await this.deleteGraph(course.id)
    return this.executeQuestion1(course)
  }
}
```

**执行规则：**
- Q1、Q2：创建课程时自动执行，可手动重新生成
- Q3：用户主动触发，每次生成不同题目
- 失败处理：记录错误状态，支持重试

**替代方案：**
- 同步执行：用户体验差，等待时间长
- 一次性全部执行：无法展示中间结果

## Risks / Trade-offs

### Risk 1: Deepseek API稳定性
**风险：** API可能超时、失败或返回格式不符
**缓解：** 
- 实现重试机制（最多3次）
- 超时设置30秒
- 响应格式验证，失败时友好提示

### Risk 2: 知识图谱性能
**风险：** 节点过多时渲染卡顿
**缓解：**
- 限制单次显示节点≤100
- 提供缩放/筛选功能
- 使用虚拟渲染（只绘制可见区域）

### Risk 3: 数据一致性
**风险：** 重新生成Q1/Q2时，旧数据如何处理
**缓解：**
- 使用事务确保原子操作
- 先删除旧数据，再写入新数据
- 提供撤销功能（保留最近一次快照）

### Risk 4: 内存占用
**风险：** Canvas + 知识图谱数据占用内存大
**缓解：**
- 及时释放不用的Canvas资源
- 节点数据按需加载
- 页面切换时清理缓存

### Trade-off 1: 功能完整度 vs 开发周期
**权衡：** MVP版本优先核心功能，高级特性后期迭代
**决策：** 
- 第一版：三问引擎 + 基础可视化 + 本地存储
- 后期迭代：高级分析、导出功能、主题定制

### Trade-off 2: AI智能度 vs 响应速度
**权衡：** 更复杂的Prompt可能更智能，但耗时更长
**决策：** 
- 优先保证≤2秒响应
- Prompt设计平衡智能度与速度
- 提供"快速模式"和"深度模式"选项

## Open Questions

1. **知识图谱布局算法选择**
   - 力导向布局 vs 层次布局？
   - 是否需要支持手动调整节点位置？
   - 建议：先实现力导向，后期可扩展

2. **用户资料解析深度**
   - PDF解析：仅提取文本 or 保留结构？
   - Word文档：支持图片提取吗？
   - 建议：第一版仅提取文本，后期扩展

3. **测评题目生成策略**
   - 完全由AI生成 or 基于模板？
   - 如何确保题目质量和难度梯度？
   - 建议：AI生成 + 人工校验模板
