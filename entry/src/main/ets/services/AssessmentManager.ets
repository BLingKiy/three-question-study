import { RDBService } from './RDBService';
import { Assessment, AssessmentResult, BloomLevel, FollowUp, AssessmentReport, DimensionScores, DimensionAnalysis, ErrorTrace } from '../model/Assessment';
import { DeepseekService } from './DeepseekService';
import { PreferencesService } from './PreferencesService';
import { PromptTemplates } from './PromptTemplates';
import { ResponseParser } from './ResponseParser';
import { generateUUID } from '../utils/UUIDUtil';

export interface SubjectiveEvaluation {
  isCorrect: boolean;
  score: number;
  analysis: string;
  suggestion: string;
}

class SubjectiveEvaluationImpl implements SubjectiveEvaluation {
  isCorrect: boolean = false;
  score: number = 0;
  analysis: string = '';
  suggestion: string = '';
}

export class AssessmentManager {
  private rdbService: RDBService;

  constructor(rdbService: RDBService) {
    this.rdbService = rdbService;
  }

  async getAssessments(courseId: string): Promise<Assessment[]> {
    return await this.rdbService.queryAssessments(courseId);
  }

  async submitAnswer(assessmentId: string, userAnswer: string): Promise<boolean> {
    // Get assessment
    const allAssessments = await this.rdbService.queryAssessments('');
    const assessment = allAssessments.find(a => a.id === assessmentId);
    
    if (!assessment) {
      throw new Error('测评题目不存在');
    }

    // Simple exact match for now
    // In real implementation, we would use more sophisticated comparison
    const isCorrect = this.evaluateAnswer(assessment.answer || '', userAnswer);
    
    // Update assessment with user answer
    assessment.userAnswer = userAnswer;
    assessment.isCorrect = isCorrect;
    
    await this.rdbService.updateAssessment(assessment);
    
    return isCorrect;
  }

  private evaluateAnswer(correctAnswer: string, userAnswer: string): boolean {
    // Simple similarity check
    const normalized1 = correctAnswer.toLowerCase().trim();
    const normalized2 = userAnswer.toLowerCase().trim();
    
    // Exact match
    if (normalized1 === normalized2) return true;
    
    // Contains key terms
    const terms1 = normalized1.split(/\s+/);
    const terms2 = normalized2.split(/\s+/);
    
    let matchCount = 0;
    for (const term of terms1) {
      if (term.length > 2 && terms2.includes(term)) {
        matchCount++;
      }
    }
    
    const similarity = matchCount / Math.max(terms1.length, 1);
    return similarity > 0.7;
  }

  async calculateResult(courseId: string): Promise<AssessmentResult> {
    const assessments = await this.getAssessments(courseId);
    const answered = assessments.filter(a => a.userAnswer !== undefined);
    
    if (answered.length === 0) {
      return {
        totalScore: 0,
        levelScores: new Map(),
        weakAreas: []
      };
    }

    const levelScores = new Map<BloomLevel, number>();
    const levelCounts = new Map<BloomLevel, number>();
    const levelCorrects = new Map<BloomLevel, number>();

    const levels: BloomLevel[] = ['remember', 'understand', 'apply', 'analyze', 'evaluate', 'create'];

    // Initialize
    for (const level of levels) {
      levelScores.set(level, 0);
      levelCounts.set(level, 0);
      levelCorrects.set(level, 0);
    }

    // Calculate scores per level
    for (const a of answered) {
      const count = levelCounts.get(a.bloomLevel) || 0;
      const correct = levelCorrects.get(a.bloomLevel) || 0;
      
      levelCounts.set(a.bloomLevel, count + 1);
      if (a.isCorrect) {
        levelCorrects.set(a.bloomLevel, correct + 1);
      }
    }

    // Calculate percentage scores
    for (const level of levels) {
      const count = levelCounts.get(level) || 0;
      const correct = levelCorrects.get(level) || 0;
      
      if (count > 0) {
        levelScores.set(level, (correct / count) * 100);
      }
    }

    // Calculate total score
    const totalCorrect = answered.filter(a => a.isCorrect).length;
    const totalScore = (totalCorrect / answered.length) * 100;

    // Identify weak areas (score < 60%)
    const weakAreas: BloomLevel[] = [];
    for (const level of levels) {
      const score = levelScores.get(level) || 0;
      const count = levelCounts.get(level) || 0;
      
      if (count > 0 && score < 60) {
        weakAreas.push(level);
      }
    }

    return {
      totalScore,
      levelScores,
      weakAreas
    };
  }

