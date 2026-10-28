@Component
export struct LoadingIndicator {
  @Prop text: string = '加载中...';

  build() {
    Column() {
      LoadingProgress()
        .width(48)
        .height(48)
        .color($r('app.color.tech_blue_primary'))

      Text(this.text)
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: 16 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
