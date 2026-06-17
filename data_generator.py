import os
import random
import pandas as pd
from faker import Faker

fake = Faker()
random.seed(42)
Faker.seed(42)

OUTPUT_DIR = "./data"
os.makedirs(OUTPUT_DIR, exist_ok=True)

# ── Dimensions ────────────────────────────────────────────────────

# DimDepartment
departments = [
    (1, "Computer Science",       "Faculty of Science & Engineering"),
    (2, "Software Engineering",   "Faculty of Science & Engineering"),
    (3, "Data Science",           "Faculty of Science & Engineering"),
    (4, "Information Technology", "Faculty of Applied Technology"),
    (5, "Computer Engineering",   "Faculty of Science & Engineering"),
]
df_dept = pd.DataFrame(departments, columns=["dept_id","dept_name","faculty"])
df_dept.to_csv(f"{OUTPUT_DIR}/DimDepartment.csv", index=False)
print(f"DimDepartment: {len(df_dept)} records")

# DimTerm
terms = []
tid = 1
for year in range(2021, 2026):
    for sem in ["Fall", "Spring", "Summer"]:
        terms.append((tid, f"{sem} {year}", year, sem))
        tid += 1
df_term = pd.DataFrame(terms, columns=["term_id","term_name","year","semester"])
df_term.to_csv(f"{OUTPUT_DIR}/DimTerm.csv", index=False)
print(f"DimTerm: {len(df_term)} records")

# DimInstructor
ranks = ["Professor", "Associate Professor", "Assistant Professor", "Lecturer"]
dept_names = [d[1] for d in departments]
instructors = []
for i in range(1, 16):
    instructors.append((
        i,
        fake.name(),
        random.choice(ranks),
        random.choice(dept_names)
    ))
df_inst = pd.DataFrame(instructors, columns=["instructor_id","name","rank","department"])
df_inst.to_csv(f"{OUTPUT_DIR}/DimInstructor.csv", index=False)
print(f"DimInstructor: {len(df_inst)} records")

# DimCourse
course_names = [
    "Database Systems", "Algorithms", "Data Structures", "Operating Systems",
    "Computer Networks", "Software Engineering", "Machine Learning",
    "Artificial Intelligence", "Web Development", "Mobile Development",
    "Computer Architecture", "Discrete Mathematics", "Linear Algebra",
    "Calculus I", "Statistics", "Data Mining", "Cloud Computing",
    "Cybersecurity", "Computer Graphics", "Compiler Design",
    "Object-Oriented Programming", "Functional Programming", "System Design",
    "Software Testing", "Project Management", "Human-Computer Interaction",
    "Embedded Systems", "Digital Logic", "Information Retrieval",
    "Natural Language Processing", "Computer Vision", "Parallel Computing",
    "Distributed Systems", "Big Data Analytics", "DevOps",
    "Network Security", "Blockchain Technology", "IoT Systems",
    "Robotics", "Game Development", "Ethics in Computing",
    "Technical Writing", "Introduction to Programming", "Data Visualization",
    "Business Intelligence", "Requirements Engineering",
    "Software Architecture", "Advanced Databases", "Deep Learning",
    "Quantum Computing"
]
levels = [100, 200, 300, 400]
courses = []
for i, name in enumerate(course_names, 1):
    level = levels[min((i - 1) // 13, 3)]
    courses.append((i, name, level, random.choice([3, 4])))
df_course = pd.DataFrame(courses, columns=["course_id","course_name","level","credits"])
df_course.to_csv(f"{OUTPUT_DIR}/DimCourse.csv", index=False)
print(f"DimCourse: {len(df_course)} records")

# DimStudent
programs = ["Computer Science", "Software Engineering", "Data Science",
            "Information Technology", "Computer Engineering"]
students = []
for i in range(1, 501):
    students.append((
        i,
        fake.name(),
        random.choice(programs),
        random.randint(2021, 2025),
        random.choice(["Male", "Female", "Non-binary"])
    ))
df_student = pd.DataFrame(students, columns=["student_id","name","program","start_year","gender"])
df_student.to_csv(f"{OUTPUT_DIR}/DimStudent.csv", index=False)
print(f"DimStudent: {len(df_student)} records")

# ── Enrollment_Fact ───────────────────────────────────────────────
# Grade distribution: A=15%, B=35%, C=15%, D=10%, F=25% (~75% pass rate)
grade_choices  = ["A", "B", "B", "B", "B", "B", "B", "B", "C", "C", "C", "D", "D", "F", "F", "F", "F", "F", "A", "A"]
gpa_map        = {"A": 4.0, "B": 3.0, "C": 2.0, "D": 1.0, "F": 0.0}

fact_rows = []
fact_id = 1
for _ in range(10000):
    student  = random.choice(students)
    course   = random.choice(courses)
    instr    = random.choice(instructors)
    term     = random.choice(terms)
    dept     = random.choice(departments)
    grade    = random.choice(grade_choices)
    gpa_pts  = gpa_map[grade]
    credits  = course[3]
    earned   = credits if grade != "F" else 0
    fact_rows.append((
        fact_id, student[0], course[0], instr[0],
        term[0], dept[0], grade, gpa_pts, credits, earned
    ))
    fact_id += 1

df_fact = pd.DataFrame(fact_rows, columns=[
    "enrollment_id","student_id","course_id","instructor_id",
    "term_id","dept_id","final_grade","gpa_points",
    "credits_attempted","credits_earned"
])
df_fact.to_csv(f"{OUTPUT_DIR}/Enrollment_Fact.csv", index=False)
print(f"Enrollment_Fact: {len(df_fact)} records")

# Grade distribution check
dist = df_fact["final_grade"].value_counts(normalize=True).sort_index()
print("\nGrade distribution:")
for g, p in dist.items():
    print(f"  {g}: {p:.1%}")
pass_rate = df_fact[df_fact["final_grade"].isin(["A","B","C"])].shape[0] / len(df_fact)
print(f"\nPass rate: {pass_rate:.1%}")
print("\nAll CSV files written to ./data/")
