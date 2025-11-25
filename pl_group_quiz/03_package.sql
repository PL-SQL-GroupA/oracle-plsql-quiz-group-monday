-- Recreate the HR Management Package with fixes
CREATE OR REPLACE PACKAGE hr_management_pkg 
AUTHID CURRENT_USER  -- INVOKER RIGHTS: Executes with privileges of current user
IS
    -- Function to calculate RSSB tax for an employee
    FUNCTION calculate_rssb_tax(
        p_emp_id IN employees.emp_id%TYPE
    ) RETURN NUMBER;
    
    -- Function to calculate net salary after RSSB tax deduction
    FUNCTION calculate_net_salary(
        p_emp_id IN employees.emp_id%TYPE
    ) RETURN NUMBER;
    
    -- Dynamic procedure to update employee salary with audit trail
    PROCEDURE update_employee_salary(
        p_emp_id IN employees.emp_id%TYPE,
        p_new_salary IN employees.salary%TYPE
    );
    
    -- Procedure to generate employee salary report
    PROCEDURE generate_salary_report;
    
    -- Bulk processing procedure (Optional Challenge)
    PROCEDURE bulk_update_salaries(
        p_percentage_raise IN NUMBER
    );

END hr_management_pkg;
/

CREATE OR REPLACE PACKAGE BODY hr_management_pkg IS

    /*
    ============================================================================
    FUNCTION: calculate_rssb_tax
    PURPOSE:  Calculates RSSB tax for a specific employee
    SECURITY: Uses INVOKER rights (AUTHID CURRENT_USER)
    ============================================================================
    */
    FUNCTION calculate_rssb_tax(
        p_emp_id IN employees.emp_id%TYPE
    ) RETURN NUMBER
    IS
        v_salary employees.salary%TYPE;
        v_tax_rate employees.tax_rate%TYPE;
        v_tax_amount NUMBER;
    BEGIN
        -- Get employee salary and tax rate
        SELECT salary, tax_rate 
        INTO v_salary, v_tax_rate
        FROM employees 
        WHERE emp_id = p_emp_id;
        
        -- Calculate RSSB tax (simple calculation: salary * tax_rate)
        v_tax_amount := v_salary * v_tax_rate;
        
        RETURN v_tax_amount;
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001, 'Employee ID ' || p_emp_id || ' not found.');
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20002, 'Error calculating RSSB tax: ' || SQLERRM);
    END calculate_rssb_tax;

    /*
    ============================================================================
    FUNCTION: calculate_net_salary
    PURPOSE:  Calculates net salary after deducting RSSB tax
    SECURITY: Uses INVOKER rights (AUTHID CURRENT_USER)
    ============================================================================
    */
    FUNCTION calculate_net_salary(
        p_emp_id IN employees.emp_id%TYPE
    ) RETURN NUMBER
    IS
        v_salary employees.salary%TYPE;
        v_net_salary NUMBER;
    BEGIN
        -- Get employee salary
        SELECT salary 
        INTO v_salary
        FROM employees 
        WHERE emp_id = p_emp_id;
        
        -- Calculate net salary: gross salary - RSSB tax
        v_net_salary := v_salary - calculate_rssb_tax(p_emp_id);
        
        RETURN v_net_salary;
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001, 'Employee ID ' || p_emp_id || ' not found.');
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20002, 'Error calculating net salary: ' || SQLERRM);
    END calculate_net_salary;

    /*
    ============================================================================
    PROCEDURE: update_employee_salary
    PURPOSE:  Dynamically updates employee salary and maintains audit trail
    SECURITY: Uses INVOKER rights (AUTHID CURRENT_USER)
    
    NOTES ON USER vs CURRENT_USER:
    - USER: Returns the name of the session user (who logged in)
    - CURRENT_USER: Returns the name of the user whose privileges are currently active
    - In DEFINER rights (AUTHID DEFINER), USER and CURRENT_USER are the same (package owner)
    - In INVOKER rights (AUTHID CURRENT_USER), USER is the session user, 
      CURRENT_USER is the user whose privileges are active (usually the same as USER)
    ============================================================================
    */
    PROCEDURE update_employee_salary(
        p_emp_id IN employees.emp_id%TYPE,
        p_new_salary IN employees.salary%TYPE
    )
    IS
        v_old_salary employees.salary%TYPE;
        v_sql_string VARCHAR2(1000);
        v_current_user VARCHAR2(50);
        v_session_user VARCHAR2(50);
    BEGIN
        -- Demonstrate USER vs CURRENT_USER
        v_current_user := SYS_CONTEXT('USERENV', 'CURRENT_USER');
        v_session_user := USER;
        
        DBMS_OUTPUT.PUT_LINE('Current User: ' || v_current_user);
        DBMS_OUTPUT.PUT_LINE('Session User (USER): ' || v_session_user);
        
        -- Get current salary for audit
        SELECT salary INTO v_old_salary
        FROM employees
        WHERE emp_id = p_emp_id;
        
        -- Dynamic SQL to update salary
        v_sql_string := 'UPDATE employees SET salary = :1 WHERE emp_id = :2';
        
        EXECUTE IMMEDIATE v_sql_string USING p_new_salary, p_emp_id;
        
        -- Log the change in salary_history
        INSERT INTO salary_history (emp_id, old_salary, new_salary, changed_by)
        VALUES (p_emp_id, v_old_salary, p_new_salary, USER);
        
        COMMIT;
        
        DBMS_OUTPUT.PUT_LINE('Salary updated successfully for Employee ID: ' || p_emp_id);
        DBMS_OUTPUT.PUT_LINE('Old Salary: ' || v_old_salary || ', New Salary: ' || p_new_salary);
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20003, 'Employee ID ' || p_emp_id || ' not found.');
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20004, 'Error updating salary: ' || SQLERRM);
    END update_employee_salary;

    /*
    ============================================================================
    PROCEDURE: generate_salary_report
    PURPOSE:  Generates a dynamic salary report for all employees
    SECURITY: Uses INVOKER rights (AUTHID CURRENT_USER)
    ============================================================================
    */
    PROCEDURE generate_salary_report
    IS
        v_sql_string VARCHAR2(2000);
        v_total_employees NUMBER := 0;
        v_total_salary NUMBER := 0;
        v_total_tax NUMBER := 0;
        v_total_net_salary NUMBER := 0;
    BEGIN
        -- Build dynamic SQL for the report
        v_sql_string := 
            'SELECT emp_id, emp_name, salary, ' ||
            'salary * tax_rate as tax_amount, ' ||
            'salary - (salary * tax_rate) as net_salary ' ||
            'FROM employees ORDER BY emp_id';
        
        DBMS_OUTPUT.PUT_LINE('=== SALARY REPORT ===');
        DBMS_OUTPUT.PUT_LINE('Generated by: ' || USER);
        DBMS_OUTPUT.PUT_LINE('Generated at: ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS'));
        DBMS_OUTPUT.PUT_LINE('=' || RPAD('=', 60, '='));
        DBMS_OUTPUT.PUT_LINE(RPAD('EMP ID', 10) || RPAD('NAME', 20) || 
                           RPAD('GROSS SALARY', 15) || RPAD('TAX', 15) || 'NET SALARY');
        DBMS_OUTPUT.PUT_LINE(RPAD('-', 75, '-'));
        
        -- Execute dynamic query using cursor FOR loop
        FOR rec IN (
            SELECT e.emp_id, e.emp_name, e.salary, 
                   e.salary * e.tax_rate as tax_amount,
                   e.salary - (e.salary * e.tax_rate) as net_salary
            FROM employees e 
            ORDER BY e.emp_id
        ) 
        LOOP
            DBMS_OUTPUT.PUT_LINE(
                RPAD(rec.emp_id, 10) || 
                RPAD(rec.emp_name, 20) || 
                RPAD(TO_CHAR(rec.salary, '999,999'), 15) || 
                RPAD(TO_CHAR(rec.tax_amount, '99,999'), 15) || 
                TO_CHAR(rec.net_salary, '999,999')
            );
            
            -- Calculate totals
            v_total_employees := v_total_employees + 1;
            v_total_salary := v_total_salary + rec.salary;
            v_total_tax := v_total_tax + rec.tax_amount;
            v_total_net_salary := v_total_net_salary + rec.net_salary;
        END LOOP;
        
        DBMS_OUTPUT.PUT_LINE(RPAD('-', 75, '-'));
        DBMS_OUTPUT.PUT_LINE('TOTALS:');
        DBMS_OUTPUT.PUT_LINE('Employees: ' || v_total_employees);
        DBMS_OUTPUT.PUT_LINE('Total Gross Salary: ' || TO_CHAR(v_total_salary, '999,999,999'));
        DBMS_OUTPUT.PUT_LINE('Total RSSB Tax: ' || TO_CHAR(v_total_tax, '999,999,999'));
        DBMS_OUTPUT.PUT_LINE('Total Net Salary: ' || TO_CHAR(v_total_net_salary, '999,999,999'));
        DBMS_OUTPUT.PUT_LINE('=' || RPAD('=', 60, '='));
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20005, 'Error generating report: ' || SQLERRM);
    END generate_salary_report;

    /*
    ============================================================================
    PROCEDURE: bulk_update_salaries (Optional Challenge)
    PURPOSE:  Updates salaries for all employees using bulk processing
    SECURITY: Uses INVOKER rights (AUTHID CURRENT_USER)
    ============================================================================
    */
    PROCEDURE bulk_update_salaries(
        p_percentage_raise IN NUMBER
    )
    IS
        CURSOR c_employees IS
            SELECT emp_id, salary, emp_name
            FROM employees;
            
        v_updated_count NUMBER := 0;
        v_new_salary NUMBER;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('Starting bulk salary update...');
        DBMS_OUTPUT.PUT_LINE('Percentage raise: ' || p_percentage_raise || '%');
        DBMS_OUTPUT.PUT_LINE(RPAD('-', 50, '-'));
        
        FOR emp_rec IN c_employees 
        LOOP
            -- Calculate new salary
            v_new_salary := emp_rec.salary * (1 + p_percentage_raise/100);
            
            -- Update salary using the existing procedure
            update_employee_salary(emp_rec.emp_id, v_new_salary);
            
            v_updated_count := v_updated_count + 1;
            
            DBMS_OUTPUT.PUT_LINE('Updated: ' || emp_rec.emp_name || 
                               ' (ID: ' || emp_rec.emp_id || ') - ' ||
                               'New Salary: ' || TO_CHAR(v_new_salary, '999,999'));
        END LOOP;
        
        DBMS_OUTPUT.PUT_LINE(RPAD('-', 50, '-'));
        DBMS_OUTPUT.PUT_LINE('Bulk update completed. ' || v_updated_count || ' employees updated.');
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20006, 'Error in bulk update: ' || SQLERRM);
    END bulk_update_salaries;

END hr_management_pkg;
/

