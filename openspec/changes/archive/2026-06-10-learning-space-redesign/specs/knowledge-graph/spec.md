## MODIFIED Requirements

### Requirement: Question 1 - Mental model extraction
The system SHALL extract the core mental model from the composite knowledge base and generate a dynamic knowledge graph. The graph SHALL be rendered using ArkWeb with vis-network library, displayed at the top of the learning space with a fixed height. Nodes SHALL be tappable to trigger detail display via JavaScript-to-ArkTS bridge.

#### Scenario: Successful mental model extraction
- **WHEN** Question 1 is executed for a course
- **THEN** system calls Deepseek API with appropriate prompt, parses the response, generates knowledge graph with nodes and edges, and renders the graph in the top section using ArkWeb + vis-network

#### Scenario: Q1 regeneration
- **WHEN** user clicks "重新生成知识图谱" button
- **THEN** system deletes the existing knowledge graph, re-executes Question 1 with current knowledge base, and re-renders the graph via `runJavaScript()` injecting new data

#### Scenario: Node tap interaction via JS bridge
- **WHEN** user taps a node in the vis-network graph
- **THEN** JS `network.on('click')` callback fires, calls `graphBridge.onNodeClick(nodeId)` via javaScriptProxy, ArkTS side receives nodeId, loads node details, and opens the node detail bottom sheet

#### Scenario: Data injection into Web component
- **WHEN** learning space page loads with knowledge graph data
- **THEN** system calls `webController.runJavaScript()` to inject nodes and edges JSON into the vis-network instance

#### Scenario: Empty knowledge graph
- **WHEN** no knowledge graph data exists for the course
- **THEN** top section shows placeholder text "暂无知识图谱数据" with a "重新生成" button (Web component is hidden)
