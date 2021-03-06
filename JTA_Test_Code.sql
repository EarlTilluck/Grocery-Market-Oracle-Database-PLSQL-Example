-- Earl Tilluck
-- Franze Khan
-- Ann Rose Regis
-- These anonymous blocks can be used to run and test each procedure/function in the jta package.
-- Note: These are *quick and dirty* blocks of code for testing only, 

/* 
    01 exception package: this is tested throughout 
    the jta package.
*/

/*
    02 get hours, this is a private procedure that 
    is used as part of procedure 03 and can be used
    elsewhere.
    
*/

/*
    03 payroll
*/
    BEGIN
        -- process payroll for week without data
        jta.process_payroll(TO_DATE('2015-05-13', 'yyyy-mm-dd'));
        -- throws an exception which is displayed and but not logged to error table
    END;
    /
    BEGIN
        -- process payroll for week with sample data
        jta.process_payroll(TO_DATE('2015-03-13', 'yyyy-mm-dd'));
        -- sample data for this week will be processed
    END;
    /
    
    -- check payroll table to see three additions to it: 
    SELECT * FROM payroll;


/*
    04 update inventory
    note: this is called in procedure 15
*/
    -- preview cost sales tracker table
    SELECT * FROM cost_sales_tracker;
    
    BEGIN
        -- add 200 of product 1 at $175 each
        jta.update_inventory(1, 200, 175);
        -- remove 100 of the same product 
        jta.update_inventory(1, -100, NULL);
    END;
    /
    
    -- see changes to cost sales tracker table
    SELECT * FROM cost_sales_tracker;

    BEGIN
        -- test bad input...
        -- product doesn't exist
        jta.update_inventory(9, 200, 175);
        -- bad input, zero products
        jta.update_inventory(1, 0, 175);
        -- bad input, null price when adding
        jta.update_inventory(1, 200, NULL);
    END;
    /

    -- check error table to see logs of above error
    SELECT * FROM jta_errors;


/*
    05 restock urgent
*/
    -- preview affected tables
    SELECT * FROM purchase_orders;
    SELECT * FROM purchase_order_lines;
    
    BEGIN
        jta.restock_urgent(12);
    END;
    /
    
    -- review affected tables, two more purchase orders should appear
    SELECT * FROM purchase_orders;
    SELECT * FROM purchase_order_lines;


/*
    06 get last payout for cashier
*/
    DECLARE
        v_id NUMBER := 11;
    BEGIN
        -- only staff no 11 has cashier data in db
        dbms_output.put_line('payout for id: ' || v_id || ' = ' || jta.get_last_cashier_payout(v_id));
    END;
    /

    -- review accuracy 
    SELECT * FROM cashier_drawer_assignments;


/*
    07 cash inflow for time period
*/
    BEGIN
        dbms_output.put_line(
            'cash inflow for Carlton Center (location 10) = ' 
            || jta.get_money_inflow(10, TO_DATE('2015-01-01', 'yyyy-mm-dd'), 
            TO_DATE('2015-01-02', 'yyyy-mm-dd'))
        );
        dbms_output.put_line(
            'non-cash inflow for Carlton Center (location 10) = ' 
            || jta.get_money_inflow(10, TO_DATE('2015-01-01', 'yyyy-mm-dd'), 
            TO_DATE('2015-01-02', 'yyyy-mm-dd'), 'non-cash')
        );
    END;  
    /
    
    -- review accuracy 
    SELECT * FROM cashier_drawer_assignments;


/*
    08 update taxes
*/
    -- insert a tax change with todays date, VAT set to 15%
    INSERT INTO pending_tax_changes VALUES 
        (1, 15, TRUNC(SYSDATE, 'dd'), 'VAT (new tax rate)');
    SELECT * FROM pending_tax_changes;
    
    -- view pending tax just added
    SELECT * FROM pending_tax_changes;
    
    -- call the update taxes procedure
    BEGIN
        jta.update_taxes;
    END;  
    /
    
    -- tables affected:
    SELECT * FROM tax_rates;
    SELECT * FROM pending_tax_changes;
    SELECT * FROM tax_rate_history;


