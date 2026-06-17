namespace EdwDashboard.Models;

public class GpaByDeptTerm
{
    public string DeptName        { get; set; } = "";
    public int    Year            { get; set; }
    public string Semester        { get; set; } = "";
    public string TermName        { get; set; } = "";
    public double AvgGpa          { get; set; }
    public int    EnrollmentCount { get; set; }
}

public class PassRateByCourse
{
    public string CourseName      { get; set; } = "";
    public int    CourseLevel     { get; set; }
    public string InstructorName  { get; set; } = "";
    public string InstructorRank  { get; set; } = "";
    public int    TotalEnrollments{ get; set; }
    public int    Passed          { get; set; }
    public int    Failed          { get; set; }
    public double PassRatePct     { get; set; }
}

public class EnrollmentByProgram
{
    public string Program         { get; set; } = "";
    public string Semester        { get; set; } = "";
    public int    Year            { get; set; }
    public string TermName        { get; set; } = "";
    public int    EnrollmentCount { get; set; }
}

public class GradeDistribution
{
    public string DeptName   { get; set; } = "";
    public string FinalGrade { get; set; } = "";
    public int    GradeCount { get; set; }
    public double GradePct   { get; set; }
}

public class SummaryKpi
{
    public int    TotalStudents      { get; set; }
    public int    TotalCourses       { get; set; }
    public int    TotalEnrollments   { get; set; }
    public double OverallAvgGpa      { get; set; }
    public double OverallPassRatePct { get; set; }
}
