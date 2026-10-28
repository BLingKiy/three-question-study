## MODIFIED Requirements

### Requirement: Question execution status tracking
The system SHALL track the execution status of each question (not started, in progress, completed, failed) and display progress indicators to the user. When a question execution fails, the system SHALL provide a retry button in the UI for manual retry.

#### Scenario: Progress display during execution
- **WHEN** a question is being executed
- **THEN** system displays loading indicator, shows "正在分析..." message, and updates progress bar

#### Scenario: Error handling with retry
- **WHEN** a question execution fails (API error, timeout, parsing error)
- **THEN** system displays error message, shows retry button, and does not proceed to next question until current one succeeds or is retried

## ADDED Requirements

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
The system SHALL provide "重新生成" buttons in the learning space page for knowledge graph (Q1) and controversy analysis (Q2), allowing users to regenerate even if previous execution succeeded.

#### Scenario: Regenerate knowledge graph
- **WHEN** user clicks "重新生成" button in knowledge graph tab
- **THEN** system shows confirmation, deletes existing knowledge graph and edges, re-executes Q1, and refreshes the display

#### Scenario: Regenerate controversy analysis
- **WHEN** user clicks "重新生成" button in controversy tab
- **THEN** system shows confirmation, deletes existing controversy nodes, re-executes Q2, and refreshes the display

#### Scenario: Regeneration in progress
- **WHEN** regeneration is in progress
- **THEN** regenerate button is disabled and shows loading state, preventing duplicate execution