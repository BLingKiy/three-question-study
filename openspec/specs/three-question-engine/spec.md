## ADDED Requirements

### Requirement: Three-question engine initialization
The system SHALL automatically execute Question 1 (mental model extraction) and Question 2 (controversy analysis) when a new course is created. Question 3 (assessment generation) SHALL be triggered manually by the user.

#### Scenario: Automatic Q1 and Q2 execution
- **WHEN** a new course is created
- **THEN** system automatically executes Question 1, waits for completion, then automatically executes Question 2

#### Scenario: Manual Q3 trigger
- **WHEN** user clicks "开始测评" button
- **THEN** system executes Question 3 and generates new assessment questions

### Requirement: Question 1 - Mental model extraction
The system SHALL extract the core mental model from the composite knowledge base and generate a dynamic knowledge graph. The graph SHALL visualize key concepts and their logical relationships.

#### Scenario: Successful mental model extraction
- **WHEN** Question 1 is executed for a course
- **THEN** system calls Deepseek API with appropriate prompt, parses the response, generates knowledge graph with nodes and edges, and displays the graph in the learning space

#### Scenario: Q1 regeneration
- **WHEN** user clicks "重新生成知识图谱" button
- **THEN** system deletes the existing knowledge graph, re-executes Question 1 with current knowledge base, and displays the new graph

### Requirement: Question 2 - Controversy analysis
The system SHALL analyze multiple sources in the knowledge base to identify academic controversies, disputes, and conflicting viewpoints. The controversy area SHALL be displayed in the middle of the learning space using a left-right split view for each controversy, with Swiper support for switching between different controversy topics. Each controversy SHALL have a logic chain graph and a discussion thread.

#### Scenario: Successful controversy analysis
- **WHEN** Question 2 is executed after Question 1 completes
- **THEN** system generates a list of controversies, each displayed in a left-right split card: left column shows position A with arguments and evidence, right column shows position B with arguments and evidence, bottom shows synthesis and logic chain graph

#### Scenario: Switch controversy topic
- **WHEN** user swipes left/right or taps navigation indicators in the controversy area
- **THEN** system switches to the next/previous controversy topic with smooth transition

#### Scenario: Q2 regeneration
- **WHEN** user clicks "重新生成" button in the controversy section
- **THEN** system deletes existing controversies, re-executes Question 2, and displays updated controversy list

#### Scenario: No controversies
- **WHEN** no controversy data exists for the course
- **THEN** middle section shows placeholder text "暂无争议分析数据" with a "重新生成" button

#### Scenario: Open discussion thread
- **WHEN** user taps "讨论" button on a controversy card
- **THEN** system navigates to the discussion thread for that controversy

#### Scenario: View logic chain graph
- **WHEN** user expands the logic chain section of a controversy card
- **THEN** system renders a vis-network graph showing controversy → evidence → conclusion chain

### Requirement: Question 3 - Assessment generation
The system SHALL generate assessment questions based on Bloom's taxonomy across six cognitive dimensions: Remember, Understand, Apply, Analyze, Evaluate, and Create. Each execution SHALL generate different questions.

#### Scenario: Assessment generation with variety
- **WHEN** user triggers Question 3
- **THEN** system generates at least 3 questions per cognitive level (minimum 18 total questions), questions are different from previous executions, and questions are stored in assessment database

#### Scenario: Multiple assessment attempts
- **WHEN** user completes an assessment and triggers Question 3 again
- **THEN** system generates a new set of different questions while preserving previous assessment records

### Requirement: Question execution status tracking
The system SHALL track the execution status of each question (not started, in progress, completed, failed) and display progress indicators to the user. When a question execution fails, the system SHALL provide a retry button in the UI for manual retry.

#### Scenario: Progress display during execution
- **WHEN** a question is being executed
- **THEN** system displays loading indicator, shows "正在分析..." message, and updates progress bar

#### Scenario: Error handling with retry
- **WHEN** a question execution fails (API error, timeout, parsing error)
- **THEN** system displays error message, shows retry button, and does not proceed to next question until current one succeeds or is retried

