import { DeepseekService } from './DeepseekService';
import { RDBService } from './RDBService';
import { PromptTemplates } from './PromptTemplates';
import { ResponseParser, ParsedControversy } from './ResponseParser';
import { KnowledgeNode, NodePosition } from '../model/KnowledgeNode';
import { KnowledgeEdge } from '../model/KnowledgeEdge';
import { Assessment, BloomLevel, QuestionType } from '../model/Assessment';
import { generateUUID } from '../utils/UUIDUtil';
import { DiscussionService } from './DiscussionService';

export interface ThreeQuestionState {
  question1Complete: boolean;
  question2Complete: boolean;
  question3Complete: boolean;
  currentQuestion: 1 | 2 | 3 | null;
  loading: boolean;
  error: string | null;
}

export class ThreeQuestionEngine {
  private deepseekService: DeepseekService;
  private rdbService: RDBService;
  private state: ThreeQuestionState;

  constructor(deepseekService: DeepseekService, rdbService: RDBService) {
    this.deepseekService = deepseekService;
    this.rdbService = rdbService;
    
    this.state = {
      question1Complete: false,
      question2Complete: false,
      question3Complete: false,
      currentQuestion: null,
      loading: false,
      error: null
    };
  }

  getState(): ThreeQuestionState {
    const copy = new ThreeQuestionStateImpl();
    copy.question1Complete = this.state.question1Complete;
    copy.question2Complete = this.state.question2Complete;
    copy.question3Complete = this.state.question3Complete;
    copy.currentQuestion = this.state.currentQuestion;
    copy.loading = this.state.loading;
    copy.error = this.state.error;
    return copy;
  }

  // Question 1: Mental Model Extraction
  async executeQuestion1(courseId: string, userQuestion: string, materials?: string): Promise<void> {
    this.state.loading = true;
    this.state.currentQuestion = 1;
    this.state.error = null;

    try {
      // Generate prompt
      const messages = PromptTemplates.getQuestion1Prompt(userQuestion, materials);
      
      // Call AI
      const response = await this.deepseekService.chatCompletion(messages, 0.7, 4000);
      
      // Parse response
      const graph = ResponseParser.parseKnowledgeGraph(response, courseId);
      
      // Apply force-directed layout
      this.applyForceDirectedLayout(graph.nodes, graph.edges);
      
      // Save to database
      await this.saveKnowledgeGraph(courseId, graph.nodes, graph.edges);
      
      this.state.question1Complete = true;
      console.info(`[ThreeQuestionEngine] Question 1 complete for course: ${courseId}`);
    } catch (err) {
      this.state.error = (err as Error).message;
      console.error('[ThreeQuestionEngine] Question 1 failed:', err);
      throw new Error((err as Error).message);
    } finally {
      this.state.loading = false;
      this.state.currentQuestion = null;
    }
  }

  // Question 2: Controversy Analysis
  async executeQuestion2(courseId: string, userQuestion: string): Promise<ParsedControversy[]> {
    this.state.loading = true;
    this.state.currentQuestion = 2;
    this.state.error = null;

    try {
      const nodes = await this.rdbService.queryKnowledgeNodes(courseId);
      const graphContext = JSON.stringify(nodes.map(n => {
        const item = new NodeSummaryImpl();
        item.id = n.id;
        item.label = n.label;
        item.type = n.type;
        return item;
      }));
      
      // Generate prompt
      const messages = PromptTemplates.getQuestion2Prompt(userQuestion, graphContext);
      
      // Call AI
      const response = await this.deepseekService.chatCompletion(messages, 0.8, 4000);
      
      // Parse response
      const controversies = ResponseParser.parseControversies(response);
      
      // Save controversies as knowledge nodes
      await this.saveControversies(courseId, controversies);

      const discussionService = new DiscussionService(this.rdbService);
      for (const c of controversies) {
        await discussionService.createDiscussion(c.id, courseId);
      }

      this.state.question2Complete = true;
      console.info(`[ThreeQuestionEngine] Question 2 complete for course: ${courseId}`);
      
      return controversies;
    } catch (err) {
      this.state.error = (err as Error).message;
      console.error('[ThreeQuestionEngine] Question 2 failed:', err);
      throw new Error((err as Error).message);
    } finally {
      this.state.loading = false;
      this.state.currentQuestion = null;
    }
  }

