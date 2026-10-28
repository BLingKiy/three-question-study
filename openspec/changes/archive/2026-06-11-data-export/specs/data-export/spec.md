## ADDED Requirements

### Requirement: Learning report export
The system SHALL allow users to export the assessment report for a course in TXT, JSON, or Markdown format. The exported content SHALL include three-dimension scores, overall suggestion, dimension analysis, and error traces.

#### Scenario: Export report as TXT
- **WHEN** user selects "导出学习报告" and chooses TXT format
- **THEN** system generates a plain text file containing the report content with line breaks and indentation, and saves it to the user-selected location

#### Scenario: Export report as JSON
- **WHEN** user selects "导出学习报告" and chooses JSON format
- **THEN** system generates a JSON file with structured report data (dimensions, overallSuggestion, dimensionAnalysis, errorTraces), and saves it to the user-selected location

#### Scenario: Export report as Markdown
- **WHEN** user selects "导出学习报告" and chooses Markdown format
- **THEN** system generates a Markdown file with headings, lists, and tables for the report content, and saves it to the user-selected location

#### Scenario: Export when no report exists
- **WHEN** user attempts to export a learning report but no report has been generated for the course
- **THEN** system displays error message "请先生成测评报告"

### Requirement: Error collection export
The system SHALL allow users to export the error question collection for a course in TXT, JSON, or Markdown format. The exported content SHALL include each incorrect question with the question text, user answer, correct answer, and explanation.

#### Scenario: Export error collection as TXT
- **WHEN** user selects "导出错题集" and chooses TXT format
- **THEN** system queries all incorrect assessments for the course, generates a plain text file listing each error with question/answer details, and saves it

#### Scenario: Export error collection as JSON
- **WHEN** user selects "导出错题集" and chooses JSON format
- **THEN** system generates a JSON array of error question objects and saves it

#### Scenario: Export error collection as Markdown
- **WHEN** user selects "导出错题集" and chooses Markdown format
- **THEN** system generates a Markdown file with each error as a section and saves it

#### Scenario: No incorrect answers
- **WHEN** user exports error collection but all questions are answered correctly
- **THEN** exported file contains a message indicating "全部回答正确，无错题"

### Requirement: Dialog records export
The system SHALL allow users to export all follow-up dialog records for a course in TXT, JSON, or Markdown format. The exported content SHALL include for each assessment: the question text, and all follow-up messages with role and content.

#### Scenario: Export dialog records as TXT
- **WHEN** user selects "导出对话记录" and chooses TXT format
- **THEN** system queries all follow-up records for the course's assessments, generates a plain text file, and saves it

#### Scenario: Export dialog records as JSON
- **WHEN** user selects "导出对话记录" and chooses JSON format
- **THEN** system generates a JSON structure grouped by assessment with all follow-up messages and saves it

#### Scenario: Export dialog records as Markdown
- **WHEN** user selects "导出对话记录" and chooses Markdown format
- **THEN** system generates a Markdown file with each assessment as a section and dialog as conversation thread and saves it

#### Scenario: No dialog records
- **WHEN** user exports dialog records but no follow-up messages exist
- **THEN** exported file contains a message indicating "暂无对话记录"

### Requirement: Export format selection
The system SHALL provide a format selection dialog when user initiates an export, offering TXT, JSON, and Markdown options.

#### Scenario: Format selection dialog
- **WHEN** user taps an export button
- **THEN** system displays a dialog with three format options: TXT, JSON, Markdown

#### Scenario: Format selection and export
- **WHEN** user selects a format and confirms
- **THEN** system generates the export file in the selected format and saves it

### Requirement: Export file saving
The system SHALL save exported files using DocumentSaveOptions to let the user choose the save location. If DocumentSaveOptions is unavailable, the system SHALL write to the application sandbox exports directory and display the file path.

#### Scenario: Save with DocumentSaveOptions
- **WHEN** export file is generated and DocumentSaveOptions is available
- **THEN** system opens the system file picker for the user to choose save location and filename

#### Scenario: Fallback save to sandbox
- **WHEN** DocumentSaveOptions is unavailable
- **THEN** system saves the file to `{filesDir}/exports/` directory and displays a toast with the file path

### Requirement: Export entry points
The system SHALL provide export entry points on the assessment report page and the profile page.

#### Scenario: Export from report page
- **WHEN** user is on the assessment report page
- **THEN** an export icon button is displayed in the top-right area of the title bar

#### Scenario: Export from profile page
- **WHEN** user is on the profile page
- **THEN** a "数据导出" entry is displayed, tapping it shows a course selection list, then export type and format selection