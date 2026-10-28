## Why

讨论线程页面（DiscussionThreadPage）中 AI 回复和讨论总结的内容使用 Markdown 格式（`**粗体**`、`- 列表`、`### 标题` 等），但当前用 `Text` 组件直接显示，Markdown 标记被当作纯文本渲染，用户体验差。

## What Changes

- DiscussionThreadPage 中 AI 消息内容改用 `RichText` 组件渲染，支持 Markdown 基础格式（粗体、斜体、标题、列表、代码块）
- 讨论总结同样改用 `RichText` 渲染
- 新增 Markdown→HTML 轻换工具函数

## Capabilities

### New Capabilities

- `markdown-render`: Markdown 转 HTML 渲染工具

### Modified Capabilities

- `discussion-zone`: AI 回复和讨论总结使用 Markdown 渲染

## Impact

- `entry/src/main/ets/pages/DiscussionThreadPage.ets`：AI 消息和总结改用 RichText
- `entry/src/main/ets/utils/MarkdownUtil.ets`：新增 Markdown→HTML 转换工具