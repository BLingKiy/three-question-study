## Why

hw.md 明确要求"提交评价报告"（占40%评分），当前系统虽已生成测评报告和追问记录，但无法导出数据供提交。需要实现数据导出功能，支持将学习报告、错题集、对话原始记录导出为 TXT/JSON/Markdown 格式，满足评分提交要求。

## What Changes

- **学习报告导出**：将课程测评报告（3维分数+复习建议+维度分析+错题溯源）导出为 TXT/JSON/Markdown
- **错题集导出**：将课程所有答错的题目（题目+用户答案+正确答案+解析）导出为 TXT/JSON/Markdown
- **对话原始记录导出**：将课程所有追问对话记录（题目+用户追问+AI回复）导出为 TXT/JSON/Markdown
- **导出入口**：在测评报告页面和个人中心页面添加导出按钮，支持格式选择
- **文件写入**：使用 HarmonyOS fs API 写入应用沙箱目录，通过 FilePicker 让用户选择保存位置

## Capabilities

### New Capabilities
- `data-export`: 数据导出功能（学习报告/错题集/对话记录，TXT/JSON/Markdown格式）

### Modified Capabilities

## Impact

- **新增 ExportService.ets**：导出逻辑服务（格式化+文件写入）
- **AssessmentReportPage.ets**：添加导出按钮
- **ProfilePage.ets**：添加导出入口
- **新增 ExportDialog 组件**：格式选择弹窗（TXT/JSON/Markdown）
- **依赖 @ohos.file.fs 和 @ohos.file.picker**：文件写入和保存位置选择