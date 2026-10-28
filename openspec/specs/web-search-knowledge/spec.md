## ADDED Requirements

### Requirement: WebSearch knowledge enrichment
The system SHALL enrich the knowledge base by calling DeepSeek Anthropic API with web_search tool when a course is created, combining web search results with user-uploaded materials.

#### Scenario: Successful WebSearch enrichment
- **WHEN** a course is created with a user question
- **THEN** system calls `https://api.deepseek.com/anthropic/v1/messages` with `web_search` server tool, using the same DeepSeek API Key, parses the response to extract web search results (title + url) and AI-integrated content, and stores them as AI-supplemented knowledge with source links

#### Scenario: WebSearch API failure
- **WHEN** WebSearch API call fails (network error, API error, timeout)
- **THEN** system logs the error and proceeds with course creation using only user-uploaded materials, displaying a warning message "网络搜索失败，仅使用本地资料"

#### Scenario: WebSearch results storage
- **WHEN** WebSearch returns search results and AI-integrated content
- **THEN** system creates KnowledgeNode entries for AI-supplemented concepts and KnowledgeSource entries linking each node to its source URL (title + url from web_search_tool_result)

### Requirement: Knowledge source links display
The system SHALL display source links for AI-supplemented knowledge nodes, allowing users to tap and open the original web page in a browser.

#### Scenario: Source link in node detail panel
- **WHEN** user opens the node detail sheet for an AI-supplemented node
- **THEN** detail sheet shows a "来源" section listing source links (title as clickable text), tapping opens the URL in the system browser

#### Scenario: Source link in materials zone
- **WHEN** AI-supplemented material is displayed in the materials zone
- **THEN** item shows "AI 补充" label with a source link icon, tapping opens the source URL in the system browser

#### Scenario: No source links
- **WHEN** a knowledge node has no associated source links
- **THEN** node detail panel and materials zone do not show the "来源" section