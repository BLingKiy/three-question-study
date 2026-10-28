export interface KnowledgeSource {
  id: string;
  courseId: string;
  nodeId: string;
  title: string;
  url: string;
  type: 'web' | 'user';
}