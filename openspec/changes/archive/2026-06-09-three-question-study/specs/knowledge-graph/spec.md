## ADDED Requirements

### Requirement: Knowledge graph data structure
The system SHALL represent knowledge graphs using nodes (concepts) and edges (relationships). Each node SHALL have unique ID, label, type, and position. Each edge SHALL define source node, target node, and relationship type.

#### Scenario: Graph data model
- **WHEN** knowledge graph is generated
- **THEN** each node contains id, label, type (concept/controversy/evidence), position (x,y coordinates), and each edge contains fromNodeId, toNodeId, type (supports/opposes/relates), weight

### Requirement: Canvas-based graph visualization
The system SHALL render the knowledge graph using HarmonyOS Canvas component with force-directed layout algorithm. The graph SHALL support pan, zoom, and node selection interactions.

#### Scenario: Graph rendering
- **WHEN** knowledge graph data is available
- **THEN** system renders nodes as circles with labels, draws edges as lines with arrows, applies force-directed layout for positioning, and renders within 2 seconds

#### Scenario: Node interaction
- **WHEN** user clicks on a node
- **THEN** system highlights the node, displays node details in a panel, and shows connected edges

#### Scenario: Graph pan and zoom
- **WHEN** user performs pinch gesture or drag gesture on the graph
- **THEN** system zooms in/out or pans the viewport accordingly

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
