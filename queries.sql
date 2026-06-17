-- ================================================================
-- EDW_StudentPerformance — OLAP Analytical Queries
-- Run against EDW_StudentPerformance database after ETL
-- ================================================================

USE EDW_StudentPerformance;
GO

-- ── Query 1: GPA Trend by Department Over Time ───────────────────
-- OLAP ops: Roll-up by year, drill-down into semester, slice by dept
SELECT
    d.dept_name,
    t.year,
    t.semester,
    ROUND(AVG(CAST(f.gpa_points AS FLOAT)), 2) AS avg_gpa,
    COUNT(*) AS total_enrollments
FROM dbo.Enrollment_Fact f
JOIN dbo.DimDepartment d ON f.dept_id  = d.dept_id
JOIN dbo.DimTerm       t ON f.term_id  = t.term_id
GROUP BY d.dept_name, t.year, t.semester
ORDER BY t.year, t.semester, d.dept_name;
GO

-- ── Query 2: Pass/Fail Rate by Course and Instructor ────────────
-- OLAP ops: Dice on course + instructor, measure = pass rate %
SELECT
    c.course_name,
    i.name       AS instructor,
    i.rank       AS instructor_rank,
    COUNT(*)     AS total_students,
    SUM(CASE WHEN f.final_grade IN ('A','B','C') THEN 1 ELSE 0 END) AS passed,
    SUM(CASE WHEN f.final_grade IN ('D','F')     THEN 1 ELSE 0 END) AS failed,
    ROUND(
        SUM(CASE WHEN f.final_grade IN ('A','B','C') THEN 1.0 ELSE 0 END)
        / COUNT(*) * 100, 1
    ) AS pass_rate_pct
FROM dbo.Enrollment_Fact f
JOIN dbo.DimCourse     c ON f.course_id     = c.course_id
JOIN dbo.DimInstructor i ON f.instructor_id = i.instructor_id
GROUP BY c.course_name, i.name, i.rank
ORDER BY pass_rate_pct DESC;
GO

-- ── Query 3: Enrollment Count by Program and Semester ───────────
-- OLAP ops: Roll-up by semester, drill-down by program
SELECT
    s.program,
    t.semester,
    t.year,
    COUNT(*) AS enrollment_count
FROM dbo.Enrollment_Fact f
JOIN dbo.DimStudent s ON f.student_id = s.student_id
JOIN dbo.DimTerm    t ON f.term_id    = t.term_id
GROUP BY s.program, t.semester, t.year
ORDER BY t.year, t.semester, s.program;
GO

-- ── Query 4: Grade Distribution by Department ───────────────────
-- Used for pie/bar charts — what % of students got each grade per dept
SELECT
    d.dept_name,
    f.final_grade,
    COUNT(*) AS grade_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY d.dept_name), 1) AS grade_pct
FROM dbo.Enrollment_Fact f
JOIN dbo.DimDepartment d ON f.dept_id = d.dept_id
GROUP BY d.dept_name, f.final_grade
ORDER BY d.dept_name, f.final_grade;
GO

-- ── Summary KPIs (for dashboard header cards) ───────────────────
SELECT
    COUNT(DISTINCT f.student_id)  AS total_students,
    COUNT(DISTINCT f.course_id)   AS total_courses,
    COUNT(*)                      AS total_enrollments,
    ROUND(AVG(CAST(f.gpa_points AS FLOAT)), 2) AS overall_avg_gpa,
    ROUND(
        SUM(CASE WHEN f.final_grade IN ('A','B','C') THEN 1.0 ELSE 0 END)
        / COUNT(*) * 100, 1
    ) AS overall_pass_rate_pct
FROM dbo.Enrollment_Fact f;
GO