/*
    09 price changes for product
    
*/
    DECLARE
        v_tab jta.price_changes_table;
    BEGIN
        -- call procedure 09, this returns a collection type
        v_tab := jta.get_price_changes(2, TO_DATE('01-JAN-14', 'dd-MON-yy'), TO_DATE('31-DEC-14', 'dd-MON-yy'));
        -- loop through and print to console each piece of data from collection
        FOR indx IN 1 .. v_tab.COUNT LOOP
            dbms_output.put_line(
                v_tab(indx).product_name 
                || ' ' || v_tab(indx).date_changed
                || ' ' || v_tab(indx).old_price
                || ' ' || v_tab(indx).new_price
                || ' ' || v_tab(indx).direction
            );
        END LOOP; 
    END;
    /
    -- review 
    SELECT * FROM price_history WHERE product_id = 2;
    

/*
    10 check profits for year 2015
    
*/
    DECLARE
        v_start_date DATE := TO_DATE('2015-01-01', 'yyyy-mm-dd');
        v_end_date DATE := TO_DATE('2015-12-31', 'yyyy-mm-dd');
        v_goods_sold NUMBER;
        v_gross_gain NUMBER;
        v_costs NUMBER;
        v_net_gain NUMBER;
    BEGIN
        jta.get_profits_for(v_start_date, v_end_date, v_goods_sold,
                            v_gross_gain, v_costs, v_net_gain);
        dbms_output.put_line( 'total goods sold - ' ||v_goods_sold); 
        dbms_output.put_line( 'gross gain - ' ||v_gross_gain);
        dbms_output.put_line( 'total costs - ' ||v_costs);
        dbms_output.put_line( 'net gain - ' ||v_net_gain);
    END;
    /
    -- review
    SELECT * FROM billed_items;
    SELECT * FROM cost_sales_tracker;


/*
    11 get a recommended new price for product no 3 
    
*/
    DECLARE
        v_product_id number := 1; -- 1,2,3 are valid products in inventory, 4 doesn't have sample input  
        v_avg_cost NUMBER;
        v_old_price NUMBER;
        v_new_price NUMBER;
    BEGIN
        jta.get_recommended_price_for (v_product_id, v_avg_cost, v_old_price, v_new_price);
        
        dbms_output.put_line( 'average cost - ' ||v_avg_cost); 
        dbms_output.put_line( 'old price - ' ||v_old_price);
        dbms_output.put_line( 'recommended new price - ' ||v_new_price);
    END;
    /
    -- review
    SELECT * FROM products;
    SELECT * FROM tax_rates;
    SELECT * FROM cost_sales_tracker;
    

/*
    12 find if requesting enought of an item in purchase order
    
*/
    
    -- view purchase order lines info;
    SELECT * FROM purchase_order_lines pol
    JOIN purchase_orders po ON (po.po_id = pol.po_id)  
    JOIN inventory_by_location inv ON (po.location_id = inv.location_id)
    AND (pol.product_id = inv.product_id);

    DECLARE
        v_line_id NUMBER := 5;
        v_restock BOOLEAN;
        v_level BOOLEAN; 
    BEGIN
    
        -- run procedure to find if we need to request more items
        jta.evaluate_po_order_line (v_line_id, v_restock, v_level);
    
        -- need if statements becuase we cannot cast 
        -- booleans to strings in plsql (FOR SOME STUPID REASON)
        IF v_restock = TRUE THEN
            dbms_output.put_line('not enough to restock item');
        ELSE
            dbms_output.put_line('okay quantity');
        END IF;
        
        IF v_level = TRUE THEN
            dbms_output.put_line('did not request the usual amount');
        ELSE
            dbms_output.put_line('good request amount');
        END IF;
    END;
    /


/*
    13 get price when given barcode
    
    212340012062  -- beef using price lookup, value = 12.06
    1234567879111 -- puncheon using regular barcode
    
*/
    DECLARE
        v_price NUMBER;
        v_id NUMBER;
        v_name VARCHAR(50);
        v_code NUMBER;
        v_rate NUMBER;
    BEGIN
        jta.lookup_barcode('212340012062', v_id, v_name, v_price, v_code, v_rate);
        dbms_output.put_line(v_id || ', ' || v_name || ' - ' || v_price || ', tax info: ' || v_code || ' - ' || v_rate); 
        jta.lookup_barcode('1234567879111', v_id, v_name, v_price, v_code, v_rate);
        dbms_output.put_line(v_id || ', ' || v_name || ' - ' || v_price || ', tax info: ' || v_code || ' - ' || v_rate); 
    END;
    /


/*
    14 called in 17, 15 moved to below 17
*/


