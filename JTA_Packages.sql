-- Earl Tilluck
-- This is a package that contains 25 subprograms and supporting constructs for the JTA database.


/*
    01 
    Exception Package
    
    This package keeps our exceptions in on place for reference
    and gives us procedures to call, so we can raise an exception 
    and also log the exception into an error table.
*/
CREATE OR REPLACE PACKAGE jta_error
IS
    invalid_input EXCEPTION;
    PRAGMA exception_init (invalid_input, -20201);
    missing_data EXCEPTION;
    PRAGMA exception_init (missing_data, -20202);
    
    -- procedures for quick exception handling
    PROCEDURE throw (
        p_code IN NUMBER,
        p_message   IN VARCHAR2
    );
    PROCEDURE log_error (
        p_code IN NUMBER,
        p_message   IN VARCHAR2
    );
    PROCEDURE show_in_console (
        p_code IN NUMBER := NULL,
        p_message IN VARCHAR2
    );
END jta_error;
/

-- package body for jta_error
CREATE OR REPLACE PACKAGE BODY jta_error
IS

    /*
        Throw an exception, this makes coding a little simpler
    */
    PROCEDURE throw (
        p_code IN NUMBER,
        p_message   IN VARCHAR2
    )
    IS
    BEGIN
        raise_application_error(p_code, p_message);
    END;
    
    /*
        Log the exception to an error table.
        
        Most procedures will do this when exceptions occur.
        For development we will show the error in console as well.
    */
    PROCEDURE log_error (
      p_code IN NUMBER,
      p_message   IN VARCHAR2
    )
    IS
        -- autonomous transaction needed, otherwise rollback will remove log entry
        PRAGMA autonomous_transaction; 
    BEGIN
        -- show info in console, disable this line in production
        dbms_output.put_line('error logged: ' || p_message);
        -- log error into error table
        INSERT INTO jta_errors (error_id, date_time, user_name, code, message)
        VALUES (error_seq.NEXTVAL, sysdate, USER, p_code, p_message);
        COMMIT;
    END;
    
    /*
        Show an error in the console.
        
        Sometimes you don't want to log an error because it is not a
        note worthy failure, e.g. it is not a problem if no data was 
        found for a query.
        
        This procedure is available for testing purposes
    */
    PROCEDURE show_in_console (
        p_code IN NUMBER := NULL,
        p_message IN VARCHAR2
    )
    IS
    BEGIN
        dbms_output.put_line('A trivial error occured: ' || p_message);        
    END;
    
END jta_error;
/


-- JTA Package Specification
-- This package contains the main constructs for the jta database
CREATE OR REPLACE PACKAGE jta 
IS
    -- some constants
    nat_insurance_rate CONSTANT NUMBER := 0.132;
    hlt_surcharge_rate CONSTANT NUMBER := 0.005;
    
    -- public procedures and functions
    PROCEDURE process_payroll (
        p_date IN DATE
    );
    
    PROCEDURE update_inventory (
        p_product_id IN cost_sales_tracker.product_id%TYPE,
        p_quantity IN NUMBER,
        p_new_cost IN cost_sales_tracker.cost_per_unit%TYPE
    );
    
    PROCEDURE restock_urgent (
        p_staff_id IN staff.staff_id%TYPE
    );
    
    FUNCTION get_last_cashier_payout (
        p_staff_id staff.staff_id%TYPE
    ) RETURN cashier_drawer_assignments.cash_amount_end%TYPE;
    
    FUNCTION get_money_inflow (
        p_location_id locations.location_id%TYPE,
        p_start_date DATE,
        p_end_date DATE,
        p_type VARCHAR2 := 'cash'
    ) RETURN cashier_drawer_assignments.cash_amount_start%TYPE;
    
    PROCEDURE update_taxes;
    
    TYPE price_change_record IS RECORD (
        product_id products.product_id%TYPE, 
        product_name products.product_name%TYPE,
        date_changed price_history.start_date%TYPE,
        old_price price_history.price_rate%TYPE,
        new_price price_history.price_rate%TYPE, 
        direction VARCHAR2(5)
    );
    
    TYPE price_changes_table IS TABLE OF price_change_record 
    INDEX BY BINARY_INTEGER;
    
    FUNCTION get_price_changes (
        p_product_id products.product_id%type,
        p_start_date DATE,
        p_end_date DATE
    ) RETURN price_changes_table;
    
    PROCEDURE get_profits_for (
        p_start_date IN DATE,
        p_end_date IN DATE,
        p_goods_sold OUT NOCOPY NUMBER,
        p_gross_gain OUT NOCOPY NUMBER,
        p_costs OUT NOCOPY NUMBER,
        p_net_gain OUT NOCOPY NUMBER
    );
    
    PROCEDURE get_recommended_price_for (
        p_product_id IN products.product_id%TYPE,
        p_avg_cost OUT NOCOPY products.price_rate%TYPE,
        p_old_price OUT NOCOPY products.price_rate%TYPE,
        p_new_price OUT NOCOPY products.price_rate%TYPE
    );
    
    PROCEDURE evaluate_po_order_line (
        p_line_id IN purchase_order_lines.po_line_id%TYPE,
        p_not_enough_to_restock OUT NOCOPY BOOLEAN,
        p_not_at_min_level OUT NOCOPY BOOLEAN
    );
    
    PROCEDURE lookup_barcode (
        p_barcode IN VARCHAR2,
        p_product_id OUT NOCOPY products.product_id%TYPE,
        p_product_name OUT NOCOPY products.product_name%TYPE,
        p_price_rate OUT NOCOPY products.price_rate%TYPE,
        p_tax_code OUT NOCOPY tax_rates.tax_code%TYPE,
        p_tax_rate OUT NOCOPY tax_rates.tax_rate%TYPE
    );
    
    PROCEDURE update_from_bill (
        p_bill_id IN customer_bills.bill_id%TYPE
    );
    
    PROCEDURE update_sales;
    
    FUNCTION receive_payment (
        p_bill_id customer_bills.bill_id%TYPE,
        p_type customer_bills.payment_type%TYPE,
        p_amount customer_bills.payment_amount%TYPE
    ) RETURN NUMBER;
    
    PROCEDURE add_item_to_bill (
        p_bill_id IN customer_bills.bill_id%TYPE,
        p_barcode IN products.barcode%TYPE
    );
    
    FUNCTION get_tax_payment_due (
        p_tax_code tax_rates.tax_code%TYPE,
        p_year DATE
    ) RETURN NUMBER;
    
    FUNCTION get_quantity_sold (
        p_product_id products.product_id%TYPE,
        p_location_id locations.location_id%TYPE,
        p_date_start DATE,
        p_date_end DATE
    ) RETURN NUMBER;
    
    PROCEDURE stock_check (
        p_product_id IN products.product_id%TYPE,
        p_location_id IN locations.location_id%TYPE,
        p_value_counted INTEGER,
        p_in_stock OUT NOCOPY INTEGER
    );
    
    PROCEDURE sunday_check (
        p_staff_id IN staff.staff_id%TYPE,
        p_month IN DATE,
        p_sundays OUT NOCOPY INTEGER,
        p_available OUT NOCOPY BOOLEAN
    );
    
    PROCEDURE payout (
        p_staff_id IN staff.staff_id%TYPE,
        p_begin_date IN DATE,
        p_end_date IN DATE,
        p_gross_pay OUT NOCOPY payroll.gross_pay%TYPE,
        p_net_pay OUT NOCOPY payroll.net_pay%TYPE,
        p_hlt OUT NOCOPY payroll.hlt_surcharge_deduction%TYPE,
        p_nat OUT NOCOPY payroll.nat_insurance_deduction%TYPE,
        p_deductions OUT NOCOPY payroll.net_pay%TYPE
    );
    
    FUNCTION get_name (
        p_staff_id staff.staff_id%TYPE
    ) RETURN VARCHAR2;
    
    -- end specification
END jta;
/

