## MODIFIED Requirements

### Requirement: Course progress tracking
The system SHALL track and display progress for each course using a unified formula across all pages (home page course cards and learning space page). The progress formula SHALL be:

- **2/3 Learning Space** (capped at 2/3):
  - Q1 心智模型: 2/9 total, awarded when mental model is checked
  - Q2 争议分析: 2/9 total, evenly divided among all controversy items
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