/*
    16 and 17, add item to bill, and recieve payment from bill 
    16 also calls 13, lookup_barcode
*/
    -- tables affected
    SELECT * FROM customer_bills;
    SELECT * FROM billed_items;
    SELECT * FROM cashier_drawer_assignments;
    SELECT * FROM inventory_by_location;
    SELECT * FROM sold_products;

    DECLARE
        v_bill_id NUMBER := bill_id_seq.NEXTVAL;
        v_change NUMBER;
    BEGIN
        -- create a new bill to add items to
        INSERT INTO customer_bills VALUES (v_bill_id, 4, sysdate, NULL, NULL, NULL, NULL, 'unpaid');
        
        -- add 2 puncheon to bill
        jta.add_item_to_bill(v_bill_id, '1234567879111');
        jta.add_item_to_bill(v_bill_id, '1234567879111');
        -- add soap to bill
        jta.add_item_to_bill(v_bill_id, '1234567879222');
        
        -- receive payment for bill
        v_change := jta.receive_payment(v_bill_id, 'cash', 500);
        IF v_change IS NOT NULL THEN
            dbms_output.put_line('your change is: ' || to_char(v_change, '$999.99' ));    
        END IF;
    END;
    /


/*
    17 and 14 again
    with enough cash, not enough cash, linx overpayment, and error
*/
    -- tables affected
    SELECT * FROM customer_bills;
    SELECT * FROM billed_items;
    SELECT * FROM cashier_drawer_assignments;
    SELECT * FROM inventory_by_location;
    SELECT * FROM sold_products;

    DECLARE
        v_change NUMBER;
    BEGIN
        dbms_output.put_line('pay bill 1, with not enough cash');
        v_change := jta.receive_payment(1, 'cash', 10);
        IF v_change IS NOT NULL THEN
            dbms_output.put_line('your change is: ' || to_char(v_change, '$999.99' ));    
        END IF;
    END;
    /
    
    DECLARE
        v_change NUMBER;
    BEGIN
        dbms_output.put_line('pay bill 1 again, this time, with enough cash');
        v_change := jta.receive_payment(1, 'cash', 500);
        IF v_change IS NOT NULL THEN
            dbms_output.put_line('your change is: ' || to_char(v_change, '$999.99' ));    
        END IF;
    END;
    /

    DECLARE
        v_change NUMBER;
    BEGIN
        dbms_output.put_line('pay bill 2, with linx, will recieve change');
        v_change := jta.receive_payment(2, 'linx', 800.00);
        IF v_change IS NOT NULL THEN
            dbms_output.put_line('your change is: ' || to_char(v_change, '$999.99' ));    
        END IF;
        
        dbms_output.put_line('pay bill 2 again, should fail because already paid');
        v_change := jta.receive_payment(2, 'linx', 699.78);
        IF v_change IS NOT NULL THEN
            dbms_output.put_line('your change is: ' || to_char(v_change, '$999.99' ));    
        END IF;
    
    END;
    /
    


/*
    15 update sales from sold_products into cost_sales_tracker
    run this after running 14 (above) since it is related to this procedure
    this procedure also calls procedure 04
*/
    -- affected tables
    SELECT * FROM sold_products;
    SELECT * FROM cost_sales_tracker;
    
    DECLARE
    BEGIN
        jta.update_sales;
    END;
    /


/*
    18 find tax payout for year 2015
*/
    -- data taken from this table, for each row sum(tax_rate * price_rate)
    SELECT * FROM billed_items;
    
    BEGIN
        -- any date for the year can be inserted into the function,
        -- the date period is processed for the beginning of that year to its end
        dbms_output.put_line('VAT due for 2015 = ' ||
            jta.get_tax_payment_due( 1, TO_DATE('2015-09-09','yyyy-mm-dd') )
        );    
    END;
    /


/*
    19 find out how much of a product was sold at a location 
    for the year 2015
*/
    -- data taken from 
    SELECT bit.product_id, cs.location_id, bit.quantity  
    FROM billed_items bit
    JOIN customer_bills cb ON (cb.bill_id = bit.bill_id)
    JOIN cashier_drawer_assignments cda ON (cda.assignment_id = cb.bill_id)
    JOIN cashier_stations cs ON (cs.station_id = cda.station_id);
    
    DECLARE
        v_product NUMBER := 1; -- sample data has 1,2,3
        v_location number := 10; -- sample data has 10
    BEGIN
        dbms_output.put_line('products sold = ' ||
            jta.get_quantity_sold(v_product, v_location, 
            TO_DATE('2015-01-01','yyyy-mm-dd'), TO_DATE('2015-12-31','yyyy-mm-dd'))
        );    
    END;
    /

