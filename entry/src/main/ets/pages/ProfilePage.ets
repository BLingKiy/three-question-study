import { BloomLevel, DimensionScores, ArchiveAssessment, ArchiveFollowUp, QuestionType } from '../model/Assessment';
import { PreferencesService } from '../services/PreferencesService';
import { DeepseekService } from '../services/DeepseekService';
import { RDBService, CourseDimensionScore } from '../services/RDBService';
import { CourseManager } from '../services/CourseManager';
import { FileService, MaterialInfo } from '../services/FileService';
import { Course } from '../model/Course';
import { ExportDialog } from '../components/ExportDialog';
import { LineChartWeb } from '../components/LineChartWeb';
import { BarChartWeb } from '../components/BarChartWeb';
import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { ConfigurationConstant } from '@kit.AbilityKit';

interface UploadHistoryItem {
  courseName: string;
  materials: MaterialInfo[];
}

class UploadHistoryItemImpl implements UploadHistoryItem {
  courseName: string = '';
  materials: MaterialInfo[] = [];
}

interface ArchiveGroup {
  courseId: string;
  courseName: string;
  assessments: ArchiveAssessment[];
}

class ArchiveGroupImpl implements ArchiveGroup {
  courseId: string = '';
  courseName: string = '';
  assessments: ArchiveAssessment[] = [];
}

@Entry
@Component
struct ProfilePage {
  @State userName: string = '学习者';
  @State totalCourses: number = 0;
  @State completedCourses: number = 0;
  @State totalAssessments: number = 0;
  @State averageScore: number = 0;
  @State apiKey: string = '';

  @State tempApiKey: string = '';
  @State isSaving: boolean = false;
  @State apiKeyStatus: string = '';
  @State courses: Course[] = [];
  @State archivedCourses: Course[] = [];
  @State lineChartDates: string[] = [];
  @State lineChartDurations: number[] = [];
  @State barCourseNames: string[] = [];
  @State barConceptScores: number[] = [];
  @State barCriticalScores: number[] = [];
  @State barPracticalScores: number[] = [];
  @State uploadHistory: UploadHistoryItem[] = [];
  @State colorModeIndex: number = 0;
  @State showSheet: boolean = false;
  @State sheetMode: string = 'apiKey';

  @State deleteTargetCourseId: string = '';
  @State deleteTargetCourseName: string = '';
  @State archiveGroups: ArchiveGroup[] = [];
  @State expandedArchiveCourseId: string = '';
  @State expandedArchiveAssessmentId: string = '';
  @State archiveFollowUps: ArchiveFollowUp[] = [];

  private preferencesService: PreferencesService | null = null;
  private deepseekService: DeepseekService | null = null;
  private rdbService: RDBService | null = null;
  private fileService: FileService | null = null;
  private exportCourseDialogController: CustomDialogController | null = null;
  private exportDialogController: CustomDialogController | null = null;

  aboutToAppear(): void {
    console.info('[ProfilePage] aboutToAppear');
    this.initializeServices(getContext(this));
  }

  onPageShow(): void {
    console.info('[ProfilePage] onPageShow rdbService=' + (this.rdbService ? 'ready' : 'null'));
    if (this.rdbService) {
      this.loadData();
    }
  }

  private async initializeServices(context: Context): Promise<void> {
    try {
      console.info('[ProfilePage] initializeServices start');
      this.preferencesService = new PreferencesService(context);
      await this.preferencesService.initialize();
      this.deepseekService = new DeepseekService(this.preferencesService);
      this.rdbService = new RDBService(context);
      await this.rdbService.initialize();
      console.info('[ProfilePage] rdbService initialized');
      this.fileService = new FileService(context as common.Context);
      await this.fileService.initialize();
      console.info('[ProfilePage] all services initialized, calling loadData');
      await this.loadData();
    } catch (err) {
      console.error('[ProfilePage] Init failed:', JSON.stringify(err));
    }
  }

