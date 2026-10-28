## Context

当前系统已实现完整的测评报告（AssessmentReportPage，含3维雷达图+复习建议+错题溯源）和追问对话记录（assessment_follow_ups表），但所有数据仅存储在本地RDB中，无法导出。hw.md要求"提交评价报告"占40%评分，需要将数据导出为可提交的文件。

已有基础设施：RDBService（查询所有数据）、FileService（文件读写）、@ohos.file.fs（文件操作）。

## Goals / Non-Goals

**Goals:**
- 支持导出学习报告（3维分数+复习建议+维度分析+错题溯源）
- 支持导出错题集（答错题目+用户答案+正确答案+解析）
- 支持导出对话原始记录（每道题的追问对话）
- 支持3种格式：TXT（纯文本，易读）、JSON（结构化，可二次处理）、Markdown（格式化，可预览）
- 在测评报告页和个人中心页提供导出入口

**Non-Goals:**
- 不实现PDF导出（HarmonyOS无原生PDF生成库，实现成本高）
- 不实现知识图谱图片导出
- 不实现跨课程合并导出

## Decisions

### 1. 导出文件保存方式
**决策**：使用 `@ohos.file.picker` 的 `PhotoSaveOptions` / `DocumentSaveOptions` 让用户选择保存位置，或直接写入应用沙箱 `filesDir/exports/` 目录后通过 `@ohos.share` 分享。
**理由**：HarmonyOS 沙箱限制，应用无法直接写入用户可见目录。DocumentSaveOptions 可让用户选择保存位置，体验最好。

### 2. 导出服务架构
**决策**：新增 ExportService，提供3个核心方法：`exportReport`、`exportErrorCollection`、`exportDialogRecords`，每个方法接受 courseId 和 format 参数，返回文件路径。
**理由**：导出逻辑与业务逻辑解耦，ExportService 负责数据收集→格式化→文件写入。

### 3. 格式化策略
**决策**：
- **TXT**：用换行和缩进组织纯文本，易读但无结构
- **JSON**：直接 JSON.stringify 结构化数据，包含所有字段
- **Markdown**：用标题/列表/表格组织，可预览且易读

**理由**：3种格式覆盖不同使用场景——TXT最通用、JSON可程序处理、Markdown可读性最好。

### 4. 导出入口位置
**决策**：
- 测评报告页：右上角添加导出图标按钮
- 个人中心页：添加"数据导出"入口，选择课程后导出

**理由**：报告页是用户最自然的导出场景，个人中心提供全局入口。

## Risks / Trade-offs

- **DocumentSaveOptions 在部分设备可能不可用** → 兜底方案：写入沙箱目录后提示用户文件位置
- **大文件导出可能耗时** → 导出操作在异步方法中执行，显示loading状态
- **中文文件名编码问题** → 文件名使用英文+时间戳，内容包含中文