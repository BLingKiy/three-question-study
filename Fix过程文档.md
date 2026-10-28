# 三问高效学习机 — Fix 过程文档

## 项目概述

**产品名称**：三问高效学习机  
**开发平台**：HarmonyOS ArkTS (API 9+)  
**核心功能**：用户提问触发生成课程 → 自动执行三问认知引擎（Q1心智模型提取、Q2学术分歧挖掘、Q3深度测评生成）→ 知识图谱可视化 + 争议分析展示 + 布鲁姆认知测评

---

## 开发过程与问题修复记录

### 阶段一：核心引擎搭建（变更1: three-question-study）

**目标**：实现三问引擎核心流程和基础UI

**完成内容**：
- 三问引擎服务（ThreeQuestionEngine）：Q1心智模型提取、Q2争议分析、Q3测评生成
- Deepseek API 集成（Anthropic Messages API）
- 12个自定义 SVG 图标
- RDB 数据库初始化（courses、knowledge_nodes、knowledge_edges、assessments 等核心表）
- 课程创建与列表展示

**遇到的问题**：
1. **系统图标不存在**：`sys.media.ohos_ic_public_*` 在 HarmonyOS 中不存在，需自定义 `app.media.ic_*` SVG 图标
2. **ArkTS 严格限制**：不允许 `any`/`unknown` 类型、不允许对象字面量作为类型声明、不允许 `throw err`

---

### 阶段二：测评系统增强（变更2: assessment-retry-enhancement）

**目标**：支持多题型答题和测评重试

**完成内容**：
- 多题型支持（单选、多选、判断、主观）
- 答题UI与判题逻辑
- 测评重试功能

**遇到的问题**：
1. **assessments 表缺少字段**：建表SQL中没有 `question_type`、`options`、`correct_answer` 列，需通过 ALTER TABLE 添加
2. **RDB 插入冲突**：需使用 `ConflictResolution.ON_CONFLICT_REPLACE`

---

### 阶段三：学习空间重构（变更3: learning-space-redesign）

**目标**：知识图谱可视化、争议左右分栏、三区纵向布局

**完成内容**：
- ArkWeb + vis-network 知识图谱
- 节点详情面板（NodeDetailSheet）
- 争议左右分栏对比 + Swiper 切换
- 逻辑链图谱（ControversyLogicChain）
- WebSearch 联网检索
- 协作讨论区

**遇到的问题**：
1. **ArkWeb HTML 必须设置 `html, body { width: 100%; height: 100%; }`**，否则内容不显示
2. **Swiper 内 ForEach 必须提供 key generator**：`(c) => c.id`
3. **ArkUI 没有 SwiperItem 组件**，Swiper 内直接放子组件
4. **同一组件上多个 bindSheet 会冲突**，必须合并为单个 bindSheet + sheetMode 状态区分

---

### 阶段四：重新生成按钮合并与 Markdown 渲染（变更4: fix-regenerate-buttons + discussion-md-render）

**目标**：合并重新生成按钮、讨论区 Markdown 渲染、文件上传修复

**完成内容**：
- 重新生成按钮合并为一个（Q1+Q2 一起重新生成）
- 讨论区 AI 回复使用原生 ArkUI 渲染 Markdown
- 文件上传读取实际内容（fs.openSync + fs.readSync）
- 删除课程级联删除所有关联数据
- 学习进度勾选

**遇到的问题**：
1. **@Builder 内不能有 try-catch**
2. **bindSheet 的关闭按钮是系统自带的**，自定义内容需 `padding-right: 40`
3. **文件上传需用 fs.openSync + fs.readSync 读取 URI 对应文件内容**

---

### 阶段五：测评中心重构（变更5: assessment-center-redesign）

**目标**：测评中心按课程分组、追问模块、完整上下文生成

**完成内容**：
- 测评中心按课程分组显示
- 生成测评按钮 + 维度类型标签
- 追问模块（用户追问 + AI 深度解答）
- 完整上下文生成测评题目

**遇到的问题**：
1. **测评生成状态持久化**：assessmentGenerating 字段存 DB，切换页面回来仍显示加载动画，3秒轮询
2. **多选题必须有2个及以上正确答案**：AI 生成只有1个正确答案的降级为单选题
3. **标签颜色**：需按用户指定色值设置，浅色背景配深色文字

