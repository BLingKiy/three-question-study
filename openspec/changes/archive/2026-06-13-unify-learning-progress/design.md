## Context

当前学习进度计算存在两处独立实现：
1. `LearningSpacePage.calculateProgress()`：前端页面内计算，将用户上传资料也计入资料权重
2. `RDBService.calculateCourseProgress()`：后端服务计算，资料部分同时包含 AI 节点和 progress 表中的 material: 条目

两者逻辑不一致，且用户上传资料不应计入进度权重。首页课程卡片调用 `RDBService.calculateCourseProgress`，学习空间页用自己的 `calculateProgress`，导致进度可能不同步。

## Goals / Non-Goals

**Goals:**
- 统一进度计算公式为：2/3 学习空间 + 1/3 测评
  - Q1 心智模型：2/9（check 即得）
  - Q2 争议分析：2/9（每个争议均分）
  - 补充资料（仅 AI 生成）：2/9（每个条目均分，不含用户上传）
  - Q3 测评：1/3（每道题均分）
- 确保首页课程卡片和学习空间页进度显示一致
- 清理用户上传资料的 progress 记录

**Non-Goals:**
- 不改变 progress 表结构
- 不改变测评进度计算逻辑
- 不实现用户上传资料的独立进度追踪

## Decisions

### 决策1：以 RDBService.calculateCourseProgress 为唯一权威计算源

**选择**：删除 `LearningSpacePage.calculateProgress()`，改为调用 `RDBService.calculateCourseProgress()`

**理由**：避免两处维护同一逻辑。RDBService 已被首页课程卡片使用，统一后保证一致性。

**替代方案**：保留两处但同步逻辑 → 维护成本高，容易再次不一致。

### 决策2：资料进度只计算 AI 生成的 concept/evidence 节点

**选择**：`material:` 类型的 progress 记录只为 AI 生成的 concept/evidence 节点创建，用户上传资料不创建 progress 记录

**理由**：用户要求"补充资料（不包含用户上传资料）"只算 AI 生成的。用户上传资料是辅助参考，不应影响学习进度。

### 决策3：清理已有的用户上传资料 progress 记录

**选择**：在 `ensureProgressRecords` 中不再为用户上传资料创建记录，并清理 `calculateCourseProgress` 中对用户上传资料的引用

**理由**：避免旧数据干扰进度计算。

## Risks / Trade-offs

- **[进度回退]**：去掉用户上传资料权重后，已有课程的进度百分比可能降低 → 可接受，因为这是正确的计算方式
- **[Progress 记录残留]**：旧版本创建的用户上传资料 progress 记录仍留在数据库中 → 在 calculateCourseProgress 中通过只查 AI 节点来忽略，不影响计算