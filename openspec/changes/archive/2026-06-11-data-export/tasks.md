## 1. ExportService 核心服务

- [x] 1.1 新增 ExportService.ets，定义 ExportType 枚举（report/errorCollection/dialogRecords）和 ExportFormat 枚举（txt/json/markdown）
- [x] 1.2 ExportService 新增 formatReport 方法（将 AssessmentReport 格式化为 TXT/JSON/Markdown 字符串）
- [x] 1.3 ExportService 新增 formatErrorCollection 方法（查询课程错题，格式化为 TXT/JSON/Markdown 字符串）
- [x] 1.4 ExportService 新增 formatDialogRecords 方法（查询课程所有追问记录，格式化为 TXT/JSON/Markdown 字符串）
- [x] 1.5 ExportService 新增 saveExportFile 方法（写入沙箱 exports 目录）

## 2. 导出交互组件

- [x] 2.1 新增 ExportDialog 组件（显示导出类型选择：学习报告/错题集/对话记录 + 格式选择：TXT/JSON/Markdown）
- [x] 2.2 ExportDialog 确认后调用 ExportService 执行导出，显示 loading 和结果提示

## 3. 页面集成

- [x] 3.1 AssessmentReportPage 标题栏右侧添加导出图标按钮，点击弹出 ExportDialog（默认选中"学习报告"）
- [x] 3.2 ProfilePage 添加"数据导出"入口，点击后选择课程→弹出 ExportDialog

## 4. 验证与构建

- [x] 4.1 构建验证：hvigorw assembleHap 通过
