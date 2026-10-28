export type CourseStatus = 'created' | 'active' | 'completed' | 'archived';

export interface Course {
  id: string;
  name: string;
  question: string;
  status: CourseStatus;
  mentalModelGenerated: boolean;
  controversyGenerated: boolean;
  assessmentGenerating: boolean;
  createdAt: number;
  updatedAt: number;
}

export interface CourseCreateInput {
  name: string;
  question: string;
}
