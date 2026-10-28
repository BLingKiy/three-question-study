## ADDED Requirements

### Requirement: Bloom's taxonomy assessment
The system SHALL generate assessment questions across six cognitive dimensions: Remember, Understand, Apply, Analyze, Evaluate, and Create. Each question SHALL be tagged with its cognitive level.

#### Scenario: Multi-level question generation
- **WHEN** assessment is generated
- **THEN** system creates at least 3 questions per cognitive level, each question has bloomLevel tag, and questions cover different aspects of the knowledge

### Requirement: Assessment taking
The system SHALL allow users to answer assessment questions one at a time, submit answers, and receive immediate feedback with explanations. For objective questions (singleChoice, multipleChoice, trueFalse), the system SHALL auto-score upon submission and display the correct answer with explanation. For subjective questions, the system SHALL use AI deep evaluation and display the analysis result. After answering, the system SHALL present a follow-up question module and navigation buttons (上一题/下一题). A "查看评测报告" button SHALL appear below the result, disabled until all course questions are answered.

#### Scenario: Objective question answer submission
- **WHEN** user submits an answer for an objective question
- **THEN** system auto-scores the answer, displays correct/incorrect status, shows the correct answer and explanation text, and presents "上一题"/"下一题" navigation buttons, a follow-up question input area, and a "查看评测报告" button

#### Scenario: Subjective question answer submission
- **WHEN** user submits an answer for a subjective question
- **THEN** system calls AI for deep evaluation, displays the evaluation result (score, analysis, suggestion), and presents "上一题"/"下一题" navigation buttons, a follow-up question input area, and a "查看评测报告" button

#### Scenario: Answer already submitted
- **WHEN** user has already submitted an answer for the current question
- **THEN** the answer input area is disabled, the result/evaluation is displayed, and the follow-up area, navigation buttons, and "查看评测报告" button are shown

#### Scenario: Navigate to previous question
- **WHEN** user taps "上一题" button and current question is not the first
- **THEN** system moves to the previous assessment question

#### Scenario: Navigate to next question
- **WHEN** user taps "下一题" button and current question is not the last
- **THEN** system moves to the next assessment question

#### Scenario: Previous button disabled on first question
- **WHEN** current question is the first question
- **THEN** "上一题" button is disabled

#### Scenario: Next button disabled on last question
- **WHEN** current question is the last question
- **THEN** "下一题" button is disabled

#### Scenario: View report button disabled when questions remain
- **WHEN** not all questions for the course have been answered
- **THEN** "查看评测报告" button is disabled (grayed out)

#### Scenario: View report button enabled when all answered
- **WHEN** all questions for the course have been answered
- **THEN** "查看评测报告" button is enabled

### Requirement: Assessment scoring
The system SHALL calculate and display overall score, scores per cognitive level, and identify weak areas for review. Objective questions SHALL be auto-scored; subjective questions SHALL use keyword similarity matching.

#### Scenario: Assessment completion
- **WHEN** user completes all questions
- **THEN** system calculates total score (including auto-scored objective and keyword-matched subjective), generates score breakdown by Bloom level, identifies weakest cognitive areas, and displays recommendations

### Requirement: Assessment history
The system SHALL maintain history of all assessment attempts, allowing users to review past performance and track improvement.

#### Scenario: Assessment history access
- **WHEN** user views assessment history
- **THEN** system displays list of past assessments with date, score, and allows viewing detailed results

### Requirement: Assessment grouped by course
The system SHALL display assessment questions grouped by course in the assessment center page. Each group SHALL show course name, question count, and be expandable/collapsible. Each course group SHALL display a "生成测评" button when the course has no assessments or when the user wants to regenerate. Courses with completed knowledge base construction (mentalModelGenerated=true) SHALL appear in the assessment center even if they have no assessments yet.

#### Scenario: Course-grouped display
- **WHEN** user opens assessment center page
- **THEN** system queries all courses with mentalModelGenerated=true, displays each course as a group header with course name and question count, and questions are listed under their course group

#### Scenario: Course with no assessments
- **WHEN** a course has mentalModelGenerated=true but no assessments
- **THEN** that course is shown in the assessment center with "暂无测评题目" placeholder and a "生成测评" button

#### Scenario: Course group expansion
- **WHEN** user taps a course group header
- **THEN** group expands to show all assessment questions for that course, or collapses if already expanded

#### Scenario: Generate assessment button
- **WHEN** user taps "生成测评" button on a course group
- **THEN** system shows confirmation dialog, collects complete knowledge base context (knowledge graph nodes, controversy data, user-uploaded material content, WebSearch sources), calls ThreeQuestionEngine.executeQuestion3 with the full context, and displays generated questions in the course group

#### Scenario: Assessment generation in progress
- **WHEN** assessment generation is in progress
- **THEN** "生成测评" button is disabled and shows loading state, the course group displays a loading indicator

#### Scenario: Assessment generation error
- **WHEN** assessment generation fails
- **THEN** system displays error message "测评生成失败：{error message}" and the "生成测评" button becomes available again

#### Scenario: Assessment generation with API key not configured
- **WHEN** user taps "生成测评" and API key is not configured
- **THEN** system displays error message "请先在「我的」页面配置 API 密钥"

### Requirement: Assessment question metadata display
The system SHALL display Bloom's cognitive level and question type as visible tags on each assessment question in the list and during answering.

#### Scenario: Question tags in list
- **WHEN** assessment questions are displayed in the course group list
- **THEN** each question card shows a Bloom level tag (记忆/理解/应用/分析/评价/创造) and a question type tag (单选/多选/判断/主观) with distinct colors

#### Scenario: Question tags during answering
- **WHEN** user is answering an assessment question
- **THEN** the question header area shows Bloom level tag and question type tag

### Requirement: Assessment generation with full knowledge base context
The system SHALL generate assessment questions based on the complete knowledge base including user-uploaded material content, knowledge graph, controversy data, and WebSearch sources.

#### Scenario: Collect user material content for generation
- **WHEN** user triggers assessment generation for a course
- **THEN** system reads content from user-uploaded txt/md files (via FileService), includes the text content in the generation prompt context

#### Scenario: Collect knowledge graph for generation
- **WHEN** user triggers assessment generation for a course
- **THEN** system queries all knowledge nodes and includes their labels and content in the generation prompt context

#### Scenario: Collect controversy data for generation
- **WHEN** user triggers assessment generation for a course
- **THEN** system queries controversy nodes and includes their topics, left/right views, and synthesis in the generation prompt context

#### Scenario: Material content truncation
- **WHEN** total collected material content exceeds 8000 characters
- **THEN** system truncates to 8000 characters and appends "...(内容过长已截断)" notice
