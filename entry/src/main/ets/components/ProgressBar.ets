@Component
export struct ProgressBar {
  @Prop value: number = 0;
  @Prop total: number = 100;
  @Prop showPercentage: boolean = true;
  @Prop color: ResourceColor = $r('app.color.tech_blue_primary');

  build() {
    Column() {
      Row() {
        Progress({ value: this.value, total: this.total, type: ProgressType.Linear })
          .layoutWeight(1)
          .height(8)
          .color(this.color)

        if (this.showPercentage) {
          Text(`${Math.round((this.value / this.total) * 100)}%`)
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .margin({ left: 8 })
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
  }
}
