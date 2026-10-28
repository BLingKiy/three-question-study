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

### Requirement: Course deletion
The system SHALL allow users to delete a course, which SHALL permanently remove all associated data (knowledge graph, controversies, assessments, uploaded materials).

#### Scenario: Course deletion with confirmation
- **WHEN** user requests to delete a course and confirms the action
- **THEN** system removes the course and all related data from storage, and the course card disappears from the interface

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

### Requirement: Course deletion cascades to archives
The system SHALL delete all answer_archives and follow_up_archives records for a course when the course is deleted.

#### Scenario: Delete archives on course deletion
- **WHEN** a course is deleted
- **THEN** system deletes all follow_up_archives records where the linked answer_archive's original_course_id matches, then deletes all answer_archives records where original_course_id matches the deleted course id

### Requirement: Dark mode switching
The system SHALL allow users to switch between three color modes: follow system (跟随系统), light (浅色), and dark (深色). The selection SHALL be persisted in PreferencesService and applied globally via `ApplicationContext.setColorMode()`.

#### Scenario: Select dark mode
- **WHEN** user selects "深色" in the color mode sheet
- **THEN** system calls `setColorMode(COLOR_MODE_DARK)`, persists the mode value 0 to PreferencesService, and all pages immediately render with dark color scheme

#### Scenario: Select light mode
- **WHEN** user selects "浅色" in the color mode sheet
- **THEN** system calls `setColorMode(COLOR_MODE_LIGHT)`, persists the mode value 1 to PreferencesService, and all pages immediately render with light color scheme

#### Scenario: Select follow system
- **WHEN** user selects "跟随系统" in the color mode sheet
- **THEN** system calls `setColorMode(COLOR_MODE_NOT_SET)`, persists the mode value -1 to PreferencesService, and the app follows the system color mode

#### Scenario: Restore color mode on app launch
- **WHEN** the app starts (EntryAbility.onCreate)
- **THEN** system reads the saved color mode from PreferencesService and calls `setColorMode()` with the saved value

#### Scenario: Restore color mode on ProfilePage load
- **WHEN** user navigates to ProfilePage
- **THEN** system reads the saved color mode from PreferencesService, updates the colorModeIndex state, and calls `setColorMode()` with the saved value

### Requirement: Semantic color resources for dark mode
The system SHALL define all UI colors as semantic color resources in both base and dark resource directories, so that switching color mode automatically updates all colors.

#### Scenario: Color resources in base directory
- **WHEN** the app is in light mode
- **THEN** all `$r('app.color.xxx')` references resolve to light-mode colors from the base resource directory

#### Scenario: Color resources in dark directory
- **WHEN** the app is in dark mode
- **THEN** all `$r('app.color.xxx')` references resolve to dark-mode colors from the dark resource directory

#### Scenario: No hardcoded colors in page files
- **WHEN** a page renders in dark mode
- **THEN** all background colors, text colors, and fill colors that differ between light and dark mode use `$r('app.color.xxx')` resource references instead of hardcoded hex values

### Requirement: Course deletion confirmation
The system SHALL require user confirmation before deleting a course, as deletion is irreversible and removes all associated data.

#### Scenario: Delete from active list
- **WHEN** user selects "删除" from a course card's action menu
- **THEN** system displays AlertDialog with message "确定删除课程「{courseName}」？此操作不可恢复。" with "取消" and "确定" buttons

#### Scenario: Delete from archived section
- **WHEN** user selects "删除" from an archived course card's action menu
- **THEN** system displays the same confirmation dialog, and on confirm, deletes the course
