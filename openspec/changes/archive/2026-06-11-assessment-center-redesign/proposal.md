## Why

当前测评中心存在三个核心问题：(1) 测评题目生成入口不明确——用户需从学习空间手动触发Q3，测评中心本身没有生成按钮；(2) 题目缺少维度和类型明示——用户无法直观看到每道题对应的布鲁姆认知层级和题型；(3) 答题后缺少追问环节——无论客观题还是主观题，答完后无法进行深入追问和讨论，无法实现"验证理解深度"的认知闭环。需求书明确要求"支持即时答题、答案解析、错题溯源、测评报告生成"，且每道题答完后应有追问模块以深化学习效果。

## What Changes

- 测评中心按课程分组显示，已完成知识库构建的课程自动出现在列表中，初始无题目
- 每个课程旁显示"生成测评"按钮，点击后基于用户上传文件+已生成的全部课程资料库（知识图谱节点+争议数据+WebSearch资料）调用AI生成测评题目
- 题目生成时融合用户上传材料内容（txt/md文件实际内容）作为上下文
- 测评列表中每道题明示布鲁姆认知维度（记忆/理解/应用/分析/评价/创造）和题型（单选/多选/判断/主观）
- 答题流程：客观题提交后显示判题结果+正确答案解析+下一题按钮；主观题提交后AI深度评价+下一题按钮
- **追问模块**：每道题答完后（无论客观/主观），显示"追问"输入区域，用户可输入追问，AI基于当前题目上下文和用户答案进行深入解答
- 追问记录持久化存储，可查看历史追问对话

## Capabilities

### New Capabilities
- `assessment-follow-up`: 答题追问模块——每道题答完后支持用户追问，AI基于题目上下文和用户答案进行深入解答，追问记录持久化

### Modified Capabilities
- `assessment-system`: 测评中心UI重构——按课程分组+生成按钮+维度类型明示+基于完整资料库生成题目
- `assessment-question-types`: 答题流程增强——客观题判题后显示解析，主观题AI评价后显示分析，答完统一进入追问模块

## Impact

- `AssessmentCenterPage.ets`：大幅重构，新增课程分组列表、生成按钮、维度/类型标签、追问UI
- `AssessmentManager.ets`：新增追问相关方法（saveFollowUp、getFollowUps、generateFollowUpReply）
- `RDBService.ets`：新增 assessment_follow_ups 表，新增追问CRUD方法
- `ThreeQuestionEngine.ets`：executeQuestion3 增加材料内容上下文传入
- `PromptTemplates.ets`：新增追问prompt模板，优化Q3 prompt加入材料内容
- `Assessment.ets`：新增 FollowUp 模型定义