---

### 阶段六：课程卡片管理（变更6: course-card-management）

**目标**：课程卡片操作菜单、归档/折叠、排序切换

**完成内容**：
- bindMenu 三点图标操作菜单
- 归档/取消归档/标记完成/删除（带确认）
- 已归档课程底部折叠区域
- 排序切换（最近使用/创建时间/学习进度）

**遇到的问题**：
1. **课程列表顶部对齐**：Scroll 内 Column 需加 `alignItems(HorizontalAlign.Start)` + Scroll 加 `align(Alignment.TopStart)`
2. **已归档课程**：2列 Grid 布局，`opacity(0.6)` 置灰

---

### 阶段七：测评报告重构（变更7: assessment-report-redesign）

**目标**：AI 生成3维评分报告 + 雷达图

**完成内容**：
- AI 生成3维评分（概念理解/批判思维/实践迁移）+ 复习建议 + 错题溯源
- ArkWeb + ECharts 雷达图
- "查看测评报告"按钮（答题完成后可用）
- 上一题/下一题导航

**遇到的问题**：
1. **ECharts 雷达图 center 偏移**：用 `center: ['50%', '55%']` 避免标签被削顶
2. **ArkWeb 圆角**：用 Stack + borderRadius + clip(true) 包裹 Web 组件

---

### 阶段八：数据导出（变更8: data-export）

**目标**：学习报告/错题集/对话记录导出

**完成内容**：
- ExportService + ExportDialog
- 3种内容 × 3种格式（TXT/JSON/Markdown）
- DocumentViewPicker.save() 让用户选择保存位置

**遇到的问题**：
1. **filePicker.save() 不存在**，正确 API 是 `new filePicker.DocumentViewPicker()` 然后 `documentViewPicker.save()`
2. **导出文件写入 cacheDir**（系统保证存在），不要用 filesDir 子目录

---

### 阶段九：个人中心完善（变更: profile-center-enhancement）

**完成内容**：
- 学习统计（课程总数/已答题目/测评数/平均分）
- 折线图（周学习时长）+ 柱状图（学科能力对比）
- 归档管理 + 上传历史 + 答题档案
- 暗色模式设置 + 学习时长追踪

**遇到的问题**：
1. **学习统计数字全是0**：`@Builder` 接收字符串参数会断开 `@State` 响应式追踪，改为在 build 中直接内联引用 `this.xxx`
2. **getCourseStats 内部异常导致整体失败**：`getAssessmentReportByCourseId` 中 `JSON.parse` 可能失败，需 try-catch 隔离每个课程
3. **CustomDialogController 必须保存为组件属性**：在回调内创建为局部变量会导致引用丢失，关闭对话框失败
4. **上传历史日期显示1970年**：`stat.mtime` 是秒级时间戳，需乘以1000转毫秒
5. **文件名前缀多出随机字符串**：`materialId` 格式为 `courseId_timestamp_random`（3段下划线），解析时需取前3段为ID

---

### 阶段十：重新生成重置进度 + 答题档案（变更: regenerate-reset-progress）

**完成内容**：
- 重新生成时重置学习进度
- 归档已答题目到 answer_archives/follow_up_archives 表
- resetCourseAfterRegenerate 方法
- ProfilePage 答题档案 UI

---

### 阶段十一：暗色模式修复（变更: dark-mode-fix）

**完成内容**：
- setColorMode 参数映射修复（COLOR_MODE_NOT_SET=-1, COLOR_MODE_DARK=0, COLOR_MODE_LIGHT=1）
- dark 资源目录补全
- 页面硬编码颜色替换为 `$r('app.color.xxx')`
- ArkWeb HTML applyTheme() 暗色适配
- EntryAbility 启动恢复颜色模式

**遇到的问题**：
1. **ColorMode 枚举值**：COLOR_MODE_NOT_SET=-1, COLOR_MODE_DARK=0, COLOR_MODE_LIGHT=1，不能搞混
2. **暗色模式资源**：base/element/color.json 和 dark/element/color.json 各自定义颜色

---

### 阶段十二：统一学习进度计算（变更: unify-learning-progress）

