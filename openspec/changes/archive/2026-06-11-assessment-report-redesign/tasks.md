## 1. 数据模型与持久化

- [x] 1.1 在 RDBService 中新增 assessment_reports 表创建（id, course_id UNIQUE, dimensions_json, overall_suggestion, error_traces_json, dimension_analysis_json, created_at）
- [x] 1.2 新增 AssessmentReport 模型类（id, courseId, dimensions: DimensionScores, overallSuggestion, errorTraces: ErrorTrace[], dimensionAnalysis: DimensionAnalysis, createdAt）
- [x] 1.3 新增 ErrorTrace 接口（questionId, knowledgeNodeId, knowledgeNodeLabel, traceExplanation）
- [x] 1.4 新增 DimensionScores 接口（conceptUnderstanding, criticalThinking, practicalTransfer，均为 number）
- [x] 1.5 新增 DimensionAnalysis 接口（conceptUnderstanding, criticalThinking, practicalTransfer，均为 string）
- [x] 1.6 RDBService 新增 saveAssessmentReport / getAssessmentReportByCourseId / deleteAssessmentReportByCourseId 方法
- [x] 1.7 deleteCourse 级联删除 assessment_reports 数据

## 2. AI报告生成

- [x] 2.1 PromptTemplates 新增 getAssessmentReportPrompt（包含所有题目+用户答案+判定结果+追问记录+知识节点列表，要求AI输出3维分数+复习建议+错题溯源+维度分析JSON）
- [x] 2.2 ResponseParser 新增 parseAssessmentReport 方法（解析AI返回的JSON为 AssessmentReport 对象，兜底处理解析失败）
- [x] 2.3 AssessmentManager 新增 generateAssessmentReport 方法（收集上下文→调用AI→解析→存储→返回报告）
- [x] 2.4 AssessmentManager 新增 getAssessmentReport 方法（从DB读取已有报告）
- [x] 2.5 重新生成测评时删除旧报告（AssessmentManager.regenerateAssessments 中调用 deleteAssessmentReportByCourseId）

## 3. 3维雷达图 ArkWeb+ECharts

- [x] 3.1 创建 rawfile/radar_chart.html（ECharts雷达图，3维：概念理解/批判思维/实践迁移，0-100刻度，接收javaScriptProxy传入的分数数据）
- [x] 3.2 新增 RadarChartWeb 组件（ArkWeb封装，javaScriptProxy通信，传入dimensions数据渲染雷达图）

## 4. 评测报告页面

- [x] 4.1 新增 AssessmentReportPage 页面（接收courseId参数，显示3维雷达图+整体复习建议+维度分析+错题溯源列表）
- [x] 4.2 报告页面加载逻辑：优先从DB读取，无则调用AI生成（显示loading），生成失败显示错误提示
- [x] 4.3 错题溯源条目点击跳转 LearningSpacePage（路由参数传递 nodeId）
- [x] 4.4 main_pages.json 注册 AssessmentReportPage 路由

## 5. 答题页面导航重构

- [x] 5.1 AssessmentCenterPage 答题区域：去掉最后一题"查看结果"按钮逻辑，改为所有题目显示"上一题"/"下一题"按钮
- [x] 5.2 "上一题"按钮：非第一题时enabled，第一题时disabled
- [x] 5.3 "下一题"按钮：非最后题时enabled，最后题时disabled
- [x] 5.4 答题结果区域下方新增"查看评测报告"按钮（初始disabled，课程所有题目答完后enabled）
- [x] 5.5 课程题目列表中已答题目卡片新增"查看报告"按钮（初始disabled，全部答完后enabled）
- [x] 5.6 "查看评测报告"按钮点击跳转 AssessmentReportPage（传递courseId）
- [x] 5.7 删除旧的 RadarChart Canvas 组件引用（替换为 RadarChartWeb）

## 6. 验证与构建

- [x] 6.1 构建验证：hvigorw assembleHap 通过