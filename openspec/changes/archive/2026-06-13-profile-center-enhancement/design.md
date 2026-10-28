## Context

当前 ProfilePage 仅有3个占位数字（课程总数/完成测评/平均分数，数据来自 PreferencesService 而非 RDB 真实查询）、API 密钥配置、主题设置占位、关于占位。需求书要求：学习数据总览（折线图展示周学习时长变化，柱状图对比各学科能力得分）、课程归档管理、资料上传历史、设置选项（含暗色模式）。

已有基础设施：RDBService（courses/assessments/assessment_reports表）、PreferencesService（用户设置）、ArkWeb+ECharts（RadarChartWeb已验证可行）、FileService（资料管理）。

## Goals / Non-Goals

**Goals:**
- 学习数据总览：真实数据+周学习时长折线图+学科能力柱状图
- 课程归档管理：独立入口展示归档课程列表，支持取消归档和删除
- 资料上传历史：按课程分组展示已上传资料文件名和上传时间
- 暗色模式：支持跟随系统/亮色/暗色三种模式
- 学习时长追踪：记录用户在各课程学习空间的停留时长

**Non-Goals:**
- 不实现跨学科横向对比独立页面（柱状图已覆盖基本需求）
- 不实现个性化提醒/通知
- 不实现课程分享

## Decisions

### 1. 图表实现方案
**决策**：复用 ArkWeb+ECharts 方案（与 RadarChartWeb 一致），新增 LineChartWeb 和 BarChartWeb 组件。
**理由**：ECharts 折线图/柱状图效果优于 Canvas 自绘，ArkWeb 通信模式已验证可行。

### 2. 学习时长追踪方案
**决策**：新增 study_sessions 表（id, course_id, date, duration_seconds），LearningSpacePage 的 onPageShow/onPageHide 记录进入/离开时间，计算停留时长并累加到当日记录。
**理由**：按日累加时长，折线图按最近7天展示，数据量小且查询简单。

### 3. 学科能力数据来源
**决策**：从 assessment_reports 表查询各课程的 dimensions（3维分数），柱状图按课程名分组展示3个维度的柱状图。
**理由**：数据已在 assessment_reports 中，无需额外计算。

### 4. 暗色模式实现
**决策**：使用 `@ohos.app.ability.ConfigurationConstant.ColorMode` + `AppStorage` 全局状态 + PreferencesService 持久化选择。ProfilePage 提供三选一：跟随系统/亮色/暗色。
**理由**：HarmonyOS 原生支持 ColorMode 切换，AppStorage 全局传播最简单。

### 5. 真实数据替换占位
**决策**：ProfilePage 的统计数据直接从 RDBService 查询：课程总数=所有课程count，已完成=status=completed的count，测评数=所有assessments count，平均分=所有assessment_reports的3维平均。
**理由**：PreferencesService 的占位数据不准确，应从 RDB 实时查询。

## Risks / Trade-offs

- **study_sessions 表需要数据积累** → 首次使用时折线图可能为空，显示"暂无学习记录"提示
- **暗色模式需要全局颜色适配** → 当前仅切换系统 ColorMode，已有颜色资源可能需要补充 dark 模式值
- **ProfilePage 重构范围大** → 分步实现，先做数据总览+图表，再做归档管理+上传历史+暗色模式