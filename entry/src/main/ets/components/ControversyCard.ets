import { ParsedControversy } from '../services/ResponseParser';
import router from '@ohos.router';

@Component
export struct ControversyCard {
  @Prop controversy: ParsedControversy | null = null;
  @Prop courseId: string = '';
  @Prop checked: boolean = false;
  onCheckChange: () => void = () => {};

  build() {
    Column() {
      Row() {
        Text(this.controversy?.topic || '争议主题')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)

        Text(this.checked ? '✅' : '⬜')
          .fontSize(22)
          .onClick(() => {
            this.onCheckChange();
          })
      }
      .width('100%')
      .margin({ bottom: 16 })

      Row() {
        Column() {
          Text(this.controversy?.leftView.title || '观点A')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.tech_blue_primary'))
            .width('100%')
            .margin({ bottom: 8 })

          ForEach(this.controversy?.leftView.arguments || [], (arg: string) => {
            Row() {
              Text('•')
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
                .margin({ right: 4 })

              Text(arg)
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
                .layoutWeight(1)
            }
            .width('100%')
            .margin({ bottom: 4 })
          })

          if ((this.controversy?.leftView.evidence?.length || 0) > 0) {
            Text('证据：')
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
              .width('100%')
              .margin({ top: 8, bottom: 4 })

            ForEach(this.controversy?.leftView.evidence || [], (ev: string) => {
              Text(ev)
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
                .width('100%')
                .margin({ bottom: 2 })
            })
          }
        }
        .layoutWeight(1)
        .padding(12)
        .backgroundColor($r('app.color.tech_blue_light'))
        .borderRadius(8)

        Blank().width(12)

        Column() {
          Text(this.controversy?.rightView.title || '观点B')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.error_color'))
            .width('100%')
            .margin({ bottom: 8 })

          ForEach(this.controversy?.rightView.arguments || [], (arg: string) => {
            Row() {
              Text('•')
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
                .margin({ right: 4 })

              Text(arg)
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
                .layoutWeight(1)
            }
            .width('100%')
            .margin({ bottom: 4 })
          })

          if ((this.controversy?.rightView.evidence?.length || 0) > 0) {
            Text('证据：')
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
              .width('100%')
              .margin({ top: 8, bottom: 4 })

            ForEach(this.controversy?.rightView.evidence || [], (ev: string) => {
              Text(ev)
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
                .width('100%')
                .margin({ bottom: 2 })
            })
          }
        }
        .layoutWeight(1)
        .padding(12)
        .backgroundColor('#FFF3E0')
        .borderRadius(8)
      }
      .width('100%')

      if (this.controversy?.synthesis) {
        Column() {
          Text('综合分析')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
            .width('100%')
            .margin({ bottom: 8 })

          Text(this.controversy.synthesis)
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
        }
        .width('100%')
        .padding(12)
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
        .margin({ top: 12 })
      }

      Row() {
        Blank()

        Text('💬')
          .fontSize(24)
          .margin({ top: 8 })
          .onClick(() => {
            if (this.controversy) {
              router.pushUrl({
                url: 'pages/DiscussionThreadPage',
                params: {
                  controversyId: this.controversy.id,
                  courseId: this.courseId,
                  controversyTopic: this.controversy.topic
                }
              });
            }
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .shadow({ radius: 8, color: '#1A000000', offsetX: 0, offsetY: 2 })
  }
}
