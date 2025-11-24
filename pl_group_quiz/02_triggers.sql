CREATE OR REPLACE TRIGGER trg_access_restriction
BEFORE INSERT OR UPDATE OR DELETE ON target_table
DECLARE
    v_day   VARCHAR2(10);
    v_hour  NUMBER;
BEGIN
    v_day  := RTRIM(TO_CHAR(SYSDATE, 'DAY', 'NLS_DATE_LANGUAGE=ENGLISH'));
    v_hour := TO_NUMBER(TO_CHAR(SYSDATE, 'HH24'));

    IF v_day IN ('SATURDAY', 'SUNDAY') THEN
        RAISE_APPLICATION_ERROR(-20001,
            'ACCESS DENIED: System not accessible on Sabbath (Saturday/Sunday).');
    END IF;

    IF v_hour < 8 OR v_hour >= 17 THEN
        RAISE_APPLICATION_ERROR(-20002,
            'ACCESS DENIED: Allowed time is Monday–Friday, 08:00–17:00.');
    END IF;

END;
/

CREATE OR REPLACE TRIGGER trg_access_violations_log
BEFORE INSERT OR UPDATE OR DELETE ON target_table
DECLARE
    PRAGMA AUTONOMOUS_TRANSACTION;
    v_day   VARCHAR2(10) := RTRIM(TO_CHAR(SYSDATE, 'DAY', 'NLS_DATE_LANGUAGE=ENGLISH'));
    v_hour  NUMBER := TO_NUMBER(TO_CHAR(SYSDATE, 'HH24'));
    violation BOOLEAN := FALSE;
    v_reason VARCHAR2(200);
BEGIN
    IF v_day IN ('SATURDAY', 'SUNDAY') THEN
        violation := TRUE;
        v_reason := 'Attempt on Sabbath (Saturday/Sunday)';
    ELSIF v_hour < 8 OR v_hour >= 17 THEN
        violation := TRUE;
        v_reason := 'Attempt outside allowed hours (08:00–17:00)';
    END IF;

    IF violation THEN
        INSERT INTO access_errors_log (username, action_type, table_name, attempted_at, reason)
        VALUES (USER, ORA_SYSEVENT, 'TARGET_TABLE', SYSDATE, v_reason);
        COMMIT;
    END IF;

END;
/


INSERT INTO target_table (data_value) VALUES ('Test OK');


INSERT INTO target_table (data_value) VALUES ('Should Fail');




-- Check trigger status
SELECT trigger_name, status 
FROM user_triggers 
WHERE table_name = 'TARGET_TABLE';

-- Test 1: This should work ONLY if time is allowed
INSERT INTO target_table (data_value) VALUES ('Allowed Test');

-- Test 2: This should FAIL if time/day is NOT allowed
INSERT INTO target_table (data_value) VALUES ('Should Fail');




SELECT *
FROM access_errors_log
ORDER BY log_id DESC;




SELECT log_id,
       attempted_at,
       username,
       reason AS error_message
FROM access_errors_log
ORDER BY log_id DESC;



-- Insert sample data (if not already exists)
INSERT INTO employees (emp_id, emp_name, salary) VALUES (1, 'John Doe', 500000);
INSERT INTO employees (emp_id, emp_name, salary) VALUES (2, 'Jane Smith', 750000);
INSERT INTO employees (emp_id, emp_name, salary) VALUES (3, 'Bob Johnson', 600000);
COMMIT;


COLUMN "User"         FORMAT A15
COLUMN "Action"       FORMAT A12
COLUMN "Table"        FORMAT A15
COLUMN "Timestamp"    FORMAT A25
COLUMN "Error Reason" FORMAT A40

SELECT 
    username       AS "User",
    action_type    AS "Action",
    table_name     AS "Table",
    TO_CHAR(attempted_at, 'YYYY-MM-DD HH24:MI:SS') AS "Timestamp",
    reason         AS "Error Reason"
FROM access_errors_log
ORDER BY log_id DESC;

INSERT INTO target_table (data_value) VALUES ('Hello');
INSERT INTO target_table (data_value) VALUES ('World');