  async getAssessmentsByLevel(courseId: string, level: BloomLevel): Promise<Assessment[]> {
    const all = await this.getAssessments(courseId);
    return all.filter(a => a.bloomLevel === level);
  }

  async getUnansweredAssessments(courseId: string): Promise<Assessment[]> {
    const all = await this.getAssessments(courseId);
    return all.filter(a => !a.userAnswer);
  }

  async getCorrectAssessments(courseId: string): Promise<Assessment[]> {
    const all = await this.getAssessments(courseId);
    return all.filter(a => a.isCorrect === true);
  }

  async evaluateSubjectiveAnswer(context: Context, assessmentId: string, userAnswer: string): Promise<SubjectiveEvaluation> {
    const allAssessments = await this.rdbService.queryAssessments('');
    const assessment = allAssessments.find(a => a.id === assessmentId);

    if (!assessment) {
      throw new Error('测评题目不存在');
    }

    if (!userAnswer.trim()) {
      throw new Error('答案不能为空');
    }

    try {
      const preferencesService = new PreferencesService(context);
      await preferencesService.initialize();
      const deepseekService = new DeepseekService(preferencesService);

      const messages = PromptTemplates.getSubjectiveEvaluationPrompt(
        assessment.question,
        assessment.answer || '',
        userAnswer
      );

      const response = await deepseekService.chatCompletion(messages);
      const jsonStr = this.extractJSON(response);
      const data = JSON.parse(jsonStr) as Record<string, Object>;

      const result = new SubjectiveEvaluationImpl();
      result.isCorrect = Boolean(data['isCorrect']);
      result.score = Number(data['score']) || 0;
      result.analysis = String(data['analysis'] || '');
      result.suggestion = String(data['suggestion'] || '');

      assessment.userAnswer = userAnswer;
      assessment.isCorrect = result.isCorrect;
      await this.rdbService.updateAssessment(assessment);

      return result;
    } catch (err) {
      const isCorrect = this.evaluateAnswer(assessment.answer || '', userAnswer);
      assessment.userAnswer = userAnswer;
      assessment.isCorrect = isCorrect;
      await this.rdbService.updateAssessment(assessment);

      const fallback = new SubjectiveEvaluationImpl();
      fallback.isCorrect = isCorrect;
      fallback.score = isCorrect ? 80 : 40;
      fallback.analysis = isCorrect ? '答案关键词匹配通过。' : '答案关键词匹配未通过，请参考正确答案。';
      fallback.suggestion = assessment.answer || '';
      return fallback;
    }
  }

  private extractJSON(response: string): string {
    const jsonMatch = response.match(/```(?:json)?\s*([\s\S]*?)```/);
    if (jsonMatch && jsonMatch[1]) {
      return jsonMatch[1].trim();
    }
    const objectMatch = response.match(/\{[\s\S]*\}/);
    if (objectMatch) {
      return objectMatch[0];
    }
    return response;
  }

  async saveFollowUp(assessmentId: string, role: 'user' | 'assistant', content: string): Promise<FollowUp> {
    const followUp = new FollowUpImpl();
    followUp.id = generateUUID();
    followUp.assessmentId = assessmentId;
    followUp.role = role;
    followUp.content = content;
    followUp.createdAt = Date.now();
    await this.rdbService.insertFollowUp(followUp);
    return followUp;
  }

  async getFollowUps(assessmentId: string): Promise<FollowUp[]> {
    return await this.rdbService.queryFollowUpsByAssessmentId(assessmentId);
  }

