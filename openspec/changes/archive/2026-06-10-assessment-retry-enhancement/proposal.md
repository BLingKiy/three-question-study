## Why

当前测评系统存在三个核心缺陷：(1) 测评题目仅支持主观题，缺少选择题（单选/多选）、判断题等客观题型，限制了测评的覆盖面和效率；(2) 测评中心页面未按课程分组，用户无法区分不同课程的题目；(3) 课程创建阶段的三问引擎（Q1心智模型提取、Q2争议分析）执行失败后无法重试，用户只能删除课程重新创建，体验极差。这些问题直接影响学习效率和用户留存。

## What Changes

- 扩展 Assessment 数据模型，新增 `questionType` 字段支持 `subjective`（主观题）、`singleChoice`（单选题）、`multipleChoice`（多选题）、`trueFalse`（判断题）四种题型
- 新增 `options` 字段存储选项列表（选择题/判断题），新增 `correctAnswer` 字段存储标准答案
- 扩展 PromptTemplates Q3 提示词，指示 AI 生成混合题型的测评题目
- 扩展 ResponseParser 解析逻辑，支持解析不同题型的 AI 响应
- 测评中心页面按课程分组显示题目，每组显示课程名称和题目数量
- 主页课程卡片上增加"重试"按钮，当 Q1/Q2 执行失败时允许用户手动重试
- 学习空间页面增加"重新生成"按钮，允许重新执行 Q1（知识图谱）或 Q2（争议分析）
- 重试逻辑：重新生成前先删除该阶段的旧数据，再调用对应引擎方法

## Capabilities

### New Capabilities
- `assessment-question-types`: 多题型测评支持——数据模型扩展、AI提示词适配、响应解析、答题UI组件（单选/多选/判断题交互）

### Modified Capabilities
- `assessment-system`: 测评中心页面按课程分组显示题目；答题交互适配多题型；评分逻辑适配客观题自动判分
- `three-question-engine`: 新增重试机制——Q1/Q2 执行失败后支持手动重试；重试前清除旧数据

## Impact

- **数据模型**: Assessment 新增 `questionType`、`options`、`correctAnswer` 字段，需数据库迁移（ALTER TABLE）
- **服务层**: PromptTemplates、ResponseParser、ThreeQuestionEngine 需扩展
- **UI层**: AssessmentCenterPage 重构为分组列表；新增选择题/判断题答题组件；MainPage/LearningSpacePage 新增重试按钮
- **API**: Deepseek API 调用逻辑不变，但 Q3 prompt 需调整以生成混合题型