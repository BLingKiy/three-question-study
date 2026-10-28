## ADDED Requirements

### Requirement: Learning data overview with real data
The system SHALL display real learning statistics on the profile page, queried from RDB: total courses count, completed courses count, total assessments count, and average score across all assessment reports.

#### Scenario: Display real statistics
- **WHEN** user opens the profile page
- **THEN** system queries RDB for course counts, assessment counts, and average scores from assessment_reports, and displays the real values

### Requirement: Weekly study duration line chart
The system SHALL display a line chart showing daily study duration for the past 7 days on the profile page. Each data point represents total study duration in minutes for that day.

#### Scenario: Display line chart with data
- **WHEN** user opens the profile page and study sessions exist for the past 7 days
- **THEN** system queries study_sessions table, aggregates duration by date, and displays a line chart with 7 data points

#### Scenario: No study data
- **WHEN** no study sessions exist
- **THEN** line chart area displays "暂无学习记录"

### Requirement: Subject ability bar chart
The system SHALL display a bar chart comparing ability dimensions across courses on the profile page. Each course is a group with 3 bars (概念理解/批判思维/实践迁移) based on assessment report dimensions.

#### Scenario: Display bar chart with data
- **WHEN** user opens the profile page and assessment reports exist for multiple courses
- **THEN** system queries assessment_reports for all courses, and displays a grouped bar chart

#### Scenario: No assessment reports
- **WHEN** no assessment reports exist
- **THEN** bar chart area displays "暂无能力数据"

### Requirement: Course archive management
The system SHALL provide an archive management section on the profile page listing all archived courses with options to unarchive or delete.

#### Scenario: Display archived courses
- **WHEN** user opens the profile page and archived courses exist
- **THEN** system displays an "归档管理" section listing all archived courses

#### Scenario: Unarchive from profile
- **WHEN** user taps "取消归档" on an archived course in the profile page
- **THEN** system restores the course status and the course disappears from the archived list

#### Scenario: Delete from profile
- **WHEN** user taps "删除" on an archived course in the profile page
- **THEN** system displays confirmation dialog, on confirm deletes the course and all associated data

#### Scenario: No archived courses
- **WHEN** no archived courses exist
- **THEN** the "归档管理" section is not displayed

### Requirement: Material upload history
The system SHALL display an upload history section on the profile page listing all user-uploaded materials grouped by course.

#### Scenario: Display upload history
- **WHEN** user opens the profile page and uploaded materials exist
- **THEN** system displays an "上传历史" section with materials grouped by course name, showing file name and upload time

#### Scenario: No uploaded materials
- **WHEN** no uploaded materials exist
- **THEN** the "上传历史" section is not displayed

### Requirement: Dark mode setting
The system SHALL provide a dark mode setting on the profile page with three options: follow system, light mode, and dark mode.

#### Scenario: Switch to dark mode
- **WHEN** user selects "暗色模式"
- **THEN** system switches the app color mode to dark and persists the preference

#### Scenario: Switch to light mode
- **WHEN** user selects "亮色模式"
- **THEN** system switches the app color mode to light and persists the preference

#### Scenario: Follow system mode
- **WHEN** user selects "跟随系统"
- **THEN** system sets color mode to follow the system setting and persists the preference

### Requirement: Study session tracking
The system SHALL track user study duration per course per day. When user enters LearningSpacePage, start timing; when user leaves, calculate duration and save to study_sessions table.

#### Scenario: Track study session
- **WHEN** user enters a course's learning space and stays for N seconds, then leaves
- **THEN** system saves/updates a study_sessions record for that course and date with accumulated duration

#### Scenario: Study session data persistence
- **WHEN** the app initializes the database
- **THEN** system creates study_sessions table with columns: id (TEXT PRIMARY KEY), course_id (TEXT NOT NULL), date (TEXT NOT NULL, YYYY-MM-DD format), duration_seconds (INTEGER NOT NULL), with UNIQUE constraint on (course_id, date)