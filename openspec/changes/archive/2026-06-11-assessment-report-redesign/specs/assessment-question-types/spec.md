## MODIFIED Requirements

### Requirement: Assessment taking
The system SHALL allow users to answer assessment questions one at a time, submit answers, and receive immediate feedback with explanations. For objective questions (singleChoice, multipleChoice, trueFalse), the system SHALL auto-score upon submission and display the correct answer with explanation. For subjective questions, the system SHALL use AI deep evaluation and display the analysis result. After answering, the system SHALL present a follow-up question module and navigation buttons (上一题/下一题). The "查看结果" button on the last question is removed; instead, a "查看评测报告" button appears on every answered question.

#### Scenario: Objective question answer submission
- **WHEN** user submits an answer for an objective question
- **THEN** system auto-scores the answer, displays correct/incorrect status, shows the correct answer and explanation text, and presents "上一题"/"下一题" navigation buttons, a follow-up question input area, and a "查看评测报告" button

#### Scenario: Subjective question answer submission
- **WHEN** user submits an answer for a subjective question
- **THEN** system calls AI for deep evaluation, displays the evaluation result (score, analysis, suggestion), and presents "上一题"/"下一题" navigation buttons, a follow-up question input area, and a "查看评测报告" button

#### Scenario: Answer already submitted
- **WHEN** user has already submitted an answer for the current question
- **THEN** the answer input area is disabled, the result/evaluation is displayed, and the follow-up area, navigation buttons, and "查看评测报告" button are shown

#### Scenario: Navigate to previous question
- **WHEN** user taps "上一题" button and current question is not the first
- **THEN** system moves to the previous assessment question

#### Scenario: Navigate to next question
- **WHEN** user taps "下一题" button and current question is not the last
- **THEN** system moves to the next assessment question

#### Scenario: Previous button disabled on first question
- **WHEN** current question is the first question
- **THEN** "上一题" button is disabled

#### Scenario: Next button disabled on last question
- **WHEN** current question is the last question
- **THEN** "下一题" button is disabled