  private async loadData(): Promise<void> {
    console.info('[ProfilePage] loadData called prefs=' + (this.preferencesService ? 'ok' : 'null') + ' rdb=' + (this.rdbService ? 'ok' : 'null'));
    if (!this.preferencesService || !this.rdbService) return;
    try {
      this.userName = await this.preferencesService.getUserName();
      this.apiKey = await this.preferencesService.getApiKey();
    } catch (e) {
      console.warn('[ProfilePage] Failed to load user prefs:', e);
    }
    try {
      const colorMode = await this.preferencesService.getColorMode();
      this.colorModeIndex = colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET ? 0 : (colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT ? 1 : 2);
      try {
        const context = getContext(this) as common.UIAbilityContext;
        context.getApplicationContext().setColorMode(colorMode);
      } catch (e) {
        console.warn('[ProfilePage] Failed to restore color mode:', e);
      }
    } catch (e) {
      console.warn('[ProfilePage] Failed to load preferences:', e);
    }

    try {
      console.info('[ProfilePage] loadData: calling getCourseStats...');
      const stats = await this.rdbService.getCourseStats();
      console.info('[ProfilePage] loadData: stats received totalCourses=' + stats.totalCourses + ' completedCourses=' + stats.completedCourses + ' totalAssessments=' + stats.totalAssessments + ' averageScore=' + stats.averageScore);
      this.totalCourses = stats.totalCourses;
      this.completedCourses = stats.completedCourses;
      this.totalAssessments = stats.totalAssessments;
      this.averageScore = stats.averageScore;
    } catch (e) {
      console.error('[ProfilePage] Failed to load stats:', JSON.stringify(e));
    }

    this.loadStudyChartData();
    this.loadBarChartData();
    this.loadArchivedCourses();
    this.loadUploadHistory();
    this.loadArchiveData();
  }

