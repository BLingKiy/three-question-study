## 1. CourseCard 操作菜单

- [x] 1.1 在 CourseCard.ets 中添加 onArchiveClick、onCompleteClick 回调 props
- [x] 1.2 在 CourseCard.ets 中将底部删除按钮替换为"更多"按钮（三点图标），使用 bindMenu 绑定菜单
- [x] 1.3 根据 course.status 动态生成菜单项：created/active → [归档, 删除]；completed → [归档, 取消完成, 删除]；archived → [取消归档, 删除]
- [x] 1.4 删除操作改为弹出 AlertDialog 确认后再执行 onDeleteClick

## 2. MainPage 归档/完成操作

- [x] 2.1 在 MainPage.ets 中实现 handleArchiveCourse(course) 方法，调用 courseManager.archiveCourse + loadCourses
- [x] 2.2 在 MainPage.ets 中实现 handleUnarchiveCourse(course) 方法，恢复为 active 状态 + loadCourses
- [x] 2.3 在 MainPage.ets 中实现 handleCompleteCourse(course) 方法，调用 courseManager.completeCourse + loadCourses
- [x] 2.4 在 MainPage.ets 中实现 handleUncompleteCourse(course) 方法，恢复为 active 状态 + loadCourses
- [x] 2.5 将新回调绑定到 CourseCard 的 onArchiveClick、onCompleteClick

## 3. 已归档课程折叠区域

- [x] 3.1 在 MainPage.ets 中添加 @State archivedCourses: Course[] 和 @State archivedExpanded: boolean = false
- [x] 3.2 在 loadCourses 中分离非归档和归档课程
- [x] 3.3 在课程列表底部添加"已归档课程(N)"折叠区域，默认折叠，点击展开
- [x] 3.4 归档课程卡片使用 opacity(0.6) 置灰样式

## 4. 排序切换

- [x] 4.1 在 MainPage.ets 中添加 @State sortMethod: string = 'updatedAt'（updatedAt/createdAt/progress）
- [x] 4.2 在搜索栏右侧添加排序图标按钮，使用 bindMenu 绑定排序选项（按最近使用时间/按创建时间/按学习进度）
- [x] 4.3 在 getFilteredCourses 中根据 sortMethod 排序：updatedAt 按 updatedAt 降序，createdAt 按 createdAt 降序，progress 按 courseProgressMap 降序
- [x] 4.4 排序选项旁显示当前排序方式的选中标记

## 5. 构建验证

- [x] 5.1 运行 hvigorw assembleHap 确保构建成功
