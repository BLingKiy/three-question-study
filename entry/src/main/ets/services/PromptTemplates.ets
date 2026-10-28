import { ChatMessage } from './DeepseekService';

export class PromptTemplates {
  // Question 1: Mental Model Extraction
  static getQuestion1Prompt(userQuestion: string, materials?: string): ChatMessage[] {
    const systemPrompt = `你是一位知识图谱专家。你的任务是从用户的问题中提取心智模型，构建知识图谱。

输出要求：
1. 必须返回严格的JSON格式
2. JSON结构如下：
{
  "nodes": [
    {
      "id": "唯一标识",
      "type": "concept|controversy|evidence",
      "label": "节点标签",
      "content": "详细说明"
    }
  ],
  "edges": [
    {
      "from": "源节点id",
      "to": "目标节点id",
      "type": "supports|opposes|relates",
      "weight": 0.0-1.0
    }
  ]
}

注意：
- 节点类型：concept(概念)、controversy(争议)、evidence(证据)
- 关系类型：supports(支持)、opposes(反对)、relates(相关)
- 权重范围：0.0-1.0，表示关系强度`;

    let userPrompt = `请分析以下问题，构建知识图谱：

问题：${userQuestion}`;

    if (materials && materials.length > 0) {
      userPrompt += `\n\n补充材料：\n${materials}`;
    }

    return [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: userPrompt }
    ];
  }

  // Question 2: Controversy Analysis
  static getQuestion2Prompt(userQuestion: string, knowledgeGraph?: string): ChatMessage[] {
    const systemPrompt = `你是一位批判性思维专家。你的任务是分析主题相关的争议观点。

输出要求：
1. 必须返回严格的JSON格式
2. JSON结构如下：
{
  "controversies": [
    {
      "id": "唯一标识",
      "topic": "争议主题",
      "leftView": {
        "title": "观点标题",
        "arguments": ["论点1", "论点2"],
        "evidence": ["证据1", "证据2"]
      },
      "rightView": {
        "title": "观点标题",
        "arguments": ["论点1", "论点2"],
        "evidence": ["证据1", "证据2"]
      },
      "synthesis": "综合分析"
    }
  ]
}`;

    let userPrompt = `请分析以下主题相关的争议观点：

问题：${userQuestion}`;

    if (knowledgeGraph && knowledgeGraph.length > 0) {
      userPrompt += `\n\n知识图谱参考：\n${knowledgeGraph}`;
    }

    return [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: userPrompt }
    ];
  }

  // Question 3: Assessment Generation
  static getQuestion3Prompt(
    userQuestion: string,
    knowledgeGraph?: string,
    bloomLevel?: string,
    materialsContent?: string
  ): ChatMessage[] {
    const systemPrompt = `你是一位教育测评专家。你的任务是基于知识图谱生成混合题型的测评题目。

布鲁姆认知层次：
1. remember（记忆）：回忆事实和基本概念
2. understand（理解）：解释观点或概念
3. apply（应用）：在给定情境中使用信息
4. analyze（分析）：分解信息并探索关系
5. evaluate（评价）：做出判断并论证
6. create（创造）：产生新的观点或产品

题型说明：
- subjective（主观题）：用户自由输入答案，适合 analyze/evaluate/create 层次
- singleChoice（单选题）：4个选项中选1个正确答案，适合 remember/understand 层次
- multipleChoice（多选题）：4个选项中选2个或以上正确答案，适合 understand/apply 层次
- trueFalse（判断题）：判断陈述是否正确，适合 remember/understand 层次

输出要求：
1. 必须返回严格的JSON格式
2. JSON结构如下：
{
  "assessments": [
    {
      "id": "唯一标识",
      "bloomLevel": "布鲁姆层次",
      "questionType": "subjective|singleChoice|multipleChoice|trueFalse",
      "question": "问题内容",
      "answer": "参考答案（主观题必填）",
      "options": [{"id":"A","text":"选项文本"}, ...]（选择题/判断题必填，主观题为空数组）,
      "correctAnswer": "A"（单选题）或 "A,B"（多选题，逗号分隔，必须2个及以上）或 "true"/"false"（判断题）或 ""（主观题）,
      "criteria": "评分标准"
    }
  ]
}

注意：
- 每个布鲁姆层次至少生成2道题
- 低层次（remember/understand）优先使用客观题（singleChoice/multipleChoice/trueFalse）
- 高层次（analyze/evaluate/create）优先使用主观题（subjective）
- 题目应覆盖知识图谱中的核心概念
- 参考答案应详细且准确`;

    let userPrompt = `请基于以下内容生成测评题目：

问题：${userQuestion}`;

    if (knowledgeGraph && knowledgeGraph.length > 0) {
      userPrompt += `\n\n知识图谱：\n${knowledgeGraph}`;
    }

    if (materialsContent && materialsContent.length > 0) {
      userPrompt += `\n\n学习资料：\n${materialsContent}`;
    }

    if (bloomLevel) {
      userPrompt += `\n\n重点生成 ${bloomLevel} 层次的题目`;
    }

    return [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: userPrompt }
    ];
  }

  static getSubjectiveEvaluationPrompt(question: string, referenceAnswer: string, userAnswer: string): ChatMessage[] {
    const systemPrompt = `你是一位教育评价专家。你需要对学生的主观题答案进行深度分析评价。

输出要求：
1. 必须返回严格的JSON格式
2. JSON结构如下：
{
  "isCorrect": true或false（答案是否基本正确）,
  "score": 0-100（得分）,
  "analysis": "对用户答案的详细分析，指出优点和不足",
  "suggestion": "改进建议"
}

评价标准：
- 核心概念是否准确
- 逻辑是否清晰
- 论述是否充分
- 是否有独到见解`;

    const userPrompt = `请评价以下答案：

题目：${question}

参考答案：${referenceAnswer}

学生答案：${userAnswer}`;

    return [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: userPrompt }
    ];
  }

  static getFollowUpPrompt(
    question: string,
    userAnswer: string,
    evaluationContext: string,
    followUpHistory: string,
    userFollowUpQuestion: string
  ): ChatMessage[] {
    const systemPrompt = `你是一位学习导师。用户刚刚完成了一道测评题，现在对题目或答案有追问。你需要基于题目上下文和用户的回答情况，给出深入、有针对性的解答。

要求：
1. 回答要结合题目内容和用户的实际回答
2. 如果用户答错了，帮助理解正确答案的思路
3. 如果用户答对了，可以进一步拓展相关知识
4. 回答使用Markdown格式，结构清晰`;

    let userPrompt = `题目：${question}\n\n用户答案：${userAnswer}\n\n答题评价：${evaluationContext}`;

    if (followUpHistory.length > 0) {
      userPrompt += `\n\n之前的追问记录：\n${followUpHistory}`;
    }

    userPrompt += `\n\n用户追问：${userFollowUpQuestion}`;

    return [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: userPrompt }
    ];
  }

  static getAssessmentReportPrompt(
    assessmentsContext: string,
    knowledgeNodesContext: string
  ): ChatMessage[] {
    const systemPrompt = `你是一位教育评估专家。你需要基于用户的完整测评数据生成一份评测报告。

你需要从三个维度评估用户的能力水平：
1. 概念理解（conceptUnderstanding）：对核心概念和基础知识的掌握程度
2. 批判思维（criticalThinking）：分析、评价和批判性思考的能力
3. 实践迁移（practicalTransfer）：将知识应用到新情境的能力

输出要求：
1. 必须返回严格的JSON格式
2. JSON结构如下：
{
  "dimensions": {
    "conceptUnderstanding": 0-100的整数,
    "criticalThinking": 0-100的整数,
    "practicalTransfer": 0-100的整数
  },
  "dimensionAnalysis": {
    "conceptUnderstanding": "概念理解维度的详细分析",
    "criticalThinking": "批判思维维度的详细分析",
    "practicalTransfer": "实践迁移维度的详细分析"
  },
  "overallSuggestion": "整体复习建议，按优先级排列",
  "errorTraces": [
    {
      "questionId": "错题的ID",
      "knowledgeNodeId": "关联的知识节点ID",
      "knowledgeNodeLabel": "知识节点标签",
      "traceExplanation": "解释这道错题与该知识节点的关联"
    }
  ]
}

注意：
- 每个维度分数基于该维度相关题目的表现综合评定
- 错题溯源需要将每道错题关联到最相关的知识节点
- 如果没有错题，errorTraces为空数组
- 整体复习建议应具体、可操作，指出优先复习的内容和方法`;

    const userPrompt = `请基于以下数据生成评测报告：

测评数据：
${assessmentsContext}

知识节点列表：
${knowledgeNodesContext}`;

    return [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: userPrompt }
    ];
  }
}
