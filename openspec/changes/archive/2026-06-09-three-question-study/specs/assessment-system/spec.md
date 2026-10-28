## ADDED Requirements

### Requirement: Bloom's taxonomy assessment
The system SHALL generate assessment questions across six cognitive dimensions: Remember, Understand, Apply, Analyze, Evaluate, and Create. Each question SHALL be tagged with its cognitive level.

#### Scenario: Multi-level question generation
- **WHEN** assessment is generated
- **THEN** system creates at least 3 questions per cognitive level, each question has bloomLevel tag, and questions cover different aspects of the knowledge

### Requirement: Assessment taking
The system SHALL allow users to answer assessment questions one at a time, submit answers, and receive immediate feedback with explanations.

#### Scenario: Answer submission
- **WHEN** user selects an answer and submits
- **THEN** system evaluates the answer, displays correct/incorrect status, shows explanation, and moves to next question

### Requirement: Assessment scoring
The system SHALL calculate and display overall score, scores per cognitive level, and identify weak areas for review.

#### Scenario: Assessment completion
- **WHEN** user completes all questions
- **THEN** system calculates total score, generates score breakdown by Bloom level, identifies weakest cognitive areas, and displays recommendations

### Requirement: Assessment history
The system SHALL maintain history of all assessment attempts, allowing users to review past performance and track improvement.

#### Scenario: Assessment history access
- **WHEN** user views assessment history
- **THEN** system displays list of past assessments with date, score, and allows viewing detailed results
