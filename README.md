# Educational Data Warehouse — Project

## Quick Start

### 1. Start SQL Server
```bash
docker-compose up -d
# Wait ~30 seconds for SQL Server to initialize
```

### 2. Create the Schema
Connect to SQL Server and run `schema.sql`:
```bash
# Using sqlcmd inside the container
docker exec -it edw_sqlserver /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "EDW_Strong@Pass1" -i /dev/stdin < schema.sql
```
Or open **Azure Data Studio** / **DBeaver**, connect to `127.0.0.1:1433` with `sa / EDW_Strong@Pass1`, and run `schema.sql`.

### 3. Generate Synthetic Data
```bash
pip install -r requirements.txt
python data_generator.py
# Outputs CSVs to ./data/
```

### 4. Run ETL Pipeline
```bash
python etl_pipeline.py
# Loads all CSVs into SQL Server
```

### 5. Run the ASP.NET Dashboard
```bash
cd EdwDashboard
dotnet run
# Open http://localhost:5000
```

---

## Project Structure
```
edw_project/
├── docker-compose.yml      — SQL Server 2022 container
├── requirements.txt        — Python dependencies
├── data_generator.py       — Synthetic data generation (Faker)
├── schema.sql              — Star schema DDL + OLAP views
├── etl_pipeline.py         — CSV → SQL Server ETL
├── queries.sql             — Standalone OLAP queries
├── data/                   — Generated CSVs (after running generator)
└── EdwDashboard/           — ASP.NET Core Web App
    ├── EdwDashboard.csproj
    ├── Program.cs
    ├── appsettings.json
    ├── Controllers/
    │   └── EdwController.cs
    ├── Models/
    │   └── EdwModels.cs
    └── wwwroot/
        ├── index.html
        ├── css/dashboard.css
        └── js/dashboard.js
```

## Credentials
- **SQL Server:** `127.0.0.1:1433`
- **User:** `sa`
- **Password:** `EDW_Strong@Pass1`
- **Database:** `EDW_StudentPerformance`

## Dashboard Charts
1. Average GPA by Department Over Time (line chart)
2. Grade Distribution by Department (stacked bar)
3. Enrollment by Program per Semester (stacked bar)
4. Top 20 Courses Pass Rate by Instructor (horizontal bar)
