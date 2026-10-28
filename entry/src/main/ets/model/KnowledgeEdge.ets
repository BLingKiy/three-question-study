export type EdgeType = 'supports' | 'opposes' | 'relates';

export interface KnowledgeEdge {
  id: string;
  courseId: string;
  fromNodeId: string;
  toNodeId: string;
  type: EdgeType;
  weight: number;
}