-- JTA Package Body
CREATE OR REPLACE PACKAGE BODY jta IS


    /*
        02
        Private procedure: Get Hours
        
        Given staff_id and time period, retrieve the regular, 
        overtime and doubletime hours that a staff member has 
        worked for. 
    */    
    PROCEDURE get_hours (
        p_staff_id IN staff.staff_id%TYPE,
        start_date IN DATE,
        end_date IN DATE,
        basic OUT NOCOPY INTEGER,
        overtime OUT NOCOPY INTEGER,
        doubletime OUT NOCOPY INTEGER
    )
    IS
    BEGIN
        
        basic := 0;
        overtime := 0;
        doubletime := 0;
        
        SELECT nvl(SUM(hours_worked), 0) INTO doubletime
            FROM work_hours
            WHERE work_date BETWEEN start_date AND end_date 
            AND staff_id = p_staff_id 
            AND to_char(work_date, 'd') = '1';
            
        SELECT nvl(SUM(hours_worked), 0) INTO basic
            FROM work_hours
            WHERE work_date BETWEEN start_date AND end_date 
            AND staff_id = p_staff_id 
            AND to_char(work_date, 'd') != '1';
        
        IF basic > 40 THEN
            overtime := basic - 40;
            basic := 40;
        END IF;
            
    -- excpetions will be handled in called procedure
    END;
    

    /*
        03
        Process payroll
        
        Given any date in a week,
        retrieve the hours worked for each relevant employee from the 
        work_hours table and populate the payroll table with payroll data 
        for the week.
        
        Payroll Rules:
        > First forty hours is regular rate 
        > Above forty hours is overtime x1.5
        > Sunday is double time
        
        Note1: this query only considers basic deductions. In the real world payroll
        is far more complex, however we couldn't find enough information and didn't
        have the time to learn all Accounting practices for this organization. This 
        procedure can be modified easily to calculate other automatic deductions as needed.
    */
    PROCEDURE process_payroll (
        p_date IN DATE
    )
    IS
    
        -- date range is Sunday to Sat for this day (friday)
        v_start_date DATE := TRUNC(p_date, 'DAY');
        v_end_date DATE := v_start_date + 6 
            + numtodsinterval(23, 'hour')
            + numtodsinterval(59, 'minute')
            + numtodsinterval(59, 'second'); 
        
        -- gets a list of staff_ids for workers who worked for the week    
        CURSOR c_staff_worked 
            IS SELECT DISTINCT staff_id FROM work_hours
            WHERE work_date BETWEEN v_start_date AND v_end_date
            ORDER BY staff_id;
        
        doubletime payroll.hours_doubletime%TYPE;
        overtime payroll.hours_overtime%TYPE;
        basic payroll.hours_basic%TYPE;
        payrate staff.wage_rate%TYPE;
        gross_pay payroll.gross_pay%TYPE;
        nat_insurance_deduction payroll.nat_insurance_deduction%TYPE;
        hlt_surcharge_deduction payroll.hlt_surcharge_deduction%TYPE;
        net_pay payroll.net_pay%TYPE;
        
        v_count INTEGER := 0;
        
    BEGIN
    
        --dbms_output.put_line(to_char(v_start_date, 'yyyy-Mon-dd, HH24:MI:SS'));
        --dbms_output.put_line(to_char(v_end_date, 'yyyy-Mon-dd, HH24:MI:SS'));
    
       -- note that the procedure essentially do nothing if there are no work data for this week 
        
        -- delete rows from payroll table if they already exist with current dates
        DELETE FROM payroll WHERE payroll.start_date = v_start_date AND payroll.end_date = v_end_date;
        
        -- for each staff that worked this week
        FOR current_staff IN c_staff_worked LOOP
        
            -- get the hours each staff member worked for
            get_hours(current_staff.staff_id, v_start_date, v_end_date, basic, overtime, doubletime);
            -- get staff pay rate
            SELECT wage_rate INTO payrate FROM staff WHERE staff_id = current_staff.staff_id;
            -- calculate and save gross pay
            gross_pay := (basic * payrate) + (overtime * payrate * 1.5) + (doubletime * payrate * 2);
            -- calculate and save deductions
            nat_insurance_deduction := ROUND((gross_pay * nat_insurance_rate) / 3, 2);
            hlt_surcharge_deduction := ROUND((gross_pay * hlt_surcharge_rate), 2);
            -- calculate and save net pay
            net_pay := gross_pay - (nat_insurance_deduction + hlt_surcharge_deduction); 
            
            -- insert new row into payroll table
            INSERT INTO payroll ( 
                payroll_id, staff_id, start_date, end_date, 
                hours_basic, hours_overtime, hours_doubletime, 
                basic_pay_rate, gross_pay, 
                nat_insurance_deduction, hlt_surcharge_deduction, 
                net_pay)
            VALUES (
                payroll_id_seq.NEXTVAL, current_staff.staff_id, v_start_date, v_end_date,
                basic, overtime, doubletime,
                payrate, gross_pay,
                nat_insurance_deduction, hlt_surcharge_deduction, 
                net_pay);
            
                v_count := v_count + 1;
        END LOOP;
        
        IF v_count > 0 THEN
            COMMIT; -- commit when done and only when rows modified
        ELSE 
            -- this exception is caught but not logged since it is trivial
            jta_error.throw(-20201, 'There was no work hours recorded for this week: '
                || to_char(v_start_date, 'yyyy-Mon-dd, HH24:MI:SS') || ' to '
                || to_char(v_end_date, 'yyyy-Mon-dd, HH24:MI:SS'));
        END IF;
        
    EXCEPTION
        WHEN jta_error.invalid_input THEN
            jta_error.show_in_console(SQLCODE, SQLERRM);
            ROLLBACK;
        WHEN OTHERS THEN
            -- all OTHER exceptions will be logged into error table...
            jta_error.log_error(SQLCODE, SQLERRM);  
            ROLLBACK;
    END process_payroll;
    
    
    /*
        04
        Update Inventory
        
        Add or remove items from the overall inventory (all lcoations).
        This procedure also updates the average cost per unit whenever items are added.
        This procedure would be called whenever new items are recieved into the warehouse
        and also called for every item at the end of the day to remove items.
                
        The cost_sales_tracker table is slighlty redundant, however it improves speed when
        the supermarket needs to quickly check the inventory total for a product as well as 
        its current avg_cost_price. This is a query that is run very often in the business as
        prices change daily for the organization.
        
        p_product_id:   the product to update
        p_quantity:     the quantity to update, negative numbers for removing, positive for adding
        p_new_cost:     the cost per unit when adding new items, set to null when removing
    */
    PROCEDURE update_inventory (
        p_product_id IN cost_sales_tracker.product_id%TYPE,
        p_quantity IN NUMBER,
        p_new_cost IN cost_sales_tracker.cost_per_unit%TYPE
    )
    IS
        v_direction cost_sales_tracker.direction%TYPE := 'OUT';
        v_old_total cost_sales_tracker.total%TYPE;
        v_new_total cost_sales_tracker.total%TYPE;
        v_old_avg cost_sales_tracker.average_cost_per_unit%TYPE;
        v_new_avg cost_sales_tracker.average_cost_per_unit%TYPE;
        v_test_id products.product_id%TYPE;
        v_cost cost_sales_tracker.cost_per_unit%TYPE;
        
    BEGIN
    
        -- if zero quantity, raise error
        IF p_quantity = 0 THEN
            jta_error.throw(-20201, 'cannot update a zero amount to inventory');
        END IF;
        
        
        -- if not actual product raise error
        BEGIN
            -- see if product id exists in product table
            SELECT product_id INTO v_test_id FROM products WHERE product_id = p_product_id;
        EXCEPTION
            WHEN no_data_found THEN
                jta_error.throw(-20201, 'non existing product being updated to inventory');
            WHEN OTHERS THEN
                RAISE; -- outer procedure will deal with it
        END;
        
        
        -- get old total from db, if exists
        v_old_total := 0;
        BEGIN
            SELECT total INTO v_old_total
            FROM cost_sales_tracker
            WHERE product_id = p_product_id 
            AND transaction_id IN (
            SELECT MAX(transaction_id) FROM cost_sales_tracker WHERE product_id = p_product_id);
        EXCEPTION
            WHEN no_data_found THEN
                -- if a previous entry was not made for this product it will remain zero
                NULL; 
            WHEN OTHERS THEN
                RAISE;
        END;
        
        -- get old average if exists
        v_old_avg := 0;
        BEGIN
            SELECT average_cost_per_unit INTO v_old_avg
            FROM cost_sales_tracker
            WHERE product_id = p_product_id 
            AND transaction_id IN (SELECT MAX(transaction_id) FROM cost_sales_tracker 
            WHERE product_id = p_product_id);
        EXCEPTION
            WHEN no_data_found THEN
                -- if we never added a this product before, the old average is zero
                NULL;
            WHEN OTHERS THEN
                RAISE;
        END;
        

        -- update to new total, 
        IF p_quantity > 0 THEN
        
            -- if adding an item, the cost must be positive, otherwise it is ignored
            IF p_new_cost <= 0 OR p_new_cost IS NULL THEN
                jta_error.throw(-20201, 'cannot update inventory with non positive cost per unit');
            ELSE
                v_cost := p_new_cost;            
            END IF;
            
            -- switch direction 
            v_direction := 'IN';
            
            -- update new average
            v_new_avg := ROUND(((v_old_avg * v_old_total) + (p_quantity * p_new_cost) ) / (v_old_total + p_quantity), 2);
            
            -- calculate new total
            v_new_total := v_old_total + p_quantity; 
                
        ELSE
            -- cost is ignored if removing items,
            v_cost := NULL;
            -- average also remains the same
            
            -- reduce quantity (its a negative number)
            v_new_total := v_old_total + p_quantity; 

            -- throw error if negative
            IF v_new_total < 0 THEN
                jta_error.throw(-20201, 'cannot remove more items than already exists in inventory');
            END IF;
            
            -- set old average as new average, 
            -- if old average doesn't exist, the above negative error would have been thrown            
            v_new_avg := v_old_avg; 
            
        END IF;
        
        -- insert data into database
        INSERT INTO cost_sales_tracker (
            transaction_id, product_id, direction, date_time, quantity,
            total, average_cost_per_unit, cost_per_unit
        )
        VALUES (
            transaction_id_seq.NEXTVAL, p_product_id, v_direction, sysdate, p_quantity,
            v_new_total, v_new_avg, v_cost
        );
        
        COMMIT;
        
    EXCEPTION
        WHEN OTHERS THEN
            -- all exceptions will be logged into error table...
            jta_error.log_error(SQLCODE, SQLERRM);  
            ROLLBACK;
    END update_inventory;

    
    /*
        05
        Restock Urgent
        
        Find items that need restocking, and automatically create a purchase order for them.
        The application can then allow the user to modify the purchase order to suit or delete 
        it if they want. Items are choosen based on the re-order level stored for each product.
        
    */
    PROCEDURE restock_urgent (
        p_staff_id IN staff.staff_id%TYPE
    )
    IS 

        -- find products that need to be restocked 
        -- by checking reorder-level and min_stock_level and quantity
        -- for a specific supplier's goods and location
        CURSOR urgent(
            p_supplier_id suppliers_per_products.supplier_id%TYPE, 
            p_location_id inventory_by_location.location_id%TYPE
        ) IS
            SELECT inv.product_id, inv.reorder_level 
            FROM inventory_by_location inv
            JOIN products pr ON (inv.product_id = pr.product_id)
            JOIN suppliers_per_products sp ON (sp.product_id = pr.product_id) 
            WHERE inv.reorder_level <= (inv.min_stock_level - inv.quantity)
            AND inv.location_id = p_location_id AND sp.supplier_id = p_supplier_id;

        -- find distinct list of suppliers whose products need restocking
        CURSOR suppliers IS
            SELECT DISTINCT supplier_id, location_id
            FROM inventory_by_location inv
            JOIN products pr ON (inv.product_id = pr.product_id)
            JOIN suppliers_per_products sp ON (sp.product_id = pr.product_id) 
            WHERE inv.reorder_level <= (inv.min_stock_level - inv.quantity);
          
        -- current purchase order being worked on    
        v_current_po purchase_orders.po_id%TYPE;

    BEGIN
        
        -- for all suppliers who need restocking at each inventory location...
        FOR supplier IN suppliers LOOP
            -- create purchase orders for each supplier
            v_current_po := po_id_seq.NEXTVAL;
            INSERT INTO purchase_orders (po_id, supplier_id, staff_id, location_id, pending, approved, submitted_date)
            VALUES (v_current_po, supplier.supplier_id, p_staff_id, supplier.location_id, 'T', 'F', sysdate);

            -- add purchase order lines for this supplier
            FOR stock IN urgent(supplier.supplier_id, supplier.location_id) LOOP
                INSERT INTO purchase_order_lines (po_line_id, po_id, product_id, quantity, price_rate)
                VALUES(po_line_id_seq.NEXTVAL, v_current_po, stock.product_id, stock.reorder_level, NULL );
            END LOOP;
            
        END LOOP;
        
        COMMIT;
        
    EXCEPTION
        WHEN OTHERS THEN
            -- all exceptions will be logged into error table...
            jta_error.log_error(SQLCODE, SQLERRM);    
            ROLLBACK;
    END restock_urgent;
    
    
    /*
        06
        Get last cashier payout.
        
        This function processes all bills created by a cashier
        for his/her last shift. This function would be called 
        everytime a cashier finishes a shift in order to find out
        how much money should be recieved from them.
    */
    FUNCTION get_last_cashier_payout (
        p_staff_id staff.staff_id%TYPE
    )
    RETURN cashier_drawer_assignments.cash_amount_end%TYPE
    IS
        v_assignment_id cashier_drawer_assignments.assignment_id%TYPE;
        v_cash_sum cashier_drawer_assignments.cash_amount_end%TYPE := 0;
    BEGIN
        
        -- get last cashier assingment (shift)
        SELECT MAX(assignment_id) INTO v_assignment_id 
        FROM cashier_drawer_assignments 
        WHERE staff_id = p_staff_id;

        
        -- we can sum the bill amounts, however we do something else instead
        /*
            SELECT SUM(nvl(payment_tender, 0)) INTO v_cash_sum
            FROM customer_bills b 
            WHERE LOWER(payment_type) = 'cash' 
            AND assignment_id = v_assignment_id;
        */
        
        -- we can get the payout from the assignment table instead,
        -- this is because we have now set up the package so that this table
        -- is automatically updated when the recieve_payment procedure is called
        -- to pay a bill.
        SELECT nvl(cash_amount_end, 0) INTO v_cash_sum
        FROM cashier_drawer_assignments 
        WHERE assignment_id = v_assignment_id;
        
        -- return sum
        return v_cash_sum;
    
    EXCEPTION
        WHEN no_data_found THEN
            -- no shift for cashier, no cashier with that id etc...
            RETURN 0;
        WHEN OTHERS THEN
            -- all exceptions will be logged into error table...
            jta_error.log_error(SQLCODE, SQLERRM);
            -- return null because the function failed
            RETURN NULL;
    END get_last_cashier_payout;
    
    
    /*
        07
        Cash flow query
        
        Find the total cash amount retrieved by cashiers for a certain period
        This query is useful in determining how much cash is on hand and when to
        arrange with the bank to collect.
        Date range can be changed to reflect days, week�s months etc.
        
        The default type value of cash can be changed to non-cash to find out
        how much was gained via credit card, linx etc.
    */
    FUNCTION get_money_inflow (
        p_location_id locations.location_id%TYPE,
        p_start_date DATE,
        p_end_date DATE,
        p_type VARCHAR2 := 'cash'
    ) RETURN cashier_drawer_assignments.cash_amount_start%TYPE
    IS 
        v_cash_flow cashier_drawer_assignments.cash_amount_start%TYPE;
        v_location locations.location_id%TYPE;
    BEGIN
    
        BEGIN
            SELECT location_id INTO v_location
            FROM locations
            where location_id = p_location_id;
        EXCEPTION
            WHEN no_data_found THEN
                jta_error.throw(-20201, 'location does not exist');
        END;
        
        
        IF p_type = 'cash' THEN
            SELECT SUM(cash_amount_end) INTO v_cash_flow 
            FROM cashier_drawer_assignments cda
            JOIN cashier_stations cs ON (cs.station_id = cda.station_id)
            WHERE TRUNC(cda.start_time, 'dd') BETWEEN p_start_date AND p_end_date
            AND cs.location_id = p_location_id;
        ELSIF p_type = 'non-cash' THEN
            SELECT SUM(non_cash_tender) INTO v_cash_flow
            FROM cashier_drawer_assignments cda
            JOIN cashier_stations cs ON (cs.station_id = cda.station_id)
            WHERE TRUNC(cda.start_time, 'dd') BETWEEN p_start_date AND p_end_date
            AND cs.location_id = p_location_id;
        ELSE
            jta_error.throw(-20201, 'invalid type, valid types: cash, non-cash');
        END IF;
    
    RETURN v_cash_flow;
    
    EXCEPTION
        
        WHEN no_data_found THEN
            -- no need to log an error
            -- this means that there was no gain for that day or payment type
            RETURN 0;
        WHEN jta_error.invalid_input THEN
            -- no need to log error, will output something to console for us to see
            jta_error.show_in_console(SQLCODE, SQLERRM);
            RETURN NULL;
        WHEN OTHERS THEN
            -- all other exceptions will be logged into error table...
            jta_error.log_error(SQLCODE, SQLERRM);  
            -- return null instead of zero because of fail
            RETURN NULL;
    END get_money_inflow;

      
    /*
        08
        Update Taxes
        
        This procedure reads the pending tax rates table, and updates the tax_rates and
        tax_rate_history table to reflect the changes that should take place that day.
             
        It then deletes the pending tax rates once changes have been made.
        
        This procedure should be scheduled to run every day 6 am via dbms_scheduler.
        A similar procedure should be run for pending price changes as well. However,
        since that would just be a copy of this algorithm, we didn't bother including it.
    */
    PROCEDURE update_taxes 
    IS
        -- for update cursor, gets all changes starting today only
        CURSOR changes IS
            SELECT * FROM pending_tax_changes 
            WHERE start_date = TRUNC(SYSDATE, 'dd')
        FOR UPDATE;
    BEGIN
    
        -- open cursor and update the taxes
        FOR new_rate IN changes LOOP
            -- an exception may be raised if the tax code is the same
            -- in which case, the loop should continue in on to the next rate 
            BEGIN
                -- update the current taxes table
                UPDATE tax_rates SET
                    tax_rate = new_rate.tax_rate,
                    DESCRIPTION = new_rate.DESCRIPTION
                WHERE tax_code = new_rate.tax_code 
                AND tax_rate != new_rate.tax_rate; -- only if tax rate not the same
                
                -- if no rows updated, that means the tax rate was the same
                IF SQL%rowcount = 0 THEN
                    jta_error.throw(-20201, 'attempt to update tax to same rate');
                END IF;
                
                -- update the tax_rate_history table, set old rate to end
                UPDATE tax_rate_history SET
                    end_date = sysdate
                WHERE tax_code = new_rate.tax_code AND 
                start_date IN ( SELECT MAX(start_date) FROM tax_rate_history
                    WHERE tax_code = new_rate.tax_code);
                -- insert new rate into tax_rate_history
                INSERT INTO tax_rate_history (tax_code, start_date, end_date, tax_rate)
                VALUES (new_rate.tax_code, sysdate, NULL, new_rate.tax_rate);
            EXCEPTION
                WHEN jta_error.invalid_input THEN
                    -- log error and proceed to next row
                    jta_error.log_error(SQLCODE, SQLERRM);
            END;
        END LOOP;
        
        -- delete relevant entries from pending tax changes table
        DELETE FROM pending_tax_changes 
        WHERE start_date = TRUNC(SYSDATE, 'dd');
            
        COMMIT;
    EXCEPTION
        WHEN no_data_found THEN
            -- ignore no data found error, there are no pending changes to be made
            NULL; 
        WHEN OTHERS THEN
            -- all other exceptions will be logged into error table (not the no_data_exception)
            jta_error.log_error(SQLCODE, SQLERRM);  
            ROLLBACK; 
    END update_taxes;
    
    
    /*
        09
        Get price changes
        
        Retreive a table (not stored) containing the price changes
        that have occured for a given product within a time frame
        
        It can be used to track how a products price fluctuates over time
        for planning purposes
        
        The return type is an index by table of records, this would
        then have to be read by the application layer and displayed on screen
        or printed out somewhere.
    */
    FUNCTION get_price_changes (
        p_product_id products.product_id%type,
        p_start_date DATE,
        p_end_date DATE
    ) RETURN price_changes_table
    IS
        -- cursor, retrieves price change history for this product
        CURSOR price_changes IS
            SELECT 
                hist.product_id, 
                pr.product_name,
                hist.start_date,
                hist.price_rate
            FROM price_history hist JOIN products pr 
            ON (hist.product_id = pr.product_id)
            WHERE hist.product_id = p_product_id
            AND hist.start_date BETWEEN p_start_date AND p_end_date
            ORDER BY start_date;
        
        -- record for each change
        v_price_record price_change_record;
        
        -- return this index by table of records
        v_return_table price_changes_table;
        
        -- return empty table if exception
        v_empty price_changes_table;
        
        -- index for table
        v_index BINARY_INTEGER := 1;
    
    BEGIN
        
        FOR pc_record IN price_changes LOOP
            -- insert values into record
            v_price_record.product_id := pc_record.product_id;
            v_price_record.product_name := pc_record.product_name;
            v_price_record.date_changed := pc_record.start_date;
            v_price_record.new_price := pc_record.price_rate;
            
            -- get old price for this product change
            BEGIN 
                SELECT price_rate into v_price_record.old_price
                FROM price_history
                WHERE start_date = (
                      SELECT MAX(start_date)
                      FROM price_history
                      WHERE start_date < v_price_record.date_changed
                ) AND product_id = p_product_id;
            EXCEPTION
                WHEN no_data_found THEN
                    v_price_record.old_price := 0;
            END;
            
                
            -- calculate direcion
            IF v_price_record.new_price > v_price_record.old_price THEN
                v_price_record.direction := 'UP';
            ELSIF v_price_record.new_price < v_price_record.old_price THEN
                v_price_record.direction := 'DOWN';
            ELSE
                v_price_record.direction := '--';
            END IF;
            
            -- add to index by table of records
            v_return_table(v_index) := v_price_record;
            v_index := v_index + 1;
        END LOOP;
        
        RETURN v_return_table;
        
    EXCEPTION
        WHEN OTHERS THEN
            -- all exceptions will be logged into error table...
            jta_error.log_error(SQLCODE, SQLERRM);       
            RETURN v_empty;
    END get_price_changes;
    
    
    /*
        10
        Get profits for
        
        Retrieve total number of goods sold, and total profit for a given time period
    */
    PROCEDURE get_profits_for (
        p_start_date IN DATE,
        p_end_date IN DATE,
        p_goods_sold OUT NOCOPY NUMBER,
        p_gross_gain OUT NOCOPY NUMBER,
        p_costs OUT NOCOPY NUMBER,
        p_net_gain OUT NOCOPY NUMBER
    )
    IS
    BEGIN
        -- complex query to get values
        -- this is actually more efficient that using several cursors
        WITH avg_cost AS (
            SELECT
                bi.bill_line_id,
                bi.quantity AS "Quantity",
                bi.quantity * bi.price_rate AS "Gross Gain",
                cb.date_time_created AS "Date",
                ( SELECT average_cost_per_unit 
                    FROM cost_sales_tracker
                    WHERE date_time = (SELECT MAX(date_time)
                    FROM cost_sales_tracker
                    WHERE cb.date_time_created >= date_time AND bi.product_id = product_id)  
                ) AS "Average Cost"
            FROM billed_items bi JOIN customer_bills cb ON (cb.bill_id = bi.bill_id)
        ),
        total_cost AS (
              SELECT 
                  bi.bill_line_id,
                  bi.quantity * av."Average Cost" AS "Cost"
              FROM billed_items bi JOIN avg_cost av ON (bi.bill_line_id = av.bill_line_id)
        ),
        net_gain AS (
              SELECT  
                  av.bill_line_id,
                  av."Gross Gain" - co."Cost" AS "Net Gain"
              FROM avg_cost av JOIN total_cost co ON (av.bill_line_id = co.bill_line_id)
        )
        SELECT  
            SUM(av."Quantity"), SUM(av."Gross Gain"), SUM(co."Cost"), SUM(ng."Net Gain") 
            INTO p_goods_sold, p_gross_gain, p_costs, p_net_gain
        FROM avg_cost av JOIN total_cost co ON (av.bill_line_id = co.bill_line_id)
        JOIN net_gain ng ON (ng.bill_line_id = av.bill_line_id)
        WHERE av."Date" BETWEEN p_start_date AND p_end_date;

    EXCEPTION
        WHEN OTHERS THEN
            -- all exceptions will be logged into error table...
            jta_error.log_error(SQLCODE, SQLERRM);   
            p_goods_sold := NULL;
            p_gross_gain := NULL;
            p_costs := NULL;
            p_net_gain := NULL;
    END get_profits_for;
    
    
    /*
        11
        Get recommended price for 
        
        given a product_id, recommend a new price based on the average cost
        calculation:
            > find the average cost price from the cost sales tracker table, 
            > add a minimum markup of 30% 
            > add the correct vat rate from the tax_rate table 
            > round the value up to the nearest integer, 
            > subtracts 0.01 to produce a nice $19.99 like price
    */
    PROCEDURE get_recommended_price_for (
        p_product_id IN products.product_id%TYPE,
        p_avg_cost OUT NOCOPY products.price_rate%TYPE,
        p_old_price OUT NOCOPY products.price_rate%TYPE,
        p_new_price OUT NOCOPY products.price_rate%TYPE
    ) 
    IS
        v_avg products.price_rate%TYPE;
        v_tax tax_rates.tax_rate%TYPE;
    BEGIN
        
        -- try to get current price and average cost and perform calculations, 
        -- log our own error if doesn't exist.
        BEGIN
            SELECT price_rate, tax_rate INTO p_old_price, v_tax
            FROM products pr JOIN tax_rates tr ON (pr.tax_code = tr.tax_code)
            WHERE pr.product_id = p_product_id;
        
            SELECT average_cost_per_unit INTO v_avg
            FROM cost_sales_tracker
            WHERE transaction_id IN (SELECT 
                MAX(transaction_id) FROM cost_sales_tracker
            WHERE product_id = p_product_id);
            
            p_avg_cost := v_avg;    
            
            p_new_price := CEIL((v_avg * 1.3) 
                + (v_avg * 1.3 * (v_tax/100))) 
                - 0.01;
            
        EXCEPTION
            WHEN no_data_found THEN
            -- outside procedure will log this error insead of a generic no data found error
            jta_error.throw(-20202, 'product does not exist or has not been added to inventory');
        END;
     
    EXCEPTION
        WHEN OTHERS THEN
            -- all exceptions will be logged into error table...
            jta_error.log_error(SQLCODE, SQLERRM); 
            p_avg_cost := NULL;
            p_old_price := NULL;
            p_new_price := NULL;
    END get_recommended_price_for;
    
    
    /*
        12 
        Evalutate purchaase order line
        
        Given a purchase order line...
        Find out how much exists in the current stock, and alert if not 
        ordering enough or not ordering the recommended amount
        
        This procedure can be called from the application when a user
        is creating or viewing a purchase order, alerting them about their
        input.
    */
    PROCEDURE evaluate_po_order_line (
        p_line_id IN purchase_order_lines.po_line_id%TYPE,
        p_not_enough_to_restock OUT NOCOPY BOOLEAN,
        p_not_at_min_level OUT NOCOPY BOOLEAN
    )
    IS
        v_quantity_ordered purchase_order_lines.quantity%TYPE;
        v_in_stock inventory_by_location.quantity%TYPE;
        v_min_stock inventory_by_location.min_stock_level%TYPE;
        v_reorder_level inventory_by_location.reorder_level%TYPE;
        
    BEGIN
        
        -- get relevant data for this purchase order line        
        SELECT pol.quantity, inv.quantity, inv.min_stock_level, inv.reorder_level
        INTO v_quantity_ordered, v_in_stock, v_min_stock, v_reorder_level
        FROM purchase_order_lines pol 
        JOIN purchase_orders po ON (po.po_id = pol.po_id) 
        JOIN inventory_by_location inv ON (inv.product_id = pol.product_id AND inv.location_id = po.location_id)
        WHERE pol.po_line_id = p_line_id;
        
        IF (v_in_stock + v_quantity_ordered) < v_min_stock THEN
            p_not_enough_to_restock := TRUE;
        ELSE
            p_not_enough_to_restock := FALSE;
        END IF;
        
        IF v_quantity_ordered < v_reorder_level THEN
            p_not_at_min_level := TRUE;
        ELSE
            p_not_at_min_level := FALSE;
        END IF;
        
    EXCEPTION
        WHEN no_data_found THEN
            -- log a missing data exception
            jta_error.log_error(-20202, 'purchase not exist or inventory has never been added for this item');
            p_not_enough_to_restock := TRUE;
            p_not_at_min_level := TRUE;
        WHEN OTHERS THEN
            -- all OTHER exceptions will be logged into error table...
            jta_error.log_error(SQLCODE, SQLERRM); 
            p_not_enough_to_restock := TRUE;
            p_not_at_min_level := TRUE;
    END evaluate_po_order_line;
    
    
    /*
        13
        Lookup barcode
        
        Find the price of an item given the barcode.
        Barcodes can be international standard barcodes, or Price Lookup codes
        which contain a unique id and the price of the item in the barcode itself.
        Price lookup codes start with the number 2 and are guaranteed to not be the
        same as any official barcode.
        
        example:           
        212340012062  -- beef using price lookup, value = 12.06
        1234567879111 -- puncheon using regular barcode
        
        see appendix for more info on how barcodes work
    */
    PROCEDURE lookup_barcode (
        p_barcode IN VARCHAR2,
        p_product_id OUT NOCOPY products.product_id%TYPE,
        p_product_name OUT NOCOPY products.product_name%TYPE,
        p_price_rate OUT NOCOPY products.price_rate%TYPE,
        p_tax_code OUT NOCOPY tax_rates.tax_code%TYPE,
        p_tax_rate OUT NOCOPY tax_rates.tax_rate%TYPE
    )
    IS
    BEGIN
        /*
            SUBSTR is used to test the barcode to find if it is a PLU or not 
            and to extract the id and price if needed.
        */
        IF SUBSTR(p_barcode, 1, 1) = '2' THEN
            -- price rate is calculated from the barcode itself
            p_price_rate := TO_NUMBER(SUBSTR(p_barcode, 7, 5)/100);
            -- get id and name from products table
            SELECT pr.product_id, pr.product_name, tr.tax_code, tr.tax_rate 
            INTO p_product_id, p_product_name, p_tax_code, p_tax_rate
            FROM products pr JOIN tax_rates tr ON (pr.tax_code = tr.tax_code) 
            WHERE price_lookup_code = SUBSTR(p_barcode, 1, 5);
        ELSE
            -- regular look up from products table
            SELECT pr.product_id, pr.product_name, pr.price_rate, tr.tax_code, tr.tax_rate
            INTO p_product_id, p_product_name, p_price_rate, p_tax_code, p_tax_rate
            FROM products pr JOIN tax_rates tr ON (pr.tax_code = tr.tax_code) 
            WHERE barcode = p_barcode;
        END IF;
        
    EXCEPTION
        WHEN no_data_found THEN
            -- log a missing data exception instead of no data exception
            jta_error.log_error(-20202, 'price look up for item that does not exist');
            p_product_id := NULL;
            p_product_name := NULL;
            p_price_rate := NULL;
            p_tax_code := NULL;
            p_tax_rate := NULL;
        WHEN OTHERS THEN
            -- all OTHER exceptions will be logged into error table...
            jta_error.log_error(SQLCODE, SQLERRM);
            p_product_id := NULL;
            p_product_name := NULL;
            p_price_rate := NULL;
            p_tax_code := NULL;
            p_tax_rate := NULL;
    END lookup_barcode;
    
    
    /*
        14
        Update from bill
        
        Given a bill (which has just been approved and cashed),
        remove the items on the bill from inventory at that location,
        then update products sold table to relect changes.
    */
    PROCEDURE update_from_bill (
        p_bill_id IN customer_bills.bill_id%TYPE
    )
    IS 
        -- products, and their inventory location from current bill
        CURSOR items_in_bill IS
            SELECT bit.product_id, inv.location_id, bit.quantity, pr.barcode 
            FROM billed_items bit 
            JOIN customer_bills cb ON (bit.bill_id = cb.bill_id)
            JOIN products pr ON (pr.product_id = bit.product_id)
            JOIN cashier_drawer_assignments cda ON (cda.assignment_id = cb.assignment_id)
            JOIN cashier_stations cs ON (cs.station_id = cda.station_id)
            JOIN inventory_by_location inv ON (cs.location_id = inv.location_id 
                AND bit.product_id = inv.product_id)
            WHERE cb.bill_id = p_bill_id
            FOR UPDATE OF inv.quantity; -- for update lock to prevent issues
                
    BEGIN
    
        FOR item IN items_in_bill LOOP
            -- if the product is not a plu item then we track it in inventory 
            -- (see barcode info in document appendix)
            IF item.barcode IS NOT NULL THEN
            
                -- if one item throws an excpetion, we still want to 
                -- proceed through the cursor to other items
                -- hence, we have this sub-block to catch exceptions here
                BEGIN
                    -- updates don't throw errors if 0 rows updated
                    UPDATE inventory_by_location SET
                        quantity = quantity - item.quantity
                    WHERE product_id = item.product_id AND location_id = item.location_id;
                    -- throw error if didn't update anything
                    IF SQL%rowcount = 0 THEN
                        jta_error.throw(-20202, 'product not in inventory');
                    END IF;
                    -- insert into sold products, 
                    -- only inserts if above exception was not thrown
                    INSERT INTO sold_products (sold_products_id, product_id, quantity)
                    VALUES (sold_products_seq.NEXTVAL, item.product_id, item.quantity);
                EXCEPTION
                    WHEN OTHERS THEN
                        -- log all errors regardless of type (including 20202)
                        jta_error.log_error(SQLCODE, SQLERRM);
                        -- then proceed through cursor
                END;
            END IF;
        END LOOP;
        
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            -- all OTHER exceptions will be logged into error table as well
            jta_error.log_error(SQLCODE, SQLERRM);
            ROLLBACK; -- roll back only if something terrible happened
    END update_from_bill;
    
    
    
    /*
        15
        Update sales
        
        Update the cost_sales_tracker using the update_inventory
        procedure (procedure 04) with data from sold_products.
        
        This updates the inventory for all locations from the sold_products table.
        
        Sold_products is updated after every bill transaction (customer pays for goods).
        This procedure should run once at the end of the day to perform its update.
        
        A few tables are locked during this procedure, as there may be concurrency issues 
        (updating sold_products while running this procedure).
    */
    PROCEDURE update_sales 
    IS 
        -- current date to add cost_sales_tracker
        v_date DATE := sysdate;
        
        -- index by to bulk collect all products sold
        TYPE v_sold_products IS TABLE OF sold_products%ROWTYPE 
        INDEX BY BINARY_INTEGER;
        v_all v_sold_products;
        
        -- collection to hold sum of quantities
        TYPE v_sum_type IS TABLE OF sold_products.quantity%TYPE
        INDEX BY BINARY_INTEGER;
        v_sum v_sum_type;
        
        -- hold current quantity from collection
        v_current_sum sold_products.quantity%TYPE;
        v_current_product sold_products.product_id%TYPE;
    BEGIN
        -- perform a commit, 
        -- if application freezes and a rollback is needed because we 
        -- locked a bunch of tables without unlocking them, it will rollback
        -- to this point. 
        COMMIT;
        
        -- lock the tables before doing anything
        LOCK TABLE sold_products, customer_bills, billed_items IN EXCLUSIVE MODE NOWAIT;
    
        -- bulk collect all rows
        SELECT * BULK COLLECT INTO v_all FROM sold_products 
        ORDER BY product_id;
        -- loop through all and records and sum up products quantities 
        -- into v_sum collection
        FOR indx IN v_all.FIRST..v_all.LAST LOOP
            -- try to update v_sum as if it already has an entry for this product
            BEGIN
                v_current_product := v_all(indx).product_id;
                v_current_sum := v_sum(v_current_product);
                v_sum(v_current_product) := v_current_sum + v_all(indx).quantity;
            EXCEPTION
                -- if the above throws a no data found exception,
                -- it means we didn't have an entry before,
                -- now we insert a new one like normal
                WHEN no_data_found THEN
                v_sum(v_all(indx).product_id) := v_all(indx).quantity;
            END;
            --dbms_output.put_line(v_all(indx).product_id || ' - ' || v_sum(v_all(indx).product_id) );
        END LOOP;
        
        -- update inventory
        FOR indx IN v_sum.FIRST..v_sum.LAST LOOP
            --dbms_output.put_line(indx || ' - ' || (v_sum(indx) * -1) );
            update_inventory (indx, (v_sum(indx) * -1), NULL);
        END LOOP;
        
        -- remove all entries from sold_products table
        DELETE FROM sold_products;
        
        -- a commit here or a rollback in the excpetion will unlock all the locked tables
        COMMIT;
    EXCEPTION
        WHEN no_data_found THEN
        -- there was nothing to update, this isn't an error per se
        dbms_output.put_line('*alert application layer*, there was no data to update');
        WHEN OTHERS THEN
            -- all exceptions will be logged into error table regardless
            jta_error.log_error(SQLCODE, SQLERRM);
            ROLLBACK; 
    END update_sales;
    
    
    /*
        16 
        Add item to bill
        
        Given bill id and a barcode...
        Update the bill with item, update its due value.
        The procedure ensures you cannot update a bill that has been 
        already paid for.
    */
    PROCEDURE add_item_to_bill (
        p_bill_id IN customer_bills.bill_id%TYPE,
        p_barcode IN products.barcode%TYPE
    )
    IS 
        
        v_price products.price_rate%TYPE;
        v_product_id products.product_id%TYPE;
        v_tax_code tax_rates.tax_code%TYPE;
        v_tax_rate tax_rates.tax_rate%TYPE;
        v_line_id billed_items.bill_line_id%TYPE := NULL;
        v_bill_id customer_bills.bill_id%TYPE;
        
        -- not used in this function, but retrieved in lookup_barcode procedure
        v_name products.product_name%TYPE;
        
        
    BEGIN 
        -- if bill already paid or pending then throw exception,
        BEGIN
            SELECT bill_id INTO v_bill_id 
            FROM customer_bills 
            WHERE bill_id = p_bill_id AND payment_status = 'unpaid'; 
                -- exception thrown here if status not unpaid
                -- payment_status column constrained to paid, pending and unpaid via DDL 
        EXCEPTION
            WHEN no_data_found THEN
                jta_error.throw(-20201, 'failed to update bill items because bill status not unpaid');
        END;
        
        -- find price and tax info using lookup_barcode procedure
        jta.lookup_barcode (p_barcode, v_product_id, v_name, v_price, v_tax_code, v_tax_rate);
        -- test if item already in bill 
        -- the same item may be cashed several times e.g. customer buys to sacks of flour
        BEGIN
            -- query billed_items to see if this product exists for this bill
            SELECT bill_line_id INTO v_line_id 
            FROM billed_items 
            WHERE product_id = v_product_id AND bill_id = p_bill_id;
        EXCEPTION
            WHEN no_data_found THEN 
                NULL; -- ignore and proceed
        END; 
        
        -- item alread exists, will update its quantity
        IF v_line_id IS NOT NULL THEN
            UPDATE billed_items SET
                quantity = quantity + 1
            WHERE bill_line_id = v_line_id;
            
        -- otherwise, insert new item for this product
        ELSE
            INSERT INTO billed_items (
                bill_line_id, bill_id, product_id, quantity, 
                price_rate, tax_code, tax_rate
            )
            VALUES (
                bill_line_id_seq.NEXTVAL, p_bill_id, v_product_id, 1,
                v_price, v_tax_code, v_tax_rate
            );
        END IF;
        
        -- update price of bill,
        UPDATE customer_bills SET
            payment_tender = nvl(payment_tender, 0) + v_price
        WHERE bill_id = p_bill_id;

        COMMIT;
    EXCEPTION
        WHEN jta_error.invalid_input THEN
            -- this code can change to invoke an application layer event or something...
            jta_error.show_in_console(SQLCODE, SQLERRM);
            ROLLBACK;
        WHEN OTHERS THEN
            -- all OTHER exceptions will be logged into error table regardless
            jta_error.log_error(SQLCODE, SQLERRM);
            ROLLBACK;
    END add_item_to_bill;
    
    
    
    /*
        17 
        Receive payment for bill
        
        Given bill id, recieve payment for it
        and update the cashiers shift data.
        
        This function returns NULL if the transaction function failed
        or a number for the amount of money to pay a customer as change.
        
        It is an autonomous transaction.
    */
    FUNCTION receive_payment (
        p_bill_id customer_bills.bill_id%TYPE,
        p_type customer_bills.payment_type%TYPE,
        p_amount customer_bills.payment_amount%TYPE
    ) RETURN NUMBER
    IS 
        -- this function performs DML, therefore it is set to autonomous
        -- that way it won't cause issues like committing during a query
        PRAGMA autonomous_transaction;
        
        -- hold amount due
        v_tender customer_bills.payment_tender%TYPE;
        -- hold previous payment if exists
        v_prev customer_bills.payment_amount%TYPE;
        -- hold cashier assigned to bill
        v_assignment customer_bills.assignment_id%TYPE;
        -- return cash amount (change for customer)
        v_return_change NUMBER := 0;
        -- hold status of this bill
        v_status customer_bills.payment_status%TYPE;
        -- update inventory after payment received?
        v_do_update_inventory BOOLEAN := TRUE;
        
    BEGIN 
        
        -- check payment type, throw (raise) error if not valid
        IF p_type NOT IN ('cash', 'cheque', 'creditcard', 'linx') THEN
            jta_error.throw(-20201, 'invalid payment type, valid types: cash, cheque, creditcard, linx');
        END IF;
    
        -- get tender (amount due) from bill
        SELECT assignment_id, nvl(payment_tender, 0), nvl(payment_amount, 0), nvl(payment_status, 'unpaid') 
        INTO v_assignment, v_tender, v_prev, v_status
        FROM customer_bills WHERE bill_id = p_bill_id;
        
        -- check if already paid, throw (raise) error if it did
        IF v_status = 'paid' THEN
            -- throw (raise) invalid input error
            jta_error.throw(-20201, 'attempt to pay on bill that has already received full payment');
        end if;
        
        -- check if amount is valid, change status depending on if full amount is paid
        IF p_amount <= 0 THEN
            -- throw (raise) invalid input error
            jta_error.throw(-20201, 'invalid money amount, negative number');
        end if;
        
        -- check if bill is pending (has previous payment on it)
        IF v_status = 'pending' THEN
            -- amount due is now less
            v_tender := v_tender - v_prev;
            v_do_update_inventory := FALSE; -- no need to remove items from inventory
        END IF;
        
        -- perform new payment calculation
        IF p_amount < v_tender THEN
            -- no change given, however bill is set to pending...
            -- this means that the customer owes the supermaket money
            -- sometimes they let frequent customers do this if they forget their wallet etc.
            -- the goods are usually kept at the grocery (in a special area) until the full amount is paid
            -- or sometimes they will let the customer leave with the goods if they the owners trust them.
            v_status := 'pending';
        ELSE
            v_status := 'paid';
            -- calculate change, 
                -- **note: although non cash payments usually do not have change,
                -- sometimes a customer will request to pay more than the bill amount in order to receive change.
                -- otherwise the exact value is processed, which results in zero change here.
            v_return_change := p_amount - v_tender;
        END IF;    
        
        -- update bill with payment
        UPDATE customer_bills SET
            payment_amount = v_prev + (p_amount - v_return_change),
            payment_type = p_type,
            payment_status = v_status,
            date_time_paid = sysdate
        WHERE bill_id = p_bill_id;
        
        -- if paying in cash, update cashier's cash on hand
        IF p_type = 'cash' THEN
            -- update cashier cash amount on hand
            UPDATE cashier_drawer_assignments SET
                cash_amount_end = nvl(cash_amount_end, 0) + (p_amount - v_return_change)
            WHERE assignment_id = v_assignment;
        
        -- if non-cash, then update non_cash_tender
        ELSE
            UPDATE cashier_drawer_assignments SET
                non_cash_tender = nvl(non_cash_tender, 0) + p_amount,
                cash_amount_end = nvl(cash_amount_end, 0) - v_return_change
            WHERE assignment_id = v_assignment;
        END IF;
        
        -- MAGIC!! call procedure to update inventory for bill, only if status was not pending
        IF v_do_update_inventory THEN
            jta.update_from_bill(p_bill_id);
        END IF;
        
        COMMIT;
        RETURN v_return_change;
    EXCEPTION 
        WHEN jta_error.invalid_input THEN
            -- if amount is less than payment, then this error isn't logged,
            -- however the application layer should be alerted.
            jta_error.show_in_console(SQLCODE, SQLERRM);
            ROLLBACK;
            RETURN NULL;
        WHEN OTHERS THEN
            -- all exceptions will be logged into error table regardless
            jta_error.log_error(SQLCODE, SQLERRM);
            ROLLBACK; 
            RETURN NULL;
    END receive_payment;
    
    
    /*
        18
        Get tax payments due
        
        Find out tax payments due for a specified year.
        
        Any date can be passed in, taxes are processed for the period 
        Jan 1st to Dec 31st for that year.
        
        You can pass in different tax_rates to find out payments due for those,
        if you have a combo tax_rate like vat plus luxury tax, then the amount
        retrieved will have to be divided into the seperate rates accordingly.
        
        Currently there is only one tax that the company deals with at the product level (VAT), 
        if this changes in the future, this can be run for other tax rates and then processed 
        by an accountant accordingly or a procedure can be made to do all the calulations automatically.  
    */
    FUNCTION get_tax_payment_due (
        p_tax_code tax_rates.tax_code%TYPE,
        p_year DATE
    ) RETURN NUMBER
    IS 
        v_begin DATE;
        v_end DATE;
        v_tax_value NUMBER;
    BEGIN 
        -- sysdate can be passed in to find out for this year, 
        -- therefore we need to find the begin and end for the year provided
        v_begin := TRUNC(p_year, 'YEAR');
        -- for end, we add 12 months, then subract one day
        -- then add 23 hours, 59 mins and 59 seconds
        v_end := add_months(v_begin, 12); 
        v_end := v_end - 1;
        v_end := v_end + numtodsinterval(23, 'hour');
        v_end := v_end + numtodsinterval(59, 'minute');
        v_end := v_end + numtodsinterval(59, 'second'); 
            -- since we don't use timestamps, we don't have to add milliseconds.
            -- it was decided that bills, payroll and other transactions only needed 
            -- to record up the the seconds time frame and there is no security or 
            -- liability difference between 11:50:59.0000 and 11:50:59.9999

        -- get tax value from querying bills        
        SELECT SUM(ROUND(((tax_rate/100) * (price_rate * quantity)), 2))
        INTO v_tax_value
        FROM billed_items bi JOIN customer_bills cb ON (bi.bill_id = cb.bill_id)
        WHERE cb.date_time_created BETWEEN v_begin AND v_end
        AND bi.tax_code = p_tax_code;
        
        RETURN v_tax_value;
        
        /*
            Development Note:
            since this query is likely to end up processing millions of rows,
            it will probably be very slow and should run after business hours.
            
            thankfully, the company usually closes for stock taking during 
            the new years holdiday, at which time they do these kinds of queries.
            
            Further note: 
            bulk collect may not solve this issue since it is aggregate function 
            (one context switch). One possible solution is to modify the database 
            to use plsql to save tax payout in a table everytime a bill is processed.
            much like the sold_products table. However, they might not want the day to day 
            overhead and would most likely double check billed_items anyway. 
        */
    EXCEPTION 
        WHEN no_data_found THEN
            -- return zero if no data, 
            -- this means the supermarket didn't sell anything for that year (incorrect date provided?)
            RETURN 0;
        WHEN OTHERS THEN
            -- log error and return null if other exceptions occur
            jta_error.log_error(SQLCODE, SQLERRM);
            RETURN NULL;
    END get_tax_payment_due;
    
    
    /*
        19
        Get quantity sold
        
        A useful function to get quantity of item sold at a location
        given a time period. 
        It can be used to analyze sale trends and so on.

        We query billed_items because the sold_products table gets emptied 
        when inventory is updated
    */
    FUNCTION get_quantity_sold (
        p_product_id products.product_id%TYPE,
        p_location_id locations.location_id%TYPE,
        p_date_start DATE,
        p_date_end DATE
    ) RETURN NUMBER
    IS 
        v_quantity NUMBER;
    BEGIN
    
        -- raise our own invalid input error if product id or location id not in database
        DECLARE
            v_product products.product_id%TYPE;
            v_location locations.location_id%TYPE;
        BEGIN
            -- check if product id in db
            SELECT product_id INTO v_product
            FROM products
            WHERE product_id = p_product_id;
            -- check if location id in db
            SELECT location_id INTO v_location
            FROM locations
            WHERE location_id = p_location_id;
            
        EXCEPTION
            WHEN no_data_found THEN
                -- raise this instead of no data, for these conditions
                jta_error.throw(-20201, 'invalid location or product id when finding quantity sold');
        END;
        
        SELECT SUM(quantity) 
        INTO v_quantity
        FROM billed_items bi JOIN customer_bills cb USING (bill_id)
        JOIN cashier_drawer_assignments cda USING (assignment_id)
        JOIN cashier_stations cs USING (station_id)
        WHERE cb.date_time_created BETWEEN p_date_start AND p_date_end
        AND cs.location_id = p_location_id and bi.product_id = p_product_id;
    
        RETURN v_quantity;
    EXCEPTION
        WHEN no_data_found THEN
            -- this item did not sell at this location during time period
            RETURN 0;
        WHEN jta_error.invalid_input THEN
            -- application alert, this can be modified to do something else instead
            -- no need to log this error.
            jta_error.show_in_console(SQLCODE, SQLERRM);
            RETURN NULL;
        WHEN OTHERS THEN
            -- log error and return null if other exceptions occur
            jta_error.log_error(SQLCODE, SQLERRM);
            RETURN NULL;
    END get_quantity_sold;
    
    
    /*
        20 
        Stock check
        
        When checking stock at the end of the year,
        compare value in database with the actual stock counted.
        Update the missing items table as well as the 
        inventory by location table and cost sale tracker
        
        For convenience it returns an out value 
        to show how much was reported in stock
    */
    PROCEDURE stock_check (
        p_product_id IN products.product_id%TYPE,
        p_location_id IN locations.location_id%TYPE,
        p_value_counted INTEGER,
        p_in_stock OUT NOCOPY INTEGER
    )
    IS 
        v_difference INTEGER;
    BEGIN
        
        -- get current in stock for product by location
        -- product_id and location_id make up a composite key
        -- therefore we don't need to worry about too many rows
        SELECT quantity INTO p_in_stock
        FROM inventory_by_location
        WHERE product_id = p_product_id 
        AND location_id = p_location_id;
        
        
        IF p_in_stock > p_value_counted THEN
            -- there are missing items...
            
            v_difference := p_in_stock - p_value_counted;
            
            -- insert missing items into table
            INSERT INTO missing_items (m_item_id, product_id, date_recorded, quantity)
            VALUES (m_item_id_seq.nextval, p_product_id, sysdate, v_difference);
            
            v_difference := v_difference * -1;
            
            -- update the inventory to reflect the counted stock value
            UPDATE inventory_by_location SET
                quantity = p_value_counted
            WHERE product_id = p_product_id AND location_id = p_location_id;
            
            -- call update inventory and pass in a negative value for this product.
            jta.update_inventory(p_product_id, v_difference, NULL);
            
        /* 
        ELSIF p_in_stock < value_counted
            -- what happens when you have more than what you expect
            -- in inventory. currently we don't do anything but this 
            -- comment is here to show that something could be done
        */
        END IF;
        
    EXCEPTION 
        WHEN no_data_found THEN
            -- select statment failed because item/location doesn't exist
            -- or there was no inventory data for the item
            p_in_stock := NULL;
            jta_error.show_in_console(SQLCODE, SQLERRM);
        WHEN OTHERS THEN
            -- log error and return null if other exceptions occur
            jta_error.log_error(SQLCODE, SQLERRM);
            p_in_stock := NULL;
    END stock_check;
    
    
    /*
        21 
        Sunday Check,
        
        Find the number of Sundays an employee has worked so far in 
        a given month. Employees are only allowed to work 2 Sundays for 
        the month.
        
        It also lets you know if they are available to work on Sunday or not.
    */
    PROCEDURE sunday_check (
        p_staff_id IN staff.staff_id%TYPE,
        p_month IN DATE,
        p_sundays OUT NOCOPY INTEGER,
        p_available OUT NOCOPY BOOLEAN
    )
    IS
        -- work days for this staff memeber, for month begin to end
        CURSOR work_days IS
            SELECT * FROM work_hours 
            WHERE staff_id = p_staff_id
            AND work_date BETWEEN TRUNC(p_month, 'MONTH') 
            AND add_months(TRUNC(p_month, 'MONTH'), 1) -1;
    BEGIN

        p_sundays := 0;
        p_available := TRUE;
        
        -- find sundays for the month
        FOR work_day IN work_days LOOP
            IF to_char(work_day.work_date, 'd') = '1' THEN
                p_sundays := p_sundays + 1;
            END IF;
        END LOOP;
        
        -- check if available to work another sunday
        IF p_sundays >= 2 THEN
            p_available := FALSE;
        END IF;
        
    EXCEPTION
        WHEN no_data_found THEN
            p_sundays := 0;
            p_available := TRUE;
        WHEN OTHERS THEN
            jta_error.log_error(SQLCODE, SQLERRM);
            p_sundays := NULL;
            p_available := NULL;
    END sunday_check;
    
        
    /*
        22 
        payout
        
        Get payout for employee for a specifed period.
        This procedure returns the national insurance and
        hlt surchage deductions for that employeee as well.
        
        This data is usefull for reporting and paying employee
        related payments and taxes.
    */
    PROCEDURE payout (
        p_staff_id IN staff.staff_id%TYPE,
        p_begin_date IN DATE,
        p_end_date IN DATE,
        p_gross_pay OUT NOCOPY payroll.gross_pay%TYPE,
        p_net_pay OUT NOCOPY payroll.net_pay%TYPE,
        p_hlt OUT NOCOPY payroll.hlt_surcharge_deduction%TYPE,
        p_nat OUT NOCOPY payroll.nat_insurance_deduction%TYPE,
        p_deductions OUT NOCOPY payroll.net_pay%TYPE
    )
    IS 
    BEGIN 
        
        -- select the sum of gross and net pay from payroll
        -- if date_recieved is null, that means the pay hasn't been collected yet
        SELECT SUM(gross_pay), SUM(net_pay), SUM(hlt_surcharge_deduction), SUM(nat_insurance_deduction)
        INTO p_gross_pay, p_net_pay, p_hlt, p_nat
        FROM payroll
        WHERE staff_id = p_staff_id
        AND date_staff_received BETWEEN p_begin_date AND p_end_date;
        
        -- calculate deductions
        p_deductions := p_hlt + p_nat;
        
    EXCEPTION 
        WHEN no_data_found THEN
            -- staff didn't work? doesn't exist? 
            p_gross_pay := 0;
            p_net_pay := 0;
            p_deductions := 0;
            -- no need worry about too many rows because select uses aggregate function
        WHEN OTHERS THEN
            jta_error.log_error(SQLCODE, SQLERRM);
            p_gross_pay := NULL;
            p_net_pay := NULL;
            p_deductions := NULL;
    END payout;
    
    
    /*
        minor extra functions for debug etc...
    */
    FUNCTION get_name (
        p_staff_id staff.staff_id%TYPE
    ) RETURN VARCHAR2
    IS 
        v_return VARCHAR2(100);
    BEGIN
        SELECT first_name || ' ' || last_name INTO v_return
        FROM staff WHERE staff_id = p_staff_id;
        
        RETURN v_return;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 'Unknown';
    END get_name;
    
