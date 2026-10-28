import common from '@ohos.app.ability.common';
import { KnowledgeNode } from '../model/KnowledgeNode';
import { KnowledgeEdge, EdgeType } from '../model/KnowledgeEdge';
import { KnowledgeSource } from '../model/KnowledgeSource';

export interface ParsedControversyContent {
  topic: string;
  leftTitle: string;
  leftArguments: string[];
  leftEvidence: string[];
  rightTitle: string;
  rightArguments: string[];
  rightEvidence: string[];
  synthesis: string;
}

@Component
export struct NodeDetailSheet {
  @Prop node: KnowledgeNode | null = null;
  @Prop incomingEdges: KnowledgeEdge[] = [];
  @Prop outgoingEdges: KnowledgeEdge[] = [];
  @Prop sources: KnowledgeSource[] = [];
  @Prop allNodes: KnowledgeNode[] = [];

  private parsedControversy: ParsedControversyContent | null = null;

  aboutToAppear(): void {
    this.parseControversyContent();
  }

  aboutToUpdate(): void {
    this.parseControversyContent();
  }

  private parseControversyContent(): void {
    this.parsedControversy = null;
    if (!this.node || this.node.type !== 'controversy' || !this.node.content) return;

    try {
      const data = JSON.parse(this.node.content) as Record<string, Object>;
      const result = new ParsedControversyContentImpl();
      result.topic = String(data['topic'] || '');

      const leftData = (data['leftView'] || {}) as Record<string, Object>;
      result.leftTitle = String(leftData['title'] || '观点A');
      result.leftArguments = Array.isArray(leftData['arguments']) ? (leftData['arguments'] as string[]) : [];
      result.leftEvidence = Array.isArray(leftData['evidence']) ? (leftData['evidence'] as string[]) : [];

      const rightData = (data['rightView'] || {}) as Record<string, Object>;
      result.rightTitle = String(rightData['title'] || '观点B');
      result.rightArguments = Array.isArray(rightData['arguments']) ? (rightData['arguments'] as string[]) : [];
      result.rightEvidence = Array.isArray(rightData['evidence']) ? (rightData['evidence'] as string[]) : [];

      result.synthesis = String(data['synthesis'] || '');
      this.parsedControversy = result;
    } catch (e) {
      this.parsedControversy = null;
    }
  }

