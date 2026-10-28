import relationalStore from '@ohos.data.relationalStore';
import { Course, CourseStatus } from '../model/Course';
import { KnowledgeNode, NodePosition } from '../model/KnowledgeNode';
import { KnowledgeEdge, EdgeType } from '../model/KnowledgeEdge';
import { Assessment, BloomLevel, QuestionType, FollowUp, AssessmentReport, DimensionScores, DimensionAnalysis, ErrorTrace, ArchiveAssessment, ArchiveFollowUp } from '../model/Assessment';
import { KnowledgeSource } from '../model/KnowledgeSource';
import { Discussion, DiscussionMessage, DiscussionSummary } from '../model/Discussion';

const STORE_CONFIG: relationalStore.StoreConfig = {
  name: 'ThreeQuestionStudy.db',
  securityLevel: relationalStore.SecurityLevel.S1
};

const SQL_CREATE_COURSES = `
  CREATE TABLE IF NOT EXISTS courses (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    question TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'created',
    mental_model_generated INTEGER NOT NULL DEFAULT 0,
    controversy_generated INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )
`;

const SQL_CREATE_KNOWLEDGE_NODES = `
  CREATE TABLE IF NOT EXISTS knowledge_nodes (
    id TEXT PRIMARY KEY,
    course_id TEXT NOT NULL,
    type TEXT NOT NULL,
    label TEXT NOT NULL,
    content TEXT,
    position_x REAL NOT NULL DEFAULT 0,
    position_y REAL NOT NULL DEFAULT 0,
    FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE
  )
`;

const SQL_CREATE_KNOWLEDGE_EDGES = `
  CREATE TABLE IF NOT EXISTS knowledge_edges (
    id TEXT PRIMARY KEY,
    course_id TEXT NOT NULL,
    from_node_id TEXT NOT NULL,
    to_node_id TEXT NOT NULL,
    type TEXT NOT NULL,
    weight REAL NOT NULL DEFAULT 1.0,
    FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE,
    FOREIGN KEY (from_node_id) REFERENCES knowledge_nodes(id) ON DELETE CASCADE,
    FOREIGN KEY (to_node_id) REFERENCES knowledge_nodes(id) ON DELETE CASCADE
  )
`;

const SQL_CREATE_ASSESSMENTS = `
  CREATE TABLE IF NOT EXISTS assessments (
    id TEXT PRIMARY KEY,
    course_id TEXT NOT NULL,
    bloom_level TEXT NOT NULL,
    question_type TEXT NOT NULL DEFAULT 'subjective',
    question TEXT NOT NULL,
    answer TEXT,
    options TEXT DEFAULT '',
    correct_answer TEXT DEFAULT '',
    user_answer TEXT,
    is_correct INTEGER,
    created_at INTEGER NOT NULL,
    FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE
  )
`;

const SQL_CREATE_KNOWLEDGE_SOURCES = `
  CREATE TABLE IF NOT EXISTS knowledge_sources (
    id TEXT PRIMARY KEY,
    course_id TEXT NOT NULL,
    node_id TEXT NOT NULL DEFAULT '',
    title TEXT NOT NULL,
    url TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'web',
    FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE
  )
`;

const SQL_CREATE_DISCUSSIONS = `
  CREATE TABLE IF NOT EXISTS discussions (
    id TEXT PRIMARY KEY,
    controversy_id TEXT NOT NULL,
    course_id TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE
  )
`;

const SQL_CREATE_DISCUSSION_MESSAGES = `
  CREATE TABLE IF NOT EXISTS discussion_messages (
    id TEXT PRIMARY KEY,
    discussion_id TEXT NOT NULL,
    role TEXT NOT NULL,
    content TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    FOREIGN KEY (discussion_id) REFERENCES discussions(id) ON DELETE CASCADE
  )
`;

const SQL_CREATE_DISCUSSION_SUMMARIES = `
  CREATE TABLE IF NOT EXISTS discussion_summaries (
    id TEXT PRIMARY KEY,
    discussion_id TEXT NOT NULL,
    summary TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    FOREIGN KEY (discussion_id) REFERENCES discussions(id) ON DELETE CASCADE
  )
`;

const SQL_CREATE_LEARNING_PROGRESS = `
  CREATE TABLE IF NOT EXISTS learning_progress (
    id TEXT PRIMARY KEY,
    course_id TEXT NOT NULL,
    item_type TEXT NOT NULL,
    item_id TEXT NOT NULL,
    checked INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL,
    UNIQUE(course_id, item_type, item_id)
  )
`;

const SQL_CREATE_ASSESSMENT_FOLLOW_UPS = `
  CREATE TABLE IF NOT EXISTS assessment_follow_ups (
    id TEXT PRIMARY KEY,
    assessment_id TEXT NOT NULL,
    role TEXT NOT NULL,
    content TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    FOREIGN KEY (assessment_id) REFERENCES assessments(id) ON DELETE CASCADE
  )
`;

const SQL_CREATE_ASSESSMENT_REPORTS = `
  CREATE TABLE IF NOT EXISTS assessment_reports (
    id TEXT PRIMARY KEY,
    course_id TEXT NOT NULL UNIQUE,
    dimensions_json TEXT NOT NULL,
    overall_suggestion TEXT NOT NULL,
    error_traces_json TEXT NOT NULL,
    dimension_analysis_json TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE
  )
`;

const SQL_CREATE_STUDY_SESSIONS = `
  CREATE TABLE IF NOT EXISTS study_sessions (
    id TEXT PRIMARY KEY,
    course_id TEXT NOT NULL,
    date TEXT NOT NULL,
    duration_seconds INTEGER NOT NULL DEFAULT 0,
    UNIQUE(course_id, date),
    FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE
  )
`;

const SQL_CREATE_ANSWER_ARCHIVES = `
  CREATE TABLE IF NOT EXISTS answer_archives (
    id TEXT PRIMARY KEY,
    original_course_id TEXT NOT NULL,
    original_course_name TEXT NOT NULL,
    bloom_level TEXT NOT NULL,
    question_type TEXT NOT NULL,
    question TEXT NOT NULL,
    answer TEXT,
    options TEXT,
    correct_answer TEXT,
    user_answer TEXT,
    is_correct INTEGER,
    created_at INTEGER NOT NULL,
    archived_at INTEGER NOT NULL
  )
`;

const SQL_CREATE_FOLLOW_UP_ARCHIVES = `
  CREATE TABLE IF NOT EXISTS follow_up_archives (
    id TEXT PRIMARY KEY,
    archive_assessment_id TEXT NOT NULL,
    role TEXT NOT NULL,
    content TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    FOREIGN KEY (archive_assessment_id) REFERENCES answer_archives(id) ON DELETE CASCADE
  )
`;

export interface CourseStats {
  totalCourses: number;
  completedCourses: number;
  totalAssessments: number;
  averageScore: number;
}

