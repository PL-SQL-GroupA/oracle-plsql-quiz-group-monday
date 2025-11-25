-- Sample calls to demonstrate package functionality
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== DEMONSTRATING HR MANAGEMENT PACKAGE ===');
    DBMS_OUTPUT.PUT_LINE('');
    
    -- 1. Calculate RSSB Tax for an employee
    DBMS_OUTPUT.PUT_LINE('1. RSSB Tax Calculation for Employee ID 1:');
    DBMS_OUTPUT.PUT_LINE('RSSB Tax: ' || hr_management_pkg.calculate_rssb_tax(1));
    DBMS_OUTPUT.PUT_LINE('');
    
    -- 2. Calculate Net Salary for an employee
    DBMS_OUTPUT.PUT_LINE('2. Net Salary Calculation for Employee ID 1:');
    DBMS_OUTPUT.PUT_LINE('Net Salary: ' || hr_management_pkg.calculate_net_salary(1));
    DBMS_OUTPUT.PUT_LINE('');
    
    -- 3. Update employee salary using dynamic procedure
    DBMS_OUTPUT.PUT_LINE('3. Updating Employee Salary:');
    hr_management_pkg.update_employee_salary(1, 550000);
    DBMS_OUTPUT.PUT_LINE('');
    
    -- 4. Generate salary report
    DBMS_OUTPUT.PUT_LINE('4. Generating Salary Report:');
    hr_management_pkg.generate_salary_report();
    DBMS_OUTPUT.PUT_LINE('');
    
    -- 5. Bulk update salaries (Optional Challenge)
    DBMS_OUTPUT.PUT_LINE('5. Bulk Salary Update:');
    hr_management_pkg.bulk_update_salaries(10); -- 10% raise
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Regenerate report to see changes
    DBMS_OUTPUT.PUT_LINE('6. Salary Report After Bulk Update:');
    hr_management_pkg.generate_salary_report();
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

-- Verify the audit trail
SELECT * FROM salary_history ORDER BY change_date DESC;

-- Verify employee data
SELECT * FROM employees ORDER BY emp_id;




