## 1. 修改 RDBService.calculateCourseProgress

- [x] 1.1 修改 `calculateCourseProgress` 中资料权重计算：只统计 AI 生成的 concept/evidence 节点（`material:${n.id}`），去掉从 progress 表中扫描非 AI 节点的 material: 条目的逻辑
- [x] 1.2 确认测评部分（1/3）逻辑不变：每道已答题目均分

## 2. 修改 LearningSpacePage

- [x] 2.1 删除 `calculateProgress()` 方法，改为调用 `this.rdbService.calculateCourseProgress(this.courseId)` 获取进度
- [x] 2.2 修改 `ensureProgressRecords()`：不再为用户上传资料（`this.materials`）创建 `material:` progress 记录，只为 AI 生成的 concept/evidence 节点创建
- [x] 2.3 修改 `loadProgress()`：去掉 `materialCheckedMap` 中对用户上传资料的处理，只保留 AI 节点
- [x] 2.4 修改 `toggleCheck()`：用户上传资料的勾选不再触发进度重算（但可保留 UI 勾选状态）
- [x] 2.5 更新进度条显示：`learningProgress` 直接使用 `calculateCourseProgress` 返回值（0~1），乘以 100 显示

## 3. 验证一致性

- [x] 3.1 确认首页课程卡片进度与学习空间页进度使用同一 `calculateCourseProgress` 源
- [x] 3.2 确认用户上传资料的勾选不影响进度百分比
