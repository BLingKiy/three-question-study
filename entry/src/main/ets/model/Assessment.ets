export type BloomLevel = 'remember' | 'understand' | 'apply' | 'analyze' | 'evaluate' | 'create';

export type QuestionType = 'subjective' | 'singleChoice' | 'multipleChoice' | 'trueFalse';

export interface Assessment {
  id: string;
  courseId: string;
  bloomLevel: BloomLevel;
  questionType: QuestionType;
  question: string;
  answer?: string;
  options?: string;
  correctAnswer?: string;
  userAnswer?: string;
  isCorrect?: boolean;
  createdAt: number;
}

export interface AssessmentResult {
  totalScore: number;
  levelScores: Map<BloomLevel, number>;
  weakAreas: BloomLevel[];
}

export interface FollowUp {
  id: string;
  assessmentId: string;
  role: 'user' | 'assistant';
  content: string;
  createdAt: number;
}

export interface DimensionScores {
  conceptUnderstanding: number;
  criticalThinking: number;
  practicalTransfer: number;
}

export interface DimensionAnalysis {
  conceptUnderstanding: string;
  criticalThinking: string;
  practicalTransfer: string;
}

export interface ErrorTrace {
  questionId: string;
  knowledgeNodeId: string;
  knowledgeNodeLabel: string;
  traceExplanation: string;
}

export interface AssessmentReport {
  id: string;
  courseId: string;
  dimensions: DimensionScores;
  overallSuggestion: string;
  errorTraces: ErrorTrace[];
  dimensionAnalysis: DimensionAnalysis;
  createdAt: number;
}

export interface ArchiveAssessment {
  id: string;
  originalCourseId: string;
  originalCourseName: string;
  bloomLevel: BloomLevel;
  questionType: QuestionType;
  question: string;
  answer: string;
  options: string;
  correctAnswer: string;
  userAnswer: string;
  isCorrect: boolean;
  createdAt: number;
  archivedAt: number;
}

export interface ArchiveFollowUp {
  id: string;
  archiveAssessmentId: string;
  role: 'user' | 'assistant';
  content: string;
  createdAt: number;
}
