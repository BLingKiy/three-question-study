## Context

当前测评系统仅支持主观题（用户输入文本答案），Assessment 数据模型只有 `question`/`answer`/`userAnswer`/`isCorrect` 字段。测评中心页面展示所有课程的题目平铺列表，无法区分来源课程。三问引擎在课程创建阶段自动执行 Q1+Q2，但失败后无重试入口，用户只能删除课程重来。

现有数据模型：Assessment 表有 id, course_id, bloom_level, question, answer, user_answer, is_correct, created_at。
现有 UI：AssessmentCenterPage 平铺所有测评题目；MainPage 课程卡片无重试按钮；LearningSpacePage 无重新生成按钮。

## Goals / Non-Goals

**Goals:**
- 支持4种题型：主观题、单选题、多选题、判断题
- 测评中心按课程分组显示题目
- 课程创建阶段 Q1/Q2 失败后可手动重试
- 学习空间可重新生成 Q1（知识图谱）或 Q2（争议分析）
- 客观题（选择/判断）自动判分，主观题保持关键词匹配判分

**Non-Goals:**
- 不实现填空题、排序题等其他题型
- 不实现AI自动评分主观题（保持关键词匹配）
- 不实现测评题目的手动编辑/删除
- 不实现跨课程的综合测评

## Decisions

### 1. Assessment 数据模型扩展

**决策**: 在现有 assessments 表新增 3 个字段：`question_type TEXT DEFAULT 'subjective'`、`options TEXT DEFAULT ''`（JSON 数组字符串）、`correct_answer TEXT DEFAULT ''`。

**理由**: 
- `question_type` 用 TEXT 而非 INTEGER 枚举，与现有 `bloom_level` TEXT 字段风格一致，ArkTS 侧用联合类型 `'subjective' | 'singleChoice' | 'multipleChoice' | 'trueFalse'`
- `options` 存 JSON 字符串而非子表，避免多表 JOIN，且选项数量少（通常2-6个），JSON 解析开销可忽略
- `correct_answer` 与现有 `answer` 分离：`answer` 存 AI 生成的参考答案（主观题评分参考），`correct_answer` 存客观题的标准答案（选项ID或 true/false），语义更清晰

**备选方案**: 新建 assessment_options 子表 → 拒绝，过度设计，增加查询复杂度

### 2. Q3 Prompt 适配混合题型

**决策**: 修改 PromptTemplates.getQuestion3Prompt()，在 prompt 中明确要求 AI 返回混合题型，并指定每种题型的 JSON 结构。

**理由**: AI 生成混合题型比纯主观题更能覆盖布鲁姆认知层次低层（记忆/理解）的客观测评，高层（分析/评价/创造）仍用主观题

### 3. 测评中心按课程分组

**决策**: AssessmentCenterPage 先查询所有课程列表，再按 course_id 分组显示。每组为可折叠的 List 组件，组头显示课程名称和题目数。

**理由**: 用户通常关注特定课程的测评，分组比平铺更易定位。使用可折叠设计避免长列表滚动疲劳。

**备选方案**: 用 Tabs 按课程切换 → 拒绝，课程数量动态变化时 Tabs 不灵活

### 4. 重试机制设计

**决策**: 
- MainPage 课程卡片：当 `mentalModelGenerated=false` 或 `controversyGenerated=false` 时显示"重试"按钮
- LearningSpacePage：知识图谱 Tab 和争议分析 Tab 各有"重新生成"按钮
- 重试逻辑：调用 ThreeQuestionEngine.regenerateQuestion1() / regenerateQuestion2()，内部先 deleteKnowledgeGraph/deleteControversies 再 execute

**理由**: regenerateQuestion1/2 已有先删后生的逻辑，只需暴露 UI 入口。MainPage 侧重"创建阶段失败重试"，LearningSpacePage 侧重"不满意重新生成"，两个场景互补。

### 5. 客观题答题 UI 组件

**决策**: 在 AssessmentCenterPage 内根据 questionType 条件渲染不同答题组件：
- `singleChoice`: Radio 组件列表
- `multipleChoice`: Checkbox 组件列表  
- `trueFalse`: 两个 Radio（正确/错误）
- `subjective`: TextArea（现有逻辑）

**理由**: ArkUI 的 Radio/Checkbox 组件原生支持，无需自定义。条件渲染比动态组件更符合 ArkTS 限制（不允许动态类型推断）。

## Risks / Trade-offs

- [数据库迁移] 新增字段需 ALTER TABLE，旧数据 question_type 默认 'subjective' 兼容 → 风险低，RDBService.initialize() 中执行 ALTER
- [AI 响应格式不稳定] Q3 返回的混合题型 JSON 可能不符合预期结构 → ResponseParser 已有容错逻辑，解析失败时 fallback 为主观题
- [重试并发] 用户快速多次点击重试可能触发并发执行 → 按钮加 loading 状态禁用，与现有 isCreating 逻辑一致
- [多选题评分] 多选题部分正确如何判分 → 简化处理：全对才算对（isCorrect=true），后续可扩展部分得分