### Requirement: Course creation stage retry
The system SHALL provide retry buttons on the course card when Q1 (mental model) or Q2 (controversy) generation fails during course creation. The retry button SHALL re-execute the failed question stage.

#### Scenario: Q1 failure retry from course card
- **WHEN** course has `mentalModelGenerated=false` and user clicks retry button on course card
- **THEN** system re-executes Q1 for that course, deletes existing knowledge graph data first, and updates course status on success

#### Scenario: Q2 failure retry from course card
- **WHEN** course has `controversyGenerated=false` and user clicks retry button on course card
- **THEN** system re-executes Q2 for that course, deletes existing controversy data first, and updates course status on success

#### Scenario: Both Q1 and Q2 failed
- **WHEN** course has both `mentalModelGenerated=false` and `controversyGenerated=false`
- **THEN** course card shows two retry buttons: "重试知识图谱" and "重试争议分析"

### Requirement: Learning space regeneration
The system SHALL provide "重新生成" buttons in the learning space page for knowledge graph (Q1) and controversy analysis (Q2), allowing users to regenerate even if previous execution succeeded. Q1 regeneration SHALL preserve controversy data (controversy-type nodes). Q2 regeneration SHALL only delete controversy-type nodes. During regeneration, the corresponding section SHALL display a loading overlay.

#### Scenario: Regenerate knowledge graph
- **WHEN** user clicks "重新生成" button in knowledge graph section
- **THEN** system shows confirmation, deletes existing knowledge graph nodes (excluding controversy-type nodes) and all edges, re-executes Q1, and refreshes the display

#### Scenario: Regenerate controversy analysis
- **WHEN** user clicks "重新生成" button in controversy section
- **THEN** system shows confirmation, deletes existing controversy nodes, re-executes Q2, and refreshes the display

#### Scenario: Regeneration in progress
- **WHEN** regeneration is in progress
- **THEN** regenerate button is disabled and shows loading state, the corresponding section displays a semi-transparent loading overlay, preventing duplicate execution

#### Scenario: Regeneration error - API key not configured
- **WHEN** regeneration fails with "API密钥未配置" error
- **THEN** system displays error message "请先在「我的」页面配置 API 密钥" with a dismiss button

#### Scenario: Regeneration error - other failure
- **WHEN** regeneration fails with any other error
- **THEN** system displays error message "重新生成失败：{error message}" with a dismiss button

#### Scenario: Q1 regeneration preserves Q2 data
- **WHEN** user regenerates knowledge graph (Q1) and controversy data exists
- **THEN** system deletes only non-controversy nodes and all edges, controversy nodes remain intact, after Q1 completes the controversy section still shows existing controversy data

### Requirement: Learning space generation state detection
The system SHALL detect the course generation state when entering the learning space page, and display loading animations for sections that are still being generated.

#### Scenario: Q1 not yet generated
- **WHEN** user enters learning space and `mentalModelGenerated` is false
- **THEN** mental model section displays a skeleton loading animation with LoadingIndicator and text "正在生成心智模型..." instead of the empty state

#### Scenario: Q2 not yet generated
- **WHEN** user enters learning space and `controversyGenerated` is false
- **THEN** controversy section displays a skeleton loading animation with LoadingIndicator and text "正在生成争议分析..." instead of the empty state

#### Scenario: Both sections not yet generated
- **WHEN** user enters learning space and both Q1 and Q2 are not generated
- **THEN** both sections show their respective loading animations simultaneously

#### Scenario: All sections already generated
- **WHEN** user enters learning space and both Q1 and Q2 are already generated
- **THEN** page displays normally with data, no loading animations

### Requirement: Learning space generation state polling
The system SHALL poll the course generation state at 2-second intervals when any section is still being generated, and automatically refresh the corresponding section when generation completes.

#### Scenario: Q1 completes during polling
- **WHEN** polling detects `mentalModelGenerated` changed from false to true
- **THEN** system loads and displays the knowledge graph data, replaces the loading animation with the actual graph, and stops polling if Q2 is also complete

#### Scenario: Q2 completes during polling
- **WHEN** polling detects `controversyGenerated` changed from false to true
- **THEN** system loads and displays the controversy data, replaces the loading animation with the actual cards, and stops polling if Q1 is also complete

