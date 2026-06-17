using Dapper;
using EdwDashboard.Models;
using Microsoft.AspNetCore.Mvc;
using System.Data;

namespace EdwDashboard.Controllers;

[ApiController]
[Route("api/[controller]")]
public class EdwController : ControllerBase
{
    private readonly IDbConnection _db;
    public EdwController(IDbConnection db) => _db = db;

    [HttpGet("kpis")]
    public async Task<IActionResult> GetKpis()
    {
        const string sql = @"
            SELECT
                COUNT(DISTINCT f.student_id)  AS TotalStudents,
                COUNT(DISTINCT f.course_id)   AS TotalCourses,
                COUNT(*)                      AS TotalEnrollments,
                ROUND(AVG(CAST(f.gpa_points AS FLOAT)), 2) AS OverallAvgGpa,
                ROUND(
                    SUM(CASE WHEN f.final_grade IN ('A','B','C') THEN 1.0 ELSE 0 END)
                    / COUNT(*) * 100, 1
                ) AS OverallPassRatePct
            FROM dbo.Enrollment_Fact f";
        var result = await _db.QueryFirstAsync<SummaryKpi>(sql);
        return Ok(result);
    }

    [HttpGet("gpa-by-dept")]
    public async Task<IActionResult> GetGpaByDept()
    {
        const string sql = @"
            SELECT
                dept_name AS DeptName,
                [year] AS Year,
                semester AS Semester,
                avg_gpa AS AvgGpa
            FROM dbo.vw_GpaByDeptTerm
            ORDER BY [year], semester, dept_name";
        var result = await _db.QueryAsync<GpaByDeptTerm>(sql);
        return Ok(result);
    }

    [HttpGet("pass-rate")]
    public async Task<IActionResult> GetPassRate()
    {
        const string sql = @"
            SELECT
                course_name AS CourseName,
                instructor_name AS InstructorName,
                pass_rate_pct AS PassRatePct
            FROM dbo.vw_PassRateByCourseInstructor
            ORDER BY pass_rate_pct DESC";
        var result = await _db.QueryAsync<PassRateByCourse>(sql);
        return Ok(result);
    }

    [HttpGet("enrollment")]
    public async Task<IActionResult> GetEnrollment()
    {
        const string sql = @"
            SELECT
                program AS Program,
                [year] AS Year,
                semester AS Semester,
                enrollment_count AS EnrollmentCount
            FROM dbo.vw_EnrollmentByProgram
            ORDER BY [year], semester, program";
        var result = await _db.QueryAsync<EnrollmentByProgram>(sql);
        return Ok(result);
    }
    
    [HttpGet("grade-distribution")]
    public async Task<IActionResult> GetGradeDistribution()
    {
        const string sql = @"
        SELECT
            dept_name AS DeptName,
            final_grade AS FinalGrade,
            grade_count AS GradeCount,
            ROUND(
                CAST(grade_count AS FLOAT) * 100.0 /
                SUM(grade_count) OVER (PARTITION BY dept_name),
                1
            ) AS GradePct
        FROM dbo.vw_GradeDistribution
        ORDER BY dept_name, final_grade";
        
        var result = await _db.QueryAsync<GradeDistribution>(sql);
        return Ok(result);
    }
}