export interface CourseDimensionScore {
  courseName: string;
  conceptUnderstanding: number;
  criticalThinking: number;
  practicalTransfer: number;
}

export class RDBService {
  private rdbStore: relationalStore.RdbStore | null = null;
  private context: Context;

  constructor(context: Context) {
    this.context = context;
  }

  async initialize(): Promise<void> {
    try {
      this.rdbStore = await relationalStore.getRdbStore(this.context, STORE_CONFIG);
      
      // Create tables
      await this.rdbStore.executeSql(SQL_CREATE_COURSES);
      await this.rdbStore.executeSql(SQL_CREATE_KNOWLEDGE_NODES);
      await this.rdbStore.executeSql(SQL_CREATE_KNOWLEDGE_EDGES);
      await this.rdbStore.executeSql(SQL_CREATE_ASSESSMENTS);
      await this.rdbStore.executeSql(SQL_CREATE_KNOWLEDGE_SOURCES);
      await this.rdbStore.executeSql(SQL_CREATE_DISCUSSIONS);
      await this.rdbStore.executeSql(SQL_CREATE_DISCUSSION_MESSAGES);
      await this.rdbStore.executeSql(SQL_CREATE_DISCUSSION_SUMMARIES);
      await this.rdbStore.executeSql(SQL_CREATE_LEARNING_PROGRESS);
      await this.rdbStore.executeSql(SQL_CREATE_ASSESSMENT_FOLLOW_UPS);
      await this.rdbStore.executeSql(SQL_CREATE_ASSESSMENT_REPORTS);
      await this.rdbStore.executeSql(SQL_CREATE_STUDY_SESSIONS);
      await this.rdbStore.executeSql(SQL_CREATE_ANSWER_ARCHIVES);
      await this.rdbStore.executeSql(SQL_CREATE_FOLLOW_UP_ARCHIVES);
      
      try {
        await this.rdbStore.executeSql('ALTER TABLE assessments ADD COLUMN question_type TEXT NOT NULL DEFAULT \'subjective\'');
      } catch (e) { /* column already exists */ }
      try {
        await this.rdbStore.executeSql('ALTER TABLE assessments ADD COLUMN options TEXT DEFAULT \'\'');
      } catch (e) { /* column already exists */ }
      try {
        await this.rdbStore.executeSql('ALTER TABLE assessments ADD COLUMN correct_answer TEXT DEFAULT \'\'');
      } catch (e) { /* column already exists */ }
      try {
        await this.rdbStore.executeSql('ALTER TABLE courses ADD COLUMN assessment_generating INTEGER NOT NULL DEFAULT 0');
      } catch (e) { /* column already exists */ }
      
      console.info('[RDBService] Database initialized successfully');
    } catch (err) {
      const errMsg = err instanceof Error ? err.message : String(err);
      console.error('[RDBService] Failed to initialize database:', errMsg);
      throw new Error('数据库初始化失败: ' + errMsg);
    }
  }

  getStore(): relationalStore.RdbStore {
    if (!this.rdbStore) {
      throw new Error('RDB store not initialized. Call initialize() first.');
    }
    return this.rdbStore;
  }

  // Course operations
  async insertCourse(course: Course): Promise<number> {
    const valueBucket: relationalStore.ValuesBucket = {
      id: course.id,
      name: course.name,
      question: course.question,
      status: course.status,
      mental_model_generated: course.mentalModelGenerated ? 1 : 0,
      controversy_generated: course.controversyGenerated ? 1 : 0,
      assessment_generating: course.assessmentGenerating ? 1 : 0,
      created_at: course.createdAt,
      updated_at: course.updatedAt
    };
    return await this.getStore().insert('courses', valueBucket);
  }

  async queryCourses(): Promise<Course[]> {
    const predicates = new relationalStore.RdbPredicates('courses');
    predicates.orderByDesc('updated_at');
    const resultSet = await this.getStore().query(predicates);
    
    const courses: Course[] = [];
    while (resultSet.goToNextRow()) {
      const course = new CourseImpl();
      course.id = resultSet.getString(resultSet.getColumnIndex('id'));
      course.name = resultSet.getString(resultSet.getColumnIndex('name'));
      course.question = resultSet.getString(resultSet.getColumnIndex('question'));
      course.status = resultSet.getString(resultSet.getColumnIndex('status')) as CourseStatus;
      course.mentalModelGenerated = resultSet.getLong(resultSet.getColumnIndex('mental_model_generated')) === 1;
      course.controversyGenerated = resultSet.getLong(resultSet.getColumnIndex('controversy_generated')) === 1;
      course.assessmentGenerating = resultSet.getLong(resultSet.getColumnIndex('assessment_generating')) === 1;
      course.createdAt = resultSet.getLong(resultSet.getColumnIndex('created_at'));
      course.updatedAt = resultSet.getLong(resultSet.getColumnIndex('updated_at'));
      courses.push(course);
    }
    resultSet.close();
    console.info('[RDBService] queryCourses returned ' + courses.length + ' courses');
    for (const c of courses) {
      console.info('[RDBService] course: id=' + c.id + ' name=' + c.name + ' status=' + c.status);
    }
    return courses;
  }

  async updateCourse(course: Course): Promise<number> {
    const valueBucket: relationalStore.ValuesBucket = {
      name: course.name,
      status: course.status,
      mental_model_generated: course.mentalModelGenerated ? 1 : 0,
      controversy_generated: course.controversyGenerated ? 1 : 0,
      assessment_generating: course.assessmentGenerating ? 1 : 0,
      updated_at: course.updatedAt
    };
    const predicates = new relationalStore.RdbPredicates('courses');
    predicates.equalTo('id', course.id);
    return await this.getStore().update(valueBucket, predicates);
  }

  async deleteCourse(courseId: string): Promise<number> {
    await this.deleteKnowledgeSourcesByCourseId(courseId);
    await this.deleteDiscussionSummariesByCourseId(courseId);
    await this.deleteDiscussionMessagesByCourseId(courseId);
    await this.deleteDiscussionsByCourseId(courseId);
    await this.deleteKnowledgeEdgesByCourse(courseId);
    await this.deleteKnowledgeNodesByCourse(courseId);
    await this.deleteProgressByCourseId(courseId);
    await this.deleteAssessmentReportByCourseId(courseId);
    await this.deleteStudySessionsByCourseId(courseId);
    await this.deleteAnswerArchivesByCourseId(courseId);
    await this.deleteFollowUpArchivesByCourseId(courseId);
    const predicates = new relationalStore.RdbPredicates('courses');
    predicates.equalTo('id', courseId);
    return await this.getStore().delete(predicates);
  }

