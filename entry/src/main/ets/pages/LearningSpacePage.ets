import { KnowledgeNode } from '../model/KnowledgeNode';
import { KnowledgeEdge } from '../model/KnowledgeEdge';
import { KnowledgeGraphWeb } from '../components/KnowledgeGraphWeb';
import { NodeDetailSheet } from '../components/NodeDetailSheet';
import { ControversyCard } from '../components/ControversyCard';
import { LoadingIndicator } from '../components/LoadingIndicator';
import { ParsedControversy, ControversyView } from '../services/ResponseParser';
import { RDBService } from '../services/RDBService';
import { KnowledgeBaseManager } from '../services/KnowledgeBaseManager';
import { FileService, MaterialInfo } from '../services/FileService';
import { ThreeQuestionEngine } from '../services/ThreeQuestionEngine';
import { DeepseekService } from '../services/DeepseekService';
import { PreferencesService } from '../services/PreferencesService';
import { CourseManager } from '../services/CourseManager';
import { KnowledgeSource } from '../model/KnowledgeSource';
import { MarkdownUtil, MdBlock } from '../utils/MarkdownUtil';
import common from '@ohos.app.ability.common';
import picker from '@ohos.file.picker';
import fs from '@ohos.file.fs';
import router from '@ohos.router';

@Entry
@Component
struct LearningSpacePage {
  @State courseId: string = '';
  @State courseName: string = '';
  @State courseQuestion: string = '';
  @State nodes: KnowledgeNode[] = [];
  @State edges: KnowledgeEdge[] = [];
  @State graphVersion: number = 0;
  @State controversies: ParsedControversy[] = [];
  @State materials: MaterialInfo[] = [];
  @State knowledgeSources: KnowledgeSource[] = [];
  @State isLoading: boolean = true;
  @State isRegenerating: boolean = false;
  @State errorMessage: string = '';
  @State showNodeDetail: boolean = false;
  @State sheetMode: string = 'node';
  @State selectedNode: KnowledgeNode | null = null;
  @State selectedNodeIncomingEdges: KnowledgeEdge[] = [];
  @State selectedNodeOutgoingEdges: KnowledgeEdge[] = [];
  @State selectedNodeSources: KnowledgeSource[] = [];
  @State mentalModelGenerated: boolean = false;
  @State controversyGenerated: boolean = false;
  @State mentalModelChecked: boolean = false;
  @State controversyCheckedMap: Map<string, boolean> = new Map();
  @State materialCheckedMap: Map<string, boolean> = new Map();
  @State learningProgress: number = 0;


  @State detailTitle: string = '';
  @State detailContent: string = '';

