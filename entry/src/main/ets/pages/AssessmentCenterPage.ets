import { Assessment, BloomLevel, AssessmentResult, QuestionType, FollowUp } from '../model/Assessment';
import { Course } from '../model/Course';
import { RadarChartWeb } from '../components/RadarChartWeb';
import { LoadingIndicator } from '../components/LoadingIndicator';
import { RDBService } from '../services/RDBService';
import { AssessmentManager, SubjectiveEvaluation } from '../services/AssessmentManager';
import { CourseManager } from '../services/CourseManager';
import { ThreeQuestionEngine } from '../services/ThreeQuestionEngine';
import { DeepseekService } from '../services/DeepseekService';
import { PreferencesService } from '../services/PreferencesService';
import { KnowledgeBaseManager } from '../services/KnowledgeBaseManager';
import { FileService } from '../services/FileService';
import { MarkdownUtil, MdBlock, MdSpan } from '../utils/MarkdownUtil';
import router from '@ohos.router';
import fileFs from '@ohos.file.fs';

interface OptionItem {
  id: string;
  text: string;
}

class OptionItemImpl implements OptionItem {
  id: string = '';
  text: string = '';
}

interface CourseGroup {
  courseId: string;
  courseName: string;
  courseQuestion: string;
  assessments: Assessment[];
  expanded: boolean;
  assessmentGenerating: boolean;
}

class CourseGroupImpl implements CourseGroup {
  courseId: string = '';
  courseName: string = '';
  courseQuestion: string = '';
  assessments: Assessment[] = [];
  expanded: boolean = false;
  assessmentGenerating: boolean = false;
}

@Entry
@Component
struct AssessmentCenterPage {
  @State courseGroups: CourseGroup[] = [];
  @State currentAssessment: Assessment | null = null;
  @State currentAssessmentList: Assessment[] = [];
  @State currentAssessmentIndex: number = 0;
  @State userAnswer: string = '';
  @State selectedOptions: string[] = [];
  @State showResult: boolean = false;
  @State totalScore: number = 0;
  @State levelScores: Map<BloomLevel, number> = new Map();
  @State isLoading: boolean = true;
  @State errorMessage: string = '';
  @State currentCourseId: string = '';
  @State answerSubmitted: boolean = false;
  @State submitResult: string = '';
  @State isCorrect: boolean = false;
  @State isEvaluating: boolean = false;
  @State evaluationResult: SubjectiveEvaluation | null = null;

  @State followUpMessages: FollowUp[] = [];
  @State followUpInput: string = '';
  @State isFollowUpLoading: boolean = false;