  // Knowledge node operations
  async insertKnowledgeNode(node: KnowledgeNode): Promise<number> {
    const valueBucket: relationalStore.ValuesBucket = {
      id: node.id,
      course_id: node.courseId,
      type: node.type,
      label: node.label,
      content: node.content || '',
      position_x: node.position.x,
      position_y: node.position.y
    };
    return await this.getStore().insert('knowledge_nodes', valueBucket, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
  }

  async queryKnowledgeNodes(courseId: string): Promise<KnowledgeNode[]> {
    const predicates = new relationalStore.RdbPredicates('knowledge_nodes');
    predicates.equalTo('course_id', courseId);
    const resultSet = await this.getStore().query(predicates);
    
    const nodes: KnowledgeNode[] = [];
    while (resultSet.goToNextRow()) {
      const node = new KnowledgeNodeImpl();
      node.id = resultSet.getString(resultSet.getColumnIndex('id'));
      node.courseId = resultSet.getString(resultSet.getColumnIndex('course_id'));
      node.type = resultSet.getString(resultSet.getColumnIndex('type')) as 'concept' | 'controversy' | 'evidence';
      node.label = resultSet.getString(resultSet.getColumnIndex('label'));
      node.content = resultSet.getString(resultSet.getColumnIndex('content'));
      const pos = new NodePositionImpl();
      pos.x = resultSet.getDouble(resultSet.getColumnIndex('position_x'));
      pos.y = resultSet.getDouble(resultSet.getColumnIndex('position_y'));
      node.position = pos;
      nodes.push(node);
    }
    resultSet.close();
    return nodes;
  }

  // Knowledge edge operations
  async insertKnowledgeEdge(edge: KnowledgeEdge): Promise<number> {
    const valueBucket: relationalStore.ValuesBucket = {
      id: edge.id,
      course_id: edge.courseId,
      from_node_id: edge.fromNodeId,
      to_node_id: edge.toNodeId,
      type: edge.type,
      weight: edge.weight
    };
    return await this.getStore().insert('knowledge_edges', valueBucket, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
  }

  async queryKnowledgeEdges(courseId: string): Promise<KnowledgeEdge[]> {
    const predicates = new relationalStore.RdbPredicates('knowledge_edges');
    predicates.equalTo('course_id', courseId);
    const resultSet = await this.getStore().query(predicates);
    
    const edges: KnowledgeEdge[] = [];
    while (resultSet.goToNextRow()) {
      const edge = new KnowledgeEdgeImpl();
      edge.id = resultSet.getString(resultSet.getColumnIndex('id'));
      edge.courseId = resultSet.getString(resultSet.getColumnIndex('course_id'));
      edge.fromNodeId = resultSet.getString(resultSet.getColumnIndex('from_node_id'));
      edge.toNodeId = resultSet.getString(resultSet.getColumnIndex('to_node_id'));
      edge.type = resultSet.getString(resultSet.getColumnIndex('type')) as EdgeType;
      edge.weight = resultSet.getDouble(resultSet.getColumnIndex('weight'));
      edges.push(edge);
    }
    resultSet.close();
    return edges;
  }

  // Assessment operations
  async insertAssessment(assessment: Assessment): Promise<number> {
    const valueBucket: relationalStore.ValuesBucket = {
      id: assessment.id,
      course_id: assessment.courseId,
      bloom_level: assessment.bloomLevel,
      question_type: assessment.questionType,
      question: assessment.question,
      answer: assessment.answer || '',
      options: assessment.options || '',
      correct_answer: assessment.correctAnswer || '',
      user_answer: assessment.userAnswer || '',
      is_correct: assessment.isCorrect ? 1 : 0,
      created_at: assessment.createdAt
    };
    return await this.getStore().insert('assessments', valueBucket, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
  }

  async queryAssessments(courseId: string): Promise<Assessment[]> {
    const predicates = new relationalStore.RdbPredicates('assessments');
    if (courseId) {
      predicates.equalTo('course_id', courseId);
    }
    predicates.orderByDesc('created_at');
    const resultSet = await this.getStore().query(predicates);
    
    const assessments: Assessment[] = [];
    while (resultSet.goToNextRow()) {
      const a = new AssessmentImpl();
      a.id = resultSet.getString(resultSet.getColumnIndex('id'));
      a.courseId = resultSet.getString(resultSet.getColumnIndex('course_id'));
      a.bloomLevel = resultSet.getString(resultSet.getColumnIndex('bloom_level')) as BloomLevel;
      a.questionType = resultSet.getString(resultSet.getColumnIndex('question_type')) as QuestionType;
      a.question = resultSet.getString(resultSet.getColumnIndex('question'));
      a.answer = resultSet.getString(resultSet.getColumnIndex('answer'));
      a.options = resultSet.getString(resultSet.getColumnIndex('options'));
      a.correctAnswer = resultSet.getString(resultSet.getColumnIndex('correct_answer'));
      a.userAnswer = resultSet.getString(resultSet.getColumnIndex('user_answer'));
      a.isCorrect = resultSet.getLong(resultSet.getColumnIndex('is_correct')) === 1;
      a.createdAt = resultSet.getLong(resultSet.getColumnIndex('created_at'));
      assessments.push(a);
    }
    resultSet.close();
    return assessments;
  }

  async updateAssessment(assessment: Assessment): Promise<number> {
    const valueBucket: relationalStore.ValuesBucket = {
      user_answer: assessment.userAnswer || '',
      is_correct: assessment.isCorrect ? 1 : 0
    };
    const predicates = new relationalStore.RdbPredicates('assessments');
    predicates.equalTo('id', assessment.id);
    return await this.getStore().update(valueBucket, predicates);
  }

  async deleteAssessmentsByCourseId(courseId: string): Promise<number> {
    const predicates = new relationalStore.RdbPredicates('assessments');
    predicates.equalTo('course_id', courseId);
    return await this.getStore().delete(predicates);
  }

  async insertFollowUp(followUp: FollowUp): Promise<number> {
    const valueBucket: relationalStore.ValuesBucket = {
      id: followUp.id,
      assessment_id: followUp.assessmentId,
      role: followUp.role,
      content: followUp.content,
      created_at: followUp.createdAt
    };
    return await this.getStore().insert('assessment_follow_ups', valueBucket, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
  }

  async queryFollowUpsByAssessmentId(assessmentId: string): Promise<FollowUp[]> {
    const predicates = new relationalStore.RdbPredicates('assessment_follow_ups');
    predicates.equalTo('assessment_id', assessmentId);
    predicates.orderByAsc('created_at');
    const resultSet = await this.getStore().query(predicates);
    const followUps: FollowUp[] = [];
    while (resultSet.goToNextRow()) {
      const f = new FollowUpImpl();
      f.id = resultSet.getString(resultSet.getColumnIndex('id'));
      f.assessmentId = resultSet.getString(resultSet.getColumnIndex('assessment_id'));
      f.role = resultSet.getString(resultSet.getColumnIndex('role')) as 'user' | 'assistant';
      f.content = resultSet.getString(resultSet.getColumnIndex('content'));
      f.createdAt = resultSet.getLong(resultSet.getColumnIndex('created_at'));
      followUps.push(f);
    }
    resultSet.close();
    return followUps;
  }

  async deleteFollowUpsByAssessmentId(assessmentId: string): Promise<number> {
    const predicates = new relationalStore.RdbPredicates('assessment_follow_ups');
    predicates.equalTo('assessment_id', assessmentId);
    return await this.getStore().delete(predicates);
  }

  async deleteKnowledgeNodesByCourse(courseId: string): Promise<number> {
    const predicates = new relationalStore.RdbPredicates('knowledge_nodes');
    predicates.equalTo('course_id', courseId);
    return await this.getStore().delete(predicates);
  }

  async deleteKnowledgeEdgesByCourse(courseId: string): Promise<number> {
    const predicates = new relationalStore.RdbPredicates('knowledge_edges');
    predicates.equalTo('course_id', courseId);
    return await this.getStore().delete(predicates);
  }

  async deleteKnowledgeNodesByType(courseId: string, type: string): Promise<number> {
    const predicates = new relationalStore.RdbPredicates('knowledge_nodes');
    predicates.equalTo('course_id', courseId);
    predicates.equalTo('type', type);
    return await this.getStore().delete(predicates);
  }

  async deleteKnowledgeNodesByCourseExcludeType(courseId: string, excludeType: string): Promise<number> {
    const predicates = new relationalStore.RdbPredicates('knowledge_nodes');
    predicates.equalTo('course_id', courseId);
    predicates.notEqualTo('type', excludeType);
    return await this.getStore().delete(predicates);
  }

  async queryKnowledgeNodeById(nodeId: string): Promise<KnowledgeNode | null> {
    const predicates = new relationalStore.RdbPredicates('knowledge_nodes');
    predicates.equalTo('id', nodeId);
    const resultSet = await this.getStore().query(predicates);
    
    let node: KnowledgeNode | null = null;
    if (resultSet.goToFirstRow()) {
      node = new KnowledgeNodeImpl();
      node.id = resultSet.getString(resultSet.getColumnIndex('id'));
      node.courseId = resultSet.getString(resultSet.getColumnIndex('course_id'));
      node.type = resultSet.getString(resultSet.getColumnIndex('type')) as 'concept' | 'controversy' | 'evidence';
      node.label = resultSet.getString(resultSet.getColumnIndex('label'));
      node.content = resultSet.getString(resultSet.getColumnIndex('content'));
      const pos = new NodePositionImpl();
      pos.x = resultSet.getDouble(resultSet.getColumnIndex('position_x'));
      pos.y = resultSet.getDouble(resultSet.getColumnIndex('position_y'));
      node.position = pos;
    }
    resultSet.close();
    return node;
  }

  async queryEdgesByNodeId(nodeId: string): Promise<KnowledgeEdge[]> {
    const predicates = new relationalStore.RdbPredicates('knowledge_edges');
    predicates.equalTo('from_node_id', nodeId).or().equalTo('to_node_id', nodeId);
    const resultSet = await this.getStore().query(predicates);
    
    const edges: KnowledgeEdge[] = [];
    while (resultSet.goToNextRow()) {
      const edge = new KnowledgeEdgeImpl();
      edge.id = resultSet.getString(resultSet.getColumnIndex('id'));
      edge.courseId = resultSet.getString(resultSet.getColumnIndex('course_id'));
      edge.fromNodeId = resultSet.getString(resultSet.getColumnIndex('from_node_id'));
      edge.toNodeId = resultSet.getString(resultSet.getColumnIndex('to_node_id'));
      edge.type = resultSet.getString(resultSet.getColumnIndex('type')) as EdgeType;
      edge.weight = resultSet.getDouble(resultSet.getColumnIndex('weight'));
      edges.push(edge);
    }
    resultSet.close();
    return edges;
  }

  async insertKnowledgeSource(source: KnowledgeSource): Promise<number> {
    const valueBucket: relationalStore.ValuesBucket = {
      id: source.id,
      course_id: source.courseId,
      node_id: source.nodeId,
      title: source.title,
      url: source.url,
      type: source.type
    };
    return await this.getStore().insert('knowledge_sources', valueBucket, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
  }

  async queryKnowledgeSourcesByNodeId(nodeId: string): Promise<KnowledgeSource[]> {
    const predicates = new relationalStore.RdbPredicates('knowledge_sources');
    predicates.equalTo('node_id', nodeId);
    const resultSet = await this.getStore().query(predicates);

    const sources: KnowledgeSource[] = [];
    while (resultSet.goToNextRow()) {
      const s = new KnowledgeSourceImpl();
      s.id = resultSet.getString(resultSet.getColumnIndex('id'));
      s.courseId = resultSet.getString(resultSet.getColumnIndex('course_id'));
      s.nodeId = resultSet.getString(resultSet.getColumnIndex('node_id'));
      s.title = resultSet.getString(resultSet.getColumnIndex('title'));
      s.url = resultSet.getString(resultSet.getColumnIndex('url'));
      s.type = resultSet.getString(resultSet.getColumnIndex('type')) as 'web' | 'user';
      sources.push(s);
    }
    resultSet.close();
    return sources;
  }

  async queryKnowledgeSourcesByCourseId(courseId: string): Promise<KnowledgeSource[]> {
    const predicates = new relationalStore.RdbPredicates('knowledge_sources');
    predicates.equalTo('course_id', courseId);
    const resultSet = await this.getStore().query(predicates);

    const sources: KnowledgeSource[] = [];
    while (resultSet.goToNextRow()) {
      const s = new KnowledgeSourceImpl();
      s.id = resultSet.getString(resultSet.getColumnIndex('id'));
      s.courseId = resultSet.getString(resultSet.getColumnIndex('course_id'));
      s.nodeId = resultSet.getString(resultSet.getColumnIndex('node_id'));
      s.title = resultSet.getString(resultSet.getColumnIndex('title'));
      s.url = resultSet.getString(resultSet.getColumnIndex('url'));
      s.type = resultSet.getString(resultSet.getColumnIndex('type')) as 'web' | 'user';
      sources.push(s);
    }
    resultSet.close();
    return sources;
  }

  async deleteKnowledgeSourcesByNodeId(nodeId: string): Promise<number> {
    const predicates = new relationalStore.RdbPredicates('knowledge_sources');
    predicates.equalTo('node_id', nodeId);
    return await this.getStore().delete(predicates);
  }

  async insertDiscussion(discussion: Discussion): Promise<number> {
    const valueBucket: relationalStore.ValuesBucket = {
      id: discussion.id,
      controversy_id: discussion.controversyId,
      course_id: discussion.courseId,
      created_at: discussion.createdAt
    };
    return await this.getStore().insert('discussions', valueBucket, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
  }

  async queryDiscussionByControversyId(controversyId: string): Promise<Discussion | null> {
    const predicates = new relationalStore.RdbPredicates('discussions');
    predicates.equalTo('controversy_id', controversyId);
    const resultSet = await this.getStore().query(predicates);

    let discussion: Discussion | null = null;
    if (resultSet.goToFirstRow()) {
      discussion = new DiscussionImpl();
      discussion.id = resultSet.getString(resultSet.getColumnIndex('id'));
      discussion.controversyId = resultSet.getString(resultSet.getColumnIndex('controversy_id'));
      discussion.courseId = resultSet.getString(resultSet.getColumnIndex('course_id'));
      discussion.createdAt = resultSet.getLong(resultSet.getColumnIndex('created_at'));
    }
    resultSet.close();
    return discussion;
  }

  async queryDiscussionsByCourseId(courseId: string): Promise<Discussion[]> {
    const predicates = new relationalStore.RdbPredicates('discussions');
    predicates.equalTo('course_id', courseId);
    predicates.orderByDesc('created_at');
    const resultSet = await this.getStore().query(predicates);

    const discussions: Discussion[] = [];
    while (resultSet.goToNextRow()) {
      const d = new DiscussionImpl();
      d.id = resultSet.getString(resultSet.getColumnIndex('id'));
      d.controversyId = resultSet.getString(resultSet.getColumnIndex('controversy_id'));
      d.courseId = resultSet.getString(resultSet.getColumnIndex('course_id'));
      d.createdAt = resultSet.getLong(resultSet.getColumnIndex('created_at'));
      discussions.push(d);
    }
    resultSet.close();
    return discussions;
  }

  async insertDiscussionMessage(message: DiscussionMessage): Promise<number> {
    const valueBucket: relationalStore.ValuesBucket = {
      id: message.id,
      discussion_id: message.discussionId,
      role: message.role,
      content: message.content,
      created_at: message.createdAt
    };
    return await this.getStore().insert('discussion_messages', valueBucket, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
  }

  async queryDiscussionMessages(discussionId: string): Promise<DiscussionMessage[]> {
    const predicates = new relationalStore.RdbPredicates('discussion_messages');
    predicates.equalTo('discussion_id', discussionId);
    predicates.orderByAsc('created_at');
    const resultSet = await this.getStore().query(predicates);

    const messages: DiscussionMessage[] = [];
    while (resultSet.goToNextRow()) {
      const m = new DiscussionMessageImpl();
      m.id = resultSet.getString(resultSet.getColumnIndex('id'));
      m.discussionId = resultSet.getString(resultSet.getColumnIndex('discussion_id'));
      m.role = resultSet.getString(resultSet.getColumnIndex('role')) as 'user' | 'assistant';
      m.content = resultSet.getString(resultSet.getColumnIndex('content'));
      m.createdAt = resultSet.getLong(resultSet.getColumnIndex('created_at'));
      messages.push(m);
    }
    resultSet.close();
    return messages;
  }

  async insertDiscussionSummary(summary: DiscussionSummary): Promise<number> {
    const valueBucket: relationalStore.ValuesBucket = {
      id: summary.id,
      discussion_id: summary.discussionId,
      summary: summary.summary,
      created_at: summary.createdAt
    };
    return await this.getStore().insert('discussion_summaries', valueBucket, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
  }

  async queryDiscussionSummary(discussionId: string): Promise<DiscussionSummary | null> {
    const predicates = new relationalStore.RdbPredicates('discussion_summaries');
    predicates.equalTo('discussion_id', discussionId);
    predicates.orderByDesc('created_at');
    const resultSet = await this.getStore().query(predicates);

    let summary: DiscussionSummary | null = null;
    if (resultSet.goToFirstRow()) {
      summary = new DiscussionSummaryImpl();
      summary.id = resultSet.getString(resultSet.getColumnIndex('id'));
      summary.discussionId = resultSet.getString(resultSet.getColumnIndex('discussion_id'));
      summary.summary = resultSet.getString(resultSet.getColumnIndex('summary'));
      summary.createdAt = resultSet.getLong(resultSet.getColumnIndex('created_at'));
    }
    resultSet.close();
    return summary;
  }

  async deleteKnowledgeSourcesByCourseId(courseId: string): Promise<number> {
    const predicates = new relationalStore.RdbPredicates('knowledge_sources');
    predicates.equalTo('course_id', courseId);
    return await this.getStore().delete(predicates);
  }

  async deleteDiscussionsByCourseId(courseId: string): Promise<number> {
    const discussions = await this.queryDiscussionsByCourseId(courseId);
    for (const d of discussions) {
      const msgPred = new relationalStore.RdbPredicates('discussion_messages');
      msgPred.equalTo('discussion_id', d.id);
      await this.getStore().delete(msgPred);
      const sumPred = new relationalStore.RdbPredicates('discussion_summaries');
      sumPred.equalTo('discussion_id', d.id);
      await this.getStore().delete(sumPred);
    }
    const predicates = new relationalStore.RdbPredicates('discussions');
    predicates.equalTo('course_id', courseId);
    return await this.getStore().delete(predicates);
  }

  async deleteDiscussionMessagesByCourseId(courseId: string): Promise<number> {
    const discussions = await this.queryDiscussionsByCourseId(courseId);
    let total = 0;
    for (const d of discussions) {
      const predicates = new relationalStore.RdbPredicates('discussion_messages');
      predicates.equalTo('discussion_id', d.id);
      total += await this.getStore().delete(predicates);
    }
    return total;
  }

  async deleteDiscussionSummariesByCourseId(courseId: string): Promise<number> {
    const discussions = await this.queryDiscussionsByCourseId(courseId);
    let total = 0;
    for (const d of discussions) {
      const predicates = new relationalStore.RdbPredicates('discussion_summaries');
      predicates.equalTo('discussion_id', d.id);
      total += await this.getStore().delete(predicates);
    }
    return total;
  }

  async setProgressChecked(courseId: string, itemType: string, itemId: string, checked: boolean): Promise<void> {
    const valueBucket: relationalStore.ValuesBucket = {
      id: `${courseId}_${itemType}_${itemId}`,
      course_id: courseId,
      item_type: itemType,
      item_id: itemId,
      checked: checked ? 1 : 0,
      created_at: Date.now()
    };
    await this.getStore().insert('learning_progress', valueBucket, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
  }

  async getProgressChecked(courseId: string, itemType: string, itemId: string): Promise<boolean> {
    const predicates = new relationalStore.RdbPredicates('learning_progress');
    predicates.equalTo('course_id', courseId);
    predicates.equalTo('item_type', itemType);
    predicates.equalTo('item_id', itemId);
    const resultSet = await this.getStore().query(predicates);
    let checked = false;
    if (resultSet.goToFirstRow()) {
      checked = resultSet.getLong(resultSet.getColumnIndex('checked')) === 1;
    }
    resultSet.close();
    return checked;
  }

  async getAllProgressByCourseId(courseId: string): Promise<Map<string, boolean>> {
    const predicates = new relationalStore.RdbPredicates('learning_progress');
    predicates.equalTo('course_id', courseId);
    const resultSet = await this.getStore().query(predicates);
    const map = new Map<string, boolean>();
    while (resultSet.goToNextRow()) {
      const itemType = resultSet.getString(resultSet.getColumnIndex('item_type'));
      const itemId = resultSet.getString(resultSet.getColumnIndex('item_id'));
      const checked = resultSet.getLong(resultSet.getColumnIndex('checked')) === 1;
      map.set(`${itemType}:${itemId}`, checked);
    }
    resultSet.close();
    return map;
  }

  async deleteProgressByCourseId(courseId: string): Promise<number> {
    const predicates = new relationalStore.RdbPredicates('learning_progress');
    predicates.equalTo('course_id', courseId);
    return await this.getStore().delete(predicates);
  }

  async saveAssessmentReport(report: AssessmentReport): Promise<number> {
    const valueBucket: relationalStore.ValuesBucket = {
      id: report.id,
      course_id: report.courseId,
      dimensions_json: JSON.stringify(report.dimensions),
      overall_suggestion: report.overallSuggestion,
      error_traces_json: JSON.stringify(report.errorTraces),
      dimension_analysis_json: JSON.stringify(report.dimensionAnalysis),
      created_at: report.createdAt
    };
    return await this.getStore().insert('assessment_reports', valueBucket, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
  }

  async getAssessmentReportByCourseId(courseId: string): Promise<AssessmentReport | null> {
    const predicates = new relationalStore.RdbPredicates('assessment_reports');
    predicates.equalTo('course_id', courseId);
    const resultSet = await this.getStore().query(predicates);

    let report: AssessmentReport | null = null;
    if (resultSet.goToFirstRow()) {
      try {
        const r = new AssessmentReportImpl();
        r.id = resultSet.getString(resultSet.getColumnIndex('id'));
        r.courseId = resultSet.getString(resultSet.getColumnIndex('course_id'));
        const dimsStr = resultSet.getString(resultSet.getColumnIndex('dimensions_json'));
        r.dimensions = dimsStr ? JSON.parse(dimsStr) as DimensionScores : { conceptUnderstanding: 0, criticalThinking: 0, practicalTransfer: 0 } as DimensionScores;
        r.overallSuggestion = resultSet.getString(resultSet.getColumnIndex('overall_suggestion'));
        const errStr = resultSet.getString(resultSet.getColumnIndex('error_traces_json'));
        r.errorTraces = errStr ? JSON.parse(errStr) as ErrorTrace[] : [];
        const daStr = resultSet.getString(resultSet.getColumnIndex('dimension_analysis_json'));
        r.dimensionAnalysis = daStr ? JSON.parse(daStr) as DimensionAnalysis : { conceptUnderstanding: '', criticalThinking: '', practicalTransfer: '' } as DimensionAnalysis;
        r.createdAt = resultSet.getLong(resultSet.getColumnIndex('created_at'));
        report = r;
      } catch (e) {
        console.warn('[RDBService] Failed to parse assessment report:', e);
      }
    }
    resultSet.close();
    return report;
  }

  async deleteAssessmentReportByCourseId(courseId: string): Promise<number> {
    const predicates = new relationalStore.RdbPredicates('assessment_reports');
    predicates.equalTo('course_id', courseId);
    return await this.getStore().delete(predicates);
  }

  async calculateCourseProgress(courseId: string): Promise<number> {
    const progressMap = await this.getAllProgressByCourseId(courseId);
    let progress = 0;

    if (progressMap.get('mental:mental')) {
      progress += 2 / 9;
    }

    const allNodes = await this.queryKnowledgeNodes(courseId);
    const controversies = allNodes.filter(n => {
      if (n.type !== 'controversy') return false;
      try {
        const data = n.content ? JSON.parse(n.content) as Record<string, Object> : {} as Record<string, Object>;
        return !!(data['leftView'] || data['rightView']);
      } catch (e) {
        return false;
      }
    });
    if (controversies.length > 0) {
      const perControversy = (2 / 9) / controversies.length;
      for (const c of controversies) {
        if (progressMap.get(`controversy:${c.id}`)) {
          progress += perControversy;
        }
      }
    }

    const aiNodes = allNodes.filter(n => (n.type === 'concept' || n.type === 'evidence') && n.content);
    const totalMaterialItems = aiNodes.length;
    if (totalMaterialItems > 0) {
      const perMaterial = (2 / 9) / totalMaterialItems;
      for (const n of aiNodes) {
        if (progressMap.get(`material:${n.id}`)) {
          progress += perMaterial;
        }
      }
    }

    let assessmentProgress = 0;
    const assessments = await this.queryAssessments(courseId);
    if (assessments.length > 0) {
      const answered = assessments.filter(a => a.userAnswer && a.userAnswer.length > 0);
      assessmentProgress = (1 / 3) * (answered.length / assessments.length);
    }

    return Math.min(progress, 2 / 3) + assessmentProgress;
  }

  async saveStudySession(courseId: string, date: string, additionalSeconds: number): Promise<void> {
    const predicates = new relationalStore.RdbPredicates('study_sessions');
    predicates.equalTo('course_id', courseId);
    predicates.equalTo('date', date);
    const resultSet = await this.getStore().query(predicates);
    let existingId: string = '';
    let existingDuration: number = 0;
    if (resultSet.goToFirstRow()) {
      existingId = resultSet.getString(resultSet.getColumnIndex('id'));
      existingDuration = resultSet.getLong(resultSet.getColumnIndex('duration_seconds'));
    }
    resultSet.close();

    if (existingId) {
      const valueBucket: relationalStore.ValuesBucket = {
        duration_seconds: existingDuration + additionalSeconds
      };
      const updatePred = new relationalStore.RdbPredicates('study_sessions');
      updatePred.equalTo('id', existingId);
      await this.getStore().update(valueBucket, updatePred);
    } else {
      const valueBucket: relationalStore.ValuesBucket = {
        id: `${courseId}_${date}`,
        course_id: courseId,
        date: date,
        duration_seconds: additionalSeconds
      };
      await this.getStore().insert('study_sessions', valueBucket, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
    }
  }

  async getStudySessionsByDateRange(startDate: string, endDate: string): Promise<Map<string, number>> {
    const predicates = new relationalStore.RdbPredicates('study_sessions');
    predicates.greaterThanOrEqualTo('date', startDate);
    predicates.lessThanOrEqualTo('date', endDate);
    const resultSet = await this.getStore().query(predicates);
    const map = new Map<string, number>();
    while (resultSet.goToNextRow()) {
      const date = resultSet.getString(resultSet.getColumnIndex('date'));
      const duration = resultSet.getLong(resultSet.getColumnIndex('duration_seconds'));
      const current = map.get(date) || 0;
      map.set(date, current + duration);
    }
    resultSet.close();
    return map;
  }

  async deleteStudySessionsByCourseId(courseId: string): Promise<number> {
    const predicates = new relationalStore.RdbPredicates('study_sessions');
    predicates.equalTo('course_id', courseId);
    return await this.getStore().delete(predicates);
  }

  async getCourseStats(): Promise<CourseStats> {
    console.info('[RDBService] getCourseStats called');
    const courses = await this.queryCourses();
    const totalCourses = courses.length;
    const completedCourses = courses.filter(c => c.status === 'completed').length;
    console.info('[RDBService] getCourseStats: totalCourses=' + totalCourses + ' completedCourses=' + completedCourses);

    let totalAssessments = 0;
    let answeredAssessments = 0;
    let scoreSum = 0;
    let scoreCount = 0;
    for (const course of courses) {
      try {
        const assessments = await this.queryAssessments(course.id);
        totalAssessments += assessments.length;
        answeredAssessments += assessments.filter(a => a.userAnswer && a.userAnswer.length > 0).length;
        console.info('[RDBService] getCourseStats: course=' + course.name + ' assessments=' + assessments.length);
        const report = await this.getAssessmentReportByCourseId(course.id);
        if (report) {
          const avg = (report.dimensions.conceptUnderstanding + report.dimensions.criticalThinking + report.dimensions.practicalTransfer) / 3;
          scoreSum += avg;
          scoreCount++;
          console.info('[RDBService] getCourseStats: course=' + course.name + ' reportAvg=' + avg);
        } else {
          console.info('[RDBService] getCourseStats: course=' + course.name + ' no report');
        }
      } catch (e) {
        console.warn('[RDBService] getCourseStats failed for course:', course.id, JSON.stringify(e));
      }
    }
    const averageScore = scoreCount > 0 ? scoreSum / scoreCount : 0;
    console.info('[RDBService] getCourseStats result: totalCourses=' + totalCourses + ' answeredAssessments=' + answeredAssessments + ' totalAssessments=' + totalAssessments + ' averageScore=' + averageScore);
    const stats = new CourseStatsImpl();
    stats.totalCourses = totalCourses;
    stats.completedCourses = answeredAssessments;
    stats.totalAssessments = totalAssessments;
    stats.averageScore = averageScore;
    return stats;
  }

  async getCourseDimensionScores(): Promise<CourseDimensionScore[]> {
    const courses = await this.queryCourses();
    const result: CourseDimensionScore[] = [];
    for (const course of courses) {
      try {
        const report = await this.getAssessmentReportByCourseId(course.id);
        if (report) {
          const score = new CourseDimensionScoreImpl();
          score.courseName = course.name;
          score.conceptUnderstanding = report.dimensions.conceptUnderstanding;
          score.criticalThinking = report.dimensions.criticalThinking;
          score.practicalTransfer = report.dimensions.practicalTransfer;
          result.push(score);
        }
      } catch (e) {
        console.warn('[RDBService] getCourseDimensionScores failed for course:', course.id, e);
      }
    }
    return result;
  }

  async insertAnswerArchive(archive: ArchiveAssessment): Promise<number> {
    const valueBucket: relationalStore.ValuesBucket = {
      id: archive.id,
      original_course_id: archive.originalCourseId,
      original_course_name: archive.originalCourseName,
      bloom_level: archive.bloomLevel,
      question_type: archive.questionType,
      question: archive.question,
      answer: archive.answer,
      options: archive.options,
      correct_answer: archive.correctAnswer,
      user_answer: archive.userAnswer,
      is_correct: archive.isCorrect ? 1 : 0,
      created_at: archive.createdAt,
      archived_at: archive.archivedAt
    };
    return await this.getStore().insert('answer_archives', valueBucket, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
  }

  async queryAnswerArchivesByCourseId(courseId: string): Promise<ArchiveAssessment[]> {
    const predicates = new relationalStore.RdbPredicates('answer_archives');
    predicates.equalTo('original_course_id', courseId);
    predicates.orderByAsc('created_at');
    const resultSet = await this.getStore().query(predicates);
    const archives: ArchiveAssessment[] = [];
    while (resultSet.goToNextRow()) {
      const a = new ArchiveAssessmentImpl();
      a.id = resultSet.getString(resultSet.getColumnIndex('id'));
      a.originalCourseId = resultSet.getString(resultSet.getColumnIndex('original_course_id'));
      a.originalCourseName = resultSet.getString(resultSet.getColumnIndex('original_course_name'));
      a.bloomLevel = resultSet.getString(resultSet.getColumnIndex('bloom_level')) as BloomLevel;
      a.questionType = resultSet.getString(resultSet.getColumnIndex('question_type')) as QuestionType;
      a.question = resultSet.getString(resultSet.getColumnIndex('question'));
      a.answer = resultSet.getString(resultSet.getColumnIndex('answer'));
      a.options = resultSet.getString(resultSet.getColumnIndex('options'));
      a.correctAnswer = resultSet.getString(resultSet.getColumnIndex('correct_answer'));
      a.userAnswer = resultSet.getString(resultSet.getColumnIndex('user_answer'));
      a.isCorrect = resultSet.getLong(resultSet.getColumnIndex('is_correct')) === 1;
      a.createdAt = resultSet.getLong(resultSet.getColumnIndex('created_at'));
      a.archivedAt = resultSet.getLong(resultSet.getColumnIndex('archived_at'));
      archives.push(a);
    }
    resultSet.close();
    return archives;
  }

  async queryAllAnswerArchives(): Promise<ArchiveAssessment[]> {
    const predicates = new relationalStore.RdbPredicates('answer_archives');
    predicates.orderByDesc('archived_at');
    const resultSet = await this.getStore().query(predicates);
    const archives: ArchiveAssessment[] = [];
    while (resultSet.goToNextRow()) {
      const a = new ArchiveAssessmentImpl();
      a.id = resultSet.getString(resultSet.getColumnIndex('id'));
      a.originalCourseId = resultSet.getString(resultSet.getColumnIndex('original_course_id'));
      a.originalCourseName = resultSet.getString(resultSet.getColumnIndex('original_course_name'));
      a.bloomLevel = resultSet.getString(resultSet.getColumnIndex('bloom_level')) as BloomLevel;
      a.questionType = resultSet.getString(resultSet.getColumnIndex('question_type')) as QuestionType;
      a.question = resultSet.getString(resultSet.getColumnIndex('question'));
      a.answer = resultSet.getString(resultSet.getColumnIndex('answer'));
      a.options = resultSet.getString(resultSet.getColumnIndex('options'));
      a.correctAnswer = resultSet.getString(resultSet.getColumnIndex('correct_answer'));
      a.userAnswer = resultSet.getString(resultSet.getColumnIndex('user_answer'));
      a.isCorrect = resultSet.getLong(resultSet.getColumnIndex('is_correct')) === 1;
      a.createdAt = resultSet.getLong(resultSet.getColumnIndex('created_at'));
      a.archivedAt = resultSet.getLong(resultSet.getColumnIndex('archived_at'));
      archives.push(a);
    }
    resultSet.close();
    return archives;
  }

  async insertFollowUpArchive(archive: ArchiveFollowUp): Promise<number> {
    const valueBucket: relationalStore.ValuesBucket = {
      id: archive.id,
      archive_assessment_id: archive.archiveAssessmentId,
      role: archive.role,
      content: archive.content,
      created_at: archive.createdAt
    };
    return await this.getStore().insert('follow_up_archives', valueBucket, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
  }

  async queryFollowUpArchivesByArchiveAssessmentId(archiveAssessmentId: string): Promise<ArchiveFollowUp[]> {
    const predicates = new relationalStore.RdbPredicates('follow_up_archives');
    predicates.equalTo('archive_assessment_id', archiveAssessmentId);
    predicates.orderByAsc('created_at');
    const resultSet = await this.getStore().query(predicates);
    const archives: ArchiveFollowUp[] = [];
    while (resultSet.goToNextRow()) {
      const f = new ArchiveFollowUpImpl();
      f.id = resultSet.getString(resultSet.getColumnIndex('id'));
      f.archiveAssessmentId = resultSet.getString(resultSet.getColumnIndex('archive_assessment_id'));
      f.role = resultSet.getString(resultSet.getColumnIndex('role')) as 'user' | 'assistant';
      f.content = resultSet.getString(resultSet.getColumnIndex('content'));
      f.createdAt = resultSet.getLong(resultSet.getColumnIndex('created_at'));
      archives.push(f);
    }
    resultSet.close();
    return archives;
  }

  async deleteAnswerArchivesByCourseId(courseId: string): Promise<number> {
    const archives = await this.queryAnswerArchivesByCourseId(courseId);
    for (const a of archives) {
      const fuPred = new relationalStore.RdbPredicates('follow_up_archives');
      fuPred.equalTo('archive_assessment_id', a.id);
      await this.getStore().delete(fuPred);
    }
    const predicates = new relationalStore.RdbPredicates('answer_archives');
    predicates.equalTo('original_course_id', courseId);
    return await this.getStore().delete(predicates);
  }

  async deleteFollowUpArchivesByCourseId(courseId: string): Promise<number> {
    const archives = await this.queryAnswerArchivesByCourseId(courseId);
    let total = 0;
    for (const a of archives) {
      const predicates = new relationalStore.RdbPredicates('follow_up_archives');
      predicates.equalTo('archive_assessment_id', a.id);
      total += await this.getStore().delete(predicates);
    }
    return total;
  }

  async archiveAnsweredAssessments(courseId: string, courseName: string): Promise<void> {
    const assessments = await this.queryAssessments(courseId);
    const answered = assessments.filter(a => a.userAnswer && a.userAnswer.length > 0);
    const now = Date.now();
    for (const a of answered) {
      const archive = new ArchiveAssessmentImpl();
      archive.id = a.id;
      archive.originalCourseId = courseId;
      archive.originalCourseName = courseName;
      archive.bloomLevel = a.bloomLevel;
      archive.questionType = a.questionType;
      archive.question = a.question;
      archive.answer = a.answer || '';
      archive.options = a.options || '';
      archive.correctAnswer = a.correctAnswer || '';
      archive.userAnswer = a.userAnswer || '';
      archive.isCorrect = a.isCorrect || false;
      archive.createdAt = a.createdAt;
      archive.archivedAt = now;
      await this.insertAnswerArchive(archive);

      const followUps = await this.queryFollowUpsByAssessmentId(a.id);
      for (const fu of followUps) {
        const fuArchive = new ArchiveFollowUpImpl();
        fuArchive.id = fu.id;
        fuArchive.archiveAssessmentId = a.id;
        fuArchive.role = fu.role;
        fuArchive.content = fu.content;
        fuArchive.createdAt = fu.createdAt;
        await this.insertFollowUpArchive(fuArchive);
      }
    }
  }

  async resetCourseAfterRegenerate(courseId: string): Promise<void> {
    const assessments = await this.queryAssessments(courseId);
    for (const a of assessments) {
      const fuPred = new relationalStore.RdbPredicates('assessment_follow_ups');
      fuPred.equalTo('assessment_id', a.id);
      await this.getStore().delete(fuPred);
    }
    const aPred = new relationalStore.RdbPredicates('assessments');
    aPred.equalTo('course_id', courseId);
    await this.getStore().delete(aPred);

    await this.deleteAssessmentReportByCourseId(courseId);
    await this.deleteProgressByCourseId(courseId);

    const valueBucket: relationalStore.ValuesBucket = {
      assessment_generating: 0
    };
    const coursePred = new relationalStore.RdbPredicates('courses');
    coursePred.equalTo('id', courseId);
    await this.getStore().update(valueBucket, coursePred);
  }
}

class CourseImpl implements Course {
  id: string = '';
  name: string = '';
  question: string = '';
  status: CourseStatus = 'created';
  mentalModelGenerated: boolean = false;
  controversyGenerated: boolean = false;
  assessmentGenerating: boolean = false;
  createdAt: number = 0;
  updatedAt: number = 0;
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

class KnowledgeSourceImpl implements KnowledgeSource {
  id: string = '';
  courseId: string = '';
  nodeId: string = '';
  title: string = '';
  url: string = '';
  type: 'web' | 'user' = 'web';
}

class DiscussionImpl implements Discussion {
  id: string = '';
  controversyId: string = '';
  courseId: string = '';
  createdAt: number = 0;
}

class DiscussionMessageImpl implements DiscussionMessage {
  id: string = '';
  discussionId: string = '';
  role: 'user' | 'assistant' = 'user';
  content: string = '';
  createdAt: number = 0;
}

class DiscussionSummaryImpl implements DiscussionSummary {
  id: string = '';
  discussionId: string = '';
  summary: string = '';
  createdAt: number = 0;
}

class FollowUpImpl implements FollowUp {
  id: string = '';
  assessmentId: string = '';
  role: 'user' | 'assistant' = 'user';
  content: string = '';
  createdAt: number = 0;
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

class CourseStatsImpl implements CourseStats {
  totalCourses: number = 0;
  completedCourses: number = 0;
  totalAssessments: number = 0;
  averageScore: number = 0;
}

class CourseDimensionScoreImpl implements CourseDimensionScore {
  courseName: string = '';
  conceptUnderstanding: number = 0;
  criticalThinking: number = 0;
  practicalTransfer: number = 0;
}

class ArchiveAssessmentImpl implements ArchiveAssessment {
  id: string = '';
  originalCourseId: string = '';
  originalCourseName: string = '';
  bloomLevel: BloomLevel = 'understand';
  questionType: QuestionType = 'subjective';
  question: string = '';
  answer: string = '';
  options: string = '';
  correctAnswer: string = '';
  userAnswer: string = '';
  isCorrect: boolean = false;
  createdAt: number = 0;
  archivedAt: number = 0;
}

class ArchiveFollowUpImpl implements ArchiveFollowUp {
  id: string = '';
  archiveAssessmentId: string = '';
  role: 'user' | 'assistant' = 'user';
  content: string = '';
  createdAt: number = 0;
}
