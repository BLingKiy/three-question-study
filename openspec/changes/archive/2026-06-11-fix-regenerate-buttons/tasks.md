## 1. RDBService 数据删除方法修复

- [x] 1.1 RDBService 新增 `deleteKnowledgeNodesByCourseExcludeType(courseId: string, excludeType: string)` 方法，SQL 条件删除 type != excludeType 的节点
- [x] 1.2 RDBService 确认 `deleteKnowledgeEdgesByCourse(courseId: string)` 方法存在

## 2. ThreeQuestionEngine 重新生成逻辑修复

- [x] 2.1 修改 `deleteKnowledgeGraph` 方法：调用 `deleteKnowledgeNodesByCourseExcludeType(courseId, 'controversy')` 替代 `deleteKnowledgeNodesByCourse(courseId)`，保留争议节点
- [x] 2.2 确认 `deleteControversies` 方法逻辑不变（仅删除 controversy 类型节点）

## 3. LearningSpacePage 课程生成状态检测

- [x] 3.1 新增 `@State mentalModelGenerated: boolean` 和 `@State controversyGenerated: boolean` 状态
- [x] 3.2 `loadData()` 中加载课程状态，设置 `mentalModelGenerated` 和 `controversyGenerated`
- [x] 3.3 新增 `startPolling()` 方法：若任一标志为 false，启动 `setInterval` 每 2 秒查询 `CourseManager.getCourseById()` 更新状态
- [x] 3.4 轮询检测到 `mentalModelGenerated` 变为 true 时，加载知识图谱数据并刷新心智模型区
- [x] 3.5 轮询检测到 `controversyGenerated` 变为 true 时，加载争议数据并刷新争议区
- [x] 3.6 两个标志都为 true 时停止轮询
- [x] 3.7 `aboutToDisappear()` 中清理 `clearInterval`

## 4. 区域级加载动画（初始生成）

- [x] 4.1 MentalModelSection：当 `!mentalModelGenerated` 时显示骨架屏加载动画（Stack+Column+LoadingIndicator+"正在生成心智模型..."），替代空态占位
- [x] 4.2 ControversySection：当 `!controversyGenerated` 时显示骨架屏加载动画（Stack+Column+LoadingIndicator+"正在生成争议分析..."），替代空态占位
- [x] 4.3 生成完成后骨架屏自动替换为实际数据展示

## 5. 区域级加载遮罩（重新生成）

- [x] 5.1 MentalModelSection 中，当 `isRegenerating && regenerateTarget === 'Q1'` 时，在知识图谱区域上方覆盖半透明遮罩（opacity 0.6）+ LoadingIndicator
- [x] 5.2 ControversySection 中，当 `isRegenerating && regenerateTarget === 'Q2'` 时，在争议卡片区域上方覆盖半透明遮罩（opacity 0.6）+ LoadingIndicator

## 6. 错误提示改进

- [x] 6.1 `handleRegenerate` catch 中判断错误消息是否包含"API密钥未配置"，若显示"请先在「我的」页面配置 API 密钥"
- [x] 6.2 其他错误显示"重新生成失败：{message}"

## 7. 构建验证

- [x] 7.1 运行构建确认无编译错误
