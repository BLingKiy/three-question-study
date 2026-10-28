## Why

当前暗色模式功能不可用：点击"暗色模式"后弹窗选择深色，系统只闪一下屏就恢复浅色。根本原因有两个：(1) `setColorMode()` 的参数映射错误，传入的值与系统 ColorMode 枚举不匹配；(2) 页面中仍有大量硬编码颜色值（如 `#CCCCCC`、`#F0F0F0`、`#E3F2FD`、`#666666`、`#409EFF` 等）未使用资源引用，暗色模式下无法自动切换。

## What Changes

- 修复 `applyColorMode()` 中 `setColorMode()` 参数映射，直接使用 `ConfigurationConstant.ColorMode` 枚举值
- 修复 ProfilePage 加载时恢复颜色模式的映射逻辑
- 在 color.json（base + dark）中新增语义化颜色资源：`disabled_color`、`input_background`、`user_bubble_background`、`assistant_bubble_background`、`link_color`、`secondary_text_dark`
- 替换所有页面中剩余的硬编码颜色为 `$r('app.color.xxx')` 资源引用
- 确保 EntryAbility 启动时读取已保存的颜色模式并应用

## Capabilities

### New Capabilities

（无新增 capability）

### Modified Capabilities
- `course-management`：暗色模式切换逻辑修复，全局颜色适配