-- end of jta package body    
END jta;
/




/*
    23 trigger, update job history when staff job_id changes
    
    note1: because start_date is part of the primary key, the trigger will
    fail if the datetime is the same, therefore when testing, wait
    at least one second between updating job_ids for the same staff 
    memeber. (we use sysdate to insert/update the rows)
    
    note2: even though this seems useful, it is probably better to 
    have a procedure similar to update_taxes that handles this without 
    the trigger because we shouldn't use triggers to do things we can
    usually do in regualr plsql. We kept this in here to demonstrate 
    that it could be done this way if we wanted.
*/
CREATE OR REPLACE TRIGGER update_job_history_trigger
AFTER INSERT OR UPDATE OF job_id ON staff FOR EACH ROW
WHEN (NEW.job_id != OLD.job_id)
BEGIN
    -- update the old job end date to today
    UPDATE job_posts_history SET
        date_ended = sysdate 
    WHERE staff_id = :OLD.staff_id AND job_id = :OLD.job_id;
    -- if no rows updated then this is an employee without a history (first job)
    -- updates don't throw exceptions if no rows updated
    
    -- insert new job with today as startdate and null and end date
    INSERT INTO job_posts_history (staff_id, job_id, date_started, date_ended)
    VALUES (:OLD.staff_id, :NEW.job_id, sysdate, NULL);
