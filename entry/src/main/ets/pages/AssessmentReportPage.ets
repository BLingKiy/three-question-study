import { AssessmentReport, DimensionScores, DimensionAnalysis, ErrorTrace } from '../model/Assessment';
import { RDBService } from '../services/RDBService';
import { AssessmentManager } from '../services/AssessmentManager';
import { RadarChartWeb } from '../components/RadarChartWeb';
import { LoadingIndicator } from '../components/LoadingIndicator';
import { ExportDialog } from '../components/ExportDialog';
import { ExportType } from '../services/ExportService';
import router from '@ohos.router';

@Entry
@Component
struct AssessmentReportPage {
  @State courseId: string = '';
  @State report: AssessmentReport | null = null;
  @State isLoading: boolean = true;
  @State isGenerating: boolean = false;
  @State errorMessage: string = '';

  private rdbService: RDBService | null = null;
  private assessmentManager: AssessmentManager | null = null;
  exportDialogController: CustomDialogController = new CustomDialogController({
    builder: ExportDialog({
      courseId: '',
      defaultType: 'report' as ExportType,
      rdbService: null
    }),
    autoCancel: true
  });

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    if (params) {
      this.courseId = params['courseId'] || '';
    }
    this.initializeServices(getContext(this));
  }

  private async initializeServices(context: Context): Promise<void> {
    try {
      this.rdbService = new RDBService(context);
      await this.rdbService.initialize();
      this.assessmentManager = new AssessmentManager(this.rdbService);
      await this.loadReport();
    } catch (err) {
      this.errorMessage = '初始化失败：' + (err as Error).message;
      this.isLoading = false;
    }
  }

  private async loadReport(): Promise<void> {
    if (!this.assessmentManager || !this.courseId) return;

    try {
      const existing = await this.assessmentManager.getAssessmentReport(this.courseId);
      if (existing) {
        this.report = existing;
        this.isLoading = false;
      } else {
        this.isLoading = false;
        this.isGenerating = true;
        const generated = await this.assessmentManager.generateAssessmentReport(getContext(this), this.courseId);
        this.report = generated;
        this.isGenerating = false;
      }
    } catch (err) {
      this.errorMessage = '评测报告生成失败，请重试';
      this.isLoading = false;
      this.isGenerating = false;
    }
  }

  build() {
    Column() {
      Row() {
        Text('< 返回')
          .fontSize(16)
          .fontColor($r('app.color.link_color'))
          .width(60)
          .onClick(() => {
            router.back();
          })
        Text('测评报告')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Row() {
          Image($r('app.media.ic_export'))
            .width(24)
            .height(24)
            .fillColor($r('app.color.link_color'))
            .onClick(() => {
            this.exportDialogController = new CustomDialogController({
              builder: ExportDialog({
                courseId: this.courseId,
                defaultType: 'report' as ExportType,
                rdbService: this.rdbService
              }),
              autoCancel: true
            });
            this.exportDialogController.open();
          })
        }
        .width(60)
        .justifyContent(FlexAlign.End)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)

      if (this.isLoading || this.isGenerating) {
        Column() {
          LoadingIndicator()
          Text(this.isGenerating ? '正在生成评测报告...' : '加载中...')
            .fontSize(14)
            .fontColor($r('app.color.subtle_text'))
            .margin({ top: 12 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.errorMessage) {
        Column() {
          Text(this.errorMessage)
            .fontSize(16)
            .fontColor('#FF4D4F')
            .margin({ bottom: 16 })
          Button('重试')
            .onClick(() => {
              this.errorMessage = '';
              this.isGenerating = true;
              this.loadReport();
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.report) {
        Scroll() {
          Column() {
            Stack() {
              RadarChartWeb({ dimensions: this.report.dimensions })
                .width('100%')
                .height(280)
            }
            .width('100%')
            .height(280)
            .borderRadius(12)
            .clip(true)

            this.DimensionScoreSection()

            this.OverallSuggestionSection()

            this.DimensionAnalysisSection()

            this.ErrorTracesSection()
          }
          .padding(16)
        }
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
  }

  @Builder DimensionScoreSection() {
    Column() {
      Text('能力维度评分')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 12 })

      this.DimensionScoreItem('概念理解', this.report!.dimensions.conceptUnderstanding, '#409EFF')
      this.DimensionScoreItem('批判思维', this.report!.dimensions.criticalThinking, '#67C23A')
      this.DimensionScoreItem('实践迁移', this.report!.dimensions.practicalTransfer, '#E6A23C')
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(12)
    .margin({ top: 12 })
  }

  @Builder DimensionScoreItem(label: string, score: number, color: string) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor($r('app.color.text_primary'))
      Blank()
      Text(`${score}`)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
    }
    .width('100%')
    .margin({ bottom: 8 })

    Progress({ value: score, total: 100, type: ProgressType.Linear })
      .width('100%')
      .color(color)
      .margin({ bottom: 12 })
  }

  @Builder OverallSuggestionSection() {
    Column() {
      Text('整体复习建议')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 8 })

      Text(this.report!.overallSuggestion)
        .fontSize(14)
        .fontColor($r('app.color.text_primary'))
        .lineHeight(22)
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(12)
    .margin({ top: 12 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder DimensionAnalysisSection() {
    Column() {
      Text('维度分析')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 12 })

      if (this.report!.dimensionAnalysis.conceptUnderstanding) {
        this.DimensionAnalysisItem('概念理解', this.report!.dimensionAnalysis.conceptUnderstanding, '#409EFF')
      }
      if (this.report!.dimensionAnalysis.criticalThinking) {
        this.DimensionAnalysisItem('批判思维', this.report!.dimensionAnalysis.criticalThinking, '#67C23A')
      }
      if (this.report!.dimensionAnalysis.practicalTransfer) {
        this.DimensionAnalysisItem('实践迁移', this.report!.dimensionAnalysis.practicalTransfer, '#E6A23C')
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(12)
    .margin({ top: 12 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder DimensionAnalysisItem(title: string, content: string, color: string) {
    Column() {
      Row() {
        Text('●')
          .fontSize(12)
          .fontColor(color)
          .margin({ right: 6 })
        Text(title)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
      }
      .margin({ bottom: 4 })

      Text(content)
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
        .lineHeight(20)
        .margin({ left: 18, bottom: 12 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder ErrorTracesSection() {
    Column() {
      Text('错题溯源')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 8 })

      if (this.report!.errorTraces.length === 0) {
        Text('全部回答正确，无需溯源复习')
          .fontSize(14)
          .fontColor('#67C23A')
      } else {
        ForEach(this.report!.errorTraces, (trace: ErrorTrace) => {
          this.ErrorTraceItem(trace)
        }, (trace: ErrorTrace) => trace.questionId + trace.knowledgeNodeId)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(12)
    .margin({ top: 12, bottom: 24 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder ErrorTraceItem(trace: ErrorTrace) {
    Column() {
      Row() {
        Text('🔗')
          .fontSize(14)
          .margin({ right: 6 })
        Text(trace.knowledgeNodeLabel)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.link_color'))
          .onClick(() => {
            router.pushUrl({
              url: 'pages/LearningSpacePage',
              params: { courseId: this.courseId, highlightNodeId: trace.knowledgeNodeId }
            });
          })
      }

      Text(trace.traceExplanation)
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
        .lineHeight(20)
        .margin({ top: 4, left: 24 })
    }
    .width('100%')

    .alignItems(HorizontalAlign.Start)
  }
}