import axios, { AxiosInstance, AxiosRequestConfig, AxiosResponse, AxiosError } from '@ohos/axios';
import { PreferencesService } from './PreferencesService';

const DEEPSEEK_API_URL = 'https://api.deepseek.com/v1/chat/completions';
const DEEPSEEK_ANTHROPIC_URL = 'https://api.deepseek.com/anthropic/v1/messages';
const TIMEOUT = 30000;
const MAX_RETRIES = 3;

export interface ChatMessage {
  role: 'system' | 'user' | 'assistant';
  content: string;
}

export interface ChatCompletionChoice {
  message: ChatCompletionMessage;
  finish_reason: string;
}

export interface ChatCompletionMessage {
  role: string;
  content: string;
}

export interface ChatCompletionUsage {
  prompt_tokens: number;
  completion_tokens: number;
  total_tokens: number;
}

export interface ChatCompletionResponse {
  id: string;
  choices: ChatCompletionChoice[];
  usage: ChatCompletionUsage;
}

class ValidateRequestData {
  model: string = '';
  messages: ChatMessage[] = [];
  max_tokens: number = 1;
}

class ChatRequestData {
  model: string = '';
  messages: ChatMessage[] = [];
  temperature: number = 0.7;
  max_tokens: number = 4000;
}

class ValidateMessage implements ChatMessage {
  role: 'system' | 'user' | 'assistant' = 'user';
  content: string = '';
}

export interface WebSearchResult {
  title: string;
  url: string;
}

export interface WebSearchResponse {
  content: string;
  searchResults: WebSearchResult[];
}

class AnthropicMessage {
  role: string = '';
  content: string = '';
}

class AnthropicTool {
  type: string = '';
  name: string = '';
}

class AnthropicRequestData {
  model: string = '';
  messages: AnthropicMessage[] = [];
  tools: AnthropicTool[] = [];
  max_tokens: number = 8000;
}

export class DeepseekService {
  private preferencesService: PreferencesService;
  private client: AxiosInstance;

  constructor(preferencesService: PreferencesService) {
    this.preferencesService = preferencesService;

    this.client = axios.create({
      timeout: TIMEOUT,
      headers: {
        'Content-Type': 'application/json'
      }
    });
  }

  private async getApiKey(): Promise<string> {
    const apiKey = await this.preferencesService.getApiKey();
    if (!apiKey) {
      throw new Error('API密钥未配置，请先在设置中配置Deepseek API密钥');
    }
    return apiKey;
  }

  async chatCompletion(
    messages: ChatMessage[],
    temperature: number = 0.7,
    maxTokens: number = 4000
  ): Promise<string> {
    const apiKey = await this.getApiKey();

    const requestData = new ChatRequestData();
    requestData.model = 'deepseek-chat';
    requestData.messages = messages;
    requestData.temperature = temperature;
    requestData.max_tokens = maxTokens;

    const config: AxiosRequestConfig = {
      method: 'POST',
      url: DEEPSEEK_API_URL,
      headers: {
        'Authorization': `Bearer ${apiKey}`
      },
      data: requestData
    };

    let lastError: Error | null = null;

    for (let attempt = 1; attempt <= MAX_RETRIES; attempt++) {
      try {
        const response: AxiosResponse<ChatCompletionResponse> = await this.client.request(config);

        if (response.data && response.data.choices && response.data.choices.length > 0) {
          return response.data.choices[0].message.content;
        }

        throw new Error('API返回数据格式错误');
      } catch (err) {
        const errorObj = err as Error;
        lastError = errorObj;

        if (errorObj.message && errorObj.message.includes('401')) {
          throw new Error('API密钥无效，请检查配置');
        }
        if (errorObj.message && errorObj.message.includes('429')) {
          if (attempt < MAX_RETRIES) {
            await this.sleep(1000 * attempt);
            continue;
          }
          throw new Error('API请求过于频繁，请稍后重试');
        }
        if (errorObj.message && (errorObj.message.includes('timeout') || errorObj.message.includes('ECONNABORTED'))) {
          if (attempt < MAX_RETRIES) {
            continue;
          }
          throw new Error('请求超时，请检查网络连接');
        }

        console.error(`[DeepseekService] Attempt ${attempt} failed:`, err);
      }
    }

    throw lastError || new Error('请求失败，请重试');
  }

