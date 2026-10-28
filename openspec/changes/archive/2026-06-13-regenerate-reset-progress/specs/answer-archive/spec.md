## ADDED Requirements

### Requirement: Answer archive data persistence
The system SHALL persist archived answer records in RDB with an `answer_archives` table and a `follow_up_archives` table.

#### Scenario: Answer archives table schema
- **WHEN** the app initializes the database
- **THEN** system creates `answer_archives` table with columns: id (TEXT PRIMARY KEY), original_course_id (TEXT NOT NULL), original_course_name (TEXT NOT NULL), bloom_level (TEXT NOT NULL), question_type (TEXT NOT NULL), question (TEXT NOT NULL), answer (TEXT), options (TEXT), correct_answer (TEXT), user_answer (TEXT), is_correct (INTEGER), created_at (INTEGER NOT NULL), archived_at (INTEGER NOT NULL)

#### Scenario: Follow-up archives table schema
- **WHEN** the app initializes the database
- **THEN** system creates `follow_up_archives` table with columns: id (TEXT PRIMARY KEY), archive_assessment_id (TEXT NOT NULL), role (TEXT NOT NULL), content (TEXT NOT NULL), created_at (INTEGER NOT NULL), FOREIGN KEY (archive_assessment_id) REFERENCES answer_archives(id) ON DELETE CASCADE

#### Scenario: Save archived assessment
- **WHEN** system archives an answered assessment
- **THEN** system inserts a record into answer_archives table with the assessment data plus original_course_id, original_course_name, and archived_at

#### Scenario: Save archived follow-ups
- **WHEN** system archives follow-up records for an assessment
- **THEN** system inserts records into follow_up_archives table with the follow-up data linked to the archived assessment

#### Scenario: Delete archives on course deletion
- **WHEN** a course is deleted
- **THEN** system deletes all answer_archives and follow_up_archives records where original_course_id matches the deleted course id

### Requirement: Answer archive display
The system SHALL display archived answer records in the ProfilePage under an "答题档案" section, grouped by original course name.

#### Scenario: Archive section display
- **WHEN** user views the ProfilePage
- **THEN** an "答题档案" section is displayed showing archived answer records grouped by original course name

#### Scenario: Course group in archive
- **WHEN** archived records exist for a course
- **THEN** system displays the course name as a group header with the count of archived questions

#### Scenario: No archived records
- **WHEN** no archived answer records exist
- **THEN** system displays "暂无答题档案" placeholder text

#### Scenario: Question card in archive
- **WHEN** user views an archived question
- **THEN** system displays the question text, question type tag, and correct/incorrect status indicator

#### Scenario: Expand question detail
- **WHEN** user taps an archived question card
- **THEN** system expands to show user answer, correct answer, and any follow-up conversation records

#### Scenario: Follow-up conversation in archive
- **WHEN** an archived question has follow-up records
- **THEN** system displays the follow-up conversation with role indicators (user/assistant) and content text