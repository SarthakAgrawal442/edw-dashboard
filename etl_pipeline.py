import os
import time
import pyodbc
import pandas as pd

CONN_STR = (
    "DRIVER={ODBC Driver 18 for SQL Server};"
    "SERVER=127.0.0.1,1433;"
    "DATABASE=EDW_StudentPerformance;"
    "UID=sa;"
    "PWD=Pass1234!;"
    "TrustServerCertificate=yes;"
)

DATA_DIR = "./data"

LOAD_ORDER = [
    ("DimDepartment",  "DimDepartment.csv"),
    ("DimTerm",        "DimTerm.csv"),
    ("DimInstructor",  "DimInstructor.csv"),
    ("DimCourse",      "DimCourse.csv"),
    ("DimStudent",     "DimStudent.csv"),
    ("Enrollment_Fact","Enrollment_Fact.csv"),
]

def wait_for_sql_server(max_retries=12, delay=5):
    print("Waiting for SQL Server to be ready...")
    for attempt in range(1, max_retries + 1):
        try:
            conn = pyodbc.connect(CONN_STR)
            conn.close()
            print("SQL Server is ready.")
            return
        except Exception as e:
            print(f"Attempt {attempt}/{max_retries}: {e}")
            time.sleep(delay)
    raise RuntimeError("SQL Server did not become ready in time.")

def get_connection():
    return pyodbc.connect(CONN_STR)

def truncate_table(cursor, table_name):
    cursor.execute(f"DELETE FROM dbo.{table_name}")

def load_table(conn, table_name, csv_file):
    df = pd.read_csv(os.path.join(DATA_DIR, csv_file))
    cols = list(df.columns)
    placeholders = ", ".join(["?"] * len(cols))
    col_names = ", ".join(cols)
    sql = f"INSERT INTO dbo.{table_name} ({col_names}) VALUES ({placeholders})"

    cursor = conn.cursor()
    rows = [tuple(row) for row in df.itertuples(index=False, name=None)]

    batch_size = 500
    for i in range(0, len(rows), batch_size):
        cursor.executemany(sql, rows[i:i+batch_size])
        conn.commit()

    print(f"Loaded {len(rows):>6,} rows -> {table_name}")
    cursor.close()

def run_etl():
    wait_for_sql_server()
    conn = get_connection()
    print("\\nStarting ETL...\\n")

    cursor = conn.cursor()
    for table, _ in reversed(LOAD_ORDER):
        truncate_table(cursor, table)
    conn.commit()
    cursor.close()

    for table, csv_file in LOAD_ORDER:
        load_table(conn, table, csv_file)

    print("\\nVerification — Row counts:")
    cursor = conn.cursor()
    for table, _ in LOAD_ORDER:
        cursor.execute(f"SELECT COUNT(*) FROM dbo.{table}")
        count = cursor.fetchone()[0]
        print(f"{table:<25} {count:>7,} rows")
    cursor.close()
    conn.close()
    print("\\nETL complete.")

if __name__ == "__main__":
    run_etl()