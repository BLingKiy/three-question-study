## ADDED Requirements

### Requirement: Course card action menu
The system SHALL provide an action menu on each course card, triggered by tapping a "more" button (three-dot icon) on the card. The menu SHALL include options for: Archive/Unarchive, Mark Complete/Unmark Complete, and Delete.

#### Scenario: Open action menu
- **WHEN** user taps the "more" button on a course card
- **THEN** system displays a popup menu with available actions for that course

#### Scenario: Archive course from menu
- **WHEN** user selects "归档" from the action menu on an active or completed course
- **THEN** system sets course status to "archived", the card is removed from the active list, and the course appears in the archived section

#### Scenario: Unarchive course from menu
- **WHEN** user selects "取消归档" from the action menu on an archived course
- **THEN** system restores the course status to its previous state (active or completed), the card is removed from the archived section and appears in the active list

#### Scenario: Mark course as complete from menu
- **WHEN** user selects "标记完成" from the action menu on an active course
- **THEN** system sets course status to "completed", the card status label updates to "已完成"

#### Scenario: Unmark course as complete from menu
- **WHEN** user selects "取消完成" from the action menu on a completed course
- **THEN** system sets course status back to "active", the card status label updates to "学习中"

#### Scenario: Delete course from menu with confirmation
- **WHEN** user selects "删除" from the action menu
- **THEN** system displays an AlertDialog asking "确定删除课程「{courseName}」？此操作不可恢复。" with Cancel and Confirm buttons

#### Scenario: Confirm course deletion
- **WHEN** user confirms the deletion dialog
- **THEN** system deletes the course and all associated data, the card disappears from the list

#### Scenario: Cancel course deletion
- **WHEN** user cancels the deletion dialog
- **THEN** no action is taken, the menu closes

#### Scenario: Menu options vary by course status
- **WHEN** course status is "created" or "active"
- **THEN** menu shows: "归档", "删除"

#### Scenario: Menu options for completed course
- **WHEN** course status is "completed"
- **THEN** menu shows: "归档", "取消完成", "删除"

#### Scenario: Menu options for archived course
- **WHEN** course status is "archived"
- **THEN** menu shows: "取消归档", "删除"