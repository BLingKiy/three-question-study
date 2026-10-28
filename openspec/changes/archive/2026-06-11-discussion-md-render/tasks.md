## 1. Markdown 转 HTML 工具

- [ ] 1.1 创建 `entry/src/main/ets/utils/MarkdownUtil.ets`，实现 `markdownToHtml(md: string): string` 函数
- [ ] 1.2 处理代码块（```...```）→ `<pre><code>...</code></pre>`
- [ ] 1.3 处理行内代码（`...`）→ `<code>...</code>`
- [ ] 1.4 处理标题（### → h3, #### → h4）
- [ ] 1.5 处理粗体（**...**）→ `<b>...</b>`
- [ ] 1.6 处理斜体（*...*）→ `<i>...</i>`
- [ ] 1.7 处理无序列表（- item）→ `<ul><li>...</li></ul>`
- [ ] 1.8 处理有序列表（1. item）→ `<ol><li>...</li></ol>`
- [ ] 1.9 处理段落换行（\n\n → `</p><p>`，\n → `<br/>`）
- [ ] 1.10 包裹基础 CSS 样式（字体大小 14px、颜色 #333、行高 1.6、代码背景色 #f5f5f5）

## 2. DiscussionThreadPage AI 消息渲染

- [ ] 2.1 AI 消息内容从 `Text(msg.content)` 改为 `RichText(markdownToHtml(msg.content))`
- [ ] 2.2 用户消息保持 `Text(msg.content)` 纯文本渲染

## 3. DiscussionThreadPage 讨论总结渲染

- [ ] 3.1 讨论总结从 `Text(this.summary.summary)` 改为 `RichText(markdownToHtml(this.summary.summary))`

## 4. 构建验证

- [ ] 4.1 运行构建确认无编译错误