END update_job_history_trigger;
/

/*
    24 
    email the purchasing department staff
    if an item is close to running out
    (quantity reaches min_stock_level)
    
    note: triggers are fired once per transaction,
    the database is usually committed after an inventory update
    however for testing, ensure that everytime you update
    the inventory table, you commit afterwards.
    
*/
CREATE OR REPLACE TRIGGER email_on_inv_trigger
AFTER UPDATE OF quantity ON inventory_by_location FOR EACH ROW
WHEN (NEW.quantity < OLD.quantity) -- only when quanitity is being decreased
BEGIN
    -- need an inner block to declare variables in triggers
    DECLARE
        v_email VARCHAR2(50);
        v_product_name products.product_name%TYPE;
        v_subject VARCHAR2(200);
        v_message VARCHAR2(200);
    BEGIN
        
        -- we only want this trigger to work when we have reduced the quantity from above min stock level
        -- to a value below min stock level, otherwise we will send emails everytime an item
        -- is sold and our stock is below the min stock level
        
        -- only if we had enough items before, but now the quanity has droped below min_stock_level ...
        IF :OLD.quantity > :old.min_stock_level and :NEW.quantity < :NEW.min_stock_level THEN
            
            -- set the recipient email to the department at that location
            IF :OLD.location_id = 10 OR :OLD.location_id = 12 THEN
                v_email := 'carlton_center_purchasing@jta.com';
            ELSIF :OLD.location_id = 11 THEN
                v_email := 'marabella_purchasing@jta.com';
            END IF;
        
            SELECT product_name INTO v_product_name 
            FROM products WHERE product_id = :OLD.product_id;
            
            -- set subject and message        
            v_subject := 'subject: purchase needed for: ' || v_product_name;
            v_message := 'instock = ' || :NEW.quantity
                        || ', min stock level = ' || :OLD.min_stock_level
                        || ', reorder level = ' || :OLD.reorder_level;
        
            -- utl_mail is not available on apex and not installed by default when installing oracle locally
            -- therefore we output to console instead 
            dbms_output.put_line(' ');
            dbms_output.put_line('---------------------------------------');
            dbms_output.put_line('restock trigger activated');
            dbms_output.put_line ('the following email will be sent'); 
            dbms_output.put_line ('from:  database@jta.com');
            dbms_output.put_line ('to: ' || v_email);
            dbms_output.put_line ('subject: ' || v_subject);
            dbms_output.put_line ('message: ' || v_message);
            dbms_output.put_line('---------------------------------------');
            dbms_output.put_line(' ');

            -- utl mail package code
            -- we have this disabled, otherwise the trigger won't compile.
            -- to test the trigger, utl_mail will have to be installed and configured to work
            
            /*                        
            utl_mail.send(
                'database@jta.com', 
                v_email, 
                message => v_message,
                subject =>  v_subject);
            */
            
        END IF;
    EXCEPTION 
        WHEN OTHERS THEN
            jta_error.log_error(SQLCODE, SQLERRM);
    END;
