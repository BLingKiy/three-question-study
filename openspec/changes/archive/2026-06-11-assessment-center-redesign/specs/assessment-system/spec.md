## MODIFIED Requirements

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

## ADDED Requirements

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