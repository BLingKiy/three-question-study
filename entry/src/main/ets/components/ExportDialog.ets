import { ExportType, ExportFormat, ExportService } from '../services/ExportService';
import { RDBService } from '../services/RDBService';

@CustomDialog
export struct ExportDialog {
  @State selectedType: ExportType = 'report';
  @State selectedFormat: ExportFormat = 'markdown';
  @State isExporting: boolean = false;
  @State exportResult: string = '';

  courseId: string = '';
  defaultType: ExportType = 'report';
  controller: CustomDialogController;
  onCancel?: () => void;
  private rdbService: RDBService | null = null;

  aboutToAppear(): void {
    this.selectedType = this.defaultType;
  }

  build() {
    Column() {
      Text('数据导出')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })

      Text('导出内容')
        .fontSize(14)
        .fontColor('#666666')
        .width('100%')
        .margin({ bottom: 8 })

      Row() {
        this.TypeButton('学习报告', 'report')
        this.TypeButton('错题集', 'errorCollection')
        this.TypeButton('对话记录', 'dialogRecords')
      }
      .width('100%')
      .margin({ bottom: 20 })

      Text('文件格式')
        .fontSize(14)
        .fontColor('#666666')
        .width('100%')
        .margin({ bottom: 8 })

      Row() {
        this.FormatButton('TXT', 'txt')
        this.FormatButton('JSON', 'json')
        this.FormatButton('Markdown', 'markdown')
      }
      .width('100%')
      .margin({ bottom: 20 })

      if (this.exportResult) {
        Text(this.exportResult)
          .fontSize(13)
          .fontColor(this.exportResult.startsWith('导出成功') ? '#4CAF50' : '#F44336')
          .width('100%')
          .margin({ bottom: 12 })
      }

      Row() {
        Button('取消')
          .fontSize(14)
          .height(40)
          .backgroundColor('#EEEEEE')
          .fontColor('#333333')
          .layoutWeight(1)
          .onClick(() => {
            try {
              this.controller.close();
            } catch (_e) {}
          })

        Button('导出')
          .fontSize(14)
          .height(40)
          .backgroundColor('#409EFF')
          .fontColor(Color.White)
          .layoutWeight(1)
          .margin({ left: 12 })
          .enabled(!this.isExporting)
          .onClick(() => {
            this.doExport();
          })
      }
      .width('100%')

      if (this.isExporting) {
        Row() {
          LoadingProgress()
            .width(20)
            .height(20)
            .color('#409EFF')
            .margin({ right: 8 })
          Text('正在导出...')
            .fontSize(14)
            .fontColor('#999999')
        }
        .margin({ top: 12 })
      }
    }
    .padding(24)
    .backgroundColor(Color.White)
    .borderRadius(16)
  }

  @Builder TypeButton(label: string, type: ExportType) {
    Button(label)
      .fontSize(13)
      .height(32)
      .backgroundColor(this.selectedType === type ? '#409EFF' : '#F0F0F0')
      .fontColor(this.selectedType === type ? Color.White : '#333333')
      .layoutWeight(1)
      .margin({ right: type === 'report' ? 8 : type === 'errorCollection' ? 8 : 0 })
      .onClick(() => {
        this.selectedType = type;
      })
  }

  @Builder FormatButton(label: string, format: ExportFormat) {
    Button(label)
      .fontSize(13)
      .height(32)
      .backgroundColor(this.selectedFormat === format ? '#409EFF' : '#F0F0F0')
      .fontColor(this.selectedFormat === format ? Color.White : '#333333')
      .layoutWeight(1)
      .margin({ right: format === 'txt' ? 8 : format === 'json' ? 8 : 0 })
      .onClick(() => {
        this.selectedFormat = format;
      })
  }

  private async doExport(): Promise<void> {
    if (!this.rdbService || !this.courseId) return;
    this.isExporting = true;
    this.exportResult = '';
    try {
      const exportService = new ExportService(this.rdbService);
      const filePath = await exportService.exportData(
        getContext(this), this.courseId, this.selectedType, this.selectedFormat
      );
      this.exportResult = `导出成功：${filePath}`;
    } catch (err) {
      this.exportResult = `导出失败：${(err as Error).message}`;
    } finally {
      this.isExporting = false;
    }
  }
}