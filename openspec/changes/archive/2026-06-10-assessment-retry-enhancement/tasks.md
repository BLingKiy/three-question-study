## 1. 数据模型扩展

- [x] 1.1 在 Assessment 接口中新增 `questionType`、`options`、`correctAnswer` 字段，导出 QuestionType 联合类型
- [x] 1.2 在 RDBService 中执行 ALTER TABLE 为 assessments 表新增 `question_type`、`options`、`correct_answer` 列
- [x] 1.3 更新 RDBService.insertAssessment() 写入新字段
- [x] 1.4 更新 RDBService.queryAssessments() 读取新字段
- [x] 1.5 更新 RDBService.updateAssessment() 支持新字段
- [x] 1.6 更新 AssessmentImpl class 添加新字段默认值

## 2. AI 提示词与响应解析

- [x] 2.1 修改 PromptTemplates.getQuestion3Prompt() 指示 AI 生成混合题型（主观题+单选+多选+判断题）
- [x] 2.2 扩展 ParsedAssessment 接口新增 `questionType`、`options`、`correctAnswer` 字段
- [x] 2.3 更新 ParsedAssessmentImpl class 添加新字段
- [x] 2.4 修改 ResponseParser.parseAssessments() 解析 questionType、options、correctAnswer，未知类型 fallback 为 subjective
- [x] 2.5 更新 ThreeQuestionEngine.executeQuestion3() 将新字段传入 Assessment 对象

## 3. 客观题答题 UI

- [x] 3.1 在 AssessmentCenterPage 中根据 questionType 条件渲染不同答题组件（Radio/Checkbox/TextArea）
- [x] 3.2 实现单选题 Radio 列表答题交互
- [x] 3.3 实现多选题 Checkbox 列表答题交互
- [x] 3.4 实现判断题两个 Radio 答题交互
- [x] 3.5 实现客观题自动判分逻辑（单选/多选/判断题在 submitAnswer 中自动比对 correctAnswer）

## 4. 测评中心按课程分组

- [x] 4.1 AssessmentCenterPage 查询课程列表，按 course_id 对测评题目分组
- [x] 4.2 实现课程分组可折叠列表 UI，组头显示课程名称和题目数
- [x] 4.3 点击课程组展开/折叠题目列表

## 5. 课程创建阶段重试

- [x] 5.1 MainPage 课程卡片根据 mentalModelGenerated/controversyGenerated 状态显示重试按钮
- [x] 5.2 实现重试 Q1 按钮：调用 ThreeQuestionEngine.regenerateQuestion1()
- [x] 5.3 实现重试 Q2 按钮：调用 ThreeQuestionEngine.regenerateQuestion2()
- [x] 5.4 重试按钮添加 loading 状态防止重复点击

## 6. 学习空间重新生成

- [x] 6.1 LearningSpacePage 知识图谱 Tab 添加"重新生成"按钮
- [x] 6.2 LearningSpacePage 争议分析 Tab 添加"重新生成"按钮
- [x] 6.3 重新生成前显示确认提示
- [x] 6.4 重新生成完成后刷新页面数据
- [x] 6.5 重新生成按钮添加 loading 状态

## 7. 构建验证

- [x] 7.1 运行构建确认无编译错误