## ADDED Requirements

### Requirement: Course creation triggered by user question
The system SHALL allow users to create a new course by entering a learning question in the search box. When a user submits a question, the system SHALL automatically generate a course package dedicated to that topic.

#### Scenario: Successful course creation
- **WHEN** user enters a learning question (e.g., "如何快速掌握鸿蒙ArkTS开发？") and submits
- **THEN** system creates a new course with unique ID, stores the triggering question, sets status to "active", and displays the course card on the main interface

#### Scenario: Empty question validation
- **WHEN** user submits an empty or whitespace-only question
- **THEN** system displays validation error and does not create a course

### Requirement: Course lifecycle management
The system SHALL manage courses through four states: uncreated, created, active, and completed. Only created or active courses SHALL be displayed on the main interface.

#### Scenario: Course state transitions
- **WHEN** course is first created
- **THEN** status is set to "created" and course card appears on main interface

#### Scenario: Course completion
- **WHEN** all three questions are completed for a course
- **THEN** course status changes to "completed", card becomes grayed out, and course can be archived

### Requirement: Multiple concurrent courses
The system SHALL support multiple active courses simultaneously. Courses SHALL be sorted by most recent usage time on the main interface.

#### Scenario: Multiple course display
- **WHEN** user has created multiple courses
- **THEN** all active courses are displayed as cards, sorted by last access time (most recent first)

### Requirement: Course deletion
The system SHALL allow users to delete a course, which SHALL permanently remove all associated data (knowledge graph, controversies, assessments, uploaded materials).

#### Scenario: Course deletion with confirmation
- **WHEN** user requests to delete a course and confirms the action
- **THEN** system removes the course and all related data from storage, and the course card disappears from the interface

### Requirement: Course archiving
The system SHALL allow users to archive completed courses. Archived courses SHALL be hidden from the main interface but remain accessible in the archive section.

#### Scenario: Archive completed course
- **WHEN** user archives a completed course
- **THEN** course moves to archive, card is removed from main interface, and course data is preserved
