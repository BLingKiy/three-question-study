## ADDED Requirements

### Requirement: RDB database schema
The system SHALL use HarmonyOS RDB for structured data storage with defined schema for courses, knowledge nodes, edges, and assessments.

#### Scenario: Database initialization
- **WHEN** app starts for the first time
- **THEN** system creates RDB with tables: courses, knowledge_nodes, knowledge_edges, assessments, and creates necessary indexes

### Requirement: Preferences for configuration
The system SHALL use HarmonyOS Preferences for storing user settings and application configuration with fast read/write access.

#### Scenario: Settings storage
- **WHEN** user changes a setting (theme, API key, timeout)
- **THEN** system stores in Preferences with appropriate key, and setting persists across app restarts

### Requirement: File storage for materials
The system SHALL use HarmonyOS file system for storing uploaded materials (PDF, Word, Markdown) and exported files.

#### Scenario: File storage structure
- **WHEN** user uploads a material file
- **THEN** system stores file in `{filesDir}/materials/{courseId}/` directory, maintains reference path in RDB, and organizes by course

### Requirement: Data backup and restore
The system SHALL support exporting all user data (courses, progress, materials) and importing from backup.

#### Scenario: Data export
- **WHEN** user requests data export
- **THEN** system exports RDB data as JSON, packages uploaded files, creates downloadable backup archive

### Requirement: Data integrity
The system SHALL ensure data integrity through transactions when performing multi-step operations like course deletion or regeneration.

#### Scenario: Transactional course deletion
- **WHEN** user deletes a course
- **THEN** system uses transaction to delete course record, all related nodes/edges, all assessments, and file references atomically