  private rdbService: RDBService | null = null;
  private assessmentManager: AssessmentManager | null = null;
  private pollingTimer: number = -1;

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    if (params) {
      this.currentCourseId = params['courseId'] || '';
    }
    this.initializeServices(getContext(this));
  }

  aboutToDisappear(): void {
    if (this.pollingTimer !== -1) {
      clearInterval(this.pollingTimer);
    }
  }

  private async initializeServices(context: Context): Promise<void> {
    try {
      this.rdbService = new RDBService(context);
      await this.rdbService.initialize();
      this.assessmentManager = new AssessmentManager(this.rdbService);
      await this.loadAssessments();
    } catch (err) {
      this.errorMessage = '初始化失败：' + (err as Error).message;
      this.isLoading = false;
    }
  }

  private async loadAssessments(): Promise<void> {
    if (!this.rdbService) return;

    try {
      const courseManager = new CourseManager(this.rdbService);
      const courses: Course[] = await courseManager.getAllCourses();
      const allAssessments: Assessment[] = this.assessmentManager
        ? await this.assessmentManager.getAssessments('')
        : [];

      const groups: CourseGroup[] = [];
      for (const course of courses) {
        if (!course.mentalModelGenerated) continue;
        if (course.status === 'archived') continue;
        const courseAssessments = allAssessments.filter(a => a.courseId === course.id);
        const group = new CourseGroupImpl();
        group.courseId = course.id;
        group.courseName = course.name;
        group.courseQuestion = course.question;
        group.assessments = courseAssessments;
        group.expanded = this.currentCourseId === course.id;
        group.assessmentGenerating = course.assessmentGenerating;
        groups.push(group);
      }
      this.courseGroups = groups;
      this.startPollingIfNeeded();
    } catch (err) {
      this.errorMessage = '加载测评失败';
    } finally {
      this.isLoading = false;
    }
  }

  private async collectAssessmentContext(courseId: string): Promise<string> {
    if (!this.rdbService) return '';
    let context = '';

    const nodes = await this.rdbService.queryKnowledgeNodes(courseId);
    const conceptNodes = nodes.filter(n => n.type === 'concept' || n.type === 'evidence');
    if (conceptNodes.length > 0) {
      context += '【知识图谱概念】\n';
      for (const n of conceptNodes) {
        context += `- ${n.label}: ${n.content || ''}\n`;
      }
    }

    const controversyNodes = nodes.filter(n => n.type === 'controversy');
    if (controversyNodes.length > 0) {
      context += '\n【争议分析】\n';
      for (const n of controversyNodes) {
        context += `- ${n.label}: ${n.content || ''}\n`;
      }
    }

    const sources = await this.rdbService.queryKnowledgeSourcesByCourseId(courseId);
    if (sources.length > 0) {
      context += '\n【WebSearch资料】\n';
      for (const s of sources) {
        context += `- ${s.title}: ${s.url}\n`;
      }
    }

    try {
      const fileService = new FileService(getContext(this));
      const knowledgeBaseManager = new KnowledgeBaseManager(this.rdbService, fileService);
      const materials = await knowledgeBaseManager.getMaterials(courseId);
      if (materials.length > 0) {
        context += '\n【用户上传资料】\n';
        const ctx = getContext(this);
        const materialsDir = ctx.filesDir + '/materials';
        const courseDir = `${materialsDir}/${courseId}`;
        for (const m of materials) {
          if (m.fileType === 'text' || m.fileType === 'markdown') {
            try {
              const listFile = fileFs.listFileSync(courseDir);
              for (const fileName of listFile) {
                if (fileName.startsWith(m.id)) {
                  const filePath = `${courseDir}/${fileName}`;
                  const file = fileFs.openSync(filePath, fileFs.OpenMode.READ_ONLY);
                  const stat = fileFs.statSync(filePath);
                  const buf = new ArrayBuffer(stat.size);
                  fileFs.readSync(file.fd, buf);
                  fileFs.closeSync(file);
                  const text = String.fromCharCode(...new Uint8Array(buf));
                  context += `\n--- ${m.fileName} ---\n${text}\n`;
                  break;
                }
              }
            } catch (e) {
              context += `\n--- ${m.fileName} --- (读取失败)\n`;
            }
          }
        }
      }
    } catch (e) {
      console.warn('[AssessmentCenter] Failed to collect materials:', e);
    }

    if (context.length > 8000) {
      context = context.substring(0, 8000) + '\n...(内容过长已截断)';
    }
    return context;
  }

  private async handleGenerateAssessment(courseId: string, courseQuestion: string): Promise<void> {
    if (!this.rdbService) return;

    const preferencesService = new PreferencesService(getContext(this));
    await preferencesService.initialize();
    const hasApiKey = await preferencesService.hasApiKey();
    if (!hasApiKey) {
      this.errorMessage = '请先在「我的」页面配置 API 密钥';
      return;
    }

    await this.setAssessmentGenerating(courseId, true);
    this.errorMessage = '';
    try {
      const materialsContent = await this.collectAssessmentContext(courseId);
      const deepseekService = new DeepseekService(preferencesService);
      const engine = new ThreeQuestionEngine(deepseekService, this.rdbService);
      await engine.executeQuestion3(courseId, courseQuestion, undefined, materialsContent);
      await this.setAssessmentGenerating(courseId, false);
      await this.loadAssessments();
    } catch (err) {
      await this.setAssessmentGenerating(courseId, false);
      this.errorMessage = '测评生成失败：' + (err as Error).message;
    }
  }

  private async handleRegenerateAssessment(courseId: string, courseQuestion: string): Promise<void> {
    if (!this.rdbService) return;
    await this.rdbService.deleteAssessmentsByCourseId(courseId);
    await this.rdbService.deleteAssessmentReportByCourseId(courseId);
    await this.handleGenerateAssessment(courseId, courseQuestion);
  }

  private async setAssessmentGenerating(courseId: string, generating: boolean): Promise<void> {
    if (!this.rdbService) return;
    const courses = await this.rdbService.queryCourses();
    const course = courses.find(c => c.id === courseId);
    if (course) {
      course.assessmentGenerating = generating;
      await this.rdbService.updateCourse(course);
    }
    await this.loadAssessments();
  }

  private startPollingIfNeeded(): void {
    if (this.pollingTimer !== -1) {
      clearInterval(this.pollingTimer);
      this.pollingTimer = -1;
    }
    const hasGenerating = this.courseGroups.some(g => g.assessmentGenerating);
    if (hasGenerating) {
      this.pollingTimer = setInterval(() => {
        this.loadAssessments();
      }, 3000);
    }
  }

  build() {
    Column() {
      Row() {
        if (this.currentAssessment && !this.showResult) {
          Image($r('app.media.ic_arrow_left'))
            .width(24)
            .height(24)
            .fillColor($r('app.color.text_primary'))
            .onClick(() => {
              this.currentAssessment = null;
              this.answerSubmitted = false;
              this.userAnswer = '';
              this.selectedOptions = [];
              this.followUpMessages = [];
              this.followUpInput = '';
            })
            .margin({ right: 12 })
        }

        Text('测评中心')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.tech_blue_primary'))

        Blank()

        if (this.showResult) {
          Button('重新开始')
            .fontSize(14)
            .height(36)
            .backgroundColor($r('app.color.tech_blue_primary'))
            .onClick(() => {
              this.showResult = false;
              this.currentAssessment = null;
              this.answerSubmitted = false;
              this.userAnswer = '';
              this.selectedOptions = [];
              this.followUpMessages = [];
              this.followUpInput = '';
            })
        }
      }
      .width('100%')
      .padding(16)

      if (this.errorMessage) {
        Row() {
          Text(this.errorMessage)
            .fontSize(14)
            .fontColor($r('app.color.error_color'))
            .layoutWeight(1)
          Text('×')
            .fontSize(18)
            .fontColor($r('app.color.text_secondary'))
            .onClick(() => { this.errorMessage = ''; })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .backgroundColor('#FFF3E0')
      }

      if (this.isLoading) {
        LoadingIndicator({ text: '加载测评...' })
      } else if (this.showResult) {
        this.ResultReport()
      } else if (this.currentAssessment) {
        this.AssessmentTaking()
      } else {
        this.AssessmentList()
      }

      this.BottomNavigation()
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
  }

  @Builder
  AssessmentList(): void {
    Column() {
      if (this.courseGroups.length === 0) {
        Column() {
          Image($r('app.media.ic_document'))
            .width(64)
            .height(64)
            .fillColor($r('app.color.text_secondary'))
            .margin({ bottom: 16 })
          Text('暂无课程')
            .fontSize(16)
            .fontColor($r('app.color.text_secondary'))
          Text('请先创建课程并生成知识图谱')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: 8 })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        List() {
          ForEach(this.courseGroups, (group: CourseGroup) => {
            ListItem() {
              Column() {
                Row() {
                  Text(group.courseName)
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .fontColor($r('app.color.text_primary'))
                    .layoutWeight(1)

                  Text(`${group.assessments.length}题`)
                    .fontSize(14)
                    .fontColor($r('app.color.text_secondary'))
                    .margin({ right: 8 })

                  if (group.assessmentGenerating) {
                    LoadingProgress()
                      .width(20)
                      .height(20)
                      .color($r('app.color.tech_blue_primary'))
                      .margin({ right: 8 })
                  } else if (group.assessments.length > 0) {
                    SymbolGlyph($r('sys.symbol.arrow_counterclockwise'))
                      .fontSize(20)
                      .fontColor([$r('app.color.text_secondary')])
                      .margin({ right: 8 })
                      .onClick(() => {
                        AlertDialog.show({
                          title: '重新生成测评',
                          message: `确定为「${group.courseName}」重新生成测评题目？原有题目将被删除。`,
                          primaryButton: {
                            value: '取消',
                            action: () => {}
                          },
                          secondaryButton: {
                            value: '确定',
                            action: () => {
                              this.handleRegenerateAssessment(group.courseId, group.courseQuestion);
                            }
                          }
                        });
                      })
                  } else {
                    Button('生成测评')
                      .fontSize(12)
                      .height(28)
                      .backgroundColor($r('app.color.tech_blue_primary'))
                      .onClick(() => {
                        AlertDialog.show({
                          title: '生成测评',
                          message: `确定为「${group.courseName}」生成测评题目吗？`,
                          primaryButton: {
                            value: '取消',
                            action: () => {}
                          },
                          secondaryButton: {
                            value: '确定',
                            action: () => {
                              this.handleGenerateAssessment(group.courseId, group.courseQuestion);
                            }
                          }
                        });
                      })
                  }

                  Image($r('app.media.ic_arrow_right'))
                    .width(20)
                    .height(20)
                    .fillColor($r('app.color.text_secondary'))
                    .rotate({ angle: group.expanded ? 90 : 0 })
                }
                .width('100%')
                .padding(16)
                .onClick(() => {
                  const idx = this.courseGroups.indexOf(group);
                  if (idx >= 0) {
                    const newGroup = new CourseGroupImpl();
                    newGroup.courseId = group.courseId;
                    newGroup.courseName = group.courseName;
                    newGroup.courseQuestion = group.courseQuestion;
                    newGroup.assessments = group.assessments;
                    newGroup.expanded = !group.expanded;
                    this.courseGroups[idx] = newGroup;
                  }
                })

                if (group.expanded) {
                  if (group.assessments.length === 0) {
                    Text('暂无测评题目，点击上方"生成测评"按钮开始')
                      .fontSize(14)
                      .fontColor($r('app.color.text_secondary'))
                      .width('100%')
                      .padding(16)
                  } else {
                    if (this.isGroupAllAnswered(group)) {
                      Row() {
                        Blank()
                        Button('查看测评报告')
                          .fontSize(14)
                          .height(36)
                          .backgroundColor($r('app.color.tech_blue_primary'))
                          .fontColor(Color.White)
                          .width('85%')
                          .margin({ top: 8, bottom: 8 })
                          .onClick(() => {
                            router.pushUrl({
                              url: 'pages/AssessmentReportPage',
                              params: { courseId: group.courseId }
                            });
                          })
                        Blank()
                      }
                      .width('100%')
                    }

                    ForEach(group.assessments, (a: Assessment) => {
                      Row() {
                        Column() {
                          Row() {
                            Text(this.getBloomLevelText(a.bloomLevel))
                              .fontSize(12)
                              .fontColor($r('app.color.text_primary'))
                              .backgroundColor(this.getBloomLevelColor(a.bloomLevel))
                              .borderRadius(4)
                              .padding({ left: 8, right: 8, top: 2, bottom: 2 })

                            Text(this.getQuestionTypeText(a.questionType))
                              .fontSize(12)
                              .fontColor($r('app.color.text_primary'))
                              .backgroundColor(this.getQuestionTypeColor(a.questionType))
                              .borderRadius(4)
                              .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                              .margin({ left: 8 })

                            if (a.userAnswer) {
                              Text(a.isCorrect ? '✓' : '✗')
                                .fontSize(12)
                                .fontColor(a.isCorrect ? '#4CAF50' : '#F44336')
                                .margin({ left: 8 })
                            }
                          }

                          Text(a.question)
                            .fontSize(16)
                            .fontColor($r('app.color.text_primary'))
                            .maxLines(2)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                            .margin({ top: 8 })
                        }
                        .layoutWeight(1)
                        .alignItems(HorizontalAlign.Start)

                        Image($r('app.media.ic_arrow_right'))
                          .width(20)
                          .height(20)
                          .fillColor($r('app.color.text_secondary'))
                      }
                      .width('100%')
                      .padding(16)
                      .backgroundColor($r('app.color.card_background'))
                      .borderRadius(12)
                      .margin({ bottom: 12 })
                      .onClick(() => {
                        this.startAssessment(a, group.assessments);
                      })
                    })
                  }
                }
              }
              .width('100%')
              .backgroundColor($r('app.color.card_background'))
              .borderRadius(12)
              .margin({ bottom: 12 })
              .clip(true)
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      }
    }
    .layoutWeight(1)
  }

  @Builder
  AssessmentTaking(): void {
    Scroll() {
      Column() {
        Text(`${this.currentAssessmentIndex + 1} / ${this.currentAssessmentList.length}`)
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ top: 8, bottom: 8 })

        Column() {
          Row() {
            Text(this.getBloomLevelText(this.currentAssessment!.bloomLevel))
              .fontSize(12)
              .fontColor($r('app.color.text_primary'))
              .backgroundColor(this.getBloomLevelColor(this.currentAssessment!.bloomLevel))
              .borderRadius(4)
              .padding({ left: 8, right: 8, top: 2, bottom: 2 })

            Text(this.getQuestionTypeText(this.currentAssessment!.questionType))
              .fontSize(12)
              .fontColor($r('app.color.text_primary'))
              .backgroundColor(this.getQuestionTypeColor(this.currentAssessment!.questionType))
              .borderRadius(4)
              .padding({ left: 8, right: 8, top: 2, bottom: 2 })
              .margin({ left: 8 })
          }

          Text(this.currentAssessment!.question)
            .fontSize(18)
            .fontColor($r('app.color.text_primary'))
            .margin({ top: 16 })
        }
        .width('100%')
        .padding(16)
        .backgroundColor($r('app.color.card_background'))
        .borderRadius(12)
        .margin({ left: 16, right: 16 })

        if (!this.answerSubmitted) {
          if (this.currentAssessment!.questionType === 'subjective') {
            TextArea({ placeholder: '输入你的答案...' })
              .width('100%')
              .height(200)
              .margin({ left: 16, right: 16, top: 16 })
              .onChange((value: string) => { this.userAnswer = value; })
          } else if (this.currentAssessment!.questionType === 'trueFalse') {
            Column() {
              Row() {
                Radio({ value: 'true', group: 'trueFalseGroup' })
                  .checked(this.selectedOptions.length > 0 && this.selectedOptions[0] === 'true')
                  .onChange((isChecked: boolean) => {
                    if (isChecked) { this.selectedOptions = ['true']; }
                  })
                Text('正确')
                  .fontSize(16)
                  .margin({ left: 8 })
              }
              .margin({ bottom: 16 })

              Row() {
                Radio({ value: 'false', group: 'trueFalseGroup' })
                  .checked(this.selectedOptions.length > 0 && this.selectedOptions[0] === 'false')
                  .onChange((isChecked: boolean) => {
                    if (isChecked) { this.selectedOptions = ['false']; }
                  })
                Text('错误')
                  .fontSize(16)
                  .margin({ left: 8 })
              }
            }
            .padding(16)
          } else {
            Column() {
              ForEach(this.parseOptions(this.currentAssessment!.options || ''), (opt: OptionItem) => {
                Row() {
                  if (this.currentAssessment!.questionType === 'singleChoice') {
                    Radio({ value: opt.id, group: 'singleChoiceGroup' })
                      .checked(this.selectedOptions.length > 0 && this.selectedOptions[0] === opt.id)
                      .onChange((isChecked: boolean) => {
                        if (isChecked) { this.selectedOptions = [opt.id]; }
                      })
                  } else {
                    Checkbox()
                      .select(this.selectedOptions.includes(opt.id))
                      .onChange((isChecked: boolean) => {
                        if (isChecked) {
                          this.selectedOptions = [...this.selectedOptions, opt.id];
                        } else {
                          this.selectedOptions = this.selectedOptions.filter(id => id !== opt.id);
                        }
                      })
                  }
                  Text(`${opt.id}. ${opt.text}`)
                    .fontSize(16)
                    .margin({ left: 8 })
                    .layoutWeight(1)
                }
                .width('100%')
                .margin({ bottom: 12 })
              })
            }
            .padding(16)
          }

          Button('提交答案')
            .width('90%')
            .height(48)
            .backgroundColor($r('app.color.tech_blue_primary'))
            .margin({ top: 24 })
            .enabled(!this.isEvaluating)
            .onClick(() => { this.submitAnswer(); })

          if (this.isEvaluating) {
            Row() {
              LoadingProgress()
                .width(20)
                .height(20)
                .color($r('app.color.tech_blue_primary'))
                .margin({ right: 8 })
              Text('AI 正在分析你的答案...')
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .margin({ top: 16 })
          }
        } else {
          Column() {
            Row() {
              Text(this.isCorrect ? '✓ 回答正确' : '✗ 回答错误')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.isCorrect ? '#4CAF50' : '#F44336')
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .margin({ top: 16, bottom: 16 })

            if (this.currentAssessment!.questionType !== 'subjective' && this.currentAssessment!.correctAnswer) {
              Text(`正确答案：${this.formatCorrectAnswer(this.currentAssessment!.correctAnswer, this.currentAssessment!.questionType)}`)
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
                .width('100%')
                .margin({ bottom: 8 })
              if (this.currentAssessment!.userAnswer) {
                Text(`你的答案：${this.formatCorrectAnswer(this.currentAssessment!.userAnswer, this.currentAssessment!.questionType)}`)
                  .fontSize(14)
                  .fontColor($r('app.color.text_secondary'))
                  .width('100%')
                  .margin({ bottom: 8 })
              }
            }

            if (this.evaluationResult) {
              if (this.evaluationResult.score > 0) {
                Text(`得分：${this.evaluationResult.score}/100`)
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor($r('app.color.tech_blue_primary'))
                  .width('100%')
                  .margin({ bottom: 12 })
              }

              if (this.evaluationResult.analysis) {
                Text('分析')
                  .fontSize(14)
                  .fontWeight(FontWeight.Bold)
                  .fontColor($r('app.color.text_primary'))
                  .width('100%')
                  .margin({ bottom: 4 })
                Text(this.evaluationResult.analysis)
                  .fontSize(14)
                  .fontColor($r('app.color.text_secondary'))
                  .width('100%')
                  .margin({ bottom: 12 })
              }

              if (this.evaluationResult.suggestion) {
                Text('改进建议')
                  .fontSize(14)
                  .fontWeight(FontWeight.Bold)
                  .fontColor($r('app.color.text_primary'))
                  .width('100%')
                  .margin({ bottom: 4 })
                Text(this.evaluationResult.suggestion)
                  .fontSize(14)
                  .fontColor($r('app.color.text_secondary'))
                  .width('100%')
              }
            } else if (this.currentAssessment!.answer) {
              Text(`参考答案：${this.currentAssessment!.answer}`)
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
                .width('100%')
            }
          }
          .width('100%')
          .padding(16)
          .backgroundColor($r('app.color.card_background'))
          .borderRadius(12)
          .margin({ left: 16, right: 16, top: 16 })

          this.FollowUpSection()

          Row() {
            Button('上一题')
              .fontSize(14)
              .height(40)
              .backgroundColor(this.currentAssessmentIndex > 0 ? $r('app.color.tech_blue_primary') : $r('app.color.disabled_color'))
              .fontColor(Color.White)
              .layoutWeight(1)
              .enabled(this.currentAssessmentIndex > 0)
              .onClick(() => { this.goToPrev(); })

            Button('下一题')
              .fontSize(14)
              .height(40)
              .backgroundColor(this.currentAssessmentIndex < this.currentAssessmentList.length - 1 ? $r('app.color.tech_blue_primary') : $r('app.color.disabled_color'))
              .fontColor(Color.White)
              .layoutWeight(1)
              .margin({ left: 12 })
              .enabled(this.currentAssessmentIndex < this.currentAssessmentList.length - 1)
              .onClick(() => { this.goToNext(); })
          }
          .width('90%')
          .margin({ top: 16 })

          Button('查看测评报告')
            .width('90%')
            .height(48)
            .backgroundColor(this.allCourseQuestionsAnswered() ? $r('app.color.tech_blue_primary') : $r('app.color.disabled_color'))
            .fontColor(Color.White)
            .margin({ top: 12 })
            .enabled(this.allCourseQuestionsAnswered())
            .onClick(() => {
              const courseId = this.currentAssessmentList[0]?.courseId || '';
              if (courseId) {
                router.pushUrl({
                  url: 'pages/AssessmentReportPage',
                  params: { courseId: courseId }
                });
              }
            })
        }
      }
    }
    .layoutWeight(1)
  }

  @Builder
  FollowUpSection(): void {
    Column() {
      Text('追问')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .width('100%')
        .margin({ bottom: 12 })

      if (this.followUpMessages.length > 0) {
        ForEach(this.followUpMessages, (msg: FollowUp) => {
          if (msg.role === 'user') {
            Row() {
              Blank()
              Text(msg.content)
                .fontSize(14)
                .fontColor(Color.White)
                .backgroundColor($r('app.color.tech_blue_primary'))
                .borderRadius(12)
                .padding(12)
                .constraintSize({ maxWidth: '85%' })
            }
            .width('100%')
            .margin({ bottom: 8 })
          } else {
            Row() {
              Column() {
                ForEach(MarkdownUtil.parse(msg.content), (block: MdBlock) => {
                  if (block.type === 'heading') {
                    Text(block.text)
                      .fontSize(block.level === 1 ? 18 : 16)
                      .fontWeight(FontWeight.Bold)
                      .fontColor($r('app.color.text_primary'))
                      .width('100%')
                      .margin({ top: 8, bottom: 4 })
                  } else if (block.type === 'codeBlock') {
                    Text(block.text)
                      .fontSize(13)
                      .fontFamily('monospace')
                      .fontColor($r('app.color.text_primary'))
                      .backgroundColor($r('app.color.input_background'))
                      .borderRadius(4)
                      .padding(8)
                      .width('100%')
                  } else if (block.type === 'listItem') {
                    Text(block.text)
                      .fontSize(14)
                      .fontColor($r('app.color.text_secondary'))
                      .width('100%')
                      .margin({ bottom: 2 })
                  } else if (block.type === 'paragraph') {
                    Text() {
                      ForEach(block.spans, (span: MdSpan) => {
                        Span(span.text)
                          .fontWeight(span.type === 'bold' ? FontWeight.Bold : FontWeight.Normal)
                          .fontStyle(span.type === 'italic' ? FontStyle.Italic : FontStyle.Normal)
                      }, (span: MdSpan, index: number) => `${index}_${span.text}`)
                    }
                    .fontSize(14)
                    .fontColor($r('app.color.text_secondary'))
                    .width('100%')
                  }
                }, (block: MdBlock, index: number) => `${index}_${block.type}`)
              }
              .alignItems(HorizontalAlign.Start)
              .backgroundColor($r('app.color.card_background'))
              .borderRadius(12)
              .padding(12)
              .shadow({ radius: 4, color: '#1A000000', offsetX: 0, offsetY: 1 })
              .constraintSize({ maxWidth: '85%' })

              Blank()
            }
            .width('100%')
            .margin({ bottom: 8 })
          }
        }, (msg: FollowUp) => msg.id)
      }

      Row() {
        TextInput({ placeholder: '输入追问...' })
          .layoutWeight(1)
          .height(40)
          .onChange((value: string) => { this.followUpInput = value; })

        Button('追问')
          .height(40)
          .backgroundColor($r('app.color.tech_blue_primary'))
          .margin({ left: 8 })
          .enabled(!this.isFollowUpLoading && this.followUpInput.trim().length > 0)
          .onClick(() => { this.submitFollowUp(); })
      }
      .width('100%')
      .margin({ top: 8 })

      if (this.isFollowUpLoading) {
        Row() {
          LoadingProgress()
            .width(16)
            .height(16)
            .color($r('app.color.tech_blue_primary'))
            .margin({ right: 8 })
          Text('AI 思考中...')
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
        }
        .margin({ top: 8 })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(12)
    .margin({ left: 16, right: 16, top: 16 })
  }

  @Builder
  ResultReport(): void {
    Column() {
      Column() {
        Text('总分')
          .fontSize(16)
          .fontColor($r('app.color.text_secondary'))
        Text(`${Math.round(this.totalScore)}分`)
          .fontSize(48)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.tech_blue_primary'))
          .margin({ top: 8 })
      }
      .width('100%')
      .padding(24)
      .backgroundColor($r('app.color.card_background'))
      .borderRadius(12)
      .margin(16)

      Column() {
        Text('能力维度分析')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 16 })
        RadarChartWeb({ dimensions: { conceptUnderstanding: 0, criticalThinking: 0, practicalTransfer: 0 } })
          .width('100%')
          .height(250)
      }
      .width('100%')
      .padding(16)
      .backgroundColor($r('app.color.card_background'))
      .borderRadius(12)
      .margin({ left: 16, right: 16 })

      Blank()
    }
    .layoutWeight(1)
  }

  private startAssessment(assessment: Assessment, list: Assessment[]): void {
    this.currentAssessment = assessment;
    this.currentAssessmentList = list;
    this.currentAssessmentIndex = list.indexOf(assessment);
    this.userAnswer = '';
    this.selectedOptions = [];
    this.answerSubmitted = false;
    this.submitResult = '';
    this.isCorrect = false;
    this.evaluationResult = null;
    this.followUpMessages = [];
    this.followUpInput = '';
    if (assessment.userAnswer) {
      this.answerSubmitted = true;
      this.isCorrect = assessment.isCorrect || false;
      this.userAnswer = assessment.userAnswer;
      this.loadFollowUpHistory(assessment.id);
    }
  }

  private async loadFollowUpHistory(assessmentId: string): Promise<void> {
    if (!this.assessmentManager) return;
    try {
      this.followUpMessages = await this.assessmentManager.getFollowUps(assessmentId);
    } catch (e) {
      this.followUpMessages = [];
    }
  }

  private parseOptions(optionsStr: string): OptionItem[] {
    if (!optionsStr) return [];
    try {
      const arr = JSON.parse(optionsStr) as Object[];
      const result: OptionItem[] = [];
      for (const item of arr) {
        const record = item as Record<string, string>;
        const opt = new OptionItemImpl();
        opt.id = record['id'] || '';
        opt.text = record['text'] || '';
        result.push(opt);
      }
      return result;
    } catch (e) {
      return [];
    }
  }

  private async submitAnswer(): Promise<void> {
    if (!this.assessmentManager || !this.currentAssessment || !this.rdbService) return;

    try {
      const assessment = this.currentAssessment;
      if (assessment.questionType === 'subjective') {
        if (!this.userAnswer.trim()) {
          this.errorMessage = '请输入答案';
          return;
        }
        this.isEvaluating = true;
        const evaluation = await this.assessmentManager.evaluateSubjectiveAnswer(
          getContext(this), assessment.id, this.userAnswer
        );
        this.isEvaluating = false;
        this.isCorrect = evaluation.isCorrect;
        this.evaluationResult = evaluation;
        this.submitResult = '';
      } else {
        const answerStr = assessment.questionType === 'multipleChoice'
          ? this.selectedOptions.sort().join(',')
          : this.selectedOptions.length > 0 ? this.selectedOptions[0] : '';
        if (!answerStr) {
          this.errorMessage = '请选择答案';
          return;
        }
        assessment.userAnswer = answerStr;
        assessment.isCorrect = this.evaluateObjectiveAnswer(assessment.correctAnswer || '', answerStr, assessment.questionType);
        this.isCorrect = assessment.isCorrect;
        this.submitResult = '';
        this.evaluationResult = null;
        await this.rdbService.updateAssessment(assessment);
      }
      this.answerSubmitted = true;
      this.errorMessage = '';
      this.followUpMessages = [];
      this.followUpInput = '';
    } catch (err) {
      this.isEvaluating = false;
      this.errorMessage = '提交答案失败：' + (err as Error).message;
    }
  }

  private async submitFollowUp(): Promise<void> {
    if (!this.assessmentManager || !this.currentAssessment) return;
    const question = this.followUpInput.trim();
    if (!question) return;

    this.isFollowUpLoading = true;
    this.errorMessage = '';
    try {
      let evaluationContext = '';
      if (this.evaluationResult) {
        evaluationContext = `得分：${this.evaluationResult.score}/100，分析：${this.evaluationResult.analysis}`;
      } else {
        evaluationContext = this.isCorrect ? '回答正确' : '回答错误';
      }

      const aiFollowUp = await this.assessmentManager.generateFollowUpReply(
        getContext(this),
        this.currentAssessment.id,
        this.currentAssessment.question,
        this.currentAssessment.userAnswer || this.userAnswer,
        evaluationContext,
        this.followUpMessages,
        question
      );

      const userMsg = this.followUpMessages[this.followUpMessages.length - 1];
      if (userMsg && userMsg.role === 'user' && userMsg.content === question) {
        this.followUpMessages = [...this.followUpMessages, aiFollowUp];
      } else {
        this.followUpMessages = [...this.followUpMessages, aiFollowUp];
      }
      this.followUpInput = '';
    } catch (err) {
      this.errorMessage = '追问回复生成失败';
    } finally {
      this.isFollowUpLoading = false;
    }
  }

  private async goToNext(): Promise<void> {
    if (this.currentAssessmentIndex < this.currentAssessmentList.length - 1) {
      this.currentAssessmentIndex++;
      this.currentAssessment = this.currentAssessmentList[this.currentAssessmentIndex];
      this.userAnswer = '';
      this.selectedOptions = [];
      this.answerSubmitted = false;
      this.submitResult = '';
      this.isCorrect = false;
      this.evaluationResult = null;
      this.followUpMessages = [];
      this.followUpInput = '';
      if (this.currentAssessment.userAnswer) {
        this.answerSubmitted = true;
        this.isCorrect = this.currentAssessment.isCorrect || false;
        this.userAnswer = this.currentAssessment.userAnswer;
        this.loadFollowUpHistory(this.currentAssessment.id);
      }
    }
  }

  private goToPrev(): void {
    if (this.currentAssessmentIndex > 0) {
      this.currentAssessmentIndex--;
      this.currentAssessment = this.currentAssessmentList[this.currentAssessmentIndex];
      this.userAnswer = '';
      this.selectedOptions = [];
      this.answerSubmitted = false;
      this.submitResult = '';
      this.isCorrect = false;
      this.evaluationResult = null;
      this.followUpMessages = [];
      this.followUpInput = '';
      if (this.currentAssessment.userAnswer) {
        this.answerSubmitted = true;
        this.isCorrect = this.currentAssessment.isCorrect || false;
        this.userAnswer = this.currentAssessment.userAnswer;
        this.loadFollowUpHistory(this.currentAssessment.id);
      }
    }
  }

  private allCourseQuestionsAnswered(): boolean {
    if (this.currentAssessmentList.length === 0) return false;
    for (const a of this.currentAssessmentList) {
      if (!a.userAnswer || a.userAnswer.length === 0) {
        return false;
      }
    }
    return true;
  }

  private isGroupAllAnswered(group: CourseGroup): boolean {
    if (group.assessments.length === 0) return false;
    for (const a of group.assessments) {
      if (!a.userAnswer || a.userAnswer.length === 0) {
        return false;
      }
    }
    return true;
  }

  private evaluateObjectiveAnswer(correctAnswer: string, userAnswer: string, type: QuestionType): boolean {
    if (!userAnswer) return false;
    if (type === 'multipleChoice') {
      const correctSet = correctAnswer.split(',').sort();
      const userSet = userAnswer.split(',').sort();
      if (correctSet.length !== userSet.length) return false;
      for (let i = 0; i < correctSet.length; i++) {
        if (correctSet[i] !== userSet[i]) return false;
      }
      return true;
    }
    return correctAnswer === userAnswer;
  }

  private formatCorrectAnswer(correctAnswer: string, type: QuestionType): string {
    if (type === 'trueFalse') {
      return correctAnswer === 'true' ? '正确' : '错误';
    }
    return correctAnswer;
  }

  private getBloomLevelText(level: BloomLevel): string {
    const texts: Record<BloomLevel, string> = {
      'remember': '记忆', 'understand': '理解', 'apply': '应用',
      'analyze': '分析', 'evaluate': '评价', 'create': '创造'
    };
    return texts[level];
  }

  private getQuestionTypeText(type: QuestionType): string {
    const texts: Record<QuestionType, string> = {
      'subjective': '主观', 'singleChoice': '单选',
      'multipleChoice': '多选', 'trueFalse': '判断'
    };
    return texts[type];
  }

  private getBloomLevelColor(level: BloomLevel): ResourceColor {
    const colors: Record<BloomLevel, string> = {
      'remember': '#CACCE5', 'understand': '#6CD3BA', 'apply': '#D2E091',
      'analyze': '#FDDD94', 'evaluate': '#FFB094', 'create': '#FFA7AF'
    };
    return colors[level];
  }

  private getQuestionTypeColor(type: QuestionType): ResourceColor {
    const colors: Record<QuestionType, string> = {
      'subjective': '#00B4DD', 'singleChoice': '#FB6B98',
      'multipleChoice': '#FFD55A', 'trueFalse': '#79D291'
    };
    return colors[type];
  }

  @Builder
  BottomNavigation(): void {
    Row() {
      Column() {
        Image($r('app.media.ic_home')).width(24).height(24).fillColor($r('app.color.text_secondary'))
        Text('首页').fontSize(12).fontColor($r('app.color.text_secondary')).margin({ top: 4 })
      }
      .layoutWeight(1)
      .onClick(() => { router.replaceUrl({ url: 'pages/MainPage' }); })

      Column() {
        Image($r('app.media.ic_list')).width(24).height(24).fillColor($r('app.color.tech_blue_primary'))
        Text('测评').fontSize(12).fontColor($r('app.color.tech_blue_primary')).margin({ top: 4 })
      }
      .layoutWeight(1)

      Column() {
        Image($r('app.media.ic_settings')).width(24).height(24).fillColor($r('app.color.text_secondary'))
        Text('我的').fontSize(12).fontColor($r('app.color.text_secondary')).margin({ top: 4 })
      }
      .layoutWeight(1)
      .onClick(() => { router.replaceUrl({ url: 'pages/ProfilePage' }); })
    }
    .width('100%')
    .height(56)
    .backgroundColor($r('app.color.card_background'))
    .shadow({ radius: 8, color: '#1A000000', offsetX: 0, offsetY: -2 })
  }
}
