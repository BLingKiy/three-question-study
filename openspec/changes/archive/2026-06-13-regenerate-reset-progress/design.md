## Context

当前 LearningSpacePage 的"重新生成"按钮调用 `handleRegenerate()`，该方法通过 `ThreeQuestionEngine.regenerateAll()` 重新生成知识图谱和争议分析，然后标记 `mentalModelGenerated=true` 和 `controversyGenerated=true`。但以下数据未被处理：
- `learning_progress` 表中该课程的进度记录（勾选状态）未重置
- `assessments` 表中该课程的测评题目未清除
- `assessment_reports` 表中该课程的测评报告未清除
- 已答题目的用户答案和追问历史直接丢失

用户期望：重新生成后进度归零、测评题目清除（需重新生成），但已答题目和追问历史应保留在独立板块中。

## Goals / Non-Goals

**Goals:**
- 重新生成时重置学习进度，使用户重新开始学习
- 重新生成时清除测评题目和报告，assessmentGenerating 重置为 false
- 将已答题目（userAnswer 非空）及追问历史归档到独立表
- 在"我的"页面新增"答题档案"区域，展示历史答题记录

**Non-Goals:**
- 不实现答题档案的搜索/筛选功能
- 不实现归档记录的删除功能（随课程删除级联删除）
- 不实现答题档案的导出功能（已有数据导出功能覆盖）

## Decisions

### 1. 归档数据存储方案
**决策**：新增 `answer_archives` 和 `follow_up_archives` 两张表，结构与 assessments/assessment_follow_ups 类似，但增加 `original_course_id` 和 `original_course_name` 字段。
**理由**：独立表避免修改现有表结构，查询性能好，课程删除时可级联清理。保留课程名用于展示（课程可能已删除）。

### 2. 归档时机
**决策**：在 `handleRegenerate()` 中，先迁移已答题目到归档表，再删除 assessments/assessment_follow_ups/assessment_reports/learning_progress 中的数据。
**理由**：先迁移后删除，确保数据不丢失。在同一个异步流程中完成，无需事务（RDB 不支持跨表事务）。

### 3. 答题档案 UI 方案
**决策**：在 ProfilePage 的"答题档案"区域，按原始课程名分组展示。每个课程下展示题目列表（题目文本+题型标签+正确/错误状态），点击可展开查看用户答案、正确答案、AI评价和追问对话。
**理由**：与测评中心的课程分组展示风格一致，用户熟悉。

### 4. 归档记录与课程的关联
**决策**：归档记录保留 `original_course_id` 用于级联删除，但展示时用 `original_course_name`（课程可能已删除或重命名）。
**理由**：课程删除时需清理归档数据，但展示不应依赖课程是否存在。

## Risks / Trade-offs

- **归档表数据量增长** → 单用户场景下数据量有限，无需分页；如需优化可后续添加
- **重新生成过程中的中断** → 先迁移后删除，即使中断也只是部分迁移，不影响数据完整性
- **答题档案与课程删除** → 课程删除时级联删除归档记录，用户可能希望保留；可通过 UI 提示确认