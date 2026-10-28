## ADDED Requirements

### Requirement: Composite knowledge base
The system SHALL maintain a composite knowledge base for each course, combining AI-supplemented materials and user-uploaded materials.

#### Scenario: Knowledge base initialization
- **WHEN** a course is created
- **THEN** system initializes an empty knowledge base, triggers AI to fetch relevant materials, and stores materials in the knowledge base

### Requirement: User material upload
The system SHALL allow users to upload learning materials in PDF, Word, or Markdown format. Uploaded materials SHALL be parsed and integrated into the course knowledge base.

#### Scenario: Material upload
- **WHEN** user uploads a PDF/Word/Markdown file
- **THEN** system validates file format, stores file in course directory, extracts text content, and adds to knowledge base

### Requirement: AI material supplementation
The system SHALL automatically fetch relevant learning materials from the web using AI, including academic papers, documentation, and educational resources.

#### Scenario: AI material fetching
- **WHEN** course is created or user requests material refresh
- **THEN** system uses Deepseek API to identify relevant sources, fetches content, and adds to knowledge base with source attribution

### Requirement: Material search and filter
The system SHALL allow users to search and filter materials in the knowledge base by keyword, type, or source.

#### Scenario: Material search
- **WHEN** user enters search keyword
- **THEN** system searches across all materials, returns matching results, and highlights keyword in results
