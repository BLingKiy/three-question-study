## MODIFIED Requirements

### Requirement: Course deletion cascades to archives
The system SHALL delete all answer_archives and follow_up_archives records for a course when the course is deleted.

#### Scenario: Delete archives on course deletion
- **WHEN** a course is deleted
- **THEN** system deletes all follow_up_archives records where the linked answer_archive's original_course_id matches, then deletes all answer_archives records where original_course_id matches the deleted course id