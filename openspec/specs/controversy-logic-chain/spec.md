## ADDED Requirements

### Requirement: Controversy logic chain graph
The system SHALL display a logic chain graph for each controversy point, visualizing the reasoning chain from controversy → evidence → conclusion using vis-network.

#### Scenario: Display logic chain graph
- **WHEN** user expands the logic chain section of a controversy card
- **THEN** system renders a small vis-network graph showing: a central controversy node, evidence nodes branching from it (left evidence in blue, right evidence in orange), and conclusion nodes derived from synthesis

#### Scenario: Logic chain data construction
- **WHEN** system constructs the logic chain for a controversy
- **THEN** system builds nodes from: controversy topic (center), leftView.evidence items (left branch, blue), rightView.evidence items (right branch, orange), synthesis (bottom, green); edges connect: controversy→each evidence, each evidence→conclusion

#### Scenario: Logic chain node tap
- **WHEN** user taps a node in the logic chain graph
- **THEN** system displays the node content in a tooltip or highlights the corresponding section in the controversy card

#### Scenario: No evidence data
- **WHEN** a controversy has no evidence items
- **THEN** logic chain graph shows only the controversy node with no branches, and displays placeholder text "暂无证据链路"