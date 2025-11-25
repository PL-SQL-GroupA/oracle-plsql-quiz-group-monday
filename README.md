# Oracle PL/SQL Quiz & HR Management Project

## Overview

This project is a **PL/SQL-based Oracle database application** that demonstrates:

* Table creation and schema management
* Triggers for access control and logging
* Employee salary management with audit trail
* PL/SQL packages and procedures for HR operations

The project was developed as part of **PL/SQL training exercises** for Group A (Monday).

---

## Database Schema

### Tables

1. **TARGET_TABLE**
   Stores generic test data with automatic timestamps.

   ```sql
   id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY
   data_value VARCHAR2(100)
   created_at DATE DEFAULT SYSDATE
   ```

2. **ACCESS_ERRORS_LOG**
   Logs any unauthorized access attempts based on time/day restrictions.

   ```sql
   log_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY
   username VARCHAR2(50)
   action_type VARCHAR2(20)
   table_name VARCHAR2(50)
   attempted_at DATE
   reason VARCHAR2(200)
   ```

3. **EMPLOYEES**
   Stores employee information including salary and tax rate.

   ```sql
   emp_id NUMBER PRIMARY KEY
   emp_name VARCHAR2(100)
   salary NUMBER(10,2)
   tax_rate NUMBER(5,3) DEFAULT 0.05
   created_by VARCHAR2(50)
   created_date DATE DEFAULT SYSDATE
   ```

4. **SALARY_HISTORY**
   Tracks all changes to employee salaries for auditing purposes.

   ```sql
   history_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY
   emp_id NUMBER
   old_salary NUMBER(10,2)
   new_salary NUMBER(10,2)
   changed_by VARCHAR2(50)
   change_date DATE DEFAULT SYSDATE
   ```

---

## PL/SQL Packages & Triggers

### HR Management Package

The package `hr_management_pkg` contains:

* `calculate_rssb_tax(emp_id)`: Returns RSSB tax for a given employee
* `calculate_net_salary(emp_id)`: Returns net salary after tax deduction
* `update_employee_salary(emp_id, new_salary)`: Updates salary with audit logging
* `generate_salary_report()`: Generates a formatted salary report
* `bulk_update_salaries(percentage)`: Updates salaries of all employees in bulk

---

### Access Control

* Trigger `trg_access_restriction` (planned) prevents modifications to `TARGET_TABLE` outside **working hours** (Monday–Friday, 08:00–17:00).
* Trigger `trg_access_violations_log` logs violations in `ACCESS_ERRORS_LOG`.

> Note: Triggers are created under the user schema (`ahmed`) to avoid SYS restrictions.

---

## Sample Data

Employees sample data:

| emp_id | emp_name    | salary |
| ------ | ----------- | ------ |
| 1      | John Doe    | 500000 |
| 2      | Jane Smith  | 750000 |
| 3      | Bob Johnson | 600000 |

---

## How to Use

1. Connect to your **PDB** as the schema user (`ahmed`) in SQL Developer.
2. Run the SQL scripts in this order:

   * Create tables
   * Insert sample data
   * Create the `hr_management_pkg` package and body
   * Test using the demo PL/SQL block
3. Enable **DBMS Output** in SQL Developer to see reports and logs.
4. Query `salary_history` and `access_errors_log` to verify audit trails.

---

## GitHub Repository

You can clone or download the project here:
[https://github.com/PL-SQL-GroupA/oracle-plsql-quiz-group-monday](https://github.com/PL-SQL-GroupA/oracle-plsql-quiz-group-monday)

---

## Notes

* All scripts are designed for **Oracle 21c** or higher.
* Ensure you are **not using SYS** for creating tables or triggers; use your own schema (`ahmed`).
* Modify the package or table structures as needed for further exercises.

---

## Author

**Ahmed Mohammed AL-GUBARI ID 25859** – Group A, Monday PL/SQL 

**Byiringiro Niyonagize Olivier ID 27119** 

**Fatime Dadi Wardougou 25858**

**Semelane Temana Tlhohonolofatso 27293**

**Ineza Sonia   27852**
