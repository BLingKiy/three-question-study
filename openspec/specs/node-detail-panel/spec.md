## ADDED Requirements

### Requirement: Node detail bottom sheet
The system SHALL display a bottom sheet when a knowledge graph node is tapped, showing the node's label, type, content description, incoming relationships, outgoing relationships, associated materials, and source links.

#### Scenario: Tap on concept node
- **WHEN** user taps a concept node in the knowledge graph
- **THEN** system opens a bottom sheet showing node label, type badge ("概念"), content text, list of incoming edges (from-node label + edge type), list of outgoing edges (to-node label + edge type), and source links (if any)

#### Scenario: Tap on controversy node
- **WHEN** user taps a controversy node in the knowledge graph
- **THEN** system opens a bottom sheet showing node label, type badge ("争议"), content text, and related evidence nodes

#### Scenario: Close detail sheet
- **WHEN** user swipes down or taps outside the bottom sheet
- **THEN** sheet closes and knowledge graph remains visible

### Requirement: Node relationship display
The system SHALL display node relationships as a list in the detail sheet, each showing the related node label, relationship type (supports/opposes/relates), and direction indicator (→ incoming / ← outgoing).

#### Scenario: Display incoming edges
- **WHEN** node has incoming edges from other nodes
- **THEN** detail sheet shows "← 关联" section listing each source node label and relationship type

#### Scenario: Display outgoing edges
- **WHEN** node has outgoing edges to other nodes
- **THEN** detail sheet shows "→ 关联" section listing each target node label and relationship type

#### Scenario: No edges
- **WHEN** node has no incoming or outgoing edges
- **THEN** detail sheet shows "暂无关联关系" placeholder text

### Requirement: Node source links display
The system SHALL display source links in the node detail sheet for AI-supplemented nodes, allowing users to tap and open the original web page.

#### Scenario: Display source links
- **WHEN** node has associated KnowledgeSource entries
- **THEN** detail sheet shows "来源" section listing each source as clickable text (title), tapping opens the URL in the system browser

#### Scenario: No source links
- **WHEN** node has no associated KnowledgeSource entries
- **THEN** detail sheet does not show the "来源" section