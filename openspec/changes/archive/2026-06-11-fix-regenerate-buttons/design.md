## Context

学习空间页面（LearningSpacePage）在初始生成和重新生成场景下都缺少加载动画和动态更新机制。当前流程：MainPage 创建课程后同步执行 Q1+Q2，用户可能在此期间进入学习空间看到空态。LearningSpacePage 没有轮询机制检测生成进度，也没有区域级加载指示器。

## Goals / Non-Goals

**Goals:**
- 进入学习空间时检测课程生成状态，未完成区域显示加载动画（骨架屏+旋转指示器）
- 添加轮询机制（2 秒间隔），生成完成后自动刷新对应区域数据
- 重新生成时在对应区域覆盖半透明加载遮罩
- 修复 Q1 重新生成误删争议数据
- 改进错误提示分类

**Non-Goals:**
- 不修改 MainPage 的课程创建流程
- 不添加生成进度百分比
- 不使用 WebSocket 或推送通知（使用轮询即可）

## Decisions

1. **轮询机制**：使用 `setInterval` 每 2 秒查询 `CourseManager.getCourseById()`，检查 `mentalModelGenerated` 和 `controversyGenerated` 状态变化。当两个标志都为 true 时停止轮询。在 `aboutToDisappear` 中清理定时器。
2. **区域级加载动画**：Q1 未完成时心智模型区显示骨架屏（Stack+Column+LoadingIndicator），Q2 未完成时争议区显示骨架屏。骨架屏与空态区分：空态是"数据不存在"，骨架屏是"正在生成中"。
3. **RDBService 新增排除类型删除方法**：Q1 重新生成时仅删除非 controversy 类型节点，SQL `DELETE FROM knowledge_node WHERE courseId = ? AND type != ?`。
4. **错误提示分类**：catch 中根据错误消息关键词区分——"API密钥未配置"→"请先在「我的」页面配置 API 密钥"，其他→"重新生成失败：{message}"。

## Risks / Trade-offs

- [轮询可能增加 RDB 读取频率] → 仅在生成未完成时轮询，完成后立即停止，频率 2 秒可接受
- [Q1 重新生成后知识图谱节点 ID 变化，边已全部删除重建] → 无引用断裂风险
- [区域级遮罩可能遮挡用户已看到的内容] → 遮罩半透明（opacity 0.6），用户仍可隐约看到旧内容
