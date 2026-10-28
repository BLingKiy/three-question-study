export interface Discussion {
  id: string;
  controversyId: string;
  courseId: string;
  createdAt: number;
}

export interface DiscussionMessage {
  id: string;
  discussionId: string;
  role: 'user' | 'assistant';
  content: string;
  createdAt: number;
}

export interface DiscussionSummary {
  id: string;
  discussionId: string;
  summary: string;
  createdAt: number;
}