#### Scenario: Both sections complete
- **WHEN** polling detects both `mentalModelGenerated` and `controversyGenerated` are true
- **THEN** system stops polling, loads all data, and displays the full page

#### Scenario: Page cleanup
- **WHEN** user navigates away from the learning space page
- **THEN** system clears the polling timer to prevent memory leaks

### Requirement: Learning space three-zone layout
The system SHALL display the learning space as a vertically scrollable page with three zones: top zone for knowledge graph (心智模型区), middle zone for controversy analysis (争议点区), bottom zone for materials (资料区). Each zone SHALL have a section header and be visually separated.

#### Scenario: Three-zone display
- **WHEN** user enters the learning space page
- **THEN** page shows zones vertically: "心智模型" section with knowledge graph canvas, "争议分析" section with controversy split-view, "补充资料" section with material list

#### Scenario: Zone scrolling
- **WHEN** page content exceeds screen height
- **THEN** user can scroll vertically to see all zones

### Requirement: Materials zone with source distinction and links
The system SHALL display materials in the bottom zone with source labels distinguishing "AI 补充" (knowledge graph content with web source links) from "用户上传" (user-uploaded files). The zone SHALL include an upload entry button.

#### Scenario: AI supplemented materials display
- **WHEN** knowledge graph has concept/evidence nodes with content
- **THEN** materials zone shows items with "AI 补充" source label, displaying node label as title, content as preview, and source link icon (tapping opens URL in browser)

#### Scenario: User uploaded materials display
- **WHEN** user has uploaded files for the course
- **THEN** materials zone shows items with "用户上传" source label, displaying file name and file type icon

#### Scenario: Upload entry
- **WHEN** user taps the upload button in materials zone
- **THEN** system opens file picker for selecting PDF/Word/Markdown files to upload

#### Scenario: Empty materials
- **WHEN** no materials exist for the course
- **THEN** materials zone shows placeholder text "暂无补充资料" with upload button

### Requirement: Regenerate resets learning progress
The system SHALL reset the learning progress for a course when the user triggers regeneration. All records in the learning_progress table for that course SHALL be deleted, and the progress SHALL be recalculated from scratch.

#### Scenario: Progress reset on regenerate
- **WHEN** user taps "重新生成" button and regeneration completes successfully
- **THEN** system deletes all learning_progress records for the course, resets checked states for all items, and recalculates the course progress from zero

#### Scenario: Progress display after regenerate
- **WHEN** regeneration completes and user views the learning space
- **THEN** all progress checkboxes are unchecked and the progress bar shows the recalculated progress (excluding assessment portion since assessments are cleared)

### Requirement: Regenerate archives answered assessments
The system SHALL archive all answered assessments (where userAnswer is not empty) and their follow-up records before clearing them during regeneration.

#### Scenario: Archive answered assessments on regenerate
- **WHEN** user triggers regeneration for a course
- **THEN** system queries all assessments for the course where userAnswer is not empty, creates answer_archives records with original_course_id, original_course_name, and archived_at, and creates follow_up_archives records for each assessment's follow-ups

#### Scenario: Skip unanswered assessments
- **WHEN** system archives assessments during regeneration
- **THEN** assessments where userAnswer is empty are not archived (they are simply deleted)

#### Scenario: Archive before delete
- **WHEN** system processes regeneration
- **THEN** archiving happens before deletion of assessments, ensuring no data loss

### Requirement: Regenerate clears assessments and report
The system SHALL delete all assessments, follow-ups, and assessment reports for a course during regeneration, and reset assessmentGenerating to false.

#### Scenario: Delete assessments on regenerate
- **WHEN** regeneration completes successfully
- **THEN** system deletes all assessment_follow_ups records for the course's assessments, deletes all assessments for the course, deletes the assessment_reports record for the course, and sets assessmentGenerating to false

#### Scenario: Assessment center after regenerate
- **WHEN** user navigates to assessment center after regeneration
- **THEN** the course group shows "暂无测评题目" with a "生成测评" button, as if the course was newly created
