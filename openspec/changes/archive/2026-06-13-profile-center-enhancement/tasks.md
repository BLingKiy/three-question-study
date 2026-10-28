## 1. 学习时长追踪

- [x] 1.1 RDBService 新增 study_sessions 表创建（id, course_id, date, duration_seconds, UNIQUE(course_id, date)）
- [x] 1.2 RDBService 新增 saveStudySession / getStudySessionsByDateRange 方法
- [x] 1.3 LearningSpacePage 新增学习时长追踪：aboutToAppear 记录进入时间，aboutToDisappear 计算时长并保存
- [x] 1.4 deleteCourse 级联删除 study_sessions 数据

## 2. 图表组件

- [x] 2.1 创建 rawfile/line_chart.html（ECharts 折线图，7天数据，接收 javaScriptProxy 传入的日期+时长数据）
- [x] 2.2 新增 LineChartWeb 组件（ArkWeb 封装，传入 dates[] + durations[] 数据）
- [x] 2.3 创建 rawfile/bar_chart.html（ECharts 分组柱状图，接收课程名+3维分数数据）
- [x] 2.4 新增 BarChartWeb 组件（ArkWeb 封装，传入课程名[] + 3维分数数据）

## 3. ProfilePage 重构

- [x] 3.1 替换占位数字为 RDB 真实查询（课程总数/已完成/测评数/平均分）
- [x] 3.2 新增"学习数据"区域：LineChartWeb 折线图（周学习时长）+ BarChartWeb 柱状图（学科能力）
- [x] 3.3 新增"归档管理"区域：列出归档课程，支持取消归档和删除操作
- [x] 3.4 新增"上传历史"区域：按课程分组展示已上传资料（文件名+上传时间）
- [x] 3.5 设置区域新增暗色模式切换（跟随系统/亮色/暗色三选一）
- [x] 3.6 PreferencesService 新增暗色模式偏好存储（get/set ColorMode）

## 4. 验证与构建

- [x] 4.1 构建验证：hvigorw assembleHap 通过