/*
    20, stock check
    if stock was counted at Marabella branch (id 11) 
    and we get 95 of colgate(id 3) then we have 5 missing items
    (on fresh create of database)
*/
    -- affected tables
    SELECT * FROM missing_items;
    SELECT * FROM inventory_by_location;
    SELECT * FROM cost_sales_tracker;
    
    DECLARE
        v_counted INTEGER := 95;
        v_location NUMBER := 11;
        v_product NUMBER := 3;
        v_in_stock INTEGER;
    BEGIN
        dbms_output.put_line('we counted: ' || v_counted);
        jta.stock_check(v_product, v_location, v_counted, v_in_stock);
        dbms_output.put_line('currently in-stock: ' || v_in_stock);
    END;
    /


/*
    21, check if an employee is available to work
*/
    DECLARE
        v_id number := 10; -- change this to either 10, 11, 12 for staff memebers
        v_sun INTEGER;
        v_av BOOLEAN;
    BEGIN
        jta.sunday_check(v_id, TO_DATE('2015-03-01', 'yyyy-mm-dd'), v_sun, v_av);
        dbms_output.put_line('sundays for staff ' || v_id || ' = ' || v_sun);
        IF v_av THEN
            dbms_output.put_line('is available');
        ELSE
            dbms_output.put_line('is NOT available');
        END IF;
    END;
    /


/*
    22, get payout for employees for month of march 2015
*/
    DECLARE
        v_begin DATE := TO_DATE('2015-05-01','yyyy-mm-dd'); -- month of march, 2015
        v_end date := TO_DATE('2015-05-31','yyyy-mm-dd');
        v_gp NUMBER; v_np NUMBER; v_hlt NUMBER; v_nat NUMBER; v_ded NUMBER;
    BEGIN
        -- call payout for the three employees in sample data
        FOR indx IN 10..12 LOOP
        jta.payout (indx, v_begin, v_end, v_gp, v_np, v_hlt, v_nat, v_ded);
        -- print results 
        dbms_output.put_line('Staff member: ' || jta.get_name(indx));
        dbms_output.put_line('total gross pay: ' || v_gp);
        dbms_output.put_line('total net pay: ' || v_np);
        dbms_output.put_line('total hlt deduction: ' || v_hlt);
        dbms_output.put_line('total nat deduction: ' || v_nat);
        dbms_output.put_line('total both deduction: ' || v_ded);
        dbms_output.put_line(' ');
        END LOOP;
    END;
    /


/*
    23,
    test update job history trigger for jason bourne (id 12)
*/
    -- new job
    UPDATE staff SET job_id = 10 WHERE staff_id = 12;
    SELECT * FROM job_posts_history;
    
    -- change job
    UPDATE staff SET job_id = 11 WHERE staff_id = 12;
    SELECT * FROM job_posts_history;
    
    -- another change
    UPDATE staff SET job_id = 12 WHERE staff_id = 12;
    SELECT * FROM job_posts_history;
/


/*
    24, trigger to email purchasing dept when item is running out
*/
    BEGIN
        -- raise inventory amount
        UPDATE inventory_by_location SET quantity = 10000 
        WHERE location_id = 11 AND product_id = 1;
        COMMIT; -- triggers only fire once per transaction, so we commit update statement
        
        -- drop amount down to min level
        UPDATE inventory_by_location SET quantity = 990
        WHERE location_id = 11 AND product_id = 1;
        COMMIT;
        
        -- drop down again, should not trigger a second time
        UPDATE inventory_by_location SET quantity = 900
        WHERE location_id = 11 AND product_id = 1;
        COMMIT;
    END;
    /

    BEGIN
        -- raise and drop for another product
        UPDATE inventory_by_location SET quantity = 10000 
        WHERE location_id = 10 AND product_id = 3;
        COMMIT;
        
        UPDATE inventory_by_location SET quantity = 100 
        WHERE location_id = 10 AND product_id = 3;
        COMMIT;
        
        UPDATE inventory_by_location SET quantity = 50 
        WHERE location_id = 10 AND product_id = 3;
        COMMIT;
    END;
    /


/*
    25, to test logon and logoff trigger,
    log off and log back on, then check event table
*/
SELECT event_id, user_name, to_char(date_time, 'DD-MON-YYYY, HH24-MI-SS') AS "time" , event, ip_address FROM jta_events;






