## ADDED Requirements

### Requirement: Course progress tracking
The system SHALL track and display progress for each course, including completion status of each question, overall progress percentage, and last activity timestamp.

#### Scenario: Progress calculation
- **WHEN** user completes a question or assessment
- **THEN** system updates progress percentage, marks question as completed, and updates last activity time

### Requirement: Ability radar chart
The system SHALL generate and display a radar chart showing user's ability across multiple dimensions: concept understanding, critical thinking, practical application, and knowledge breadth.

#### Scenario: Radar chart display
- **WHEN** user views course progress
- **THEN** system calculates scores for each ability dimension, renders radar chart with 4 axes, and updates chart as user progresses

### Requirement: Learning statistics
The system SHALL aggregate and display learning statistics including total courses, total study time, average assessment scores, and improvement trends.

#### Scenario: Statistics dashboard
- **WHEN** user views personal center
- **THEN** system displays total courses count, total study hours, average score across all assessments, and score trend over time

### Requirement: Progress persistence
The system SHALL persist all progress data in RDB, ensuring progress is not lost between sessions.

#### Scenario: Progress restoration
- **WHEN** user reopens the app
- **THEN** system loads all progress data from RDB and displays current state
