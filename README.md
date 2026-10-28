# 三问学习 (Three Question Study)

一个基于 HarmonyOS 的智能学习应用，通过三问法（心智模型提取、争议分析、测评生成）帮助用户深度学习任何主题。

## 功能特性

### 🎯 核心功能

1. **心智模型提取 (Question 1)**
   - 输入学习问题，AI 自动构建知识图谱
   - 可视化展示概念、争议、证据节点
   - 支持力导向布局算法

2. **争议分析 (Question 2)**
   - 分析主题相关的争议观点
   - 左右观点对比展示
   - 证据支持与反对关系

3. **测评生成 (Question 3)**
   - 基于布鲁姆认知层次生成测评题目
   - 六个层次：记忆、理解、应用、分析、评价、创造
   - 雷达图展示能力维度

### 📚 学习管理

- 课程创建与管理
- 学习进度跟踪
- 补充材料上传（PDF、Word、Markdown）
- 测评结果统计

## 技术架构

### 数据层
- **RDBService**: 关系型数据库服务，存储课程、知识图谱、测评数据
- **PreferencesService**: 用户偏好设置存储
- **FileService**: 文件存储服务

### AI 集成
- **DeepseekService**: Deepseek API 集成
- **PromptTemplates**: 三问法提示词模板
- **ResponseParser**: AI 响应解析器

### 业务逻辑
- **CourseManager**: 课程管理
- **ThreeQuestionEngine**: 三问法引擎
- **KnowledgeBaseManager**: 知识库管理
- **AssessmentManager**: 测评管理

### UI 组件
- **CourseCard**: 课程卡片
- **KnowledgeGraphCanvas**: 知识图谱画布
- **ControversyCard**: 争议卡片
- **RadarChart**: 雷达图
- **LoadingIndicator**: 加载指示器
- **ErrorDialog**: 错误对话框

## 项目结构

```
entry/src/main/ets/
├── pages/                    # 页面
│   ├── MainPage.ets          # 主页
│   ├── LearningSpacePage.ets # 学习空间
│   ├── AssessmentCenterPage.ets # 测评中心
│   └── ProfilePage.ets       # 个人中心
├── components/               # UI 组件
│   ├── CourseCard.ets
│   ├── KnowledgeGraphCanvas.ets
│   ├── ControversyCard.ets
│   ├── RadarChart.ets
│   ├── ProgressBar.ets
│   ├── LoadingIndicator.ets
│   └── ErrorDialog.ets
├── services/                 # 服务层
│   ├── RDBService.ets
│   ├── PreferencesService.ets
│   ├── FileService.ets
│   ├── DeepseekService.ets
│   ├── PromptTemplates.ets
│   ├── ResponseParser.ets
│   ├── CourseManager.ets
│   ├── ThreeQuestionEngine.ets
│   ├── KnowledgeBaseManager.ets
│   └── AssessmentManager.ets
├── model/                    # 数据模型
│   ├── Course.ets
│   ├── KnowledgeNode.ets
│   ├── KnowledgeEdge.ets
│   └── Assessment.ets
└── utils/                    # 工具类
    └── UUIDUtil.ets
```

## 配置说明

### API 密钥配置

1. 获取 Deepseek API 密钥：https://platform.deepseek.com/
2. 在应用中打开「我的」→「设置」→「Deepseek API 密钥」
3. 输入您的 API 密钥并保存

### 权限说明

应用需要以下权限：
- `ohos.permission.INTERNET`: 网络访问（调用 AI API）
- `ohos.permission.READ_USER_STORAGE`: 读取存储（上传材料）
- `ohos.permission.WRITE_USER_STORAGE`: 写入存储（保存数据）

## 开发环境

- HarmonyOS SDK: API 11+
- DevEco Studio: 最新版本
- ArkTS: TypeScript 扩展

## 安装依赖

```bash
ohpm install
```

## 构建运行

1. 在 DevEco Studio 中打开项目
2. 连接 HarmonyOS 设备或启动模拟器
3. 点击运行按钮

## 使用指南

### 创建课程

1. 在主页点击右上角「+」按钮
2. 输入课程名称和学习问题
3. 点击「创建」

### 学习流程

1. 进入学习空间
2. 系统自动生成知识图谱（Question 1）
3. 查看争议分析（Question 2）
4. 上传补充材料（可选）
5. 点击「生成测评」

### 完成测评

1. 进入测评中心
2. 逐题回答问题
3. 查看测评结果和能力维度分析

## 设计理念

### 三问法

1. **第一问：心智模型是什么？**
   - 帮助学习者构建结构化的知识体系
   - 识别核心概念、争议点、证据关系

2. **第二问：争议在哪里？**
   - 培养批判性思维
   - 理解不同观点的论据和证据

3. **第三问：如何评估理解？**
   - 基于布鲁姆认知层次
   - 全面评估学习效果

### 布鲁姆认知层次

- **记忆 (Remember)**: 回忆事实和基本概念
- **理解 (Understand)**: 解释观点或概念
- **应用 (Apply)**: 在给定情境中使用信息
- **分析 (Analyze)**: 分解信息并探索关系
- **评价 (Evaluate)**: 做出判断并论证
- **创造 (Create)**: 产生新的观点或产品

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！
