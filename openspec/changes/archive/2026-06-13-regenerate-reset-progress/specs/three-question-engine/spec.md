## MODIFIED Requirements

### Requirement: Regenerate resets learning progress
The system SHALL reset the learning progress for a course when the user triggers regeneration. All records in the learning_progress table for that course SHALL be deleted, and the progress SHALL be recalculated from scratch.

#### Scenario: Progress reset on regenerate
- **WHEN** user taps "重新生成" button and regeneration completes successfully
- **THEN** system deletes all learning_progress records for the course, resets checked states for all items, and recalculates the course progress from zero

#### Scenario: Progress display after regenerate
- **WHEN** regeneration completes and user views the learning space
- **THEN** all progress checkboxes are unchecked and the progress bar shows the recalculated progress (excluding assessment portion since assessments are cleared)

### Requirement: Regenerate archives answered assessments
The system SHALL archive all answered assessments (where userAnswer is not empty) and their follow-up records before clearing them during regeneration.

#### Scenario: Archive answered assessments on regenerate
- **WHEN** user triggers regeneration for a course
- **THEN** system queries all assessments for the course where userAnswer is not empty, creates answer_archives records with original_course_id, original_course_name, and archived_at, and creates follow_up_archives records for each assessment's follow-ups

#### Scenario: Skip unanswered assessments
- **WHEN** system archives assessments during regeneration
- **THEN** assessments where userAnswer is empty are not archived (they are simply deleted)

#### Scenario: Archive before delete
- **WHEN** system processes regeneration
- **THEN** archiving happens before deletion of assessments, ensuring no data loss

### Requirement: Regenerate clears assessments and report
The system SHALL delete all assessments, follow-ups, and assessment reports for a course during regeneration, and reset assessmentGenerating to false.

#### Scenario: Delete assessments on regenerate
- **WHEN** regeneration completes successfully
- **THEN** system deletes all assessment_follow_ups records for the course's assessments, deletes all assessments for the course, deletes the assessment_reports record for the course, and sets assessmentGenerating to false

#### Scenario: Assessment center after regenerate
- **WHEN** user navigates to assessment center after regeneration
- **THEN** the course group shows "暂无测评题目" with a "生成测评" button, as if the course was newly created