  // Question 3: Assessment Generation
  async executeQuestion3(courseId: string, userQuestion: string, bloomLevel?: string, materialsContent?: string): Promise<Assessment[]> {
    this.state.loading = true;
    this.state.currentQuestion = 3;
    this.state.error = null;

    try {
      // Get knowledge graph for context
      const nodes = await this.rdbService.queryKnowledgeNodes(courseId);
      const graphContext = JSON.stringify(nodes.map(n => {
        const item = new NodeSummaryImpl();
        item.id = n.id;
        item.label = n.label;
        item.content = n.content || '';
        return item;
      }));
      
      // Generate prompt
      const messages = PromptTemplates.getQuestion3Prompt(userQuestion, graphContext, bloomLevel, materialsContent);
      
      // Call AI
      const response = await this.deepseekService.chatCompletion(messages, 0.7, 4000);
      
      // Parse response
      const parsedAssessments = ResponseParser.parseAssessments(response, courseId);
      
      // Save to database
      const assessments: Assessment[] = [];
      for (const pa of parsedAssessments) {
        const assessment = new AssessmentImpl();
        assessment.id = generateUUID();
        assessment.courseId = courseId;
        assessment.bloomLevel = pa.bloomLevel;
        assessment.questionType = pa.questionType;
        assessment.question = pa.question;
        assessment.answer = pa.answer;
        assessment.options = pa.options;
        assessment.correctAnswer = pa.correctAnswer;
        assessment.createdAt = Date.now();
        await this.rdbService.insertAssessment(assessment);
        assessments.push(assessment);
      }
      
      this.state.question3Complete = true;
      console.info(`[ThreeQuestionEngine] Question 3 complete for course: ${courseId}`);
      
      return assessments;
    } catch (err) {
      this.state.error = (err as Error).message;
      console.error('[ThreeQuestionEngine] Question 3 failed:', err);
      throw new Error((err as Error).message);
    } finally {
      this.state.loading = false;
      this.state.currentQuestion = null;
    }
  }

  // Regenerate Question 1
  async regenerateQuestion1(courseId: string, userQuestion: string, materials?: string): Promise<void> {
    await this.deleteKnowledgeGraph(courseId);
    await this.executeQuestion1(courseId, userQuestion, materials);
  }

  // Regenerate Question 2
  async regenerateQuestion2(courseId: string, userQuestion: string): Promise<ParsedControversy[]> {
    await this.deleteControversies(courseId);
    return await this.executeQuestion2(courseId, userQuestion);
  }

  // Regenerate all (Q1 + Q2 together)
  async regenerateAll(courseId: string, userQuestion: string, materials?: string): Promise<void> {
    await this.rdbService.deleteKnowledgeEdgesByCourse(courseId);
    await this.rdbService.deleteKnowledgeNodesByCourse(courseId);
    await this.executeQuestion1(courseId, userQuestion, materials);
    await this.executeQuestion2(courseId, userQuestion);
  }

  private async saveKnowledgeGraph(courseId: string, nodes: KnowledgeNode[], edges: KnowledgeEdge[]): Promise<void> {
    for (const node of nodes) {
      await this.rdbService.insertKnowledgeNode(node);
    }
    for (const edge of edges) {
      await this.rdbService.insertKnowledgeEdge(edge);
    }
  }

  private async saveControversies(courseId: string, controversies: ParsedControversy[]): Promise<void> {
    for (const c of controversies) {
      const node = new KnowledgeNodeImpl();
      node.id = c.id;
      node.courseId = courseId;
      node.type = 'controversy';
      node.label = c.topic;
      node.content = JSON.stringify(c);
      const pos = new NodePositionImpl();
      pos.x = 0;
      pos.y = 0;
      node.position = pos;
      await this.rdbService.insertKnowledgeNode(node);
    }
  }

