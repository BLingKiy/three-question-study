## Why

需求书明确要求个人中心包含：学习数据总览（折线图+柱状图）、课程归档管理、资料上传历史、设置选项（含暗色模式）。当前 ProfilePage 仅有3个占位数字和 API 密钥配置，功能严重不足，影响评分。

## What Changes

- **学习数据总览**：替换占位数字为真实数据（课程总数/已完成/测评数/平均分），新增周学习时长折线图、学科能力柱状图
- **课程归档管理**：新增归档课程列表入口，支持取消归档和删除操作
- **资料上传历史**：新增上传历史列表，按课程分组展示已上传资料
- **设置选项完善**：新增暗色模式切换（跟随系统/亮色/暗色）
- **学习时长追踪**：RDB 新增 study_sessions 表记录学习时长，为折线图提供数据

## Capabilities

### New Capabilities
- `profile-enhancement`: 个人中心完善（数据总览可视化+归档管理+上传历史+暗色模式）

### Modified Capabilities

## Impact

- **ProfilePage.ets**：大幅重构，新增折线图/柱状图/归档管理/上传历史/暗色模式
- **RDBService.ets**：新增 study_sessions 表 + CRUD
- **PreferencesService.ets**：新增暗色模式偏好存储
- **新增 StudySessionTracker**：学习时长追踪服务
- **新增 LineChartWeb 组件**：ArkWeb+ECharts 折线图
- **新增 BarChartWeb 组件**：ArkWeb+ECharts 柱状图
- **新增 rawfile/line_chart.html / bar_chart.html**