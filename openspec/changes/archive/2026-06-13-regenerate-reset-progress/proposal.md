## Why

当前学习空间页点击"重新生成"后，课程的知识图谱和争议分析会重新生成，但学习进度和测评题目不会重置。这导致用户重新学习时，旧的进度勾选和已答题目仍然存在，与新知识库内容不匹配，造成困惑。同时，用户已作答的题目和追问历史是有价值的学习记录，不应随重新生成而丢失，应保留在独立的历史板块中供回顾。

## What Changes

- 重新生成时重置该课程的学习进度（learning_progress 表中该课程的所有记录清空）
- 重新生成时删除该课程已生成的测评题目（assessments 表），但保留已答题目的题目文本、用户答案、判题结果和追问历史，移至"答题档案"板块
- 重新生成时删除该课程的测评报告（assessment_reports）
- 新增"答题档案"功能：在"我的"页面展示用户所有历史答题记录，按课程分组，包含题目内容、用户答案、正确答案、AI评价和追问对话
- 新增 `answer_archive` 表存储归档的答题记录，新增 `follow_up_archive` 表存储归档的追问记录
- 重新生成时将已答题目（userAnswer 非空）及追问历史从 assessments/assessment_follow_ups 迁移到 archive 表
- 重新生成后 assessmentGenerating 重置为 false，用户需在测评中心重新点击"生成测评"

## Capabilities

### New Capabilities
- `answer-archive`: 答题档案功能，存储和展示历史答题记录与追问对话

### Modified Capabilities
- `three-question-engine`: 重新生成时需重置学习进度、迁移已答题目到档案、清除测评题目和报告
- `course-management`: 重新生成逻辑变更，涉及进度重置和答题归档

## Impact

- RDBService：新增 answer_archive 和 follow_up_archive 表及 CRUD 方法；deleteCourse 需级联删除 archive 表
- ThreeQuestionEngine / LearningSpacePage：handleRegenerate 逻辑扩展
- ProfilePage：新增"答题档案"区域
- Assessment.ets：可能需新增 ArchiveAssessment 和 ArchiveFollowUp 接口