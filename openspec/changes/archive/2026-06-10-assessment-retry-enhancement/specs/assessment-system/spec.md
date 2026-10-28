## MODIFIED Requirements

### Requirement: Assessment taking
The system SHALL allow users to answer assessment questions one at a time, submit answers, and receive immediate feedback with explanations. For objective questions (singleChoice, multipleChoice, trueFalse), the system SHALL auto-score upon submission. For subjective questions, the system SHALL use keyword matching to evaluate.

#### Scenario: Answer submission
- **WHEN** user selects an answer and submits
- **THEN** system evaluates the answer based on question type (auto-score for objective, keyword match for subjective), displays correct/incorrect status, shows explanation, and moves to next question

### Requirement: Assessment scoring
The system SHALL calculate and display overall score, scores per cognitive level, and identify weak areas for review. Objective questions SHALL be auto-scored; subjective questions SHALL use keyword similarity matching.

#### Scenario: Assessment completion
- **WHEN** user completes all questions
- **THEN** system calculates total score (including auto-scored objective and keyword-matched subjective), generates score breakdown by Bloom level, identifies weakest cognitive areas, and displays recommendations

## ADDED Requirements

### Requirement: Assessment grouped by course
The system SHALL display assessment questions grouped by course in the assessment center page. Each group SHALL show course name, question count, and be expandable/collapsible.

#### Scenario: Course-grouped display
- **WHEN** user opens assessment center page
- **THEN** system queries all courses with assessments, displays each course as a group header with course name and question count, and questions are listed under their course group

#### Scenario: Empty course group
- **WHEN** a course has no assessments
- **THEN** that course is not shown in the assessment center page

#### Scenario: Course group expansion
- **WHEN** user taps a course group header
- **THEN** group expands to show all assessment questions for that course, or collapses if already expanded