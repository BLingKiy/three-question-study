export interface NodePosition {
  x: number;
  y: number;
}

export interface KnowledgeNode {
  id: string;
  courseId: string;
  type: 'concept' | 'controversy' | 'evidence';
  label: string;
  content?: string;
  position: NodePosition;
}
