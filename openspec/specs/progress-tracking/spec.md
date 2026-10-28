## ADDED Requirements

### Requirement: Course progress tracking
The system SHALL track and display progress for each course using a unified formula across all pages (home page course cards and learning space page). The progress formula SHALL be:

- **2/3 Learning Space** (capped at 2/3):
  - Q1 心智模型: 2/9 total, awarded when mental model is checked
  - Q2 争议分析: 2/9 total, evenly divided among controversy items that have both leftView and rightView
  - 补充资料 (AI-generated only, excluding user-uploaded materials): 2/9 total, evenly divided among AI-generated concept/evidence nodes with content
- **1/3 Assessment Center**:
  - Q3 测评: 1/3 total, evenly divided among all assessment questions for the course

The system SHALL NOT include user-uploaded materials in progress calculation. Only AI-generated supplementary materials (concept and evidence nodes with content) SHALL contribute to the 补充资料 portion.

The system SHALL use `RDBService.calculateCourseProgress()` as the single source of truth for progress calculation. The `LearningSpacePage` SHALL call this method instead of maintaining its own `calculateProgress()` logic.

#### Scenario: Progress calculation with unified formula
- **WHEN** user views any page showing course progress
- **THEN** system calculates progress using the unified formula: 2/3 learning space (Q1 2/9 + Q2 2/9 + AI materials 2/9) + 1/3 assessment (each question evenly divided), ensuring home page cards and learning space page show identical values

#### Scenario: User-uploaded materials excluded from progress
- **WHEN** user uploads materials to a course
- **THEN** system does NOT create progress records for uploaded materials and does NOT include them in progress calculation

#### Scenario: Progress consistency across pages
- **WHEN** user checks a learning item in learning space
- **THEN** system updates progress via RDBService, and home page course card shows the same progress value on next refresh

### Requirement: Ability radar chart
The system SHALL generate and display a radar chart showing user's ability across multiple dimensions: concept understanding, critical thinking, practical application, and knowledge breadth.

#### Scenario: Radar chart display
- **WHEN** user views course progress
- **THEN** system calculates scores for each ability dimension, renders radar chart with 4 axes, and updates chart as user progresses

### Requirement: Learning statistics
The system SHALL aggregate and display learning statistics including total courses, answered assessments count, total assessments count, and average assessment score.

#### Scenario: Statistics dashboard
- **WHEN** user views personal center
- **THEN** system displays total courses count, answered assessments count, total assessments count, average score across all assessment reports, and score trend over time

### Requirement: Progress persistence
The system SHALL persist all progress data in RDB, ensuring progress is not lost between sessions.

#### Scenario: Progress restoration
- **WHEN** user reopens the app
- **THEN** system loads all progress data from RDB and displays current state
