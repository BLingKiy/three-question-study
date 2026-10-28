@Component
export struct ErrorDialog {
  @Prop message: string = '发生错误';
  @Prop showRetry: boolean = true;
  @State isVisible: boolean = false;
  onRetry?: () => void;
  onDismiss?: () => void;

  build() {
    if (this.isVisible) {
      Column() {
        Column() {
          // Icon
          Image($r('app.media.ic_fail'))
            .width(48)
            .height(48)
            .fillColor($r('app.color.error_color'))
            .margin({ bottom: 16 })

          // Message
          Text(this.message)
            .fontSize(16)
            .fontColor($r('app.color.text_primary'))
            .textAlign(TextAlign.Center)
            .margin({ bottom: 24 })

          // Buttons
          Row() {
            if (this.showRetry) {
              Button('重试')
                .fontSize(14)
                .fontColor(Color.White)
                .backgroundColor($r('app.color.tech_blue_primary'))
                .borderRadius(8)
                .width(100)
                .height(36)
                .onClick(() => {
                  this.isVisible = false;
                  if (this.onRetry) {
                    this.onRetry();
                  }
                })
            }

            Button('关闭')
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
              .backgroundColor(Color.Transparent)
              .border({
                width: 1,
                color: $r('app.color.divider_color')
              })
              .borderRadius(8)
              .width(100)
              .height(36)
              .margin({ left: this.showRetry ? 12 : 0 })
              .onClick(() => {
                this.isVisible = false;
                if (this.onDismiss) {
                  this.onDismiss();
                }
              })
          }
        }
        .width('80%')
        .padding(24)
        .backgroundColor(Color.White)
        .borderRadius(16)
        .shadow({ radius: 16, color: '#33000000', offsetX: 0, offsetY: 4 })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor('rgba(0, 0, 0, 0.5)')
    }
  }

  show(): void {
    this.isVisible = true;
  }

  hide(): void {
    this.isVisible = false;
  }
}
