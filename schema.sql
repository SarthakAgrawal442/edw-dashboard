-- ================================================================
-- EDW_StudentPerformance  —  Star Schema
-- Run this file against your SQL Server instance before ETL
-- ================================================================

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'EDW_StudentPerformance')
    CREATE DATABASE EDW_StudentPerformance;
GO

USE EDW_StudentPerformance;
GO

-- ── Dimension Tables ─────────────────────────────────────────────

IF OBJECT_ID('dbo.DimDepartment', 'U') IS NOT NULL DROP TABLE dbo.DimDepartment;
CREATE TABLE dbo.DimDepartment (
    dept_id     INT           PRIMARY KEY,
    dept_name   NVARCHAR(100) NOT NULL,
    faculty     NVARCHAR(100) NOT NULL
);

IF OBJECT_ID('dbo.DimTerm', 'U') IS NOT NULL DROP TABLE dbo.DimTerm;
CREATE TABLE dbo.DimTerm (
    term_id     INT           PRIMARY KEY,
    term_name   NVARCHAR(50)  NOT NULL,
    year        INT           NOT NULL,
    semester    NVARCHAR(20)  NOT NULL
);

IF OBJECT_ID('dbo.DimInstructor', 'U') IS NOT NULL DROP TABLE dbo.DimInstructor;
CREATE TABLE dbo.DimInstructor (
    instructor_id INT           PRIMARY KEY,
    name          NVARCHAR(100) NOT NULL,
    rank          NVARCHAR(50)  NOT NULL,
    department    NVARCHAR(100) NOT NULL
);

IF OBJECT_ID('dbo.DimCourse', 'U') IS NOT NULL DROP TABLE dbo.DimCourse;
CREATE TABLE dbo.DimCourse (
    course_id   INT           PRIMARY KEY,
    course_name NVARCHAR(100) NOT NULL,
    level       INT           NOT NULL,
    credits     INT           NOT NULL
);

IF OBJECT_ID('dbo.DimStudent', 'U') IS NOT NULL DROP TABLE dbo.DimStudent;
CREATE TABLE dbo.DimStudent (
    student_id  INT           PRIMARY KEY,
    name        NVARCHAR(100) NOT NULL,
    program     NVARCHAR(100) NOT NULL,
    start_year  INT           NOT NULL,
    gender      NVARCHAR(20)  NOT NULL
);

-- ── Fact Table ───────────────────────────────────────────────────

IF OBJECT_ID('dbo.Enrollment_Fact', 'U') IS NOT NULL DROP TABLE dbo.Enrollment_Fact;
CREATE TABLE dbo.Enrollment_Fact (
    enrollment_id     INT             PRIMARY KEY,
    student_id        INT             NOT NULL REFERENCES dbo.DimStudent(student_id),
    course_id         INT             NOT NULL REFERENCES dbo.DimCourse(course_id),
    instructor_id     INT             NOT NULL REFERENCES dbo.DimInstructor(instructor_id),
    term_id           INT             NOT NULL REFERENCES dbo.DimTerm(term_id),
    dept_id           INT             NOT NULL REFERENCES dbo.DimDepartment(dept_id),
    final_grade       CHAR(1)         NOT NULL,
    gpa_points        DECIMAL(3,1)    NOT NULL,
    credits_attempted INT             NOT NULL,
    credits_earned    INT             NOT NULL
);

-- ── OLAP Views ───────────────────────────────────────────────────

-- View 1: GPA Trend by Department Over Time
IF OBJECT_ID('dbo.vw_GpaByDeptTerm', 'V') IS NOT NULL DROP VIEW dbo.vw_GpaByDeptTerm;
GO
CREATE VIEW dbo.vw_GpaByDeptTerm AS
SELECT
    d.dept_name,
    t.year,
    t.semester,
    t.term_name,
    ROUND(AVG(CAST(f.gpa_points AS FLOAT)), 2) AS avg_gpa,
    COUNT(*) AS enrollment_count
FROM dbo.Enrollment_Fact f
JOIN dbo.DimDepartment d ON f.dept_id      = d.dept_id
JOIN dbo.DimTerm       t ON f.term_id      = t.term_id
GROUP BY d.dept_name, t.year, t.semester, t.term_name;
GO

-- View 2: Pass/Fail Rate by Course and Instructor
IF OBJECT_ID('dbo.vw_PassRateByCourseInstructor', 'V') IS NOT NULL DROP VIEW dbo.vw_PassRateByCourseInstructor;
GO
CREATE VIEW dbo.vw_PassRateByCourseInstructor AS
SELECT
    c.course_name,
    c.level         AS course_level,
    i.name          AS instructor_name,
    i.rank          AS instructor_rank,
    COUNT(*)        AS total_enrollments,
    SUM(CASE WHEN f.final_grade IN ('A','B','C') THEN 1 ELSE 0 END) AS passed,
    SUM(CASE WHEN f.final_grade IN ('D','F')     THEN 1 ELSE 0 END) AS failed,
    ROUND(
        SUM(CASE WHEN f.final_grade IN ('A','B','C') THEN 1.0 ELSE 0 END)
        / COUNT(*) * 100, 1
    ) AS pass_rate_pct
FROM dbo.Enrollment_Fact f
JOIN dbo.DimCourse     c ON f.course_id     = c.course_id
JOIN dbo.DimInstructor i ON f.instructor_id = i.instructor_id
GROUP BY c.course_name, c.level, i.name, i.rank;
GO

-- View 3: Enrollment Count by Program and Semester
IF OBJECT_ID('dbo.vw_EnrollmentByProgram', 'V') IS NOT NULL DROP VIEW dbo.vw_EnrollmentByProgram;
GO
CREATE VIEW dbo.vw_EnrollmentByProgram AS
SELECT
    s.program,
    t.semester,
    t.year,
    t.term_name,
    COUNT(*) AS enrollment_count
FROM dbo.Enrollment_Fact f
JOIN dbo.DimStudent s ON f.student_id = s.student_id
JOIN dbo.DimTerm    t ON f.term_id    = t.term_id
GROUP BY s.program, t.semester, t.year, t.term_name;
GO

-- View 4: Grade Distribution by Department
IF OBJECT_ID('dbo.vw_GradeDistribution', 'V') IS NOT NULL DROP VIEW dbo.vw_GradeDistribution;
GO
CREATE VIEW dbo.vw_GradeDistribution AS
SELECT
    d.dept_name,
    f.final_grade,
    COUNT(*) AS grade_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY d.dept_name), 1) AS grade_pct
FROM dbo.Enrollment_Fact f
JOIN dbo.DimDepartment d ON f.dept_id = d.dept_id
GROUP BY d.dept_name, f.final_grade;
GO

PRINT 'Schema created successfully.';
