## MODIFIED Requirements

### Requirement: Discussion thread per controversy
The system SHALL provide a discussion thread for each controversy point, where the user can post opinions and AI responds with analysis and counterpoints. AI messages SHALL be rendered using Markdown format.

#### Scenario: Enter discussion thread
- **WHEN** user taps the "讨论" button on a controversy card
- **THEN** system navigates to the discussion thread page showing the controversy topic and existing messages (user messages and AI replies alternating)

#### Scenario: User posts opinion
- **WHEN** user types a message in the input box and taps "发送"
- **THEN** system saves the user message as plain text, calls DeepseekService.chatCompletion to generate an AI reply in Markdown, saves the AI reply, and displays both in the message list

#### Scenario: AI message Markdown rendering
- **WHEN** AI reply contains Markdown formatting (bold, italic, headings, lists, code)
- **THEN** system converts Markdown to HTML and renders using RichText component, displaying formatted text instead of raw Markdown syntax

#### Scenario: User message plain text rendering
- **WHEN** user message is displayed
- **THEN** system renders it as plain text using Text component, no Markdown processing

### Requirement: Discussion summary generation
The system SHALL allow the user to request an AI-generated summary of the discussion thread. The summary SHALL be rendered using Markdown format.

#### Scenario: Generate discussion summary
- **WHEN** user taps "生成总结" button in the discussion thread
- **THEN** system calls DeepseekService.chatCompletion with all discussion messages as context, generates a structured Markdown summary, saves it to DiscussionSummary table, and renders it using RichText with Markdown formatting

#### Scenario: Summary already exists
- **WHEN** a discussion summary already exists and user taps "重新总结"
- **THEN** system regenerates the summary, replacing the previous one

#### Scenario: Summary generation failure
- **WHEN** summary generation fails
- **THEN** system shows error toast "总结生成失败" and retains any previous summary