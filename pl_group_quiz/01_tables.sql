CREATE TABLE target_table (
    id          NUMBER GENERATED ALWAYS AS IDENTITY,
    data_value  VARCHAR2(100),
    created_at  DATE DEFAULT SYSDATE
);

CREATE TABLE access_errors_log (
    log_id        NUMBER GENERATED ALWAYS AS IDENTITY,
    username      VARCHAR2(50),
    action_type   VARCHAR2(20),
    table_name    VARCHAR2(50),
    attempted_at  DATE,
    reason        VARCHAR2(200)
);

CREATE TABLE employees (
    emp_id      NUMBER PRIMARY KEY,
    emp_name    VARCHAR2(100),
    salary      NUMBER(10,2),
    tax_rate    NUMBER(5,3) DEFAULT 0.05,
    created_by  VARCHAR2(50),
    created_date DATE DEFAULT SYSDATE
);

CREATE TABLE salary_history (
    history_id   NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    emp_id       NUMBER,
    old_salary   NUMBER(10,2),
    new_salary   NUMBER(10,2),
    changed_by   VARCHAR2(50),
    change_date  DATE DEFAULT SYSDATE
);
