## ADDED Requirements

### Requirement: Multi-type assessment data model
The system SHALL support four assessment question types: `subjective` (主观题), `singleChoice` (单选题), `multipleChoice` (多选题), and `trueFalse` (判断题). Each assessment record SHALL include `questionType` field indicating its type.

#### Scenario: Question type field presence
- **WHEN** an assessment is created
- **THEN** the assessment record SHALL have `questionType` field with value in `['subjective', 'singleChoice', 'multipleChoice', 'trueFalse']`

### Requirement: Options storage for choice questions
The system SHALL store question options for `singleChoice`, `multipleChoice`, and `trueFalse` question types in an `options` field as a JSON array string. Each option SHALL have `id` and `text` properties.

#### Scenario: Single choice options
- **WHEN** a singleChoice assessment is created
- **THEN** `options` field contains JSON array of option objects with `id` and `text`, and `correctAnswer` field stores the correct option's `id`

#### Scenario: Multiple choice options
- **WHEN** a multipleChoice assessment is created
- **THEN** `options` field contains JSON array of option objects, and `correctAnswer` field stores comma-separated correct option IDs

#### Scenario: True/false options
- **WHEN** a trueFalse assessment is created
- **THEN** `options` field contains two options (正确/错误), and `correctAnswer` field stores `"true"` or `"false"`

#### Scenario: Subjective question has no options
- **WHEN** a subjective assessment is created
- **THEN** `options` field is empty string, `correctAnswer` field is empty string, and `answer` field contains reference answer text

### Requirement: AI prompt generates mixed question types
The system SHALL instruct the AI to generate a mix of question types in Q3 assessment generation, with lower Bloom levels (remember, understand) preferring objective types and higher levels (analyze, evaluate, create) preferring subjective types.

#### Scenario: Mixed type generation
- **WHEN** Question 3 is executed
- **THEN** generated assessments include at least one singleChoice, one multipleChoice, one trueFalse, and one subjective question

### Requirement: Response parser handles multi-type assessments
The system SHALL parse AI response for Q3 to extract question type, options, and correct answer for each assessment item, falling back to `subjective` type when type cannot be determined.

#### Scenario: Parse single choice question
- **WHEN** AI response contains a question with `questionType: "singleChoice"` and `options` array
- **THEN** parser extracts questionType, options, and correctAnswer into ParsedAssessment

#### Scenario: Parse fallback for unknown type
- **WHEN** AI response contains a question without `questionType` field
- **THEN** parser treats it as `subjective` type with empty options and correctAnswer

### Requirement: Choice question answer UI
The system SHALL render different answer input UI based on question type: Radio list for singleChoice, Checkbox list for multipleChoice, two Radio buttons for trueFalse, and TextArea for subjective.

#### Scenario: Single choice answer interaction
- **WHEN** user views a singleChoice question
- **THEN** system displays Radio buttons for each option, user can select exactly one

#### Scenario: Multiple choice answer interaction
- **WHEN** user views a multipleChoice question
- **THEN** system displays Checkbox for each option, user can select zero or more

#### Scenario: True/false answer interaction
- **WHEN** user views a trueFalse question
- **THEN** system displays two Radio buttons labeled "正确" and "错误"

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
