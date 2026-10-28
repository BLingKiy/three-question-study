## ADDED Requirements

### Requirement: Deepseek API integration
The system SHALL integrate with Deepseek API for AI capabilities. The integration SHALL support chat completions with custom prompts for each of the three questions.

#### Scenario: API call structure
- **WHEN** system calls Deepseek API
- **THEN** request includes Authorization header with API key, specifies model as 'deepseek-chat', and includes properly formatted messages array

### Requirement: Prompt engineering
The system SHALL use specialized prompts for each question type to generate appropriate outputs. Prompts SHALL be designed to produce structured, parseable responses.

#### Scenario: Q1 prompt design
- **WHEN** executing Question 1
- **THEN** system constructs prompt requesting knowledge graph structure, specifies JSON output format, and includes relevant knowledge base content

### Requirement: API error handling
The system SHALL handle API errors gracefully, including network failures, timeouts, rate limits, and malformed responses.

#### Scenario: Network error
- **WHEN** API call fails due to network issue
- **THEN** system displays user-friendly error message, offers retry option, and does not crash

#### Scenario: Timeout handling
- **WHEN** API call exceeds 30 second timeout
- **THEN** system cancels the request, displays timeout message, and allows retry

### Requirement: API key management
The system SHALL securely store the Deepseek API key in Preferences and allow users to configure/update the key.

#### Scenario: API key configuration
- **WHEN** user enters API key in settings
- **THEN** system validates key format, stores securely in Preferences, and uses for subsequent API calls
