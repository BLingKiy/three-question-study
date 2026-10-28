## 1. 数据模型与持久化

- [x] 1.1 在 Assessment.ets 中新增 FollowUp 接口定义（id, assessmentId, role, content, createdAt）和 FollowUpImpl 实现类
- [x] 1.2 在 RDBService.ets 中添加 assessment_follow_ups 表的 CREATE TABLE SQL 语句（id, assessment_id, role, content, created_at，外键 ON DELETE CASCADE）
- [x] 1.3 在 RDBService.ets 中实现 insertFollowUp(followUp) 方法
- [x] 1.4 在 RDBService.ets 中实现 queryFollowUpsByAssessmentId(assessmentId) 方法
- [x] 1.5 在 RDBService.ets 中实现 deleteFollowUpsByAssessmentId(assessmentId) 方法（用于级联删除保险）
- [x] 1.6 在 RDBService.ets 的 deleteCourse 方法中确认 assessments 外键 CASCADE 能正确级联到 assessment_follow_ups

## 2. 追问 Prompt 与服务层

- [x] 2.1 在 PromptTemplates.ets 中新增 getFollowUpPrompt 静态方法，接收原题目、用户答案、评价结果、追问历史、当前追问问题，返回 ChatMessage[]
- [x] 2.2 在 AssessmentManager.ets 中新增 generateFollowUpReply(assessmentId, question, userAnswer, evaluationContext, followUpHistory, userFollowUpQuestion) 方法，调用 AI 生成追问回复
- [x] 2.3 在 AssessmentManager.ets 中新增 saveFollowUp(assessmentId, role, content) 方法，创建 FollowUp 对象并插入 RDB
- [x] 2.4 在 AssessmentManager.ets 中新增 getFollowUps(assessmentId) 方法，查询追问历史

## 3. 测评生成上下文增强

- [x] 3.1 在 ThreeQuestionEngine.ets 的 executeQuestion3 方法中新增 materialsContent 可选参数
- [x] 3.2 在 PromptTemplates.ets 的 getQuestion3Prompt 中新增 materialsContent 参数，将材料内容加入 user prompt
- [x] 3.3 在 AssessmentCenterPage.ets 中实现 collectAssessmentContext(courseId) 方法，收集知识图谱节点+争议数据+用户上传材料内容+WebSearch资料，材料内容超8000字符截断
- [x] 3.4 在 AssessmentCenterPage.ets 中实现 handleGenerateAssessment(courseId) 方法，调用 collectAssessmentContext + executeQuestion3，处理加载状态和错误

## 4. 测评中心 UI 重构

- [x] 4.1 重构 AssessmentCenterPage 的 loadAssessments 方法，查询所有 mentalModelGenerated=true 的课程，按课程分组显示
- [x] 4.2 在课程分组标题栏右侧添加"生成测评"按钮，无题目时显示"暂无测评题目"占位文字
- [x] 4.3 生成按钮点击时弹出确认对话框，确认后调用 handleGenerateAssessment
- [x] 4.4 生成中按钮置灰+加载指示器，生成失败显示错误 toast
- [x] 4.5 API 密钥未配置时显示"请先在「我的」页面配置 API 密钥"错误提示

## 5. 题目维度/类型标签

- [x] 5.1 在测评列表的题目卡片上添加布鲁姆认知维度标签（记忆/理解/应用/分析/评价/创造），使用不同颜色
- [x] 5.2 在测评列表的题目卡片上添加题型标签（单选/多选/判断/主观）
- [x] 5.3 在答题界面的题目头部区域显示布鲁姆维度标签和题型标签

## 6. 答题流程增强

- [x] 6.1 客观题提交后显示判题结果（✓/✗）+ 正确答案 + 用户选择对比
- [x] 6.2 主观题提交后显示 AI 评价结果（得分+分析+建议）
- [x] 6.3 答题后显示"下一题"按钮和追问输入区域

## 7. 追问模块 UI

- [x] 7.1 在答题结果下方添加追问区域：消息列表（用户消息右对齐，AI消息左对齐+Markdown渲染）+ 输入框 + "追问"按钮
- [x] 7.2 追问提交时调用 AssessmentManager.generateFollowUpReply，显示加载状态，完成后追加到消息列表
- [x] 7.3 追问失败时显示错误 toast，用户消息保留
- [x] 7.4 查看已答题目时加载并显示追问历史
- [x] 7.5 "下一题"按钮可跳过追问直接进入下一题

## 8. 构建验证

- [x] 8.1 运行 hvigorw assembleHap 确保构建成功
