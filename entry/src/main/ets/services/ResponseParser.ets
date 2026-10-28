import { KnowledgeNode, NodePosition } from '../model/KnowledgeNode';
import { KnowledgeEdge, EdgeType } from '../model/KnowledgeEdge';
import { Assessment, BloomLevel, QuestionType, AssessmentReport, DimensionScores, DimensionAnalysis, ErrorTrace } from '../model/Assessment';
import { generateUUID } from '../utils/UUIDUtil';

export interface ParsedKnowledgeGraph {
  nodes: KnowledgeNode[];
  edges: KnowledgeEdge[];
}

export interface ControversyView {
  title: string;
  arguments: string[];
  evidence: string[];
}

export interface ParsedControversy {
  id: string;
  topic: string;
  leftView: ControversyView;
  rightView: ControversyView;
  synthesis: string;
}

export interface ParsedAssessment {
  id: string;
  bloomLevel: BloomLevel;
  questionType: QuestionType;
  question: string;
  answer: string;
  options: string;
  correctAnswer: string;
  criteria: string;
}

class NodePositionImpl implements NodePosition {
  x: number = 0;
  y: number = 0;
}

class KnowledgeNodeImpl implements KnowledgeNode {
  id: string = '';
  courseId: string = '';
  type: 'concept' | 'controversy' | 'evidence' = 'concept';
  label: string = '';
  content: string = '';
  position: NodePosition = new NodePositionImpl();
}

class KnowledgeEdgeImpl implements KnowledgeEdge {
  id: string = '';
  courseId: string = '';
  fromNodeId: string = '';
  toNodeId: string = '';
  type: EdgeType = 'relates';
  weight: number = 1.0;
}

class ControversyViewImpl implements ControversyView {
  title: string = '';
  arguments: string[] = [];
  evidence: string[] = [];
}

class ParsedControversyImpl implements ParsedControversy {
  id: string = '';
  topic: string = '';
  leftView: ControversyView = new ControversyViewImpl();
  rightView: ControversyView = new ControversyViewImpl();
  synthesis: string = '';
}

class ParsedAssessmentImpl implements ParsedAssessment {
  id: string = '';
  bloomLevel: BloomLevel = 'understand';
  questionType: QuestionType = 'subjective';
  question: string = '';
  answer: string = '';
  options: string = '';
  correctAnswer: string = '';
  criteria: string = '';
}

