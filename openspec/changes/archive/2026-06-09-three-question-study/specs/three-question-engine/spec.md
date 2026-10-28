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
The system SHALL analyze multiple sources in the knowledge base to identify academic controversies, disputes, and conflicting viewpoints. The system SHALL present each controversy with supporting evidence from both sides.

#### Scenario: Successful controversy analysis
- **WHEN** Question 2 is executed after Question 1 completes
- **THEN** system generates a list of controversies, each with title, description, supporting evidence, opposing evidence, and displays in left-right split view

#### Scenario: Q2 regeneration
- **WHEN** user clicks "重新分析争议点" button
- **THEN** system deletes existing controversies, re-executes Question 2, and displays updated controversy list

### Requirement: Question 3 - Assessment generation
The system SHALL generate assessment questions based on Bloom's taxonomy across six cognitive dimensions: Remember, Understand, Apply, Analyze, Evaluate, and Create. Each execution SHALL generate different questions.

#### Scenario: Assessment generation with variety
- **WHEN** user triggers Question 3
- **THEN** system generates at least 3 questions per cognitive level (minimum 18 total questions), questions are different from previous executions, and questions are stored in assessment database

#### Scenario: Multiple assessment attempts
- **WHEN** user completes an assessment and triggers Question 3 again
- **THEN** system generates a new set of different questions while preserving previous assessment records

### Requirement: Question execution status tracking
The system SHALL track the execution status of each question (not started, in progress, completed, failed) and display progress indicators to the user.

#### Scenario: Progress display during execution
- **WHEN** a question is being executed
- **THEN** system displays loading indicator, shows "正在分析..." message, and updates progress bar

#### Scenario: Error handling
- **WHEN** a question execution fails (API error, timeout, parsing error)
- **THEN** system displays error message, allows retry, and does not proceed to next question until current one succeeds