END email_on_inv_trigger;
/

/*
    25 database event triggers
    The purpose of these database event triggers is to log
    users logging into and out of the database
*/
CREATE OR REPLACE TRIGGER logon_trigger
AFTER LOGON ON SCHEMA
BEGIN
    -- log event
    INSERT INTO jta_events (event_id, user_name, date_time, event, ip_address)
    VALUES (event_seq.nextval, USER, SYSDATE, ora_sysevent, ora_client_ip_address);
    
    COMMIT;
    
    /*
        if user logged in from strange ip address we can raise an
        application error and perform additional steps if needed
    */
    DECLARE
        v_ip VARCHAR2(20);
    BEGIN
        -- find if ip is in authorized_ip_addresses table 
        SELECT ip_address INTO v_ip FROM authorized_ip_adresses 
        WHERE ip_address = ora_client_ip_address;
    EXCEPTION
        WHEN no_data_found THEN
            NULL;
            --raise_application_error(-20900, 'Unauthorized Access');
            -- additional code
            
            -- note: code here disabled becuase we are in a dev environment
            -- in production we can alert IT staff, shutdown the db 
            -- through dbms_scheduler or do other tasks.
    END;
EXCEPTION
    WHEN OTHERS THEN
        jta_error.log_error(SQLCODE, SQLERRM);    
END logon_trigger;
/

CREATE OR REPLACE TRIGGER logoff_trigger
BEFORE LOGOFF ON SCHEMA 
BEGIN
    -- log event
    INSERT INTO jta_events (event_id, user_name, date_time, event, ip_address)
    VALUES (event_seq.nextval, USER, SYSDATE, ora_sysevent, NULL);
    
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        jta_error.log_error(SQLCODE, SQLERRM);     
END logoff_trigger;
/