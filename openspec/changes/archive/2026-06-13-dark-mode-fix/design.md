## Context

当前暗色模式实现存在两个层面的问题：

**API 层面**：ProfilePage 的 `applyColorMode()` 方法中，将用户选择（跟随系统/亮色/暗色）映射为存储值的逻辑与 HarmonyOS `ConfigurationConstant.ColorMode` 枚举值不一致。`COLOR_MODE_NOT_SET=-1`、`COLOR_MODE_DARK=0`、`COLOR_MODE_LIGHT=1`，但代码中错误地将 index 1（亮色）映射为 0（实际是 DARK），导致切换时系统收到错误指令。

**资源层面**：虽然已将 `Color.White`、`#F5F5F5`、`#999999`、`#333333` 替换为资源引用，但页面中仍有约 20+ 处硬编码颜色值未处理，包括：
- `#CCCCCC`：禁用态按钮背景
- `#F0F0F0`：输入框背景
- `#E3F2FD`：用户消息气泡背景
- `#666666`：次要文字颜色（与 text_secondary 重复但未用资源引用）
- `#409EFF`：链接/强调色
- `#0066CC`：按钮背景色（与 tech_blue_primary 重复但未用资源引用）

## Goals / Non-Goals

**Goals:**
- 修复 setColorMode 参数映射，使暗色模式切换真正生效
- 新增所有必要的语义化颜色资源（base + dark 两套）
- 替换所有页面中剩余的硬编码颜色为资源引用
- EntryAbility 启动时恢复已保存的颜色模式

**Non-Goals:**
- 不实现自定义主题色功能
- 不处理 ECharts/vis-network 图表内的暗色适配（Web 内容由 HTML/CSS 控制，需单独处理）
- 不处理组件文件（components/）中的硬编码颜色（本次聚焦页面文件）

## Decisions

### 1. 颜色资源命名方案
**决策**：在 color.json 中新增 `disabled_color`、`input_background`、`user_bubble_background`、`assistant_bubble_background`、`link_color` 颜色资源。
**理由**：语义化命名便于维护，dark 资源目录中提供对应的暗色值即可自动切换。

### 2. 颜色模式存储方案
**决策**：PreferencesService 直接存储 `ConfigurationConstant.ColorMode` 的数值（-1/0/1），ProfilePage 的 index 映射为：0→NOT_SET、1→LIGHT、2→DARK。
**理由**：存储值与系统 API 一致，避免映射错误。

### 3. EntryAbility 启动恢复
**决策**：在 EntryAbility.onCreate 中读取 PreferencesService 保存的颜色模式并调用 setColorMode。
**理由**：确保应用启动时就应用正确的颜色模式，而不是等到用户进入"我的"页面才恢复。

## Risks / Trade-offs

- **Web 组件内颜色不受控** → ECharts 和 vis-network 的 HTML 文件使用硬编码颜色，暗色模式下可能不协调；后续可通过 JS 注入动态切换
- **部分功能性颜色保持硬编码** → 如题型标签色（#FB6B98 等）、Bloom 层级色等，这些是设计规范色，暗色模式下保持不变