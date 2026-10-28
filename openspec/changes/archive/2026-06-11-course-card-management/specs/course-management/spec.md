## MODIFIED Requirements

### Requirement: Multiple concurrent courses
The system SHALL support multiple active courses simultaneously. Courses SHALL be sorted by the user-selected sorting method on the main interface. Default sorting SHALL be by most recent update time. Users SHALL be able to switch between three sorting methods: by update time (newest first), by creation time (newest first), and by learning progress (highest first).

#### Scenario: Multiple course display
- **WHEN** user has created multiple courses
- **THEN** all non-archived courses are displayed as cards, sorted by the selected sorting method

#### Scenario: Switch sorting method
- **WHEN** user taps the sort icon next to the search bar
- **THEN** system displays a popup menu with three options: "按最近使用时间", "按创建时间", "按学习进度"

#### Scenario: Sort by update time
- **WHEN** user selects "按最近使用时间"
- **THEN** courses are sorted by updated_at descending (most recently updated first)

#### Scenario: Sort by creation time
- **WHEN** user selects "按创建时间"
- **THEN** courses are sorted by created_at descending (newest first)

#### Scenario: Sort by learning progress
- **WHEN** user selects "按学习进度"
- **THEN** courses are sorted by progress percentage descending (highest progress first)

### Requirement: Course archiving
The system SHALL allow users to archive courses. Archived courses SHALL be hidden from the main course list and displayed in a collapsible "已归档课程" section at the bottom of the page.

#### Scenario: Archive course
- **WHEN** user archives a course via the action menu
- **THEN** course card is removed from the main list and appears in the "已归档课程" section

#### Scenario: Archived courses section collapsed by default
- **WHEN** user opens the main page
- **THEN** the "已归档课程(N)" section is displayed at the bottom, collapsed by default

#### Scenario: Expand archived courses section
- **WHEN** user taps the "已归档课程(N)" header
- **THEN** the section expands to show all archived course cards with grayed-out visual style

#### Scenario: No archived courses
- **WHEN** there are no archived courses
- **THEN** the "已归档课程" section is not displayed

#### Scenario: Archived course card visual style
- **WHEN** an archived course card is displayed
- **THEN** the card has reduced opacity (0.6) and the status label shows "已归档" in gray

## ADDED Requirements

### Requirement: Course deletion confirmation
The system SHALL require user confirmation before deleting a course, as deletion is irreversible and removes all associated data.

#### Scenario: Delete from active list
- **WHEN** user selects "删除" from a course card's action menu
- **THEN** system displays AlertDialog with message "确定删除课程「{courseName}」？此操作不可恢复。" with "取消" and "确定" buttons

#### Scenario: Delete from archived section
- **WHEN** user selects "删除" from an archived course card's action menu
- **THEN** system displays the same confirmation dialog, and on confirm, deletes the course