export class ResponseParser {
  private static extractJSON(response: string): string {
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

  static parseKnowledgeGraph(response: string, courseId: string): ParsedKnowledgeGraph {
    try {
      const jsonStr = ResponseParser.extractJSON(response);
      const data = JSON.parse(jsonStr) as Record<string, Object>;
      
      const nodes: KnowledgeNode[] = [];
      const edges: KnowledgeEdge[] = [];
      
      const dataNodes = data['nodes'];
      if (dataNodes && Array.isArray(dataNodes)) {
        for (let index = 0; index < dataNodes.length; index++) {
          const node = dataNodes[index] as Record<string, string>;
          const kn = new KnowledgeNodeImpl();
          kn.id = node['id'] || `node_${index}`;
          kn.courseId = courseId;
          kn.type = (node['type'] || 'concept') as 'concept' | 'controversy' | 'evidence';
          kn.label = node['label'] || '未命名';
          kn.content = node['content'] || '';
          const pos = new NodePositionImpl();
          pos.x = 0;
          pos.y = 0;
          kn.position = pos;
          nodes.push(kn);
        }
      }
      
      const dataEdges = data['edges'];
      if (dataEdges && Array.isArray(dataEdges)) {
        for (let index = 0; index < dataEdges.length; index++) {
          const edge = dataEdges[index] as Record<string, string>;
          const ke = new KnowledgeEdgeImpl();
          ke.id = `edge_${index}`;
          ke.courseId = courseId;
          ke.fromNodeId = edge['from'] || '';
          ke.toNodeId = edge['to'] || '';
          ke.type = (edge['type'] || 'relates') as EdgeType;
          ke.weight = Number(edge['weight']) || 1.0;
          edges.push(ke);
        }
      }
      
      const result = new ParsedKnowledgeGraphImpl();
      result.nodes = nodes;
      result.edges = edges;
      return result;
    } catch (err) {
      console.error('[ResponseParser] Failed to parse knowledge graph:', err);
      throw new Error('知识图谱解析失败，请重试');
    }
  }

  static parseControversies(response: string): ParsedControversy[] {
    try {
      const jsonStr = ResponseParser.extractJSON(response);
      const data = JSON.parse(jsonStr) as Record<string, Object>;
      
      const controversies: ParsedControversy[] = [];
      
      const dataControversies = data['controversies'];
      if (dataControversies && Array.isArray(dataControversies)) {
        for (let i = 0; i < dataControversies.length; i++) {
          const item = dataControversies[i] as Record<string, Object>;
          const pc = ResponseParser.parseSingleControversy(item);
          controversies.push(pc);
        }
      } else if (data['topic'] || data['leftView'] || data['rightView']) {
        const pc = ResponseParser.parseSingleControversy(data);
        controversies.push(pc);
      }
      
      return controversies;
    } catch (err) {
      console.error('[ResponseParser] Failed to parse controversies:', err);
      throw new Error('争议分析解析失败，请重试');
    }
  }

  private static parseSingleControversy(item: Record<string, Object>): ParsedControversy {
    const leftViewData = (item['leftView'] || {}) as Record<string, Object>;
    const rightViewData = (item['rightView'] || {}) as Record<string, Object>;
    
    const pc = new ParsedControversyImpl();
    pc.id = String(item['id'] || `controversy_${Date.now()}`);
    pc.topic = String(item['topic'] || '未命名争议');
    
    const lv = new ControversyViewImpl();
    lv.title = String(leftViewData['title'] || '观点A');
    lv.arguments = (leftViewData['arguments'] as string[]) || [];
    lv.evidence = (leftViewData['evidence'] as string[]) || [];
    pc.leftView = lv;
    
    const rv = new ControversyViewImpl();
    rv.title = String(rightViewData['title'] || '观点B');
    rv.arguments = (rightViewData['arguments'] as string[]) || [];
    rv.evidence = (rightViewData['evidence'] as string[]) || [];
    pc.rightView = rv;
    
    pc.synthesis = String(item['synthesis'] || '');
    return pc;
  }

  static parseAssessments(response: string, courseId: string): ParsedAssessment[] {
    try {
      const jsonStr = ResponseParser.extractJSON(response);
      const data = JSON.parse(jsonStr) as Record<string, Object>;
      
      const assessments: ParsedAssessment[] = [];
      
      const dataAssessments = data['assessments'];
      if (dataAssessments && Array.isArray(dataAssessments)) {
        for (let i = 0; i < dataAssessments.length; i++) {
          const item = dataAssessments[i] as Record<string, Object>;
          const pa = new ParsedAssessmentImpl();
          pa.id = String(item['id'] || `assessment_${Date.now()}`);
          pa.bloomLevel = ResponseParser.validateBloomLevel(String(item['bloomLevel'] || ''));
          pa.questionType = ResponseParser.validateQuestionType(String(item['questionType'] || ''));
          pa.question = String(item['question'] || '');
          pa.answer = String(item['answer'] || '');
          pa.criteria = String(item['criteria'] || '');
          const optionsData = item['options'];
          if (optionsData && Array.isArray(optionsData)) {
            pa.options = JSON.stringify(optionsData);
          } else {
            pa.options = '';
          }
          pa.correctAnswer = String(item['correctAnswer'] || '');
          if (pa.questionType === 'multipleChoice') {
            const answers = pa.correctAnswer.split(',').filter(s => s.length > 0);
            if (answers.length < 2) {
              pa.questionType = 'singleChoice';
            }
          }
          assessments.push(pa);
        }
      }
      
      return assessments;
    } catch (err) {
      console.error('[ResponseParser] Failed to parse assessments:', err);
      throw new Error('测评题目解析失败，请重试');
    }
  }

  private static validateQuestionType(type: string): QuestionType {
    const validTypes: QuestionType[] = ['subjective', 'singleChoice', 'multipleChoice', 'trueFalse'];
    if (validTypes.includes(type as QuestionType)) {
      return type as QuestionType;
    }
    return 'subjective';
  }

  private static validateBloomLevel(level: string): BloomLevel {
    const validLevels: BloomLevel[] = ['remember', 'understand', 'apply', 'analyze', 'evaluate', 'create'];
    const normalized = level.toLowerCase() || 'understand';
    
    if (validLevels.includes(normalized as BloomLevel)) {
      return normalized as BloomLevel;
    }
    
    return 'understand';
  }

  static parseAssessmentReport(response: string, courseId: string, validNodeIds: string[]): AssessmentReport {
    try {
      const jsonStr = ResponseParser.extractJSON(response);
      const data = JSON.parse(jsonStr) as Record<string, Object>;

      const dimensionsData = (data['dimensions'] || {}) as Record<string, number>;
      const dimensions: DimensionScores = {
        conceptUnderstanding: Math.min(100, Math.max(0, Math.round(Number(dimensionsData['conceptUnderstanding']) || 0))),
        criticalThinking: Math.min(100, Math.max(0, Math.round(Number(dimensionsData['criticalThinking']) || 0))),
        practicalTransfer: Math.min(100, Math.max(0, Math.round(Number(dimensionsData['practicalTransfer']) || 0)))
      };

      const analysisData = (data['dimensionAnalysis'] || {}) as Record<string, string>;
      const dimensionAnalysis: DimensionAnalysis = {
        conceptUnderstanding: String(analysisData['conceptUnderstanding'] || ''),
        criticalThinking: String(analysisData['criticalThinking'] || ''),
        practicalTransfer: String(analysisData['practicalTransfer'] || '')
      };

      const overallSuggestion = String(data['overallSuggestion'] || '');

      const errorTracesData = data['errorTraces'];
      const errorTraces: ErrorTrace[] = [];
      if (errorTracesData && Array.isArray(errorTracesData)) {
        for (let i = 0; i < errorTracesData.length; i++) {
          const trace = errorTracesData[i] as Record<string, string>;
          const nodeId = String(trace['knowledgeNodeId'] || '');
          if (nodeId && validNodeIds.includes(nodeId)) {
            const et = new ErrorTraceImpl();
            et.questionId = String(trace['questionId'] || '');
            et.knowledgeNodeId = nodeId;
            et.knowledgeNodeLabel = String(trace['knowledgeNodeLabel'] || '');
            et.traceExplanation = String(trace['traceExplanation'] || '');
            errorTraces.push(et);
          }
        }
      }

      const report = new AssessmentReportImpl();
      report.id = generateUUID();
      report.courseId = courseId;
      report.dimensions = dimensions;
      report.overallSuggestion = overallSuggestion;
      report.errorTraces = errorTraces;
      report.dimensionAnalysis = dimensionAnalysis;
      report.createdAt = Date.now();
      return report;
    } catch (err) {
      console.error('[ResponseParser] Failed to parse assessment report:', err);
      throw new Error('评测报告解析失败，请重试');
    }
  }
}

class ParsedKnowledgeGraphImpl implements ParsedKnowledgeGraph {
  nodes: KnowledgeNode[] = [];
  edges: KnowledgeEdge[] = [];
}

class ErrorTraceImpl implements ErrorTrace {
  questionId: string = '';
  knowledgeNodeId: string = '';
  knowledgeNodeLabel: string = '';
  traceExplanation: string = '';
}

class AssessmentReportImpl implements AssessmentReport {
  id: string = '';
  courseId: string = '';
  dimensions: DimensionScores = { conceptUnderstanding: 0, criticalThinking: 0, practicalTransfer: 0 };
  overallSuggestion: string = '';
  errorTraces: ErrorTrace[] = [];
  dimensionAnalysis: DimensionAnalysis = { conceptUnderstanding: '', criticalThinking: '', practicalTransfer: '' };
  createdAt: number = 0;
}
