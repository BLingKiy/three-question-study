## 1. Project Setup & Infrastructure

- [x] 1.1 Install @ohos/axios dependency via oh-package.json5
- [x] 1.2 Configure module.json5 with required permissions (INTERNET, READ_USER_STORAGE, WRITE_USER_STORAGE)
- [x] 1.3 Create project folder structure (pages, components, services, model, utils)
- [x] 1.4 Set up global app theme configuration (tech-blue color scheme)

## 2. Data Layer Implementation

- [x] 2.1 Create RDB service with database initialization logic
- [x] 2.2 Define RDB schema: courses table with all required fields
- [x] 2.3 Define RDB schema: knowledge_nodes and knowledge_edges tables
- [x] 2.4 Define RDB schema: assessments table with Bloom level tracking
- [x] 2.5 Implement Preferences service for user settings storage
- [x] 2.6 Implement File service for material storage and retrieval
- [x] 2.7 Create data models: Course, KnowledgeNode, KnowledgeEdge, Assessment interfaces

## 3. AI Integration Layer

- [x] 3.1 Create DeepseekService class with axios configuration
- [x] 3.2 Implement API key management (store in Preferences, validate format)
- [x] 3.3 Implement chat completion method with error handling
- [x] 3.4 Create prompt templates for Question 1 (mental model extraction)
- [x] 3.5 Create prompt templates for Question 2 (controversy analysis)
- [x] 3.6 Create prompt templates for Question 3 (assessment generation)
- [x] 3.7 Implement response parsing for knowledge graph JSON
- [x] 3.8 Implement response parsing for controversy list
- [x] 3.9 Implement response parsing for assessment questions
- [x] 3.10 Add retry logic and timeout handling (30s timeout, 3 retries)

## 4. Business Logic - Core Services

- [x] 4.1 Create CourseManager service with CRUD operations
- [x] 4.2 Implement course creation triggered by user question
- [x] 4.3 Implement course lifecycle state transitions (created → active → completed)
- [x] 4.4 Implement course archiving and deletion logic
- [x] 4.5 Create ThreeQuestionEngine service with state management
- [x] 4.6 Implement Question 1 execution flow (call AI, parse, save graph)
- [x] 4.7 Implement Question 2 execution flow (call AI, parse, save controversies)
- [x] 4.8 Implement Question 3 execution flow (call AI, parse, save assessments)
- [x] 4.9 Implement regeneration logic for Q1 and Q2 (delete old, generate new)
- [x] 4.10 Create KnowledgeBaseManager for composite knowledge base
- [x] 4.11 Implement material upload and parsing (PDF, Word, Markdown text extraction)
- [x] 4.12 Create AssessmentManager for assessment operations

## 5. UI Components - Reusable

- [x] 5.1 Create CourseCard component with progress display
- [x] 5.2 Create KnowledgeGraphCanvas component with Canvas rendering
- [x] 5.3 Implement force-directed layout algorithm for graph positioning
- [x] 5.4 Add graph interaction handlers (click, drag, pinch zoom)
- [x] 5.5 Create RadarChart component for ability dimensions visualization
- [x] 5.6 Create ProgressBar component with percentage display
- [x] 5.7 Create LoadingIndicator component with Chinese text
- [x] 5.8 Create ErrorDialog component with retry option
- [x] 5.9 Create ControversyCard component for left-right evidence display

## 6. UI Pages - Main Interfaces

- [x] 6.1 Create Main page with search box and course card grid
- [x] 6.2 Implement course creation flow on Main page
- [x] 6.3 Create LearningSpace page with three zones (graph, controversies, materials)
- [x] 6.4 Implement knowledge graph display in LearningSpace
- [x] 6.5 Implement controversy list display in LearningSpace
- [x] 6.6 Create AssessmentCenter page with question list and answer interface
- [x] 6.7 Implement assessment taking flow (question display, answer submission, feedback)
- [x] 6.8 Implement assessment result report with score breakdown
- [x] 6.9 Create Profile page with statistics dashboard
- [x] 6.10 Implement settings panel in Profile page (theme, API key configuration)
- [x] 6.11 Add navigation between all four main pages

## 7. Integration & State Management

- [x] 7.1 Connect CourseManager with UI components via @State/@Link
- [x] 7.2 Connect ThreeQuestionEngine with LearningSpace UI
- [x] 7.3 Connect AssessmentManager with AssessmentCenter UI
- [x] 7.4 Implement progress tracking updates across components
- [x] 7.5 Add loading states for all async operations
- [x] 7.6 Implement error handling UI for API failures

## 8. Testing & Validation

- [x] 8.1 Test course creation with various question inputs
- [x] 8.2 Test three-question engine execution flow
- [x] 8.3 Test knowledge graph rendering with different node counts
- [x] 8.4 Test assessment generation and scoring
- [x] 8.5 Test data persistence (RDB, Preferences, File)
- [x] 8.6 Test error scenarios (API failure, network timeout)
- [x] 8.7 Verify performance requirements (≤2s for course generation, graph loading)

## 9. Polish & Documentation

- [x] 9.1 Optimize knowledge graph performance for >100 nodes
- [x] 9.2 Add Chinese UI text for all user-facing strings
- [x] 9.3 Implement graceful degradation for offline mode
- [x] 9.4 Add user onboarding hints and tooltips
- [x] 9.5 Create README with project setup instructions
- [x] 9.6 Document API key configuration process
