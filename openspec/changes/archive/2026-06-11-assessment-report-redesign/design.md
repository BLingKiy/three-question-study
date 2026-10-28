## Context

当前测评中心（AssessmentCenterPage）答题流程：用户点击题目进入答题→提交答案→显示结果→最后一题显示"查看结果"按钮。问题：(1) 用户可乱序答题，但"查看结果"仅在最后一题出现，逻辑不合理；(2) 测评报告仅包含简单统计（分数/正确率），缺少AI生成的复习建议和错题溯源；(3) 雷达图为6维Bloom+Canvas实现，需改为3维+ArkWeb。

已有基础设施：DeepseekService.chatCompletion()、RDBService、PromptTemplates、AssessmentManager、ArkWeb组件（KnowledgeGraphWeb）、javaScriptProxy通信模式。

## Goals / Non-Goals

**Goals:**
- 每道已答题目下方显示"查看评测报告"按钮，课程所有题目答完后启用
- 题目导航改为上一题/下一题，去掉最后一题"查看结果"
- AI生成评测报告（复习建议+错题溯源+3维评分），内容持久化到RDB
- 雷达图改为3维（概念理解/批判思维/实践迁移）+ArkWeb+ECharts实现
- 错题溯源关联知识图谱节点，支持从报告跳转到知识节点详情

**Non-Goals:**
- 不实现报告导出（PDF/JSON/Markdown），留待数据导出功能变更
- 不实现历史报告对比（多次测评对比）
- 不修改测评题目生成逻辑（Q3）

## Decisions

### 1. "查看报告"按钮位置与启用逻辑
**决策**：在答题页面底部（提交答案后）和课程题目列表中均显示"查看评测报告"按钮。按钮初始disabled（置灰），当该课程所有题目均已回答（userAnswer非空）时enabled。
**理由**：用户从任意入口都能查看报告，符合乱序答题场景。

### 2. 评测报告生成方式
**决策**：用户首次点击"查看评测报告"时，若DB中无已有报告则调用AI生成，生成后持久化到assessment_reports表。后续点击直接读取DB。
**理由**：避免重复调用AI，报告内容固定（基于当前答题数据），生成一次即可。

### 3. AI报告Prompt设计
**决策**：Prompt包含：课程所有题目（questionText+questionType+correctAnswer+options）、用户答案、每题判定结果（isCorrect）、所有追问记录（assessment_follow_ups）、知识图谱节点列表（id+label+content）。要求AI输出JSON：`{ dimensions: { conceptUnderstanding: 0-100, criticalThinking: 0-100, practicalTransfer: 0-100 }, overallSuggestion: string, errorTraces: [{ questionId, knowledgeNodeId, knowledgeNodeLabel, traceExplanation }], dimensionAnalysis: { conceptUnderstanding: string, criticalThinking: string, practicalTransfer: string } }`
**理由**：3维分数由AI评定而非简单统计，更符合认知能力评估本质。错题溯源需要AI理解题目与知识节点的语义关联。

### 4. 雷达图实现方案
**决策**：使用ArkWeb+ECharts实现3维雷达图，复用KnowledgeGraphWeb的ArkWeb通信模式（javaScriptProxy）。
**替代方案**：继续用Canvas自绘——但3维雷达图ECharts效果更好，且已有ArkWeb基础设施。
**理由**：ECharts雷达图配置灵活、动画流畅，ArkWeb通信模式已验证可行。

### 5. 报告数据模型
**决策**：新增assessment_reports表，字段：id(TEXT PK), course_id(TEXT FK), dimensions_json(TEXT), overall_suggestion(TEXT), error_traces_json(TEXT), dimension_analysis_json(TEXT), created_at(INTEGER)。一个课程一份报告（1:1关系）。
**理由**：报告是课程级别的聚合数据，1:1关系最简单。JSON字段存储结构化内容避免过多子表。

### 6. 错题溯源跳转
**决策**：报告中的错题溯源条目显示知识节点标签，点击跳转到LearningSpacePage并高亮对应节点（通过路由参数传递nodeId）。
**理由**：复用现有知识图谱交互，无需新建页面。

## Risks / Trade-offs

- **AI生成报告耗时较长** → 显示loading动画，3秒轮询检查报告是否生成完成
- **AI可能返回不符合JSON格式的报告** → ResponseParser增加报告解析兜底，解析失败显示"报告生成失败，请重试"
- **错题溯源的knowledgeNodeId可能不存在** → AI生成时提供节点列表供选择，解析时验证id有效性，无效id跳过该溯源条目
- **ArkWeb+ECharts增加包体积** → ECharts核心约300KB，可接受；radar_chart.html放rawfile
- **报告与题目不同步** → 用户重新生成测评时（循环图标），删除旧报告，下次查看时重新生成