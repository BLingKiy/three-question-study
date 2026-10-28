## Why

首页课程卡片的学习进度和课程学习空间页的学习进度计算逻辑不一致：学习空间页的 `calculateProgress` 将用户上传资料也计入资料权重，而 `RDBService.calculateCourseProgress` 不计入；且资料权重应只包含 AI 生成的补充资料（concept/evidence 节点），不应包含用户上传资料。需要统一两处计算逻辑，确保进度显示一致。

## What Changes

- **统一进度计算公式**：2/3 学习空间 + 1/3 测评中心
  - Q1 心智模型：整体 2/9，check 即得全部分
  - Q2 争议分析：整体 2/9，每个争议均分
  - 补充资料（仅 AI 生成，不含用户上传）：整体 2/9，每个条目均分
  - Q3 测评：整体 1/3，每道习题均分
- **修改 LearningSpacePage.calculateProgress**：去掉用户上传资料的权重计算，只保留 AI 生成的补充资料节点
- **修改 RDBService.calculateCourseProgress**：确保与 LearningSpacePage 逻辑一致，资料部分只计算 AI 生成节点
- **修改 LearningSpacePage.ensureProgressRecords**：不再为用户上传资料创建 progress 记录
- **首页课程卡片进度**：已调用 `RDBService.calculateCourseProgress`，统一后自动一致

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `progress-tracking`: 统一进度计算公式，明确补充资料仅包含 AI 生成内容不含用户上传资料

## Impact

- `RDBService.calculateCourseProgress`：资料权重计算逻辑修改
- `LearningSpacePage.calculateProgress`：去掉用户上传资料的权重
- `LearningSpacePage.ensureProgressRecords`：不再为用户上传资料创建 progress 记录
- 首页课程卡片进度显示自动跟随统一