  private async loadStudyChartData(): Promise<void> {
    if (!this.rdbService) return;
    const dates: string[] = [];
    const durations: number[] = [];
    const now = new Date();
    for (let i = 6; i >= 0; i--) {
      const d = new Date(now.getTime() - i * 86400000);
      const dateStr = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
      dates.push(`${d.getMonth() + 1}/${d.getDate()}`);
      durations.push(0);
    }
    try {
      const startDate = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(new Date(now.getTime() - 6 * 86400000).getDate()).padStart(2, '0')}`;
      const endDate = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
      const sessions = await this.rdbService.getStudySessionsByDateRange(startDate, endDate);
      for (let i = 6; i >= 0; i--) {
        const d = new Date(now.getTime() - i * 86400000);
        const dateStr = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
        const seconds = sessions.get(dateStr) || 0;
        durations[6 - i] = Math.round(seconds / 60);
      }
    } catch (e) {
      console.warn('[ProfilePage] Failed to load study sessions:', e);
    }
    this.lineChartDates = dates;
    this.lineChartDurations = durations;
  }

  private async loadBarChartData(): Promise<void> {
    if (!this.rdbService) return;
    try {
      const scores = await this.rdbService.getCourseDimensionScores();
      this.barCourseNames = scores.map((s: CourseDimensionScore) => s.courseName);
      this.barConceptScores = scores.map((s: CourseDimensionScore) => s.conceptUnderstanding);
      this.barCriticalScores = scores.map((s: CourseDimensionScore) => s.criticalThinking);
      this.barPracticalScores = scores.map((s: CourseDimensionScore) => s.practicalTransfer);
    } catch (e) {
      console.warn('[ProfilePage] Failed to load dimension scores:', e);
    }
  }

  private async loadArchivedCourses(): Promise<void> {
    if (!this.rdbService) return;
    try {
      const courseManager = new CourseManager(this.rdbService);
      const allCourses = await courseManager.getAllCourses();
      this.archivedCourses = allCourses.filter(c => c.status === 'archived');
    } catch (e) {
      console.warn('[ProfilePage] Failed to load archived courses:', e);
    }
  }

  private async loadUploadHistory(): Promise<void> {
    if (!this.rdbService || !this.fileService) return;
    try {
      const courseManager = new CourseManager(this.rdbService);
      const allCourses = await courseManager.getAllCourses();
      const history: UploadHistoryItem[] = [];
      for (const course of allCourses) {
        const materials = await this.fileService.getMaterials(course.id);
        if (materials.length > 0) {
          const item = new UploadHistoryItemImpl();
          item.courseName = course.name;
          item.materials = materials;
          history.push(item);
        }
      }
      this.uploadHistory = history;
    } catch (e) {
      console.warn('[ProfilePage] Failed to load upload history:', e);
    }
  }

  private async loadArchiveData(): Promise<void> {
    if (!this.rdbService) return;
    try {
      const allArchives = await this.rdbService.queryAllAnswerArchives();
      const groupMap = new Map<string, ArchiveGroup>();
      for (const a of allArchives) {
        const key = a.originalCourseId;
        if (!groupMap.has(key)) {
          const g = new ArchiveGroupImpl();
          g.courseId = a.originalCourseId;
          g.courseName = a.originalCourseName;
          g.assessments = [];
          groupMap.set(key, g);
        }
        groupMap.get(key)!.assessments.push(a);
      }
      this.archiveGroups = Array.from(groupMap.values());
    } catch (e) {
      console.warn('[ProfilePage] Failed to load archive data:', e);
    }
  }

  private async toggleArchiveAssessment(assessmentId: string): Promise<void> {
    if (this.expandedArchiveAssessmentId === assessmentId) {
      this.expandedArchiveAssessmentId = '';
      this.archiveFollowUps = [];
      return;
    }
    this.expandedArchiveAssessmentId = assessmentId;
    if (!this.rdbService) return;
    try {
      this.archiveFollowUps = await this.rdbService.queryFollowUpArchivesByArchiveAssessmentId(assessmentId);
    } catch (e) {
      this.archiveFollowUps = [];
    }
  }

  private async toggleCourseArchive(course: Course): Promise<void> {
    if (!this.rdbService) return;
    course.status = 'created';
    course.updatedAt = Date.now();
    await this.rdbService.updateCourse(course);
    await this.loadArchivedCourses();
  }

  private async confirmDeleteCourse(): Promise<void> {
    if (!this.rdbService) return;
    await this.rdbService.deleteCourse(this.deleteTargetCourseId);
    this.showSheet = false;
    await this.loadArchivedCourses();
  }

  private async applyColorMode(index: number): Promise<void> {
    this.colorModeIndex = index;
    this.showSheet = false;
    if (!this.preferencesService) return;
    let colorMode: number;
    if (index === 0) {
      colorMode = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;
    } else if (index === 1) {
      colorMode = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
    } else {
      colorMode = ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
    }
    await this.preferencesService.setColorMode(colorMode);
    try {
      const context = getContext(this) as common.UIAbilityContext;
      context.getApplicationContext().setColorMode(colorMode);
    } catch (e) {
      console.warn('[ProfilePage] Failed to set color mode:', e);
    }
  }

  build() {
    Column() {
    Scroll() {
      Column() {
        Row() {
          Text('我的')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.tech_blue_primary'))
        }
        .width('100%')
        .padding({ left: 0, right: 0, top: 16, bottom: 16 })

        Column() {
          Row() {
            Column() {
              Text(this.userName)
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_primary'))

              Text('三问学习用户')
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
                .margin({ top: 4 })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
        }
        .width('100%')
        .padding(16)
        .backgroundColor($r('app.color.card_background'))
        .borderRadius(12)


        Column() {
          Text('学习统计')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 16 })

          Row() {
            Column() {
              Text(this.totalCourses.toString())
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.tech_blue_primary'))
              Text('课程总数')
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
                .margin({ top: 4 })
            }
            .alignItems(HorizontalAlign.Center)

            Column() {
              Text(this.completedCourses.toString())
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.tech_blue_primary'))
              Text('已答题目')
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
                .margin({ top: 4 })
            }
            .alignItems(HorizontalAlign.Center)

            Column() {
              Text(this.totalAssessments.toString())
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.tech_blue_primary'))
              Text('测评数')
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
                .margin({ top: 4 })
            }
            .alignItems(HorizontalAlign.Center)

            Column() {
              Text(`${Math.round(this.averageScore)}`)
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.tech_blue_primary'))
              Text('平均分')
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
                .margin({ top: 4 })
            }
            .alignItems(HorizontalAlign.Center)
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
        }
        .width('100%')
        .padding(16)
        .backgroundColor($r('app.color.card_background'))
        .borderRadius(12)
        .margin({ top: 16 })

        Column() {
          Text('学习数据')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 12 })

          Text('周学习时长')
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
            .margin({ bottom: 8 })

          Stack() {
            LineChartWeb({ dates: this.lineChartDates, durations: this.lineChartDurations })
          }
          .width('100%')
          .height(260)
          .borderRadius(8)
          .clip(true)

          Text('学科能力对比')
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: 16, bottom: 8 })

          if (this.barCourseNames.length > 0) {
            Stack() {
              BarChartWeb({
                courseNames: this.barCourseNames,
                conceptScores: this.barConceptScores,
                criticalScores: this.barCriticalScores,
                practicalScores: this.barPracticalScores
              })
            }
            .width('100%')
            .height(260)
            .borderRadius(8)
            .clip(true)
          } else {
            Text('暂无测评报告数据')
              .fontSize(13)
              .fontColor($r('app.color.subtle_text'))
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding(20)
          }
        }
        .width('100%')
        .padding(16)
        .backgroundColor($r('app.color.card_background'))
        .borderRadius(12)
        .margin({ top: 16 })

        Column() {
          Text('归档管理')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 12 })

          if (this.archivedCourses.length === 0) {
            Text('暂无归档课程')
              .fontSize(13)
              .fontColor($r('app.color.subtle_text'))
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding(12)
          } else {
            ForEach(this.archivedCourses, (course: Course) => {
              Row() {
                Text(course.name)
                  .fontSize(14)
                  .fontColor($r('app.color.text_primary'))
                  .layoutWeight(1)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })

                Text('取消归档')
                  .fontSize(12)
                  .fontColor($r('app.color.tech_blue_primary'))
                  .margin({ right: 12 })
                  .onClick(() => this.toggleCourseArchive(course))

                Text('删除')
                  .fontSize(12)
                  .fontColor($r('app.color.error_color'))
                  .onClick(() => {
                    this.deleteTargetCourseId = course.id;
                    this.deleteTargetCourseName = course.name;
                    this.sheetMode = 'deleteConfirm';
                    this.showSheet = true;
                  })
              }
              .width('100%')
              .padding(12)
              .backgroundColor($r('app.color.page_background'))
              .borderRadius(8)
              .margin({ top: 8 })
            }, (course: Course) => course.id)
          }
        }
        .width('100%')
        .padding(16)
        .backgroundColor($r('app.color.card_background'))
        .borderRadius(12)
        .margin({ top: 16 })

        Column() {
          Text('上传历史')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 12 })

          if (this.uploadHistory.length === 0) {
            Text('暂无上传资料')
              .fontSize(13)
              .fontColor($r('app.color.subtle_text'))
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding(12)
          } else {
            ForEach(this.uploadHistory, (item: UploadHistoryItem, index: number) => {
              Column() {
                Text(item.courseName)
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('app.color.text_primary'))
                  .width('100%')
                  .margin({ bottom: 6 })

                ForEach(item.materials, (mat: MaterialInfo) => {
                  Row() {
                    Text(mat.fileName)
                      .fontSize(12)
                      .fontColor($r('app.color.text_secondary'))
                      .layoutWeight(1)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })

                    Text(this.formatDate(mat.createdAt))
                      .fontSize(11)
                      .fontColor($r('app.color.subtle_text'))
                  }
                  .width('100%')
                  .padding({ top: 4, bottom: 4 })
                }, (mat: MaterialInfo) => mat.id)
              }
              .width('100%')
              .padding(12)
              .backgroundColor($r('app.color.page_background'))
              .borderRadius(8)
              .margin({ top: index === 0 ? 0 : 8 })
            }, (_item: UploadHistoryItem, index: number) => String(index))
          }
        }
        .width('100%')
        .padding(16)
        .backgroundColor($r('app.color.card_background'))
        .borderRadius(12)
        .margin({ top: 16 })

        Column() {
          Text('答题档案')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 12 })

          if (this.archiveGroups.length === 0) {
            Text('暂无答题档案')
              .fontSize(13)
              .fontColor($r('app.color.subtle_text'))
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding(12)
          } else {
            ForEach(this.archiveGroups, (group: ArchiveGroup) => {
              Column() {
                Row() {
                  Text(group.courseName)
                    .fontSize(14)
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('app.color.text_primary'))
                    .layoutWeight(1)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  Text(`${group.assessments.length}题`)
                    .fontSize(12)
                    .fontColor($r('app.color.text_secondary'))

                  Image($r('app.media.ic_arrow_right'))
                    .width(16)
                    .height(16)
                    .fillColor($r('app.color.text_secondary'))
                    .margin({ left: 4 })
                    .rotate({ angle: this.expandedArchiveCourseId === group.courseId ? 90 : 0 })
                }
                .width('100%')
                .padding(12)
                .onClick(() => {
                  this.expandedArchiveCourseId = this.expandedArchiveCourseId === group.courseId ? '' : group.courseId;
                })

                if (this.expandedArchiveCourseId === group.courseId) {
                  ForEach(group.assessments, (a: ArchiveAssessment) => {
                    Column() {
                      Row() {
                        Text(this.getQuestionTypeLabel(a.questionType))
                          .fontSize(11)
                          .fontColor(Color.White)
                          .backgroundColor(this.getQuestionTypeColor(a.questionType))
                          .borderRadius(4)
                          .padding({ left: 6, right: 6, top: 2, bottom: 2 })

                        Text(a.isCorrect ? '✓' : '✗')
                          .fontSize(12)
                          .fontColor(a.isCorrect ? $r('app.color.success_color') : $r('app.color.error_color'))
                          .margin({ left: 8 })

                        Text(a.question)
                          .fontSize(13)
                          .fontColor($r('app.color.text_primary'))
                          .layoutWeight(1)
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                          .margin({ left: 8 })
                      }
                      .width('100%')
                      .padding(10)
                      .onClick(() => this.toggleArchiveAssessment(a.id))

                      if (this.expandedArchiveAssessmentId === a.id) {
                        Column() {
                          if (a.userAnswer) {
                            Text('你的答案：' + a.userAnswer)
                              .fontSize(12)
                              .fontColor($r('app.color.text_secondary'))
                              .width('100%')
                              .margin({ top: 4 })
                          }
                          if (a.correctAnswer) {
                            Text('正确答案：' + a.correctAnswer)
                              .fontSize(12)
                              .fontColor($r('app.color.success_color'))
                              .width('100%')
                              .margin({ top: 4 })
                          }
                          if (a.answer) {
                            Text('解析：' + a.answer)
                              .fontSize(12)
                              .fontColor($r('app.color.text_secondary'))
                              .width('100%')
                              .margin({ top: 4 })
                          }

                          if (this.archiveFollowUps.length > 0) {
                            Text('追问记录')
                              .fontSize(12)
                              .fontWeight(FontWeight.Medium)
                              .fontColor($r('app.color.text_primary'))
                              .width('100%')
                              .margin({ top: 8, bottom: 4 })

                            ForEach(this.archiveFollowUps, (fu: ArchiveFollowUp) => {
                              Row() {
                                Text(fu.role === 'user' ? '你' : 'AI')
                                  .fontSize(11)
                                  .fontColor(Color.White)
                                  .backgroundColor(fu.role === 'user' ? $r('app.color.link_color') : $r('app.color.success_color'))
                                  .borderRadius(4)
                                  .padding({ left: 4, right: 4, top: 1, bottom: 1 })

                                Text(fu.content)
                                  .fontSize(12)
                                  .fontColor($r('app.color.text_secondary'))
                                  .layoutWeight(1)
                                  .margin({ left: 6 })
                              }
                              .width('100%')
                              .padding({ top: 3, bottom: 3 })
                            }, (fu: ArchiveFollowUp) => fu.id)
                          }
                        }
                        .width('100%')
                        .padding({ left: 10, right: 10, bottom: 10 })
                      }
                    }
                    .width('100%')
                    .backgroundColor($r('app.color.card_item_background'))
                    .borderRadius(6)
                    .margin({ top: 6 })
                  }, (a: ArchiveAssessment) => a.id)
                }
              }
              .width('100%')
              .backgroundColor($r('app.color.page_background'))
              .borderRadius(8)
              .margin({ top: 8 })
            }, (group: ArchiveGroup) => group.courseId)
          }
        }
        .width('100%')
        .padding(16)
        .backgroundColor($r('app.color.card_background'))
        .borderRadius(12)
        .margin({ top: 16 })

        Column() {
          Text('数据管理')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 16 })

          Row() {
            Text('数据导出')
              .fontSize(14)
              .fontColor($r('app.color.text_primary'))
              .layoutWeight(1)

            Text('学习报告/错题集/对话记录')
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
              .margin({ right: 8 })

            Image($r('app.media.ic_arrow_right'))
              .width(20)
              .height(20)
              .fillColor($r('app.color.text_secondary'))
          }
          .width('100%')
          .padding(12)
          .backgroundColor($r('app.color.page_background'))
          .borderRadius(8)
          .onClick(async () => {
            if (!this.rdbService) return;
            const courseManager = new CourseManager(this.rdbService);
            this.courses = await courseManager.getAllCourses();
            this.exportCourseDialogController = new CustomDialogController({
              builder: ExportCoursePickerDialog({
                courses: this.courses,
                rdbService: this.rdbService!,
                onCourseSelected: (courseId: string) => {
                  this.exportDialogController = new CustomDialogController({
                    builder: ExportDialog({
                      courseId: courseId,
                      rdbService: this.rdbService
                    }),
                    autoCancel: true
                  });
                  this.exportDialogController!.open();
                }
              }),
              autoCancel: true
            });
            this.exportCourseDialogController!.open();
          })
        }
        .width('100%')
        .padding(16)
        .backgroundColor($r('app.color.card_background'))
        .borderRadius(12)
        .margin({ top: 16 })

        Column() {
          Text('设置')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 16 })

          Row() {
            Text('Deepseek API 密钥')
              .fontSize(14)
              .fontColor($r('app.color.text_primary'))
              .layoutWeight(1)

            Text(this.apiKey ? '已配置' : '未配置')
              .fontSize(14)
              .fontColor(this.apiKey ? $r('app.color.success_color') : $r('app.color.error_color'))

            Image($r('app.media.ic_arrow_right'))
              .width(20)
              .height(20)
              .fillColor($r('app.color.text_secondary'))
              .margin({ left: 8 })
          }
          .width('100%')
          .padding(12)
          .backgroundColor($r('app.color.page_background'))
          .borderRadius(8)
          .onClick(() => {
            this.tempApiKey = this.apiKey;
            this.apiKeyStatus = '';
            this.sheetMode = 'apiKey';
            this.showSheet = true;
          })

          Row() {
            Text('暗色模式')
              .fontSize(14)
              .fontColor($r('app.color.text_primary'))
              .layoutWeight(1)

            Text(['跟随系统', '亮色', '暗色'][this.colorModeIndex])
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))

            Image($r('app.media.ic_arrow_right'))
              .width(20)
              .height(20)
              .fillColor($r('app.color.text_secondary'))
              .margin({ left: 8 })
          }
          .width('100%')
          .padding(12)
          .backgroundColor($r('app.color.page_background'))
          .borderRadius(8)
          .margin({ top: 12 })
          .onClick(() => {
            this.sheetMode = 'colorMode';
            this.showSheet = true;
          })

          Row() {
            Text('关于')
              .fontSize(14)
              .fontColor($r('app.color.text_primary'))
              .layoutWeight(1)

            Image($r('app.media.ic_arrow_right'))
              .width(20)
              .height(20)
              .fillColor($r('app.color.text_secondary'))
          }
          .width('100%')
          .padding(12)
          .backgroundColor($r('app.color.page_background'))
          .borderRadius(8)
          .margin({ top: 12 })
        }
        .width('100%')
        .padding(16)
        .backgroundColor($r('app.color.card_background'))
        .borderRadius(12)
        .margin({ top: 16 })

      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .layoutWeight(1)
    .backgroundColor($r('app.color.page_background'))
    .align(Alignment.TopStart)

    this.BottomNavigation()
  }
  .width('100%')
  .height('100%')
  .backgroundColor($r('app.color.page_background'))
  .bindSheet($$this.showSheet, this.MainSheet())


  }

  private formatDate(timestamp: number): string {
    const d = new Date(timestamp);
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
  }

  private getQuestionTypeLabel(type: QuestionType): string {
    switch (type) {
      case 'singleChoice': return '单选';
      case 'multipleChoice': return '多选';
      case 'trueFalse': return '判断';
      case 'subjective': return '主观';
      default: return '主观';
    }
  }

  private getQuestionTypeColor(type: QuestionType): string {
    switch (type) {
      case 'singleChoice': return '#FB6B98';
      case 'multipleChoice': return '#FFD55A';
      case 'trueFalse': return '#79D291';
      case 'subjective': return '#00B4DD';
      default: return '#00B4DD';
    }
  }

  @Builder
  @Builder

  MainSheet(): void {
    Column() {
      if (this.sheetMode === 'apiKey') {
        Text('配置 API 密钥')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 16 })

        Text('请输入您的 Deepseek API 密钥，用于三问认知引擎的 AI 能力。密钥将安全存储在本地。')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .margin({ bottom: 16 })

        TextInput({ placeholder: 'sk-...', text: this.tempApiKey })
          .width('100%')
          .height(48)
          .type(InputType.Normal)
          .onChange((value: string) => {
            this.tempApiKey = value;
          })

        if (this.apiKeyStatus) {
          Text(this.apiKeyStatus)
            .fontSize(14)
            .fontColor($r('app.color.error_color'))
            .margin({ top: 8 })
        }

        Row() {
          Button('取消')
            .layoutWeight(1)
            .backgroundColor(Color.Transparent)
            .fontColor($r('app.color.text_secondary'))
            .onClick(() => {
              this.showSheet = false;
            })

          Button('保存')
            .layoutWeight(1)
            .backgroundColor($r('app.color.tech_blue_primary'))
            .enabled(!this.isSaving)
            .onClick(async () => {
              if (!this.tempApiKey || this.tempApiKey.trim().length === 0) {
                this.apiKeyStatus = '请输入有效的 API 密钥';
                return;
              }
              this.isSaving = true;
              this.apiKeyStatus = '';
              try {
                if (this.preferencesService) {
                  await this.preferencesService.setApiKey(this.tempApiKey.trim());
                  this.apiKey = this.tempApiKey.trim();
                  this.showSheet = false;
                }
              } catch (err) {
                this.apiKeyStatus = '保存失败，请重试';
              } finally {
                this.isSaving = false;
              }
            })
        }
        .width('100%')
        .margin({ top: 24 })
      } else if (this.sheetMode === 'colorMode') {
        Text('暗色模式')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 16 })

        ForEach(['跟随系统', '亮色', '暗色'], (label: string, index: number) => {
          Row() {
            Text(label)
              .fontSize(16)
              .fontColor(index === this.colorModeIndex ? $r('app.color.tech_blue_primary') : $r('app.color.text_primary'))
              .layoutWeight(1)

            if (index === this.colorModeIndex) {
              Text('✓')
                .fontSize(16)
                .fontColor($r('app.color.tech_blue_primary'))
            }
          }
          .width('100%')
          .padding(16)
          .onClick(() => this.applyColorMode(index))
        }, (_label: string, index: number) => String(index))
      } else if (this.sheetMode === 'deleteConfirm') {
        Text('确认删除')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 16 })

        Text(`确定要删除课程"${this.deleteTargetCourseName}"吗？此操作不可恢复。`)
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .margin({ bottom: 24 })

        Row() {
          Button('取消')
            .layoutWeight(1)
            .backgroundColor(Color.Transparent)
            .fontColor($r('app.color.text_secondary'))
            .onClick(() => {
              this.showSheet = false;
            })

          Button('删除')
            .layoutWeight(1)
            .backgroundColor($r('app.color.error_color'))
            .fontColor(Color.White)
            .onClick(() => this.confirmDeleteCourse())
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(24)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius({ topLeft: 24, topRight: 24 })
  }

  @Builder
  BottomNavigation(): void {
    Row() {
      Column() {
        Image($r('app.media.ic_home'))
          .width(24)
          .height(24)
          .fillColor($r('app.color.text_secondary'))

        Text('首页')
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .onClick(() => {
        router.replaceUrl({ url: 'pages/MainPage' });
      })

      Column() {
        Image($r('app.media.ic_list'))
          .width(24)
          .height(24)
          .fillColor($r('app.color.text_secondary'))

        Text('测评')
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .onClick(() => {
        router.replaceUrl({ url: 'pages/AssessmentCenterPage' });
      })

      Column() {
        Image($r('app.media.ic_settings'))
          .width(24)
          .height(24)
          .fillColor($r('app.color.tech_blue_primary'))

        Text('我的')
          .fontSize(12)
          .fontColor($r('app.color.tech_blue_primary'))
          .margin({ top: 4 })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height(56)
    .backgroundColor($r('app.color.card_background'))
    .shadow({ radius: 8, color: '#1A000000', offsetX: 0, offsetY: -2 })
  }
}

@CustomDialog
struct ExportCoursePickerDialog {
  @Prop courses: Course[] = [];
  rdbService: RDBService | null = null;
  onCourseSelected?: (courseId: string) => void;
  controller: CustomDialogController;

  build() {
    Column() {
      Text('选择课程')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 16 })

      if (this.courses.length === 0) {
        Text('暂无课程')
          .fontSize(14)
          .fontColor($r('app.color.subtle_text'))
      } else {
        List() {
          ForEach(this.courses, (course: Course) => {
            ListItem() {
              Row() {
                Text(course.name)
                  .fontSize(16)
                  .fontColor($r('app.color.text_primary'))
                  .layoutWeight(1)
                Image($r('app.media.ic_arrow_right'))
                  .width(20)
                  .height(20)
                  .fillColor($r('app.color.subtle_text'))
              }
              .width('100%')
              .padding(12)
              .onClick(() => {
                if (this.onCourseSelected) {
                  this.onCourseSelected(course.id);
                }
                try {
                  this.controller.close();
                } catch (_e) {}
              })
            }
          }, (course: Course) => course.id)
        }
        .width('100%')
        .height(300)
      }
    }
    .padding(24)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(16)
  }
}