  private rdbService: RDBService | null = null;
  private knowledgeBaseManager: KnowledgeBaseManager | null = null;
  private pollingTimer: number = -1;
  private sessionStartTime: number = 0;

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    if (params) {
      this.courseId = params['courseId'] || '';
      this.courseName = params['courseName'] || '';
      this.courseQuestion = params['courseQuestion'] || '';
    }
    this.sessionStartTime = Date.now();
    this.initializeServices(getContext(this));
  }

  aboutToDisappear(): void {
    if (this.pollingTimer !== -1) {
      clearInterval(this.pollingTimer);
      this.pollingTimer = -1;
    }
    this.saveStudyDuration();
  }

  private async saveStudyDuration(): Promise<void> {
    if (!this.rdbService || !this.courseId || this.sessionStartTime === 0) return;
    const durationSeconds = Math.floor((Date.now() - this.sessionStartTime) / 1000);
    if (durationSeconds < 1) return;
    const now = new Date();
    const dateStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
    try {
      await this.rdbService.saveStudySession(this.courseId, dateStr, durationSeconds);
    } catch (e) {
      console.warn('[LearningSpacePage] Failed to save study session:', e);
    }
  }

  private async initializeServices(context: Context): Promise<void> {
    try {
      this.rdbService = new RDBService(context);
      await this.rdbService.initialize();
      const fileService = new FileService(context);
      await fileService.initialize();
      this.knowledgeBaseManager = new KnowledgeBaseManager(this.rdbService, fileService);
      await this.loadData();
      this.startPolling();
    } catch (err) {
      this.errorMessage = '初始化失败：' + (err as Error).message;
      this.isLoading = false;
    }
  }

  private async loadData(): Promise<void> {
    if (!this.knowledgeBaseManager || !this.rdbService) return;

    try {
      const courseManager = new CourseManager(this.rdbService);
      const course = await courseManager.getCourseById(this.courseId);
      if (course) {
        this.mentalModelGenerated = course.mentalModelGenerated;
        this.controversyGenerated = course.controversyGenerated;
      }

      if (this.mentalModelGenerated) {
        const graph = await this.knowledgeBaseManager.getKnowledgeGraph(this.courseId);
        this.nodes = graph.nodes;
        this.edges = graph.edges;
      }

      if (this.controversyGenerated) {
        const controversyNodes = await this.knowledgeBaseManager.getControversyNodes(this.courseId);
        this.controversies = controversyNodes.map(n => {
          const c = new ParsedControversyImpl();
          c.id = n.id;
          c.topic = n.label;
          try {
            const data = n.content ? JSON.parse(n.content) as Record<string, Object> : {} as Record<string, Object>;
            if (!data['leftView'] && !data['rightView']) {
              return null;
            }
            c.topic = String(data['topic'] || n.label);
            const leftData = (data['leftView'] || {}) as Record<string, Object>;
            const lv = new ControversyViewImpl();
            lv.title = String(leftData['title'] || '观点A');
            lv.arguments = (leftData['arguments'] as string[]) || [];
            lv.evidence = (leftData['evidence'] as string[]) || [];
            c.leftView = lv;
            const rightData = (data['rightView'] || {}) as Record<string, Object>;
            const rv = new ControversyViewImpl();
            rv.title = String(rightData['title'] || '观点B');
            rv.arguments = (rightData['arguments'] as string[]) || [];
            rv.evidence = (rightData['evidence'] as string[]) || [];
            c.rightView = rv;
            c.synthesis = String(data['synthesis'] || '');
          } catch (e) {
            return null;
          }
          return c;
        }).filter((c: ParsedControversy | null) => c !== null) as ParsedControversy[];
      }

      this.materials = await this.knowledgeBaseManager.getMaterials(this.courseId);
      this.knowledgeSources = await this.rdbService.queryKnowledgeSourcesByCourseId(this.courseId);
      await this.loadProgress();
      await this.ensureProgressRecords();
    } catch (err) {
      this.errorMessage = '加载数据失败';
    } finally {
      this.isLoading = false;
    }
  }

  private startPolling(): void {
    if (this.mentalModelGenerated && this.controversyGenerated) return;

    this.pollingTimer = setInterval(async () => {
      if (!this.rdbService) return;
      try {
        const courseManager = new CourseManager(this.rdbService);
        const course = await courseManager.getCourseById(this.courseId);
        if (!course) return;

        const prevMental = this.mentalModelGenerated;
        const prevControversy = this.controversyGenerated;
        this.mentalModelGenerated = course.mentalModelGenerated;
        this.controversyGenerated = course.controversyGenerated;

        if (!prevMental && this.mentalModelGenerated && this.knowledgeBaseManager) {
          const graph = await this.knowledgeBaseManager.getKnowledgeGraph(this.courseId);
          this.nodes = graph.nodes;
          this.edges = graph.edges;
        }

        if (!prevControversy && this.controversyGenerated && this.knowledgeBaseManager) {
          const controversyNodes = await this.knowledgeBaseManager.getControversyNodes(this.courseId);
          this.controversies = controversyNodes.map(n => {
            const c = new ParsedControversyImpl();
            c.id = n.id;
            c.topic = n.label;
            try {
              const data = n.content ? JSON.parse(n.content) as Record<string, Object> : {} as Record<string, Object>;
              if (!data['leftView'] && !data['rightView']) {
                return null;
              }
              c.topic = String(data['topic'] || n.label);
              const leftData = (data['leftView'] || {}) as Record<string, Object>;
              const lv = new ControversyViewImpl();
              lv.title = String(leftData['title'] || '观点A');
              lv.arguments = (leftData['arguments'] as string[]) || [];
              lv.evidence = (leftData['evidence'] as string[]) || [];
              c.leftView = lv;
              const rightData = (data['rightView'] || {}) as Record<string, Object>;
              const rv = new ControversyViewImpl();
              rv.title = String(rightData['title'] || '观点B');
              rv.arguments = (rightData['arguments'] as string[]) || [];
              rv.evidence = (rightData['evidence'] as string[]) || [];
              c.rightView = rv;
              c.synthesis = String(data['synthesis'] || '');
            } catch (e) {
              return null;
            }
            return c;
        }).filter((c: ParsedControversy | null) => c !== null) as ParsedControversy[];
        }

        if (this.mentalModelGenerated && this.controversyGenerated) {
          clearInterval(this.pollingTimer);
          this.pollingTimer = -1;
        }
      } catch (err) {
        console.warn('[LearningSpacePage] Polling error:', err);
      }
    }, 2000);
  }

  private async handleNodeClick(nodeId: string): Promise<void> {
    if (!this.knowledgeBaseManager || !this.rdbService) return;

    try {
      const details = await this.knowledgeBaseManager.getNodeDetails(nodeId);
      this.selectedNode = details.node;
      this.selectedNodeIncomingEdges = details.incomingEdges;
      this.selectedNodeOutgoingEdges = details.outgoingEdges;
      this.selectedNodeSources = await this.rdbService.queryKnowledgeSourcesByNodeId(nodeId);
      this.sheetMode = 'node';
      this.showNodeDetail = true;
    } catch (err) {
      console.error('[LearningSpacePage] Failed to load node details:', err);
    }
  }

  private async handleRegenerate(): Promise<void> {
    if (!this.rdbService) return;

    this.isRegenerating = true;
    this.errorMessage = '';

    try {
      const preferencesService = new PreferencesService(getContext(this));
      await preferencesService.initialize();
      const deepseekService = new DeepseekService(preferencesService);
      const engine = new ThreeQuestionEngine(deepseekService, this.rdbService);
      const courseManager = new CourseManager(this.rdbService);

      await engine.regenerateAll(this.courseId, this.courseQuestion, await this.collectMaterialsContent());
      await this.rdbService.archiveAnsweredAssessments(this.courseId, this.courseName);
      await this.rdbService.resetCourseAfterRegenerate(this.courseId);
      await courseManager.markMentalModelGenerated(this.courseId);
      await courseManager.markControversyGenerated(this.courseId);
      this.mentalModelGenerated = true;
      this.controversyGenerated = true;
      await this.loadData();
      this.graphVersion++;
    } catch (err) {
      const msg = (err as Error).message;
      if (msg.includes('API密钥未配置')) {
        this.errorMessage = '请先在「我的」页面配置 API 密钥';
      } else {
        this.errorMessage = '重新生成失败：' + msg;
      }
    } finally {
      this.isRegenerating = false;
    }
  }

  build() {
    Column() {
      Row() {
        Image($r('app.media.ic_arrow_left'))
          .width(24)
          .height(24)
          .fillColor($r('app.color.text_primary'))
          .onClick(() => {
            router.back();
          })

        Text(this.courseName || '学习空间')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .margin({ left: 16 })

        Button(this.isRegenerating ? '重新生成中...' : '重新生成')
          .fontSize(12)
          .height(32)
          .backgroundColor($r('app.color.tech_blue_primary'))
          .enabled(!this.isRegenerating)
          .onClick(() => {
            AlertDialog.show({
              title: '确认重新生成？',
              message: '重新生成将删除现有知识图谱和争议分析数据，是否继续？',
              primaryButton: {
                value: '取消',
                action: () => {}
              },
              secondaryButton: {
                value: '确认',
                action: () => {
                  this.handleRegenerate();
                }
              }
            });
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      Row() {
        Text('学习进度')
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .margin({ right: 8 })

        Progress({ value: this.learningProgress * 100, total: 100, type: ProgressType.Linear })
          .layoutWeight(1)
          .color($r('app.color.tech_blue_primary'))

        Text(`${Math.round(this.learningProgress * 100)}%`)
          .fontSize(12)
          .fontColor($r('app.color.text_primary'))
          .fontWeight(FontWeight.Bold)
          .margin({ left: 8 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 8 })

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

      if (this.isLoading) {
        LoadingIndicator({ text: '加载中...' })
      } else {
        Scroll() {
          Column() {
            this.MentalModelSection()
            this.ControversySection()
            this.MaterialsSection()
          }
        }
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
    .bindSheet($$this.showNodeDetail, this.SheetContent())
  }

  @Builder
  MentalModelSection(): void {
    Column() {
      Row() {
        Text('心智模型')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)

        Text(this.mentalModelChecked ? '✅' : '⬜')
          .fontSize(22)
          .onClick(() => {
            this.toggleCheck('mental', 'mental');
          })
      }
      .width('100%')
      .margin({ bottom: 12 })

      Stack() {
        if (!this.mentalModelGenerated) {
          Column() {
            LoadingIndicator({ text: '正在生成心智模型...' })
          }
          .width('100%')
          .height(400)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor($r('app.color.card_background'))
          .borderRadius(12)
        } else if (this.nodes.length === 0) {
          Column() {
            Text('暂无知识图谱数据')
              .fontSize(16)
              .fontColor($r('app.color.text_secondary'))
            Text('点击右上角"重新生成"重试')
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
              .margin({ top: 8 })
          }
          .width('100%')
          .height(200)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor($r('app.color.card_background'))
          .borderRadius(12)
        } else {
          KnowledgeGraphWeb({
            nodes: this.nodes,
            edges: this.edges,
            version: this.graphVersion,
            onNodeClick: (nodeId: string) => {
              this.handleNodeClick(nodeId);
            }
          })
            .width('100%')
            .height(400)

        }

        if (this.isRegenerating) {
          Column() {
            LoadingIndicator({ text: '正在重新生成...' })
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor('#99FFFFFF')
          .borderRadius(12)
        }
      }
      .width('100%')
      .borderRadius(12)
      .clip(true)
    }
    .width('100%')
    .padding(16)
  }

  @Builder
  ControversySection(): void {
    Column() {
      Text('争议分析')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: 12 })

      Stack() {
        if (!this.controversyGenerated) {
          Column() {
            LoadingIndicator({ text: '正在生成争议分析...' })
          }
          .width('100%')
          .height(200)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor($r('app.color.card_background'))
          .borderRadius(12)
        } else if (this.controversies.length === 0) {
          Column() {
            Text('暂无争议分析数据')
              .fontSize(16)
              .fontColor($r('app.color.text_secondary'))
          }
          .width('100%')
          .height(120)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor($r('app.color.card_background'))
          .borderRadius(12)
        } else if (this.controversies.length === 1) {
          ControversyCard({ controversy: this.controversies[0], courseId: this.courseId, checked: this.controversyCheckedMap.get(this.controversies[0].id) || false, onCheckChange: () => { this.toggleCheck('controversy', this.controversies[0].id); } })
        } else {
          Swiper() {
            ForEach(this.controversies, (c: ParsedControversy) => {
              Column() {
                ControversyCard({ controversy: c, courseId: this.courseId, checked: this.controversyCheckedMap.get(c.id) || false, onCheckChange: () => { this.toggleCheck('controversy', c.id); } })
              }
            }, (c: ParsedControversy) => c.id)
          }
          .width('100%')
          .indicator(this.controversies.length > 1)
          .displayMode(SwiperDisplayMode.Stretch)
          .disableSwipe(false)
          .cachedCount(1)
        }

        if (this.isRegenerating) {
          Column() {
            LoadingIndicator({ text: '正在重新生成...' })
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor('#99FFFFFF')
          .borderRadius(12)
        }
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
  }

  @Builder
  MaterialsSection(): void {
    Column() {
      Row() {
        Text('补充资料')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)

        Button('上传')
          .fontSize(12)
          .height(32)
          .backgroundColor($r('app.color.tech_blue_primary'))
          .onClick(() => {
            this.handleUpload();
          })
      }
      .width('100%')
      .margin({ bottom: 12 })

      if (this.nodes.filter(n => n.type === 'concept' || n.type === 'evidence').length === 0 && this.materials.length === 0) {
        Column() {
          Text('暂无补充资料')
            .fontSize(16)
            .fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .height(80)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor($r('app.color.card_background'))
        .borderRadius(12)
      } else {
        Column() {
          ForEach(this.nodes.filter(n => (n.type === 'concept' || n.type === 'evidence') && n.content), (node: KnowledgeNode) => {
            Row() {
              Text('AI 补充')
                .fontSize(10)
                .fontColor(Color.White)
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .borderRadius(8)
                .backgroundColor($r('app.color.tech_blue_primary'))
                .margin({ right: 8 })

              Column() {
                Text(node.label)
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })

                if (node.content) {
                  Text(node.content)
                    .fontSize(12)
                    .fontColor($r('app.color.text_secondary'))
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .margin({ top: 4 })
                }
              }
              .layoutWeight(1)

              if (this.knowledgeSources.some(s => s.nodeId === node.id)) {
                Text('🔗')
                  .fontSize(16)
                  .margin({ left: 8 })
                  .onClick(() => {
                    const source = this.knowledgeSources.find(s => s.nodeId === node.id);
                    if (source) {
                      this.openUrl(source.url);
                    }
                  })
              }

              Text(this.materialCheckedMap.get(node.id) ? '✅' : '⬜')
                .fontSize(20)
                .margin({ left: 8 })
                .onClick(() => {
                  this.toggleCheck('material', node.id);
                })
            }
            .width('100%')
            .padding(12)
            .backgroundColor($r('app.color.card_background'))
            .borderRadius(8)
            .margin({ bottom: 8 })
            .onClick(() => {
              this.detailTitle = node.label;
              this.detailContent = node.content || '';
              this.sheetMode = 'material';
              this.showNodeDetail = true;
            })
          })

          ForEach(this.materials, (mat: MaterialInfo) => {
            Row() {
              Text('用户上传')
                .fontSize(10)
                .fontColor(Color.White)
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .borderRadius(8)
                .backgroundColor('#FF9800')
                .margin({ right: 8 })

              Text(mat.fileName)
                .fontSize(14)
                .layoutWeight(1)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })

              Text(this.materialCheckedMap.get(mat.id) ? '✅' : '⬜')
                .fontSize(20)
                .margin({ left: 8 })
                .onClick(() => {
                  this.toggleCheck('material', mat.id);
                })
            }
            .width('100%')
            .padding(12)
            .backgroundColor($r('app.color.card_background'))
            .borderRadius(8)
            .margin({ bottom: 8 })
            .onClick(() => {
              this.detailTitle = mat.fileName;
              if (mat.fileType === 'text' || mat.fileType === 'markdown') {
                this.detailContent = mat.content || '（无内容）';
              } else {
                this.detailContent = '该文件类型（' + mat.fileType + '）暂不支持在线预览，请使用对应应用打开。';
              }
              this.sheetMode = 'material';
              this.showNodeDetail = true;
            })
          })
        }
      }
    }
    .width('100%')
    .padding(16)
  }

  @Builder
  SheetContent(): void {
    if (this.sheetMode === 'node') {
      NodeDetailSheet({
        node: this.selectedNode,
        incomingEdges: this.selectedNodeIncomingEdges,
        outgoingEdges: this.selectedNodeOutgoingEdges,
        sources: this.selectedNodeSources,
        allNodes: this.nodes
      })
    } else {
      Column() {
        Text(this.detailTitle)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .padding({ right: 40 })
          .margin({ bottom: 16 })

        Scroll() {
          Text(this.detailContent)
            .fontSize(14)
            .fontColor($r('app.color.text_primary'))
            .width('100%')
            .lineHeight(22)
        }
        .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 20, bottom: 16 })
      .backgroundColor($r('app.color.card_background'))
      .borderRadius({ topLeft: 24, topRight: 24 })
    }
  }

  private async handleUpload(): Promise<void> {
    try {
      const documentViewPicker = new picker.DocumentViewPicker(getContext(this) as common.UIAbilityContext);
      const selectResult = await documentViewPicker.select({ maxSelectNumber: 1 });
      const uriArr = selectResult as string[];
      if (uriArr.length > 0 && this.knowledgeBaseManager) {
        const uri = uriArr[0];
        const fileName = uri.split('/').pop() || 'file';
        const file = fs.openSync(uri, fs.OpenMode.READ_ONLY);
        const stat = fs.statSync(uri);
        const ab = new ArrayBuffer(stat.size);
        fs.readSync(file.fd, ab);
        fs.closeSync(file);
        await this.knowledgeBaseManager.uploadMaterial(this.courseId, fileName, ab);
        this.materials = await this.knowledgeBaseManager.getMaterials(this.courseId);
      }
    } catch (err) {
      console.warn('[LearningSpacePage] Upload failed:', err);
    }
  }

  private async loadProgress(): Promise<void> {
    if (!this.rdbService) return;
    const progressMap = await this.rdbService.getAllProgressByCourseId(this.courseId);
    this.mentalModelChecked = progressMap.get('mental:mental') || false;
    const cMap = new Map<string, boolean>();
    const mMap = new Map<string, boolean>();
    const aiNodeIds = new Set(this.nodes.filter(n => (n.type === 'concept' || n.type === 'evidence') && n.content).map(n => n.id));
    progressMap.forEach((checked: boolean, key: string) => {
      if (key.startsWith('controversy:')) {
        const itemId = key.substring('controversy:'.length);
        cMap.set(itemId, checked);
      } else if (key.startsWith('material:')) {
        const itemId = key.substring('material:'.length);
        if (aiNodeIds.has(itemId)) {
          mMap.set(itemId, checked);
        }
      }
    });
    this.controversyCheckedMap = cMap;
    this.materialCheckedMap = mMap;
    this.learningProgress = await this.rdbService.calculateCourseProgress(this.courseId);
  }


  private async ensureProgressRecords(): Promise<void> {
    if (!this.rdbService) return;
    const progressMap = await this.rdbService.getAllProgressByCourseId(this.courseId);
    if (!progressMap.has('mental:mental')) {
      await this.rdbService.setProgressChecked(this.courseId, 'mental', 'mental', false);
    }
    for (const c of this.controversies) {
      if (!progressMap.has(`controversy:${c.id}`)) {
        await this.rdbService.setProgressChecked(this.courseId, 'controversy', c.id, false);
      }
    }
    const aiNodes = this.nodes.filter(n => (n.type === 'concept' || n.type === 'evidence') && n.content);
    for (const n of aiNodes) {
      if (!progressMap.has(`material:${n.id}`)) {
        await this.rdbService.setProgressChecked(this.courseId, 'material', n.id, false);
      }
    }

  }

  private async toggleCheck(itemType: string, itemId: string): Promise<void> {
    if (!this.rdbService) return;
    let currentChecked = false;
    const aiNodeIds = new Set(this.nodes.filter(n => (n.type === 'concept' || n.type === 'evidence') && n.content).map(n => n.id));
    if (itemType === 'mental') {
      currentChecked = this.mentalModelChecked;
      this.mentalModelChecked = !currentChecked;
    } else if (itemType === 'controversy') {
      currentChecked = this.controversyCheckedMap.get(itemId) || false;
      const newMap = new Map<string, boolean>();
      this.controversyCheckedMap.forEach((v: boolean, k: string) => { newMap.set(k, v); });
      newMap.set(itemId, !currentChecked);
      this.controversyCheckedMap = newMap;
    } else if (itemType === 'material') {
      currentChecked = this.materialCheckedMap.get(itemId) || false;
      const newMap = new Map<string, boolean>();
      this.materialCheckedMap.forEach((v: boolean, k: string) => { newMap.set(k, v); });
      newMap.set(itemId, !currentChecked);
      this.materialCheckedMap = newMap;
    }
    await this.rdbService.setProgressChecked(this.courseId, itemType, itemId, !currentChecked);
    if (itemType === 'mental' || itemType === 'controversy' || (itemType === 'material' && aiNodeIds.has(itemId))) {
      this.learningProgress = await this.rdbService.calculateCourseProgress(this.courseId);
    }
  }

  private async collectMaterialsContent(): Promise<string> {
    if (!this.knowledgeBaseManager) return '';
    const parts: string[] = [];
    for (const mat of this.materials) {
      if (mat.fileType === 'text' || mat.fileType === 'markdown') {
        if (mat.content) {
          parts.push(`## ${mat.fileName}\n${mat.content}`);
        }
      }
    }
    return parts.join('\n\n');
  }

  private openUrl(url: string): void {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      context.openLink(url);
    } catch (e) {
      console.warn('[LearningSpacePage] Failed to open URL:', url, e);
    }
  }
}


class ControversyViewImpl implements ControversyView {
  title: string = '';
  arguments: string[] = [];
  evidence: string[] = [];
}

class ParsedControversyImpl implements ParsedControversy {
  id: string = '';
  topic: string = '';
  leftView: ControversyView = new ControversyViewImpl();
  rightView: ControversyView = new ControversyViewImpl();
  synthesis: string = '';
}
