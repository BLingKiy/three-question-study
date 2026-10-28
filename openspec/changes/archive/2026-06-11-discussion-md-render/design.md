## Context

讨论线程页面中 AI 回复和总结使用 Markdown 格式，但当前用 `Text` 组件纯文本渲染。ArkUI 的 `RichText` 组件支持 HTML 渲染，可以将 Markdown 转为 HTML 后用 `RichText` 显示。

## Goals / Non-Goals

**Goals:**
- AI 消息内容支持 Markdown 基础格式渲染（粗体、斜体、标题、有序/无序列表、行内代码、代码块、段落）
- 讨论总结支持 Markdown 渲染
- 用户消息保持纯文本显示（用户输入不含 Markdown）

**Non-Goals:**
- 不支持完整 Markdown 规范（表格、脚注、图片等不需要）
- 不引入第三方 Markdown 解析库（自行实现简易转换即可）
- 不支持 Markdown 编辑器

## Decisions

1. **Markdown→HTML 转换工具**：在 `utils/MarkdownUtil.ets` 中实现 `markdownToHtml(md: string): string` 函数，用正则依次替换：代码块→行内代码→标题→粗体→斜体→无序列表→有序列表→段落换行。简单可靠，覆盖 AI 输出的常见格式。
2. **RichText 组件**：`RichText(htmlString)` 渲染转换后的 HTML。包裹在固定宽度容器中，设置基础 CSS 样式（字体大小、颜色、行高）。
3. **用户消息仍用 Text**：用户输入不含 Markdown 标记，保持 `Text` 组件纯文本显示。

## Risks / Trade-offs

- [简易 Markdown 解析可能遗漏边界情况] → AI 输出格式相对稳定，覆盖常见格式即可
- [RichText 不支持所有 HTML 标签] → 仅使用 h3/h4/b/i/p/ul/ol/li/code/pre，均在 RichText 支持范围内