## 1. 数据库表与模型

- [x] 1.1 RDBService 新增 answer_archives 表创建（id, original_course_id, original_course_name, bloom_level, question_type, question, answer, options, correct_answer, user_answer, is_correct, created_at, archived_at）
- [x] 1.2 RDBService 新增 follow_up_archives 表创建（id, archive_assessment_id, role, content, created_at, FOREIGN KEY archive_assessment_id）
- [x] 1.3 Assessment.ets 新增 ArchiveAssessment 和 ArchiveFollowUp 接口定义
- [x] 1.4 RDBService 新增 insertAnswerArchive / queryAnswerArchivesByCourseId / queryAllAnswerArchives 方法
- [x] 1.5 RDBService 新增 insertFollowUpArchive / queryFollowUpArchivesByArchiveAssessmentId 方法
- [x] 1.6 RDBService.deleteCourse 级联删除 answer_archives + follow_up_archives 数据

## 2. 重新生成逻辑

- [x] 2.1 RDBService 新增 archiveAnsweredAssessments(courseId, courseName) 方法：查询已答题目→插入 answer_archives→查询追问→插入 follow_up_archives
- [x] 2.2 RDBService 新增 resetCourseAfterRegenerate(courseId) 方法：删除 assessment_follow_ups→删除 assessments→删除 assessment_reports→删除 learning_progress→重置 assessmentGenerating=false
- [x] 2.3 LearningSpacePage.handleRegenerate 在 regenerateAll 成功后调用 archiveAnsweredAssessments + resetCourseAfterRegenerate

## 3. 答题档案 UI

- [x] 3.1 ProfilePage 新增"答题档案"区域：按课程名分组展示归档题目
- [x] 3.2 每个课程组显示课程名+题目数量，展开显示题目列表
- [x] 3.3 题目卡片显示题目文本+题型标签+正确/错误状态
- [x] 3.4 点击题目卡片展开详情：用户答案、正确答案、追问对话记录
- [x] 3.5 无归档记录时显示"暂无答题档案"占位文字

## 4. 验证与构建

- [x] 4.1 构建验证：hvigorw assembleHap 通过