  async generateFollowUpReply(
    context: Context,
    assessmentId: string,
    question: string,
    userAnswer: string,
    evaluationContext: string,
    followUpHistory: FollowUp[],
    userFollowUpQuestion: string
  ): Promise<FollowUp> {
    await this.saveFollowUp(assessmentId, 'user', userFollowUpQuestion);

    let historyStr = '';
    for (const f of followUpHistory) {
      const prefix = f.role === 'user' ? '用户' : '导师';
      historyStr += `${prefix}：${f.content}\n`;
    }

    const preferencesService = new PreferencesService(context);
    await preferencesService.initialize();
    const deepseekService = new DeepseekService(preferencesService);

    const messages = PromptTemplates.getFollowUpPrompt(
      question, userAnswer, evaluationContext, historyStr, userFollowUpQuestion
    );

    const response = await deepseekService.chatCompletion(messages);
    const aiFollowUp = await this.saveFollowUp(assessmentId, 'assistant', response);
    return aiFollowUp;
  }

  async getAssessmentReport(courseId: string): Promise<AssessmentReport | null> {
    return await this.rdbService.getAssessmentReportByCourseId(courseId);
  }

  async generateAssessmentReport(context: Context, courseId: string): Promise<AssessmentReport> {
    const assessments = await this.rdbService.queryAssessments(courseId);
    const knowledgeNodes = await this.rdbService.queryKnowledgeNodes(courseId);

    let assessmentsContext = '';
    for (const a of assessments) {
      assessmentsContext += `题目ID: ${a.id}\n`;
      assessmentsContext += `题目: ${a.question}\n`;
      assessmentsContext += `题型: ${a.questionType}\n`;
      assessmentsContext += `布鲁姆层次: ${a.bloomLevel}\n`;
      if (a.options && a.options.length > 0) {
        assessmentsContext += `选项: ${a.options}\n`;
      }
      if (a.correctAnswer && a.correctAnswer.length > 0) {
        assessmentsContext += `正确答案: ${a.correctAnswer}\n`;
      }
      if (a.answer && a.answer.length > 0) {
        assessmentsContext += `参考答案: ${a.answer}\n`;
      }
      assessmentsContext += `用户答案: ${a.userAnswer || '未作答'}\n`;
      assessmentsContext += `是否正确: ${a.isCorrect ? '是' : '否'}\n`;

      const followUps = await this.rdbService.queryFollowUpsByAssessmentId(a.id);
      if (followUps.length > 0) {
        assessmentsContext += '追问记录:\n';
        for (const f of followUps) {
          const roleLabel = f.role === 'user' ? '用户' : 'AI';
          assessmentsContext += `  ${roleLabel}: ${f.content}\n`;
        }
      }
      assessmentsContext += '\n';
    }

    let knowledgeNodesContext = '';
    for (const n of knowledgeNodes) {
      knowledgeNodesContext += `节点ID: ${n.id}, 标签: ${n.label}, 类型: ${n.type}\n`;
    }

    const preferencesService = new PreferencesService(context);
    await preferencesService.initialize();
    const deepseekService = new DeepseekService(preferencesService);

    const messages = PromptTemplates.getAssessmentReportPrompt(assessmentsContext, knowledgeNodesContext);
    const response = await deepseekService.chatCompletion(messages);

    const validNodeIds: string[] = [];
    for (const n of knowledgeNodes) {
      validNodeIds.push(n.id);
    }
    const report = ResponseParser.parseAssessmentReport(response, courseId, validNodeIds);
    await this.rdbService.saveAssessmentReport(report);
    return report;
  }

  async deleteAssessmentReport(courseId: string): Promise<void> {
    await this.rdbService.deleteAssessmentReportByCourseId(courseId);
  }
}

class FollowUpImpl implements FollowUp {
  id: string = '';
  assessmentId: string = '';
  role: 'user' | 'assistant' = 'user';
  content: string = '';
  createdAt: number = 0;
}
