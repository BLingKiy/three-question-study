-- ============================================================
-- 三问高效学习机 数据库部署脚本
-- 数据库: ThreeQuestionStudy.db (SQLite)
-- 说明: 本脚本用于手动创建数据库和所有表结构
--       应用运行时会自动执行，此脚本仅供提交和参考
-- ============================================================

PRAGMA foreign_keys = ON;

-- 课程表
CREATE TABLE IF NOT EXISTS courses (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    question TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'created',
    mental_model_generated INTEGER NOT NULL DEFAULT 0,
    controversy_generated INTEGER NOT NULL DEFAULT 0,
    assessment_generating INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

-- 知识图谱节点表
CREATE TABLE IF NOT EXISTS knowledge_nodes (
    id TEXT PRIMARY KEY,
    course_id TEXT NOT NULL,
    type TEXT NOT NULL,
    label TEXT NOT NULL,
    content TEXT,
    position_x REAL NOT NULL DEFAULT 0,
    position_y REAL NOT NULL DEFAULT 0,
    FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE
);

-- 知识图谱边表
CREATE TABLE IF NOT EXISTS knowledge_edges (
    id TEXT PRIMARY KEY,
    course_id TEXT NOT NULL,
    from_node_id TEXT NOT NULL,
    to_node_id TEXT NOT NULL,
    type TEXT NOT NULL,
    weight REAL NOT NULL DEFAULT 1.0,
    FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE,
    FOREIGN KEY (from_node_id) REFERENCES knowledge_nodes(id) ON DELETE CASCADE,
    FOREIGN KEY (to_node_id) REFERENCES knowledge_nodes(id) ON DELETE CASCADE
);

-- 测评题目表
CREATE TABLE IF NOT EXISTS assessments (
    id TEXT PRIMARY KEY,
    course_id TEXT NOT NULL,
    bloom_level TEXT NOT NULL,
    question_type TEXT NOT NULL DEFAULT 'subjective',
    question TEXT NOT NULL,
    answer TEXT,
    options TEXT DEFAULT '',
    correct_answer TEXT DEFAULT '',
    user_answer TEXT,
    is_correct INTEGER,
    created_at INTEGER NOT NULL,
    FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE
);

-- 知识来源链接表
CREATE TABLE IF NOT EXISTS knowledge_sources (
    id TEXT PRIMARY KEY,
    course_id TEXT NOT NULL,
    node_id TEXT NOT NULL DEFAULT '',
    title TEXT NOT NULL,
    url TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'web',
    FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE
);

-- 讨论区表
CREATE TABLE IF NOT EXISTS discussions (
    id TEXT PRIMARY KEY,
    controversy_id TEXT NOT NULL,
    course_id TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE
);

-- 讨论消息表
CREATE TABLE IF NOT EXISTS discussion_messages (
    id TEXT PRIMARY KEY,
    discussion_id TEXT NOT NULL,
    role TEXT NOT NULL,
    content TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    FOREIGN KEY (discussion_id) REFERENCES discussions(id) ON DELETE CASCADE
);

-- 讨论总结表
CREATE TABLE IF NOT EXISTS discussion_summaries (
    id TEXT PRIMARY KEY,
    discussion_id TEXT NOT NULL,
    summary TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    FOREIGN KEY (discussion_id) REFERENCES discussions(id) ON DELETE CASCADE
);

-- 学习进度表
CREATE TABLE IF NOT EXISTS learning_progress (
    id TEXT PRIMARY KEY,
    course_id TEXT NOT NULL,
    item_type TEXT NOT NULL,
    item_id TEXT NOT NULL,
    checked INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL,
    UNIQUE(course_id, item_type, item_id)
);

-- 追问记录表
CREATE TABLE IF NOT EXISTS assessment_follow_ups (
    id TEXT PRIMARY KEY,
    assessment_id TEXT NOT NULL,
    role TEXT NOT NULL,
    content TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    FOREIGN KEY (assessment_id) REFERENCES assessments(id) ON DELETE CASCADE
);

-- 测评报告表
CREATE TABLE IF NOT EXISTS assessment_reports (
    id TEXT PRIMARY KEY,
    course_id TEXT NOT NULL UNIQUE,
    dimensions_json TEXT NOT NULL,
    overall_suggestion TEXT NOT NULL,
    error_traces_json TEXT NOT NULL,
    dimension_analysis_json TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE
);

-- 学习时长表
CREATE TABLE IF NOT EXISTS study_sessions (
    id TEXT PRIMARY KEY,
    course_id TEXT NOT NULL,
    date TEXT NOT NULL,
    duration_seconds INTEGER NOT NULL DEFAULT 0,
    UNIQUE(course_id, date),
    FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE
);

-- 答题档案表
CREATE TABLE IF NOT EXISTS answer_archives (
    id TEXT PRIMARY KEY,
    original_course_id TEXT NOT NULL,
    original_course_name TEXT NOT NULL,
    bloom_level TEXT NOT NULL,
    question_type TEXT NOT NULL,
    question TEXT NOT NULL,
    answer TEXT,
    options TEXT,
    correct_answer TEXT,
    user_answer TEXT,
    is_correct INTEGER,
    created_at INTEGER NOT NULL,
    archived_at INTEGER NOT NULL
);

-- 追问档案表
CREATE TABLE IF NOT EXISTS follow_up_archives (
    id TEXT PRIMARY KEY,
    archive_assessment_id TEXT NOT NULL,
    role TEXT NOT NULL,
    content TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    FOREIGN KEY (archive_assessment_id) REFERENCES answer_archives(id) ON DELETE CASCADE
);

-- ============================================================
-- 索引（提升查询性能）
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_knowledge_nodes_course ON knowledge_nodes(course_id);
CREATE INDEX IF NOT EXISTS idx_knowledge_edges_course ON knowledge_edges(course_id);
CREATE INDEX IF NOT EXISTS idx_assessments_course ON assessments(course_id);
CREATE INDEX IF NOT EXISTS idx_learning_progress_course ON learning_progress(course_id);
CREATE INDEX IF NOT EXISTS idx_study_sessions_course ON study_sessions(course_id);
CREATE INDEX IF NOT EXISTS idx_answer_archives_course ON answer_archives(original_course_id);
CREATE INDEX IF NOT EXISTS idx_follow_up_archives_assessment ON follow_up_archives(archive_assessment_id);