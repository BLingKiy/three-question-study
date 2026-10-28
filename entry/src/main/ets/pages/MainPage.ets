import { Course } from '../model/Course';
import { CourseCard } from '../components/CourseCard';
import { LoadingIndicator } from '../components/LoadingIndicator';
import { ErrorDialog } from '../components/ErrorDialog';
import { CourseManager } from '../services/CourseManager';
import { RDBService } from '../services/RDBService';
import { PreferencesService } from '../services/PreferencesService';
import { DeepseekService, WebSearchResult } from '../services/DeepseekService';
import { ThreeQuestionEngine } from '../services/ThreeQuestionEngine';
import { KnowledgeSource } from '../model/KnowledgeSource';
import { generateUUID } from '../utils/UUIDUtil';
import router from '@ohos.router';

@Entry
@Component
struct MainPage {
  @State courses: Course[] = [];
  @State archivedCourses: Course[] = [];
  @State archivedExpanded: boolean = false;
  @State searchQuery: string = '';
  @State sortMethod: string = 'updatedAt';
  @State isLoading: boolean = false;
  @State showCreateDialog: boolean = false;
  @State newCourseName: string = '';
  @State newCourseQuestion: string = '';
  @State errorMessage: string = '';
  @State isCreating: boolean = false;
  @State hasApiKey: boolean = false;
  @State retryingCourseId: string = '';
  @State courseProgressMap: Map<string, number> = new Map();

  private rdbService: RDBService | null = null;
  private courseManager: CourseManager | null = null;
  private preferencesService: PreferencesService | null = null;
  private deepseekService: DeepseekService | null = null;
  private threeQuestionEngine: ThreeQuestionEngine | null = null;

  aboutToAppear(): void {
    this.initializeServices(getContext(this));
  }

  onPageShow(): void {
    if (this.rdbService) {
      this.loadCourses();
    }
  }

  private async initializeServices(context: Context): Promise<void> {
    try {
      this.rdbService = new RDBService(context);
      await this.rdbService.initialize();
      this.courseManager = new CourseManager(this.rdbService);
      this.preferencesService = new PreferencesService(context);
      await this.preferencesService.initialize();
      this.deepseekService = new DeepseekService(this.preferencesService);
      this.threeQuestionEngine = new ThreeQuestionEngine(this.deepseekService, this.rdbService);
      this.hasApiKey = await this.preferencesService.hasApiKey();
      await this.loadCourses();
    } catch (err) {
      this.errorMessage = '初始化失败：' + (err as Error).message;
    }
  }

  private async loadCourses(): Promise<void> {
    if (!this.courseManager) return;

    this.isLoading = true;
    try {
      const allCourses = await this.courseManager.getAllCourses();
      this.courses = allCourses.filter(c => c.status !== 'archived');
      this.archivedCourses = allCourses.filter(c => c.status === 'archived');
      await this.loadAllProgress();
    } catch (err) {
      this.errorMessage = '加载课程失败';
    } finally {
      this.isLoading = false;
    }
  }

  private async loadAllProgress(): Promise<void> {
    if (!this.rdbService) return;
    const newMap = new Map<string, number>();
    for (const course of this.courses) {
      const progress = await this.calculateCourseProgress(course.id);
      newMap.set(course.id, progress);
    }
    for (const course of this.archivedCourses) {
      const progress = await this.calculateCourseProgress(course.id);
      newMap.set(course.id, progress);
    }
    this.courseProgressMap = newMap;
  }

  private async calculateCourseProgress(courseId: string): Promise<number> {
    if (!this.rdbService) return 0;
    return await this.rdbService.calculateCourseProgress(courseId);
  }

  build() {
    Column() {
      Row() {
        Text('三问学习')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.tech_blue_primary'))

        Blank()

        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.ic_add'))
            .width(24)
            .height(24)
            .fillColor(Color.White)
        }
        .width(40)
        .height(40)
        .backgroundColor($r('app.color.tech_blue_primary'))
        .onClick(() => {
          if (!this.hasApiKey) {
            this.errorMessage = '请先在"我的"页面配置 Deepseek API 密钥';
            return;
          }
          this.errorMessage = '';
          this.showCreateDialog = true;
        })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })

      if (this.errorMessage) {
        Row() {
          Text(this.errorMessage)
            .fontSize(14)
            .fontColor($r('app.color.error_color'))
            .layoutWeight(1)

          Text('×')
            .fontSize(18)
            .fontColor($r('app.color.text_secondary'))
            .onClick(() => {
              this.errorMessage = '';
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .backgroundColor('#FFF3E0')
      }

      Row() {
        Image($r('app.media.ic_search'))
          .width(20)
          .height(20)
          .fillColor($r('app.color.text_secondary'))
          .margin({ right: 8 })

        TextInput({ placeholder: '搜索课程...' })
          .layoutWeight(1)
          .backgroundColor(Color.Transparent)
          .onChange((value: string) => {
            this.searchQuery = value;
          })

        Image($r('app.media.ic_sort'))
          .width(20)
          .height(20)
          .fillColor($r('app.color.text_secondary'))
          .margin({ left: 8 })
          .bindMenu(this.getSortMenuItems())
      }
      .width('100%')
      .height(48)
      .padding({ left: 16, right: 16 })
      .backgroundColor($r('app.color.page_background'))
      .borderRadius(24)
      .margin({ left: 16, right: 16, bottom: 16 })

      if (this.isLoading) {
        LoadingIndicator({ text: '加载课程...' })
      } else if (this.getFilteredCourses().length === 0 && this.archivedCourses.length === 0) {
        Column() {
          Image($r('app.media.ic_folder'))
            .width(64)
            .height(64)
            .fillColor($r('app.color.text_secondary'))
            .margin({ bottom: 16 })

          Text('暂无课程')
            .fontSize(16)
            .fontColor($r('app.color.text_secondary'))

          Text('点击右上角按钮创建新课程')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: 8 })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        Scroll() {
          Column() {
            if (this.getFilteredCourses().length > 0) {
              Grid() {
                ForEach(this.getFilteredCourses(), (course: Course) => {
                  GridItem() {
                    CourseCard({
                      course: course,
                      progress: this.calculateProgress(course),
                      isRetrying: this.retryingCourseId === course.id,
                      onCardClick: (c: Course) => {
                        this.touchCourse(c.id);
                        router.pushUrl({
                          url: 'pages/LearningSpacePage',
                          params: { courseId: c.id, courseName: c.name, courseQuestion: c.question }
                        });
                      },
                      onDeleteClick: async (c: Course) => {
                        if (this.courseManager) {
                          await this.courseManager.deleteCourse(c.id);
                          await this.loadCourses();
                        }
                      },
                      onRetryQ1Click: async (c: Course) => {
                        await this.handleRetryQ1(c);
                      },
                      onRetryQ2Click: async (c: Course) => {
                        await this.handleRetryQ2(c);
                      },
                      onArchiveClick: async (c: Course) => {
                        await this.handleArchiveCourse(c);
                      },
                      onUnarchiveClick: async (c: Course) => {
                        await this.handleUnarchiveCourse(c);
                      },
                      onCompleteClick: async (c: Course) => {
                        await this.handleCompleteCourse(c);
                      },
                      onUncompleteClick: async (c: Course) => {
                        await this.handleUncompleteCourse(c);
                      }
                    })
                  }
                })
              }
              .columnsTemplate('1fr 1fr')
              .rowsGap(16)
              .columnsGap(16)
              .padding({ left: 16, right: 16, top: 0, bottom: 0 })
            }

            if (this.archivedCourses.length > 0) {
              Column() {
                Row() {
                  Text(`已归档课程(${this.archivedCourses.length})`)
                    .fontSize(14)
                    .fontColor($r('app.color.text_secondary'))
                    .layoutWeight(1)

                  Image($r('app.media.ic_arrow_right'))
                    .width(16)
                    .height(16)
                    .fillColor($r('app.color.text_secondary'))
                    .rotate({ angle: this.archivedExpanded ? 90 : 0 })
                }
                .width('100%')
                .padding({ left: 16, right: 16, top: 12, bottom: 12 })
                .onClick(() => {
                  this.archivedExpanded = !this.archivedExpanded;
                })

                if (this.archivedExpanded) {
                  Grid() {
                    ForEach(this.archivedCourses, (course: Course) => {
                      GridItem() {
                        CourseCard({
                          course: course,
                          progress: this.calculateProgress(course),
                          isRetrying: false,
                          onCardClick: (c: Course) => {
                            this.touchCourse(c.id);
                            router.pushUrl({
                              url: 'pages/LearningSpacePage',
                              params: { courseId: c.id, courseName: c.name, courseQuestion: c.question }
                            });
                          },
                          onDeleteClick: async (c: Course) => {
                            if (this.courseManager) {
                              await this.courseManager.deleteCourse(c.id);
                              await this.loadCourses();
                            }
                          },
                          onArchiveClick: async (c: Course) => {
                            await this.handleArchiveCourse(c);
                          },
                          onUnarchiveClick: async (c: Course) => {
                            await this.handleUnarchiveCourse(c);
                          },
                          onCompleteClick: async (c: Course) => {
                            await this.handleCompleteCourse(c);
                          },
                          onUncompleteClick: async (c: Course) => {
                            await this.handleUncompleteCourse(c);
                          }
                        })
                        .opacity(0.6)
                      }
                    })
                  }
                  .columnsTemplate('1fr 1fr')
                  .rowsGap(16)
                  .columnsGap(16)
                  .padding({ left: 16, right: 16, top: 0, bottom: 8 })
                }
              }
              .width('100%')
              .margin({ top: 16 })
            }
          }
          .alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1)
        .clip(true)
        .align(Alignment.TopStart)
      }

      this.BottomNavigation()
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
    .bindSheet($$this.showCreateDialog, this.CreateCourseSheet())
  }

  private getSortMenuItems(): MenuElement[] {
    return [
      {
        value: this.sortMethod === 'updatedAt' ? '✓ 按最近使用时间' : '按最近使用时间',
        action: () => { this.sortMethod = 'updatedAt'; }
      },
      {
        value: this.sortMethod === 'createdAt' ? '✓ 按创建时间' : '按创建时间',
        action: () => { this.sortMethod = 'createdAt'; }
      },
      {
        value: this.sortMethod === 'progress' ? '✓ 按学习进度' : '按学习进度',
        action: () => { this.sortMethod = 'progress'; }
      }
    ];
  }

  private getFilteredCourses(): Course[] {
    let filtered = this.courses;
    if (this.searchQuery) {
      const query = this.searchQuery.toLowerCase();
      filtered = filtered.filter(c =>
        c.name.toLowerCase().includes(query) ||
        c.question.toLowerCase().includes(query)
      );
    }

    const sorted = [...filtered];
    if (this.sortMethod === 'updatedAt') {
      sorted.sort((a, b) => b.updatedAt - a.updatedAt);
    } else if (this.sortMethod === 'createdAt') {
      sorted.sort((a, b) => b.createdAt - a.createdAt);
    } else if (this.sortMethod === 'progress') {
      sorted.sort((a, b) => {
        const pa = this.courseProgressMap.get(a.id) || 0;
        const pb = this.courseProgressMap.get(b.id) || 0;
        return pb - pa;
      });
    }
    return sorted;
  }

  private calculateProgress(course: Course): number {
    const progress = this.courseProgressMap.get(course.id);
    if (progress !== undefined) {
      return Math.round(progress * 100);
    }
    return 0;
  }

  private async handleArchiveCourse(course: Course): Promise<void> {
    if (!this.courseManager) return;
    await this.courseManager.archiveCourse(course.id);
    await this.loadCourses();
  }

  private async touchCourse(courseId: string): Promise<void> {
    if (!this.rdbService) return;
    const course = this.courses.find(c => c.id === courseId) || this.archivedCourses.find(c => c.id === courseId);
    if (!course) return;
    course.updatedAt = Date.now();
    await this.rdbService.updateCourse(course);
  }

  private async handleUnarchiveCourse(course: Course): Promise<void> {
    if (!this.courseManager) return;
    await this.courseManager.updateCourseStatus(course.id, 'active');
    await this.loadCourses();
  }

  private async handleCompleteCourse(course: Course): Promise<void> {
    if (!this.courseManager) return;
    await this.courseManager.completeCourse(course.id);
    await this.loadCourses();
  }

  private async handleUncompleteCourse(course: Course): Promise<void> {
    if (!this.courseManager) return;
    await this.courseManager.updateCourseStatus(course.id, 'active');
    await this.loadCourses();
  }

  private async handleRetryQ1(course: Course): Promise<void> {
    if (!this.threeQuestionEngine || !this.courseManager) return;
    this.retryingCourseId = course.id;
    this.errorMessage = '';
    try {
      await this.threeQuestionEngine.regenerateQuestion1(course.id, course.question);
      await this.courseManager.markMentalModelGenerated(course.id);
      await this.loadCourses();
    } catch (err) {
      this.errorMessage = '重试知识图谱失败：' + (err as Error).message;
    } finally {
      this.retryingCourseId = '';
    }
  }

  private async handleRetryQ2(course: Course): Promise<void> {
    if (!this.threeQuestionEngine || !this.courseManager) return;
    this.retryingCourseId = course.id;
    this.errorMessage = '';
    try {
      await this.threeQuestionEngine.regenerateQuestion2(course.id, course.question);
      await this.courseManager.markControversyGenerated(course.id);
      await this.loadCourses();
    } catch (err) {
      this.errorMessage = '重试争议分析失败：' + (err as Error).message;
    } finally {
      this.retryingCourseId = '';
    }
  }

  @Builder
  CreateCourseSheet(): void {
    Column() {
      Text('创建新课程')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 24 })

      TextInput({ placeholder: '课程名称' })
        .width('100%')
        .height(48)
        .margin({ bottom: 16 })
        .onChange((value: string) => {
          this.newCourseName = value;
        })

      TextArea({ placeholder: '输入你的学习问题...' })
        .width('100%')
        .height(120)
        .margin({ bottom: 24 })
        .onChange((value: string) => {
          this.newCourseQuestion = value;
        })

      if (this.isCreating) {
        Row() {
          LoadingProgress()
            .width(20)
            .height(20)
            .color($r('app.color.tech_blue_primary'))
            .margin({ right: 8 })

          Text('正在创建课程并执行三问引擎...')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .margin({ bottom: 16 })
      }

      Row() {
        Button('取消')
          .layoutWeight(1)
          .backgroundColor(Color.Transparent)
          .fontColor($r('app.color.text_secondary'))
          .enabled(!this.isCreating)
          .onClick(() => {
            this.showCreateDialog = false;
          })

        Button('创建')
          .layoutWeight(1)
          .backgroundColor($r('app.color.tech_blue_primary'))
          .enabled(!this.isCreating && !!this.newCourseQuestion)
          .onClick(async () => {
            await this.handleCreateCourse();
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(24)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius({ topLeft: 24, topRight: 24 })
  }

  private async handleCreateCourse(): Promise<void> {
    if (!this.courseManager || !this.threeQuestionEngine || !this.newCourseQuestion) return;

    this.isCreating = true;
    this.errorMessage = '';
    try {
      const course = await this.courseManager.createCourse({
        name: this.newCourseName || this.newCourseQuestion.substring(0, 20),
        question: this.newCourseQuestion
      });

      this.showCreateDialog = false;
      this.newCourseName = '';
      this.newCourseQuestion = '';
      await this.loadCourses();

      let webSearchWarning = '';
      try {
        if (this.deepseekService && this.rdbService) {
          const webResult = await this.deepseekService.webSearch(course.question);
          if (webResult.searchResults.length > 0) {
            for (const sr of webResult.searchResults) {
              if (!sr.title || !sr.url) continue;
              const source = new KnowledgeSourceImpl();
              source.id = generateUUID();
              source.courseId = course.id;
              source.nodeId = '';
              source.title = sr.title;
              source.url = sr.url;
              source.type = 'web';
              await this.rdbService.insertKnowledgeSource(source);
            }
          }
          if (webResult.content) {
            await this.threeQuestionEngine.executeQuestion1(course.id, course.question, webResult.content);
          } else {
            await this.threeQuestionEngine.executeQuestion1(course.id, course.question);
          }
        } else {
          await this.threeQuestionEngine.executeQuestion1(course.id, course.question);
        }
      } catch (wsErr) {
        console.warn('[MainPage] WebSearch failed, proceeding without web data:', wsErr);
        webSearchWarning = '网络搜索失败，仅使用本地资料';
        await this.threeQuestionEngine.executeQuestion1(course.id, course.question);
      }

      if (this.courseManager) {
        await this.courseManager.markMentalModelGenerated(course.id);
      }

      if (webSearchWarning) {
        this.errorMessage = webSearchWarning;
      }

      try {
        await this.threeQuestionEngine.executeQuestion2(course.id, course.question);
        if (this.courseManager) {
          await this.courseManager.markControversyGenerated(course.id);
        }
      } catch (engineErr) {
        console.error('[MainPage] Three question engine failed:', engineErr);
        this.errorMessage = '课程已创建，但三问引擎执行失败，请检查API密钥后重试';
      }

      await this.loadCourses();
    } catch (err) {
      this.errorMessage = '创建失败：' + (err as Error).message;
    } finally {
      this.isCreating = false;
    }
  }

  @Builder
  BottomNavigation(): void {
    Row() {
      Column() {
        Image($r('app.media.ic_home'))
          .width(24)
          .height(24)
          .fillColor($r('app.color.tech_blue_primary'))

        Text('首页')
          .fontSize(12)
          .fontColor($r('app.color.tech_blue_primary'))
          .margin({ top: 4 })
      }
      .layoutWeight(1)

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
          .fillColor($r('app.color.text_secondary'))

        Text('我的')
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .onClick(() => {
        router.replaceUrl({ url: 'pages/ProfilePage' });
      })
    }
    .width('100%')
    .height(56)
    .backgroundColor($r('app.color.card_background'))
    .shadow({ radius: 8, color: '#1A000000', offsetX: 0, offsetY: -2 })
  }
}

class KnowledgeSourceImpl implements KnowledgeSource {
  id: string = '';
  courseId: string = '';
  nodeId: string = '';
  title: string = '';
  url: string = '';
  type: 'web' | 'user' = 'web';
}
