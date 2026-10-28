## Why

当前测评中心存在三个核心问题：(1) "查看结果"按钮仅在最后一题显示，但用户可乱序答题，导致无法在任意题目入口查看报告；(2) 测评报告缺少整体复习建议和错题溯源（追溯到知识节点），无法形成学习闭环；(3) 雷达图使用6维Bloom分类，不符合需求要求的3维能力模型（概念理解/批判思维/实践迁移），且需改为ArkWeb实现以获得更好的可视化效果。此外，报告内容应由AI基于完整上下文（所有题目+用户答案+追问记录）生成，而非简单统计。

## What Changes

- **"查看报告"按钮改为全局可用**：每道已答题目下方均显示"查看评测报告"按钮（初始置灰禁用），当课程所有题目回答完毕后启用
- **题目导航改为上一题/下一题**：去掉仅最后一题显示"查看结果"的逻辑，改为所有题目显示上一题/下一题导航按钮
- **AI生成评测报告**：调用AI基于课程所有题目内容+用户答案+所有追问内容生成报告，包含整体复习建议和错题溯源
- **错题溯源到知识节点**：AI生成报告时将错题关联到知识图谱中的节点，用户可从报告跳转到对应知识节点
- **雷达图改为3维**：维度从6维Bloom改为3维（概念理解/批判思维/实践迁移），由AI根据答题表现评定各维度分数
- **雷达图改为ArkWeb实现**：使用ArkWeb+vis-network或ECharts替代当前Canvas RadarChart组件
- **报告数据持久化**：评测报告内容（AI生成的文本+3维分数+复习建议+错题溯源）存储到RDB

## Capabilities

### New Capabilities
- `assessment-report`: 评测报告生成、展示、持久化（AI生成复习建议+错题溯源+3维雷达图）

### Modified Capabilities
- `assessment-system`: "查看报告"按钮逻辑变更（全局可用+所有题目答完启用），题目导航改为上一题/下一题
- `assessment-question-types`: 答题页面导航按钮变更（去掉最后一题"查看结果"，改为上一题/下一题）

## Impact

- **AssessmentCenterPage.ets**：答题页面导航逻辑重构，添加"查看报告"按钮
- **RDBService.ets**：新增 assessment_reports 表（report_id, course_id, content, dimensions_json, suggestions_json, error_traces_json, created_at）
- **AssessmentManager.ets**：新增生成评测报告方法（调用AI+解析+存储）
- **PromptTemplates.ets**：新增评测报告生成prompt（含3维评分+复习建议+错题溯源）
- **RadarChart.ets**：替换为ArkWeb实现，3维雷达图
- **新增 AssessmentReportPage.ets**：评测报告展示页面