## ADDED Requirements

### Requirement: Knowledge graph data structure
The system SHALL represent knowledge graphs using nodes (concepts) and edges (relationships). Each node SHALL have unique ID, label, type, and position. Each edge SHALL define source node, target node, and relationship type.

#### Scenario: Graph data model
- **WHEN** knowledge graph is generated
- **THEN** each node contains id, label, type (concept/controversy/evidence), position (x,y coordinates), and each edge contains fromNodeId, toNodeId, type (supports/opposes/relates), weight

### Requirement: ArkWeb-based graph visualization
The system SHALL render the knowledge graph using ArkWeb with vis-network library, displayed at the top of the learning space with a fixed height. Nodes SHALL be tappable to trigger detail display via JavaScript-to-ArkTS bridge.

#### Scenario: Graph rendering
- **WHEN** knowledge graph data is available
- **THEN** system renders the graph in the top section using ArkWeb + vis-network, with force-directed layout, node colors by type, and edge arrows

#### Scenario: Node tap interaction via JS bridge
- **WHEN** user taps a node in the vis-network graph
- **THEN** JS `network.on('click')` callback fires, calls `graphBridge.onNodeClick(nodeId)` via javaScriptProxy, ArkTS side receives nodeId, loads node details, and opens the node detail bottom sheet

#### Scenario: Data injection into Web component
- **WHEN** learning space page loads with knowledge graph data
- **THEN** system calls `webController.runJavaScript()` to inject nodes and edges JSON into the vis-network instance

#### Scenario: Graph pan and zoom
- **WHEN** user performs pinch gesture or drag gesture on the graph
- **THEN** system zooms in/out or pans the viewport accordingly (handled by vis-network)

#### Scenario: Q1 regeneration
- **WHEN** user clicks "重新生成知识图谱" button
- **THEN** system deletes the existing knowledge graph, re-executes Question 1 with current knowledge base, and re-renders the graph via `runJavaScript()` injecting new data

#### Scenario: Empty knowledge graph
- **WHEN** no knowledge graph data exists for the course
- **THEN** top section shows placeholder text "暂无知识图谱数据" with a "重新生成" button (Web component is hidden)

### Requirement: Graph performance optimization
The system SHALL optimize graph rendering for performance. When node count exceeds 100, the system SHALL provide aggregation or filtering options.

#### Scenario: Large graph handling
- **WHEN** knowledge graph contains more than 100 nodes
- **THEN** system displays warning message, offers to show only key concepts, or provides filtering by node type

### Requirement: Graph persistence
The system SHALL persist knowledge graph data in RDB, including node positions for consistent display across sessions.

#### Scenario: Graph save and restore
- **WHEN** user exits and re-enters a course
- **THEN** system loads the knowledge graph from RDB with saved node positions and displays the same layout