  build() {
    Scroll() {
      Column() {
        if (this.node) {
          Row() {
            Text(this.getTypeBadge(this.node.type))
              .fontSize(12)
              .fontColor(Color.White)
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .borderRadius(12)
              .backgroundColor(this.getTypeColor(this.node.type))
              .margin({ right: 12 })

            Text(this.node.label)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .layoutWeight(1)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
          .padding({ right: 40 })
          .margin({ bottom: 16 })
          .alignItems(VerticalAlign.Center)

          if (this.parsedControversy) {
            this.ControversyContent()
          } else if (this.node.content) {
            Text(this.getDisplayContent(this.node))
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
              .width('100%')
              .margin({ bottom: 16 })
              .lineHeight(22)
          }

          if (this.incomingEdges.length > 0) {
            Text('← 关联')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .width('100%')
              .margin({ bottom: 8 })

            ForEach(this.incomingEdges, (edge: KnowledgeEdge) => {
              Row() {
                Text(this.getNodeLabel(edge.fromNodeId))
                  .fontSize(14)
                  .fontColor($r('app.color.tech_blue_primary'))
                  .layoutWeight(1)

                Text(this.getEdgeTypeLabel(edge.type))
                  .fontSize(12)
                  .fontColor($r('app.color.text_secondary'))
                  .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                  .borderRadius(8)
                  .backgroundColor('#F0F0F0')
              }
              .width('100%')
              .padding({ top: 4, bottom: 4 })
            })
          }

          if (this.outgoingEdges.length > 0) {
            Text('→ 关联')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .width('100%')
              .margin({ top: 12, bottom: 8 })

            ForEach(this.outgoingEdges, (edge: KnowledgeEdge) => {
              Row() {
                Text(this.getNodeLabel(edge.toNodeId))
                  .fontSize(14)
                  .fontColor($r('app.color.tech_blue_primary'))
                  .layoutWeight(1)

                Text(this.getEdgeTypeLabel(edge.type))
                  .fontSize(12)
                  .fontColor($r('app.color.text_secondary'))
                  .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                  .borderRadius(8)
                  .backgroundColor('#F0F0F0')
              }
              .width('100%')
              .padding({ top: 4, bottom: 4 })
            })
          }

          if (this.incomingEdges.length === 0 && this.outgoingEdges.length === 0) {
            Text('暂无关联关系')
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
              .width('100%')
              .margin({ top: 8 })
          }

          if (this.sources.length > 0) {
            Text('来源')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .width('100%')
              .margin({ top: 16, bottom: 8 })

            ForEach(this.sources, (source: KnowledgeSource) => {
              Row() {
                Text('🔗')
                  .fontSize(14)
                  .margin({ right: 8 })

                Text(source.title || source.url)
                  .fontSize(14)
                  .fontColor($r('app.color.tech_blue_primary'))
                  .layoutWeight(1)
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width('100%')
              .padding({ top: 4, bottom: 4 })
              .onClick(() => {
                this.openUrl(source.url);
              })
            })
          }
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 20, bottom: 16 })
    }
    .width('100%')

    .backgroundColor(Color.White)
    .borderRadius({ topLeft: 24, topRight: 24 })
  }

  @Builder
  ControversyContent(): void {
    Column() {

      if (this.parsedControversy) {
        Column() {
          Text(this.parsedControversy.leftTitle)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.tech_blue_primary'))
            .width('100%')
            .margin({ bottom: 6 })

          ForEach(this.parsedControversy.leftArguments, (arg: string) => {
            Row() {
              Text('•')
                .fontSize(13)
                .fontColor($r('app.color.text_secondary'))
                .margin({ right: 6 })
              Text(arg)
                .fontSize(13)
                .fontColor($r('app.color.text_secondary'))
                .layoutWeight(1)
            }
            .width('100%')
            .margin({ bottom: 3 })
          })

          if (this.parsedControversy.leftEvidence.length > 0) {
            Text('证据：')
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
              .width('100%')
              .margin({ top: 6, bottom: 3 })
            ForEach(this.parsedControversy.leftEvidence, (ev: string) => {
              Text(ev)
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
                .width('100%')
                .margin({ bottom: 2 })
            })
          }
        }
        .width('100%')
        .padding(10)
        .backgroundColor($r('app.color.tech_blue_light'))
        .borderRadius(8)
        .margin({ bottom: 8 })

        Column() {
          Text(this.parsedControversy.rightTitle)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.error_color'))
            .width('100%')
            .margin({ bottom: 6 })

          ForEach(this.parsedControversy.rightArguments, (arg: string) => {
            Row() {
              Text('•')
                .fontSize(13)
                .fontColor($r('app.color.text_secondary'))
                .margin({ right: 6 })
              Text(arg)
                .fontSize(13)
                .fontColor($r('app.color.text_secondary'))
                .layoutWeight(1)
            }
            .width('100%')
            .margin({ bottom: 3 })
          })

          if (this.parsedControversy.rightEvidence.length > 0) {
            Text('证据：')
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
              .width('100%')
              .margin({ top: 6, bottom: 3 })
            ForEach(this.parsedControversy.rightEvidence, (ev: string) => {
              Text(ev)
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
                .width('100%')
                .margin({ bottom: 2 })
            })
          }
        }
        .width('100%')
        .padding(10)
        .backgroundColor('#FFF3E0')
        .borderRadius(8)
        .margin({ bottom: 8 })

        if (this.parsedControversy.synthesis) {
          Column() {
            Text('综合分析')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
              .width('100%')
              .margin({ bottom: 6 })

            Text(this.parsedControversy.synthesis)
              .fontSize(13)
              .fontColor($r('app.color.text_secondary'))
              .width('100%')
              .lineHeight(20)
          }
          .width('100%')
          .padding(10)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
        }
      }
    }
    .width('100%')
    .margin({ bottom: 16 })
  }

  private getDisplayContent(node: KnowledgeNode): string {
    if (node.type !== 'controversy' || !node.content) {
      return node.content || '';
    }
    try {
      const data = JSON.parse(node.content) as Record<string, Object>;
      const parts: string[] = [];
      if (data['topic']) {
        parts.push('争议主题：' + String(data['topic']));
      }
      const leftData = (data['leftView'] || {}) as Record<string, Object>;
      if (leftData['title']) {
        parts.push('观点A：' + String(leftData['title']));
      }
      const leftArgs = leftData['arguments'];
      if (Array.isArray(leftArgs) && (leftArgs as string[]).length > 0) {
        parts.push('论点：' + (leftArgs as string[]).join('；'));
      }
      const rightData = (data['rightView'] || {}) as Record<string, Object>;
      if (rightData['title']) {
        parts.push('观点B：' + String(rightData['title']));
      }
      const rightArgs = rightData['arguments'];
      if (Array.isArray(rightArgs) && (rightArgs as string[]).length > 0) {
        parts.push('论点：' + (rightArgs as string[]).join('；'));
      }
      if (data['synthesis']) {
        parts.push('综合分析：' + String(data['synthesis']));
      }
      return parts.length > 0 ? parts.join('\n\n') : node.label;
    } catch (e) {
      return node.label;
    }
  }

  private getTypeBadge(type: string): string {
    if (type === 'concept') return '概念';
    if (type === 'controversy') return '争议';
    if (type === 'evidence') return '证据';
    return type;
  }

  private getTypeColor(type: string): string {
    if (type === 'concept') return '#0066CC';
    if (type === 'controversy') return '#FF9800';
    if (type === 'evidence') return '#4CAF50';
    return '#666666';
  }

  private getNodeLabel(nodeId: string): string {
    const found = this.allNodes.find(n => n.id === nodeId);
    return found ? found.label : nodeId;
  }

  private getEdgeTypeLabel(type: EdgeType): string {
    if (type === 'supports') return '支持';
    if (type === 'opposes') return '反对';
    return '相关';
  }

  private openUrl(url: string): void {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      context.openLink(url);
    } catch (e) {
      console.warn('[NodeDetailSheet] Failed to open URL:', url, e);
    }
  }
}

class ParsedControversyContentImpl implements ParsedControversyContent {
  topic: string = '';
  leftTitle: string = '观点A';
  leftArguments: string[] = [];
  leftEvidence: string[] = [];
  rightTitle: string = '观点B';
  rightArguments: string[] = [];
  rightEvidence: string[] = [];
  synthesis: string = '';
}
