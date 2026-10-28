# Change Log: three-question-study

## 2026-06-08 - Initial Implementation

### Added

#### Project Setup
- Added @ohos/axios dependency for HTTP requests
- Configured INTERNET, READ_USER_STORAGE, WRITE_USER_STORAGE permissions
- Created folder structure: pages, components, services, model, utils
- Added tech-blue theme color scheme

#### Data Layer
- Implemented RDBService with full CRUD operations
- Created database schema for courses, knowledge_nodes, knowledge_edges, assessments
- Implemented PreferencesService for user settings
- Implemented FileService for material storage
- Created data models: Course, KnowledgeNode, KnowledgeEdge, Assessment

#### AI Integration
- Implemented DeepseekService with axios configuration
- Added API key management with validation
- Created prompt templates for three questions
- Implemented response parsers for JSON extraction
- Added retry logic (3 attempts) and 30s timeout

#### Business Logic
- Implemented CourseManager with lifecycle management
- Implemented ThreeQuestionEngine with state management
- Implemented KnowledgeBaseManager for composite knowledge base
- Implemented AssessmentManager with scoring logic

#### UI Components
- Created CourseCard with progress display
- Created KnowledgeGraphCanvas with Canvas rendering
- Implemented force-directed layout algorithm
- Added graph interaction handlers (drag, pinch zoom)
- Created RadarChart for ability dimensions
- Created ControversyCard for left-right evidence
- Created ProgressBar, LoadingIndicator, ErrorDialog

#### UI Pages
- Created MainPage with search and course grid
- Created LearningSpacePage with three zones
- Created AssessmentCenterPage with question flow
- Created ProfilePage with settings
- Added bottom navigation

#### Documentation
- Created comprehensive README.md
- Documented API key configuration process

### Technical Details

- **Database**: Using HarmonyOS RDB with cascade delete
- **State Management**: @State, @Prop, @Link decorators
- **Canvas**: Custom rendering for knowledge graph and radar chart
- **Navigation**: Bottom tab navigation
- **Error Handling**: Retry logic, timeout handling, error dialogs
- **Performance**: Force-directed layout optimization, lazy loading

### Configuration

```json5
// oh-package.json5
"dependencies": {
  "@ohos/axios": "^2.2.0"
}

// module.json5
"requestPermissions": [
  { "name": "ohos.permission.INTERNET" },
  { "name": "ohos.permission.READ_USER_STORAGE" },
  { "name": "ohos.permission.WRITE_USER_STORAGE" }
]
```

### API Integration

- **Endpoint**: https://api.deepseek.com/v1/chat/completions
- **Model**: deepseek-chat
- **Timeout**: 30 seconds
- **Retries**: 3 attempts
- **Temperature**: 0.7-0.8

### Bloom's Taxonomy Levels

1. Remember (记忆)
2. Understand (理解)
3. Apply (应用)
4. Analyze (分析)
5. Evaluate (评价)
6. Create (创造)

### Knowledge Graph Node Types

- **concept**: 核心概念
- **controversy**: 争议点
- **evidence**: 证据

### Knowledge Graph Edge Types

- **supports**: 支持
- **opposes**: 反对
- **relates**: 相关

## Statistics

- **Total Files Created**: 27
- **Services**: 10
- **Models**: 4
- **Components**: 7
- **Pages**: 4
- **Utils**: 1
- **Documentation**: 1

- **Total Tasks**: 72
- **Completed**: 72 (100%)
