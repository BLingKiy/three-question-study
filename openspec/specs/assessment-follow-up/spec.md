## ADDED Requirements

### Requirement: Assessment follow-up question
The system SHALL allow users to ask follow-up questions after answering any assessment question (both objective and subjective). The follow-up area SHALL appear below the answer result, with a text input and "追问" button. AI SHALL respond based on the original question, user's answer, and evaluation result context.

#### Scenario: Follow-up area appears after answer
- **WHEN** user submits an answer (objective or subjective) and the result is displayed
- **THEN** system shows a follow-up section below the result with a text input area and "追问" button

#### Scenario: User submits follow-up question
- **WHEN** user types a follow-up question and taps "追问"
- **THEN** system saves the user's follow-up message, calls AI to generate a reply based on the question context (original assessment question, user answer, evaluation result, and follow-up history), saves the AI reply, and displays both in the follow-up conversation thread

#### Scenario: AI follow-up reply context
- **WHEN** AI generates a follow-up reply
- **THEN** system includes in the prompt: the original assessment question, the correct answer/reference answer, the user's answer, the evaluation result (correct/incorrect for objective, score and analysis for subjective), and any previous follow-up messages

#### Scenario: Follow-up conversation display
- **WHEN** follow-up messages exist for an assessment
- **THEN** system displays them as a conversation thread below the answer result, with user messages right-aligned and AI messages left-aligned, using the same Markdown rendering as discussion zone

#### Scenario: Skip follow-up
- **WHEN** user does not want to ask follow-up questions
- **THEN** user can tap "下一题" button to proceed to the next question without asking follow-up

#### Scenario: Follow-up loading state
- **WHEN** AI is generating a follow-up reply
- **THEN** system shows a loading indicator in the follow-up area and disables the "追问" button to prevent duplicate submissions

#### Scenario: Follow-up generation failure
- **WHEN** AI follow-up reply generation fails
- **THEN** system displays error toast "追问回复生成失败" and the user's follow-up question is still displayed, user can retry

### Requirement: Follow-up data persistence
The system SHALL persist follow-up conversation data in RDB with an `assessment_follow_ups` table.

#### Scenario: Follow-up data schema
- **WHEN** the app initializes the database
- **THEN** system creates `assessment_follow_ups` table with columns: id (TEXT PRIMARY KEY), assessment_id (TEXT NOT NULL), role (TEXT NOT NULL, 'user' or 'assistant'), content (TEXT NOT NULL), created_at (INTEGER NOT NULL), with foreign key on assessment_id referencing assessments(id) ON DELETE CASCADE

#### Scenario: Save follow-up message
- **WHEN** a user or AI follow-up message is created
- **THEN** system inserts a record into assessment_follow_ups table with the assessment_id, role, content, and timestamp

#### Scenario: Load follow-up history
- **WHEN** user views an answered assessment question
- **THEN** system queries assessment_follow_ups by assessment_id and displays all follow-up messages in chronological order

#### Scenario: Delete follow-ups on course deletion
- **WHEN** a course is deleted
- **THEN** system cascades deletion to assessments, which cascades to assessment_follow_ups via foreign key