  private sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  async webSearch(query: string): Promise<WebSearchResponse> {
    const apiKey = await this.getApiKey();

    const msg = new AnthropicMessage();
    msg.role = 'user';
    msg.content = query;

    const tool = new AnthropicTool();
    tool.type = 'web_search_20260209';
    tool.name = 'web_search';

    const requestData = new AnthropicRequestData();
    requestData.model = 'deepseek-v4-flash';
    requestData.messages = [msg];
    requestData.tools = [tool];
    requestData.max_tokens = 8000;

    const config: AxiosRequestConfig = {
      method: 'POST',
      url: DEEPSEEK_ANTHROPIC_URL,
      headers: {
        'x-api-key': apiKey,
        'Content-Type': 'application/json'
      },
      data: requestData
    };

    let lastError: Error | null = null;

    for (let attempt = 1; attempt <= MAX_RETRIES; attempt++) {
      try {
        const response: AxiosResponse<Object> = await this.client.request(config);
        const data = response.data as Record<string, Object>;

        let textContent = '';
        const searchResults: WebSearchResult[] = [];

        if (data && Array.isArray(data['content'])) {
          const contentBlocks = data['content'] as Record<string, Object>[];
          for (const block of contentBlocks) {
            if (block['type'] === 'text' && typeof block['text'] === 'string') {
              textContent = block['text'] as string;
            }
            if (block['type'] === 'web_search_tool_result' && Array.isArray(block['content'])) {
              const results = block['content'] as Record<string, Object>[];
              for (const r of results) {
                if (r['type'] === 'web_search_result') {
                  const sr = new WebSearchResultImpl();
                  sr.title = String(r['title'] || '');
                  sr.url = String(r['url'] || '');
                  if (sr.url.length > 0) {
                    searchResults.push(sr);
                  }
                }
              }
            }
          }
        }

        const result = new WebSearchResponseImpl();
        result.content = textContent;
        result.searchResults = searchResults;
        return result;
      } catch (err) {
        const errorObj = err as Error;
        lastError = errorObj;

        if (errorObj.message && errorObj.message.includes('401')) {
          throw new Error('API密钥无效，请检查配置');
        }
        if (errorObj.message && errorObj.message.includes('429')) {
          if (attempt < MAX_RETRIES) {
            await this.sleep(1000 * attempt);
            continue;
          }
          throw new Error('API请求过于频繁，请稍后重试');
        }
        if (errorObj.message && (errorObj.message.includes('timeout') || errorObj.message.includes('ECONNABORTED'))) {
          if (attempt < MAX_RETRIES) {
            continue;
          }
          throw new Error('WebSearch请求超时，请检查网络连接');
        }

        console.error(`[DeepseekService] WebSearch attempt ${attempt} failed:`, err);
      }
    }

    throw lastError || new Error('WebSearch请求失败，请重试');
  }

  async validateApiKey(apiKey: string): Promise<boolean> {
    try {
      const msg = new ValidateMessage();
      msg.role = 'user';
      msg.content = 'test';

      const data = new ValidateRequestData();
      data.model = 'deepseek-chat';
      data.messages = [msg];
      data.max_tokens = 1;

      await this.client.request({
        method: 'POST',
        url: DEEPSEEK_API_URL,
        headers: {
          'Authorization': `Bearer ${apiKey}`
        },
        data: data
      });
      return true;
    } catch (err) {
      const errorObj = err as Error;
      if (errorObj.message && errorObj.message.includes('401')) {
        return false;
      }
      return true;
    }
  }
}

class WebSearchResultImpl implements WebSearchResult {
  title: string = '';
  url: string = '';
}

class WebSearchResponseImpl implements WebSearchResponse {
  content: string = '';
  searchResults: WebSearchResult[] = [];
}
