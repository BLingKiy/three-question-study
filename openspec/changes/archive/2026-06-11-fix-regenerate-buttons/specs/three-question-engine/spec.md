## MODIFIED Requirements

### Requirement: Learning space regeneration
The system SHALL provide "重新生成" buttons in the learning space page for knowledge graph (Q1) and controversy analysis (Q2), allowing users to regenerate even if previous execution succeeded. Q1 regeneration SHALL preserve controversy data (controversy-type nodes). Q2 regeneration SHALL only delete controversy-type nodes. During regeneration, the corresponding section SHALL display a loading overlay.

#### Scenario: Regenerate knowledge graph
- **WHEN** user clicks "重新生成" button in knowledge graph section
- **THEN** system shows confirmation, deletes existing knowledge graph nodes (excluding controversy-type nodes) and all edges, re-executes Q1, and refreshes the display

#### Scenario: Regenerate controversy analysis
- **WHEN** user clicks "重新生成" button in controversy section
- **THEN** system shows confirmation, deletes existing controversy nodes, re-executes Q2, and refreshes the display

#### Scenario: Regeneration in progress
- **WHEN** regeneration is in progress
- **THEN** regenerate button is disabled and shows loading state, the corresponding section displays a semi-transparent loading overlay, preventing duplicate execution

#### Scenario: Regeneration error - API key not configured
- **WHEN** regeneration fails with "API密钥未配置" error
- **THEN** system displays error message "请先在「我的」页面配置 API 密钥" with a dismiss button

#### Scenario: Regeneration error - other failure
- **WHEN** regeneration fails with any other error
- **THEN** system displays error message "重新生成失败：{error message}" with a dismiss button

#### Scenario: Q1 regeneration preserves Q2 data
- **WHEN** user regenerates knowledge graph (Q1) and controversy data exists
- **THEN** system deletes only non-controversy nodes and all edges, controversy nodes remain intact, after Q1 completes the controversy section still shows existing controversy data

## ADDED Requirements

### Requirement: Learning space generation state detection
The system SHALL detect the course generation state when entering the learning space page, and display loading animations for sections that are still being generated.

#### Scenario: Q1 not yet generated
- **WHEN** user enters learning space and `mentalModelGenerated` is false
- **THEN** mental model section displays a skeleton loading animation with LoadingIndicator and text "正在生成心智模型..." instead of the empty state

#### Scenario: Q2 not yet generated
- **WHEN** user enters learning space and `controversyGenerated` is false
- **THEN** controversy section displays a skeleton loading animation with LoadingIndicator and text "正在生成争议分析..." instead of the empty state

#### Scenario: Both sections not yet generated
- **WHEN** user enters learning space and both Q1 and Q2 are not generated
- **THEN** both sections show their respective loading animations simultaneously

#### Scenario: All sections already generated
- **WHEN** user enters learning space and both Q1 and Q2 are already generated
- **THEN** page displays normally with data, no loading animations

### Requirement: Learning space generation state polling
The system SHALL poll the course generation state at 2-second intervals when any section is still being generated, and automatically refresh the corresponding section when generation completes.

#### Scenario: Q1 completes during polling
- **WHEN** polling detects `mentalModelGenerated` changed from false to true
- **THEN** system loads and displays the knowledge graph data, replaces the loading animation with the actual graph, and stops polling if Q2 is also complete

#### Scenario: Q2 completes during polling
- **WHEN** polling detects `controversyGenerated` changed from false to true
- **THEN** system loads and displays the controversy data, replaces the loading animation with the actual cards, and stops polling if Q1 is also complete

#### Scenario: Both sections complete
- **WHEN** polling detects both `mentalModelGenerated` and `controversyGenerated` are true
- **THEN** system stops polling, loads all data, and displays the full page

#### Scenario: Page cleanup
- **WHEN** user navigates away from the learning space page
- **THEN** system clears the polling timer to prevent memory leaks