**完成内容**：
- 统一进度公式：Q1(2/9) + Q2(2/9) + AI资料(2/9) + 测评(1/3)
- RDBService.calculateCourseProgress 为唯一权威源
- 去掉用户上传资料权重
- 争议只算有正反面的（过滤简单争议节点）
- LearningSpacePage 删除 calculateProgress() 改用 RDBService

**遇到的问题**：
1. **进度计算只有89%**：`calculateCourseProgress` 把所有 `type === 'controversy'` 的节点都算进分母，但简单争议节点没有 check，永远无法得分。修复为只计算有 leftView/rightView 的争议节点
2. **首页和学习空间进度不一致**：LearningSpacePage 有自己的 `calculateProgress()` 逻辑，与 RDBService 不一致。统一为只使用 RDBService

---

### 其他增量修复

| 问题 | 原因 | 修复 |
|------|------|------|
| 测评报告页标题不居中 | 返回按钮宽60，导出图标宽24，不对称 | 右侧图标用 Row 宽60 包裹 |
| 数据导出取消按钮不消失 | CustomDialogController 在回调内创建为局部变量 | 保存为组件属性 |
| "已完成"统计含义不清 | 统计的是课程状态为 completed 的数量 | 改为"已答题目"，统计已作答的测评题目数 |
| 图表高度不够有遮挡 | 容器高度200px不够 | 调整为260px |
| 柱状图图例遮挡图表 | 图例在顶部占空间 | 移到底部，grid bottom 调整为22% |

---

## 技术要点总结

### ArkTS 开发注意事项

1. `@Builder` 方法接收字符串参数会断开 `@State` 响应式追踪，必须直接在 build 中引用 `this.xxx`
2. `@State` 属性不能与 CustomComponent 基类属性冲突
3. 同一组件上多个 `bindSheet` 会冲突，需合并为单个 + sheetMode 状态区分
4. `@Builder` 内不能有 try-catch
5. ArkUI 没有 SwiperItem 组件，Swiper 内直接放子组件
6. Checkbox 用 `.select()` 而非 `.checked()`

### ArkWeb 使用注意事项

1. HTML 必须设置 `html, body { width: 100%; height: 100%; }`
2. 圆角用 Stack + borderRadius + clip(true) 包裹 Web 组件
3. 暗色适配需 HTML 文件提供 `applyTheme(dark)` 函数
4. ECharts 雷达图用 `center: ['50%', '55%']` 避免标签被削顶

### 数据持久化注意事项

1. RDB 插入需用 `ConflictResolution.ON_CONFLICT_REPLACE`
2. ALTER TABLE 添加已存在列会报 E 级别日志但 try-catch 能捕获
3. `stat.mtime` 是秒级时间戳，传给 `new Date()` 需乘以1000
4. CustomDialogController 必须保存为组件属性
5. 文件名解析：materialId 格式为 `courseId_timestamp_random`（3段下划线）

### API 集成注意事项

1. DeepSeek Anthropic API 端点：`https://api.deepseek.com/anthropic/v1/messages`
2. 使用 `x-api-key` header，模型 `deepseek-v4-flash`
3. JSON.parse 可能失败，需 try-catch + fallback

---

## 数据库说明

本项目使用 HarmonyOS 本地关系型数据库（RDB），数据库文件 `ThreeQuestionStudy.db` 在应用首次启动时自动创建，无需手动部署。

数据库建表脚本见项目根目录 `database/init.sql`。

### 数据库表结构

| 表名 | 用途 |
|------|------|
| courses | 课程信息 |
| knowledge_nodes | 知识图谱节点 |
| knowledge_edges | 知识图谱边 |
| assessments | 测评题目 |
| assessment_follow_ups | 追问记录 |
| assessment_reports | 测评报告 |
| knowledge_sources | 知识来源链接 |
| discussions | 讨论区 |
| discussion_messages | 讨论消息 |
| discussion_summaries | 讨论总结 |
| learning_progress | 学习进度 |
| study_sessions | 学习时长 |
| answer_archives | 答题档案 |
| follow_up_archives | 追问档案 |

### 数据初始化

应用启动时，`RDBService.initialize()` 方法会：
1. 创建所有表（CREATE TABLE IF NOT EXISTS）
2. 执行 ALTER TABLE 添加后续版本新增的列
3. 数据库文件位置：`/data/app/el2/100/database/{bundleName}/rdb/ThreeQuestionStudy.db`