import { DiscussionMessage, DiscussionSummary } from '../model/Discussion';
import { RDBService } from '../services/RDBService';
import { DiscussionService } from '../services/DiscussionService';
import { DeepseekService } from '../services/DeepseekService';
import { PreferencesService } from '../services/PreferencesService';
import { MarkdownUtil, MdBlock, MdSpan } from '../utils/MarkdownUtil';
import router from '@ohos.router';

@Entry
@Component
struct DiscussionThreadPage {
  @State controversyId: string = '';
  @State courseId: string = '';
  @State controversyTopic: string = '';
  @State messages: DiscussionMessage[] = [];
  @State summary: DiscussionSummary | null = null;
  @State inputText: string = '';
  @State isLoading: boolean = true;
  @State isSending: boolean = false;
  @State isGeneratingSummary: boolean = false;
  @State errorMessage: string = '';

  private rdbService: RDBService | null = null;
  private discussionService: DiscussionService | null = null;
  private discussionId: string = '';

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    if (params) {
      this.controversyId = params['controversyId'] || '';
      this.courseId = params['courseId'] || '';
      this.controversyTopic = params['controversyTopic'] || '';
    }
    this.initializeServices(getContext(this));
  }

  private async initializeServices(context: Context): Promise<void> {
    try {
      this.rdbService = new RDBService(context);
      await this.rdbService.initialize();
      this.discussionService = new DiscussionService(this.rdbService);

      const discussion = await this.discussionService.createDiscussion(this.controversyId, this.courseId);
      this.discussionId = discussion.id;
      this.messages = await this.discussionService.getMessages(this.discussionId);
      this.summary = await this.discussionService.getSummary(this.discussionId);
    } catch (err) {
      this.errorMessage = '初始化失败：' + (err as Error).message;
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      Row() {
        Image($r('app.media.ic_arrow_left'))
          .width(24)
          .height(24)
          .fillColor($r('app.color.text_primary'))
          .onClick(() => {
            router.back();
          })

        Text(this.controversyTopic || '讨论')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .margin({ left: 16 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      if (this.errorMessage) {
        Text(this.errorMessage)
          .fontSize(14)
          .fontColor($r('app.color.error_color'))
          .width('100%')
          .padding(16)
      }

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color($r('app.color.tech_blue_primary'))
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column() {
            if (this.messages.length === 0) {
              Column() {
                Text('开始讨论吧，分享你对这个争议点的看法')
                  .fontSize(16)
                  .fontColor($r('app.color.text_secondary'))
              }
              .width('100%')
              .padding(32)
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
            }

            ForEach(this.messages, (msg: DiscussionMessage) => {
              Row() {
                if (msg.role === 'user') {
                  Blank()
                }

                Column() {
                  Text(msg.role === 'user' ? '👤 你' : '🤖 AI')
                    .fontSize(12)
                    .fontColor($r('app.color.text_secondary'))
                    .margin({ bottom: 4 })

                  if (msg.role === 'user') {
                    Text(msg.content)
                      .fontSize(14)
                      .fontColor($r('app.color.text_primary'))
                  } else {
                    this.MarkdownContent(MarkdownUtil.parse(msg.content))
                  }
                }
                .padding(12)
                .backgroundColor(msg.role === 'user' ? $r('app.color.user_bubble_background') : $r('app.color.assistant_bubble_background'))
                .borderRadius(12)
                .shadow(msg.role === 'assistant' ? { radius: 4, color: '#1A000000', offsetX: 0, offsetY: 1 } : { radius: 0, color: Color.Transparent, offsetX: 0, offsetY: 0 })
                .alignItems(HorizontalAlign.Start)
                .width(msg.role === 'assistant' ? '85%' : '')
                .constraintSize({ maxWidth: '85%' })

                if (msg.role === 'assistant') {
                  Blank()
                }
              }
              .width('100%')
              .margin({ bottom: 12 })
            })

            if (this.summary) {
              Column() {
                Text('📋 讨论总结')
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .width('100%')
                  .margin({ bottom: 8 })

                this.MarkdownContent(MarkdownUtil.parse(this.summary.summary))
              }
              .width('100%')
              .padding(16)
              .backgroundColor($r('app.color.card_background'))
              .borderRadius(12)
              .margin({ top: 16 })
            }
          }
          .width('100%')
          .padding(16)
        }
        .layoutWeight(1)

        Column() {
          Row() {
            TextInput({ placeholder: '输入你的观点...' })
              .layoutWeight(1)
              .height(40)
              .enabled(!this.isSending)
              .onChange((value: string) => {
                this.inputText = value;
              })

            Button('发送')
              .height(40)
              .backgroundColor($r('app.color.tech_blue_primary'))
              .enabled(!this.isSending && this.inputText.length > 0)
              .onClick(() => {
                this.handleSend();
              })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })

          Row() {
            Blank()

            Button(this.isGeneratingSummary ? '生成中...' : (this.summary ? '重新总结' : '生成总结'))
              .fontSize(12)
              .height(32)
              .backgroundColor(Color.Transparent)
              .fontColor($r('app.color.tech_blue_primary'))
              .borderWidth(1)
              .borderColor($r('app.color.tech_blue_primary'))
              .enabled(!this.isGeneratingSummary)
              .onClick(() => {
                this.handleGenerateSummary();
              })
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 8 })
        }
        .backgroundColor($r('app.color.card_background'))
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
  }

  @Builder
  MarkdownContent(blocks: MdBlock[]): void {
    Column() {
      ForEach(blocks, (block: MdBlock, index: number) => {
        if (block.type === 'heading') {
          Text(block.text)
            .fontSize(block.level === 3 ? 16 : 15)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
            .margin({ top: 8, bottom: 4 })
            .width('100%')
        } else if (block.type === 'paragraph') {
          this.SpanRow(block.spans)
        } else if (block.type === 'listItem') {
          this.SpanRow(this.listPrefixSpans(block))
        } else if (block.type === 'codeBlock') {
          Scroll() {
            Text(block.text)
              .fontSize(13)
              .fontColor($r('app.color.text_primary'))
              .fontFamily('monospace')
          }
          .width('100%')
          .padding(8)
          .backgroundColor($r('app.color.input_background'))
          .borderRadius(6)
          .margin({ top: 4, bottom: 4 })
          .scrollable(ScrollDirection.Horizontal)
        }
      }, (_block: MdBlock, index: number) => `${index}`)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  private listPrefixSpans(block: MdBlock): MdSpan[] {
    const prefix = block.ordered ? `${block.index}. ` : '• ';
    const result: MdSpan[] = [{ type: 'normal', text: prefix }];
    for (let i = 0; i < block.spans.length; i++) {
      result.push(block.spans[i]);
    }
    return result;
  }

  @Builder
  SpanRow(spans: MdSpan[]): void {
    Text() {
      ForEach(spans, (span: MdSpan, idx: number) => {
        Span(span.text)
          .fontSize(14)
          .fontWeight(span.type === 'bold' ? FontWeight.Bold : FontWeight.Normal)
          .fontStyle(span.type === 'italic' ? FontStyle.Italic : FontStyle.Normal)
          .fontColor(span.type === 'code' ? '#D32F2F' : $r('app.color.text_primary'))
          .fontFamily(span.type === 'code' ? 'monospace' : 'sans-serif')
      }, (_span: MdSpan, idx: number) => `${idx}`)
    }
    .width('100%')
  }

  private async handleSend(): Promise<void> {
    if (!this.discussionService || !this.inputText) return;

    const text = this.inputText;
    this.inputText = '';
    this.isSending = true;
    this.errorMessage = '';

    try {
      await this.discussionService.sendMessage(this.discussionId, text);
      this.messages = await this.discussionService.getMessages(this.discussionId);

      const preferencesService = new PreferencesService(getContext(this));
      await preferencesService.initialize();
      const deepseekService = new DeepseekService(preferencesService);
      await this.discussionService.generateAiReply(this.discussionId, this.controversyTopic, deepseekService);
      this.messages = await this.discussionService.getMessages(this.discussionId);
    } catch (err) {
      this.errorMessage = 'AI 回复生成失败：' + (err as Error).message;
    } finally {
      this.isSending = false;
    }
  }

  private async handleGenerateSummary(): Promise<void> {
    if (!this.discussionService) return;

    this.isGeneratingSummary = true;
    this.errorMessage = '';

    try {
      const preferencesService = new PreferencesService(getContext(this));
      await preferencesService.initialize();
      const deepseekService = new DeepseekService(preferencesService);
      this.summary = await this.discussionService.generateSummary(this.discussionId, this.controversyTopic, deepseekService);
    } catch (err) {
      this.errorMessage = '总结生成失败：' + (err as Error).message;
    } finally {
      this.isGeneratingSummary = false;
    }
  }
}
