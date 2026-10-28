import { RDBService } from './RDBService';
import { DeepseekService, ChatMessage } from './DeepseekService';
import { Discussion, DiscussionMessage, DiscussionSummary } from '../model/Discussion';
import { generateUUID } from '../utils/UUIDUtil';

export class DiscussionService {
  private rdbService: RDBService;

  constructor(rdbService: RDBService) {
    this.rdbService = rdbService;
  }

  async createDiscussion(controversyId: string, courseId: string): Promise<Discussion> {
    const existing = await this.rdbService.queryDiscussionByControversyId(controversyId);
    if (existing) return existing;

    const discussion = new DiscussionImpl();
    discussion.id = generateUUID();
    discussion.controversyId = controversyId;
    discussion.courseId = courseId;
    discussion.createdAt = Date.now();
    await this.rdbService.insertDiscussion(discussion);
    return discussion;
  }

  async getDiscussionByControversyId(controversyId: string): Promise<Discussion | null> {
    return await this.rdbService.queryDiscussionByControversyId(controversyId);
  }

  async getDiscussionsByCourseId(courseId: string): Promise<Discussion[]> {
    return await this.rdbService.queryDiscussionsByCourseId(courseId);
  }

  async sendMessage(discussionId: string, content: string): Promise<DiscussionMessage> {
    const message = new DiscussionMessageImpl();
    message.id = generateUUID();
    message.discussionId = discussionId;
    message.role = 'user';
    message.content = content;
    message.createdAt = Date.now();
    await this.rdbService.insertDiscussionMessage(message);
    return message;
  }

  async getMessages(discussionId: string): Promise<DiscussionMessage[]> {
    return await this.rdbService.queryDiscussionMessages(discussionId);
  }

  async generateAiReply(
    discussionId: string,
    controversyTopic: string,
    deepseekService: DeepseekService
  ): Promise<DiscussionMessage> {
    const messages = await this.getMessages(discussionId);

    const chatMessages: ChatMessage[] = [];
    const sysMsg = new SystemChatMessageImpl();
    sysMsg.role = 'system';
    sysMsg.content = `你是一位学术讨论助手。用户正在讨论争议话题："${controversyTopic}"。请提供深入的分析、不同视角的观点，或对用户观点的建设性反馈。回复要简洁有深度。`;
    chatMessages.push(sysMsg);

    for (const m of messages) {
      const cm = new ChatMessageImpl();
      cm.role = m.role === 'user' ? 'user' : 'assistant';
      cm.content = m.content;
      chatMessages.push(cm);
    }

    const reply = await deepseekService.chatCompletion(chatMessages, 0.7, 2000);

    const aiMessage = new DiscussionMessageImpl();
    aiMessage.id = generateUUID();
    aiMessage.discussionId = discussionId;
    aiMessage.role = 'assistant';
    aiMessage.content = reply;
    aiMessage.createdAt = Date.now();
    await this.rdbService.insertDiscussionMessage(aiMessage);
    return aiMessage;
  }

  async generateSummary(
    discussionId: string,
    controversyTopic: string,
    deepseekService: DeepseekService
  ): Promise<DiscussionSummary> {
    const messages = await this.getMessages(discussionId);

    const chatMessages: ChatMessage[] = [];
    const sysMsg = new SystemChatMessageImpl();
    sysMsg.role = 'system';
    sysMsg.content = `你是一位学术讨论总结专家。请对以下关于"${controversyTopic}"的讨论进行总结，包括：1. 主要观点归纳 2. 关键分歧点 3. 共识与建议。回复要结构化、简洁。`;
    chatMessages.push(sysMsg);

    let discussionText = '';
    for (const m of messages) {
      discussionText += `${m.role === 'user' ? '用户' : 'AI'}：${m.content}\n\n`;
    }
    const userMsg = new ChatMessageImpl();
    userMsg.role = 'user';
    userMsg.content = discussionText;
    chatMessages.push(userMsg);

    const summaryText = await deepseekService.chatCompletion(chatMessages, 0.5, 2000);

    const summary = new DiscussionSummaryImpl();
    summary.id = generateUUID();
    summary.discussionId = discussionId;
    summary.summary = summaryText;
    summary.createdAt = Date.now();
    await this.rdbService.insertDiscussionSummary(summary);
    return summary;
  }

  async getSummary(discussionId: string): Promise<DiscussionSummary | null> {
    return await this.rdbService.queryDiscussionSummary(discussionId);
  }
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

class SystemChatMessageImpl implements ChatMessage {
  role: 'system' | 'user' | 'assistant' = 'system';
  content: string = '';
}

class ChatMessageImpl implements ChatMessage {
  role: 'system' | 'user' | 'assistant' = 'user';
  content: string = '';
}