## MODIFIED Requirements

### Requirement: Question 2 - Controversy analysis
The system SHALL analyze multiple sources in the knowledge base to identify academic controversies, disputes, and conflicting viewpoints. The controversy area SHALL be displayed in the middle of the learning space using a left-right split view for each controversy, with Swiper support for switching between different controversy topics. Each controversy SHALL have a logic chain graph and a discussion thread.

#### Scenario: Successful controversy analysis
- **WHEN** Question 2 is executed after Question 1 completes
- **THEN** system generates a list of controversies, each displayed in a left-right split card: left column shows position A with arguments and evidence, right column shows position B with arguments and evidence, bottom shows synthesis and logic chain graph

#### Scenario: Switch controversy topic
- **WHEN** user swipes left/right or taps navigation indicators in the controversy area
- **THEN** system switches to the next/previous controversy topic with smooth transition

#### Scenario: Q2 regeneration
- **WHEN** user clicks "重新生成" button in the controversy section
- **THEN** system deletes existing controversies, re-executes Question 2, and displays updated controversy list

#### Scenario: No controversies
- **WHEN** no controversy data exists for the course
- **THEN** middle section shows placeholder text "暂无争议分析数据" with a "重新生成" button

#### Scenario: Open discussion thread
- **WHEN** user taps "讨论" button on a controversy card
- **THEN** system navigates to the discussion thread for that controversy

#### Scenario: View logic chain graph
- **WHEN** user expands the logic chain section of a controversy card
- **THEN** system renders a vis-network graph showing controversy → evidence → conclusion chain

## ADDED Requirements

### Requirement: Learning space three-zone layout with discussion zone
The system SHALL display the learning space as a vertically scrollable page with three zones plus a discussion zone: top zone for knowledge graph (心智模型区), middle zone for controversy analysis (争议点区), bottom zone for materials (资料区), and discussion zone (协作讨论区). Each zone SHALL have a section header and be visually separated.

#### Scenario: Three-zone display
- **WHEN** user enters the learning space page
- **THEN** page shows zones vertically: "心智模型" section with knowledge graph canvas, "争议分析" section with controversy split-view, "补充资料" section with material list, "协作讨论" section with discussion thread list

#### Scenario: Zone scrolling
- **WHEN** page content exceeds screen height
- **THEN** user can scroll vertically to see all zones

### Requirement: Materials zone with source distinction and links
The system SHALL display materials in the bottom zone with source labels distinguishing "AI 补充" (knowledge graph content with web source links) from "用户上传" (user-uploaded files). The zone SHALL include an upload entry button.

#### Scenario: AI supplemented materials display
- **WHEN** knowledge graph has concept/evidence nodes with content
- **THEN** materials zone shows items with "AI 补充" source label, displaying node label as title, content as preview, and source link icon (tapping opens URL in browser)

#### Scenario: User uploaded materials display
- **WHEN** user has uploaded files for the course
- **THEN** materials zone shows items with "用户上传" source label, displaying file name and file type icon

#### Scenario: Upload entry
- **WHEN** user taps the upload button in materials zone
- **THEN** system opens file picker for selecting PDF/Word/Markdown files to upload

#### Scenario: Empty materials
- **WHEN** no materials exist for the course
- **THEN** materials zone shows placeholder text "暂无补充资料" with upload button