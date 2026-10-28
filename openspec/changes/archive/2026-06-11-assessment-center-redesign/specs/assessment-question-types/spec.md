## MODIFIED Requirements

### Requirement: Assessment taking
The system SHALL allow users to answer assessment questions one at a time, submit answers, and receive immediate feedback with explanations. For objective questions (singleChoice, multipleChoice, trueFalse), the system SHALL auto-score upon submission and display the correct answer with explanation. For subjective questions, the system SHALL use AI deep evaluation and display the analysis result. After answering, the system SHALL present a follow-up question module.

#### Scenario: Objective question answer submission
- **WHEN** user submits an answer for an objective question
- **THEN** system auto-scores the answer, displays correct/incorrect status, shows the correct answer and explanation text, and presents a "下一题" button and a follow-up question input area

#### Scenario: Subjective question answer submission
- **WHEN** user submits an answer for a subjective question
- **THEN** system calls AI for deep evaluation, displays the evaluation result (score, analysis, suggestion), and presents a "下一题" button and a follow-up question input area

#### Scenario: Answer already submitted
- **WHEN** user has already submitted an answer for the current question
- **THEN** the answer input area is disabled, the result/evaluation is displayed, and the follow-up area is shown

#### Scenario: Navigate to next question
- **WHEN** user taps "下一题" button
- **THEN** system moves to the next assessment question, or displays the result report if all questions are answered

### Requirement: Objective question auto-scoring
The system SHALL automatically score objective questions (singleChoice, multipleChoice, trueFalse) by comparing user answer with correctAnswer. For multipleChoice, all correct options must be selected for full credit. After scoring, the system SHALL display the correct answer and a brief explanation.

#### Scenario: Single choice correct answer
- **WHEN** user selects the option matching correctAnswer
- **THEN** isCorrect is set to true, system displays "回答正确 ✓" and the correct answer

#### Scenario: Single choice incorrect answer
- **WHEN** user selects an option not matching correctAnswer
- **THEN** isCorrect is set to false, system displays "回答错误 ✗", the user's selected answer, and the correct answer

#### Scenario: Multiple choice partial answer
- **WHEN** user selects some but not all correct options
- **THEN** isCorrect is set to false, system displays "回答错误 ✗", the user's selected answers, and the correct answers

#### Scenario: True/false correct answer
- **WHEN** user selects the answer matching correctAnswer
- **THEN** isCorrect is set to true, system displays "回答正确 ✓" and the correct answer

#### Scenario: True/false incorrect answer
- **WHEN** user selects the wrong answer
- **THEN** isCorrect is set to false, system displays "回答错误 ✗" and the correct answer