  private async deleteKnowledgeGraph(courseId: string): Promise<void> {
    await this.rdbService.deleteKnowledgeEdgesByCourse(courseId);
    await this.rdbService.deleteKnowledgeNodesByCourseExcludeType(courseId, 'controversy');
  }

  private async deleteControversies(courseId: string): Promise<void> {
    await this.rdbService.deleteKnowledgeNodesByType(courseId, 'controversy');
  }

  // Simple force-directed layout
  private applyForceDirectedLayout(nodes: KnowledgeNode[], edges: KnowledgeEdge[]): void {
    if (nodes.length === 0) return;

    const width = 800;
    const height = 600;
    const iterations = 100;

    // Initialize positions randomly
    nodes.forEach((node, i) => {
      node.position.x = (i % 10) * 80 + 40;
      node.position.y = Math.floor(i / 10) * 80 + 40;
    });

    // Simple force simulation
    for (let iter = 0; iter < iterations; iter++) {
      // Repulsion between all nodes
      for (let i = 0; i < nodes.length; i++) {
        for (let j = i + 1; j < nodes.length; j++) {
          const dx = nodes[j].position.x - nodes[i].position.x;
          const dy = nodes[j].position.y - nodes[i].position.y;
          const dist = Math.sqrt(dx * dx + dy * dy) || 1;
          const force = 1000 / (dist * dist);
          
          const fx = (dx / dist) * force;
          const fy = (dy / dist) * force;
          
          nodes[i].position.x -= fx;
          nodes[i].position.y -= fy;
          nodes[j].position.x += fx;
          nodes[j].position.y += fy;
        }
      }

      // Attraction along edges
      for (const edge of edges) {
        const source = nodes.find(n => n.id === edge.fromNodeId);
        const target = nodes.find(n => n.id === edge.toNodeId);
        
        if (source && target) {
          const dx = target.position.x - source.position.x;
          const dy = target.position.y - source.position.y;
          const dist = Math.sqrt(dx * dx + dy * dy) || 1;
          const force = (dist - 100) * 0.01;
          
          const fx = (dx / dist) * force;
          const fy = (dy / dist) * force;
          
          source.position.x += fx;
          source.position.y += fy;
          target.position.x -= fx;
          target.position.y -= fy;
        }
      }

      // Keep nodes within bounds
      nodes.forEach(node => {
        node.position.x = Math.max(50, Math.min(width - 50, node.position.x));
        node.position.y = Math.max(50, Math.min(height - 50, node.position.y));
      });
    }
  }
}

class ThreeQuestionStateImpl implements ThreeQuestionState {
  question1Complete: boolean = false;
  question2Complete: boolean = false;
  question3Complete: boolean = false;
  currentQuestion: 1 | 2 | 3 | null = null;
  loading: boolean = false;
  error: string | null = null;
}

class NodeSummaryImpl {
  id: string = '';
  label: string = '';
  type: string = '';
  content: string = '';
}

class KnowledgeNodeImpl implements KnowledgeNode {
  id: string = '';
  courseId: string = '';
  type: 'concept' | 'controversy' | 'evidence' = 'concept';
  label: string = '';
  content: string = '';
  position: NodePosition = new NodePositionImpl();
}

class NodePositionImpl implements NodePosition {
  x: number = 0;
  y: number = 0;
}

class AssessmentImpl implements Assessment {
  id: string = '';
  courseId: string = '';
  bloomLevel: BloomLevel = 'understand';
  questionType: QuestionType = 'subjective';
  question: string = '';
  answer: string = '';
  options: string = '';
  correctAnswer: string = '';
  userAnswer: string = '';
  isCorrect: boolean = false;
  createdAt: number = 0;
}
