## Why

学习空间页面在初始生成和重新生成时缺乏加载动画和动态更新机制：1) 用户在课程 Q1/Q2 尚未生成完成时进入学习空间，只看到空态"暂无数据"，无法感知正在生成；2) 重新生成过程中没有区域级加载遮罩；3) 生成完成后页面不会自动刷新显示新数据；4) Q1 重新生成时 `deleteKnowledgeGraph` 误删争议节点。

## What Changes

- LearningSpacePage 添加课程状态轮询机制：进入页面时检查 `mentalModelGenerated`/`controversyGenerated`，未完成则每 2 秒轮询直到完成，完成后自动刷新对应区域
- 心智模型区和争议区分别显示加载动画：Q1 未完成时心智模型区显示骨架屏+加载动画，Q2 未完成时争议区显示骨架屏+加载动画
- 重新生成时在对应区域覆盖半透明加载遮罩
- 修复 `deleteKnowledgeGraph`：Q1 重新生成时仅删除非 controversy 类型节点和所有边
- 改进错误提示分类

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `three-question-engine`: Q1 重新生成时不应删除争议节点；学习空间需支持生成状态轮询和区域级加载动画

## Impact

- `entry/src/main/ets/pages/LearningSpacePage.ets`：添加状态轮询、区域级加载动画/骨架屏、区域级遮罩、错误提示改进
- `entry/src/main/ets/services/ThreeQuestionEngine.ets`：修改 `deleteKnowledgeGraph` 保留争议节点
- `entry/src/main/ets/services/RDBService.ets`：新增 `deleteKnowledgeNodesByCourseExcludeType` 方法
