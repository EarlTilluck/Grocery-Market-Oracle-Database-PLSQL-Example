-- Earl Tilluck
-- Andrew Lawrence (old group)
-- Larry Williams (old group)
-- This SQL script creates the JTA database with all tables, constraints and sample data.

-- Begin

-- create an error table for logging errors
DROP TABLE jta_errors CASCADE CONSTRAINTS;
DROP SEQUENCE error_seq;
CREATE SEQUENCE error_seq START WITH 1 INCREMENT BY 1 CACHE 10;
CREATE TABLE jta_errors (
	error_id NUMBER,
	date_time DATE,
	user_name VARCHAR2(255),
	code VARCHAR2(6),
	message VARCHAR2(255),
	CONSTRAINT error_id_pk PRIMARY KEY (error_id)
);

-- create event table
DROP TABLE jta_events CASCADE CONSTRAINTS;
DROP SEQUENCE event_seq;
CREATE SEQUENCE event_seq START WITH 1 INCREMENT BY 1 CACHE 10;
CREATE TABLE jta_events (
    event_id NUMBER,
    user_name VARCHAR2(255),
    date_time DATE CONSTRAINT ev_date_time_nn NOT NULL,
    event VARCHAR2(255) CONSTRAINT ev_event_nn NOT NULL,
    ip_address VARCHAR2(20),
    CONSTRAINT event_id_pk PRIMARY KEY (event_id)
);

DROP TABLE authorized_ip_adresses CASCADE CONSTRAINTS;
CREATE TABLE authorized_ip_adresses (
    ip_address VARCHAR2(20),
    CONSTRAINT auth_ip_pk PRIMARY KEY (ip_address)
);
INSERT INTO authorized_ip_adresses VALUES ('196.244.16.101');
INSERT INTO authorized_ip_adresses VALUES ('196.244.16.102');
INSERT INTO authorized_ip_adresses VALUES ('196.244.16.103');


-- Drop old tables and sequences with same name
-- Create Tables and Sequences (sequences are used for primary keys)
DROP TABLE products CASCADE CONSTRAINTS;
DROP SEQUENCE product_id_seq;
CREATE SEQUENCE product_id_seq START WITH 1 INCREMENT BY 1 CACHE 10;
CREATE TABLE products (
	product_id NUMBER,
	category_id NUMBER CONSTRAINT prod_cat_id_nn NOT NULL,
	unit_measure VARCHAR2(2),
	product_name VARCHAR2(50) CONSTRAINT prod_name_nn NOT NULL,
	description VARCHAR2(150),
	barcode NUMBER(13,0),
	price_lookup_code NUMBER(5,0), 
	tax_code NUMBER CONSTRAINT prod_tax_code_nn NOT NULL,
	price_rate NUMBER(10,2) CONSTRAINT prod_price_nn NOT NULL,
	min_stock_level NUMBER,
	reorder_level NUMBER,
    CONSTRAINT prod_id_pk PRIMARY KEY (product_id),
    CONSTRAINT barcode_uk UNIQUE (barcode),
    CONSTRAINT plu_uk UNIQUE (price_lookup_code),
	--valid numbers for columns, ignores nulls
    CONSTRAINT misc_products_ck CHECK (min_stock_level >= 0 AND reorder_level >= 0),
    --either a barcode or a price_lookup_code must be present, but not both or neither.
    CONSTRAINT barcode_plu_ck CHECK ((barcode IS NOT NULL AND price_lookup_code IS NULL) 
	OR (barcode IS NULL AND price_lookup_code IS NOT NULL))
);

DROP TABLE staff CASCADE CONSTRAINTS;
DROP SEQUENCE staff_id_seq;
CREATE SEQUENCE staff_id_seq START WITH 10 INCREMENT BY 1 NOCACHE;
CREATE TABLE staff (
  staff_id NUMBER,
  location_id NUMBER CONSTRAINT staff_location_nn NOT NULL,
  job_id NUMBER CONSTRAINT staff_job_nn NOT NULL,
  first_name VARCHAR2(20) CONSTRAINT staff_fname_nn NOT NULL,
  last_name VARCHAR2(20) CONSTRAINT staff_lname_nn NOT NULL,
  home_phone VARCHAR2(14) CONSTRAINT staff_hphone_nn NOT NULL,
  mobile_phone VARCHAR2(14),
  hire_date DATE DEFAULT SYSDATE CONSTRAINT staff_hiredate_nn NOT NULL,
  address VARCHAR2(150) CONSTRAINT staff_addr_nn NOT NULL,
  dob DATE CONSTRAINT staff_dob_nn NOT NULL,
  emergency_number VARCHAR2(14),
  wage_rate NUMBER(10,2) CONSTRAINT staff_wage_nn NOT NULL,
  wage_interval VARCHAR2(10) CONSTRAINT staff_wage_int_nn NOT NULL,
  payment_schedule VARCHAR2(10) CONSTRAINT staff_pay_sch_nn NOT NULL,
  gender CHAR(1) CONSTRAINT staff_gender_nn NOT NULL,
  is_married CHAR(1) CONSTRAINT staff_maritial_nn NOT NULL,
  is_active CHAR(1) CONSTRAINT staff_active_nn NOT NULL,
  is_permanent CHAR(1) CONSTRAINT staff_perm_nn NOT NULL,
  CONSTRAINT staff_id_pk PRIMARY KEY (staff_id),
  --restrict values for some columns
  CONSTRAINT staff_wage_int_ck CHECK (wage_interval = 'hour' 
  OR wage_interval = 'flat' OR wage_interval = 'day'),
  CONSTRAINT staff_pay_sch_ck CHECK (payment_schedule = 'week' 
  OR payment_schedule = 'fortnight' OR payment_schedule = 'month'),
  CONSTRAINT staff_gender_ck CHECK (gender = 'M' OR gender = 'F'),
  CONSTRAINT staff_married_ck CHECK (is_married = 'T' OR is_married = 'F'),
  CONSTRAINT staff_active_ck CHECK (is_active = 'T' OR is_active = 'F'),
  CONSTRAINT staff_perm_ck CHECK (is_permanent = 'T' OR is_permanent = 'F'),
  CONSTRAINT misc_staff_ck CHECK (wage_rate > 0)
);

DROP TABLE job_posts CASCADE CONSTRAINTS;
DROP SEQUENCE job_id_seq;		
CREATE SEQUENCE job_id_seq START WITH 10 INCREMENT BY 1 NOCACHE;
CREATE TABLE job_posts (
  job_id NUMBER,
  job_title VARCHAR2(20) CONSTRAINT job_posts_title_nn NOT NULL,
  starting_wage NUMBER(10,2) CONSTRAINT job_posts_startwage_nn NOT NULL,
  default_wage_interval VARCHAR2(10) CONSTRAINT job_posts_wage_int_nn NOT NULL,
  default_payment_schedule VARCHAR2(10) CONSTRAINT job_posts_pay_sch_nn NOT NULL,
  CONSTRAINT job_posts_id_pk PRIMARY KEY (job_id),
  CONSTRAINT job_posts_title_uk UNIQUE (job_title),
  CONSTRAINT job_posts_start_wage_ck CHECK (starting_wage > 0),
  CONSTRAINT job_posts_wage_int_ck CHECK (default_wage_interval = 'hour' 
  OR default_wage_interval = 'flat' OR default_wage_interval = 'day'),
  CONSTRAINT job_posts_pay_sch_ck CHECK (default_payment_schedule = 'week' 
  OR default_payment_schedule = 'fortnight' OR default_payment_schedule = 'month')
);

DROP TABLE job_posts_history CASCADE CONSTRAINTS;
CREATE TABLE job_posts_history (
  staff_id NUMBER,
  date_started DATE,
  date_ended DATE, 
  job_id NUMBER CONSTRAINT job_post_hist_job_id_nn NOT NULL,
  CONSTRAINT job_post_hist_pk PRIMARY KEY (staff_id, date_started),
  CONSTRAINT job_posts_hist_dates_ck CHECK (date_ended >= date_started)
);

DROP TABLE payroll CASCADE CONSTRAINTS;
DROP SEQUENCE payroll_id_seq;
CREATE SEQUENCE payroll_id_seq START WITH 1 INCREMENT BY 1 CACHE 500;
CREATE TABLE payroll (
  payroll_id NUMBER,
  staff_id NUMBER CONSTRAINT payroll_staff_id_nn NOT NULL,
  start_date DATE CONSTRAINT payroll_startdate_nn NOT NULL,
  end_date DATE CONSTRAINT payroll_enddate_nn NOT NULL,
  hours_basic NUMBER CONSTRAINT payroll_hrsbasic_nn NOT NULL,
  hours_overtime NUMBER,
  hours_doubletime NUMBER,
  basic_pay_rate NUMBER(10,2) CONSTRAINT payroll_payrate_nn NOT NULL,
  nat_insurance_deduction NUMBER(10,2) CONSTRAINT payroll_nat_nn NOT NULL,
  hlt_surcharge_deduction NUMBER(10,2) CONSTRAINT payroll_hlt_nn NOT NULL,
  COLA_deduction NUMBER(10,2),
  PAYE_deduction NUMBER(10,2),
  pension_deduction NUMBER(10,2),
  health_plan_deduction NUMBER(10,2),
  other_deduction NUMBER(10,2),
  date_staff_received DATE,
  gross_pay NUMBER(10,2),
  net_pay NUMBER(10,2),
  notes VARCHAR2(150),
  CONSTRAINT payroll_pk PRIMARY KEY (payroll_id),
  CONSTRAINT payroll_dates_ck CHECK (end_date >= start_date),
  CONSTRAINT payroll_payout_ck CHECK (date_staff_received >= end_date),
  CONSTRAINT payroll_hours_ck CHECK (hours_basic >= 0
  AND hours_doubletime >= 0
  AND hours_overtime >= 0),
  CONSTRAINT payroll_payrate_ck CHECK (basic_pay_rate >= 0
  AND gross_pay >= 0
  AND net_pay >= 0),
  CONSTRAINT payroll_deductions_ck CHECK (
  nat_insurance_deduction > 0 
  AND hlt_surcharge_deduction > 0
  AND COLA_deduction > 0
  AND PAYE_deduction > 0
  AND pension_deduction > 0
  AND health_plan_deduction > 0
  AND other_deduction > 0)
);

DROP TABLE work_hours CASCADE CONSTRAINTS;
CREATE TABLE work_hours (
  staff_id NUMBER,
  work_date DATE,
  hours_worked NUMBER CONSTRAINT work_hours_hw_nn NOT NULL,
  CONSTRAINT work_hours_pk PRIMARY KEY (staff_id, work_date),
  CONSTRAINT work_hours_ck CHECK (hours_worked > 0)
);

DROP TABLE locations CASCADE CONSTRAINTS;
DROP SEQUENCE location_id_seq;
CREATE SEQUENCE location_id_seq START WITH 10 INCREMENT BY 1 NOCACHE;
CREATE TABLE locations (
  location_id NUMBER,
  name VARCHAR2(20) CONSTRAINT locations_name_nn NOT NULL,
  type VARCHAR2(20),
  address VARCHAR2(150) CONSTRAINT locations_addr_nn NOT NULL,
  CONSTRAINT locations_pk PRIMARY KEY (location_id),
  CONSTRAINT locations_name_uk UNIQUE (name)
);

DROP TABLE office_sections CASCADE CONSTRAINTS;
DROP SEQUENCE office_id_seq;
CREATE SEQUENCE office_id_seq START WITH 10 INCREMENT BY 1 NOCACHE;
CREATE TABLE office_sections (
  office_id NUMBER,
  contact_number VARCHAR2(14) CONSTRAINT office_contact_num_nn NOT NULL,
  extension VARCHAR2(4),
  location_id NUMBER CONSTRAINT office_location_id_nn NOT NULL,
  desk_name VARCHAR2(20) CONSTRAINT office_deskname_nn NOT NULL,
  staff_id NUMBER CONSTRAINT office_staff_id_nn NOT NULL,
  CONSTRAINT office_sections_pk PRIMARY KEY (office_id)
);

DROP SEQUENCE bill_id_seq;
CREATE SEQUENCE bill_id_seq START WITH 1 INCREMENT BY 1 CACHE 500;
DROP TABLE customer_bills CASCADE CONSTRAINTS;
CREATE TABLE customer_bills (
  bill_id NUMBER,
  assignment_id NUMBER CONSTRAINT bills_assignment_nn NOT NULL,
  date_time_created DATE CONSTRAINT bills_date_nn NOT NULL,
  date_time_paid DATE,
  payment_tender NUMBER(10,2),
  payment_amount NUMBER(10,2),
  payment_type VARCHAR2(10),
  payment_status VARCHAR2(10) CONSTRAINT bills_status_nn NOT NULL,
  CONSTRAINT customer_bills_pk PRIMARY KEY (bill_id),
  CONSTRAINT bills_date_ck CHECK (date_time_paid >= date_time_created),
  CONSTRAINT bills_numeric_ck CHECK (payment_tender >= 0 AND payment_amount >= 0),
  CONSTRAINT bills_paytype_ck CHECK (payment_type = 'cash' 
  OR payment_type = 'cheque' OR payment_type = 'creditcard'
  OR payment_type = 'linx'),
  CONSTRAINT bills_paystatus_ck CHECK (payment_status = 'paid' 
  OR payment_status = 'pending' OR payment_type = 'unpaid')
);

DROP SEQUENCE bill_line_id_seq;
CREATE SEQUENCE bill_line_id_seq START WITH 1 INCREMENT BY 1 CACHE 500;
DROP TABLE billed_items CASCADE CONSTRAINTS;  
CREATE TABLE billed_items (
  bill_line_id NUMBER,
  bill_id NUMBER CONSTRAINT billed_bill_id_nn NOT NULL,
  product_id NUMBER CONSTRAINT billed_product_nn NOT NULL,
  quantity NUMBER CONSTRAINT billed_quantity_nn NOT NULL,
  price_rate NUMBER(10,2) CONSTRAINT billed_pricerate_nn NOT NULL,
  tax_code NUMBER CONSTRAINT billed_taxcode_nn NOT NULL,
  tax_rate NUMBER(5,2) CONSTRAINT billed_taxrate_nn NOT NULL,
  CONSTRAINT billed_items_pk PRIMARY KEY (bill_line_id),
  CONSTRAINT billed_numaric_ck CHECK (quantity > 0 AND price_rate > 0)
);

DROP SEQUENCE station_id_seq;
CREATE SEQUENCE station_id_seq START WITH 10 INCREMENT BY 1 NOCACHE;
DROP TABLE cashier_stations CASCADE CONSTRAINTS;
CREATE TABLE cashier_stations (
  station_id NUMBER,
  location_id NUMBER CONSTRAINT station_location_nn NOT NULL,
  description VARCHAR2(150),
  CONSTRAINT cashier_stations_pk PRIMARY KEY (station_id)
);

DROP SEQUENCE assignment_id_seq;
CREATE SEQUENCE assignment_id_seq START WITH 1 INCREMENT BY 1 CACHE 100;
DROP TABLE cashier_drawer_assignments CASCADE CONSTRAINTS;
CREATE TABLE cashier_drawer_assignments (
  assignment_id NUMBER,
  staff_id NUMBER CONSTRAINT cashiers_assign_staff_nn NOT NULL,
  station_id NUMBER CONSTRAINT cashiers_assign_station_nn NOT NULL,
  start_time date CONSTRAINT cashiers_assign_start_nn NOT NULL,
  end_time date,
  drawer_id NUMBER CONSTRAINT cashiers_assign_drawerid_nn NOT NULL,
  cash_amount_start NUMBER(10,2) CONSTRAINT cashiers_assign_cashstart_nn NOT NULL,
  cash_amount_end NUMBER(10,2) CONSTRAINT cashiers_assign_cashend_nn NOT NULL,
  non_cash_tender NUMBER(10,2),
  CONSTRAINT cashier_drawer_assign_pk PRIMARY KEY (assignment_id),
  CONSTRAINT cashier_drawer_time_ck CHECK (start_time < end_time),
  CONSTRAINT cashier_drawer_numeric_ck CHECK (cash_amount_start >= 0 
  AND cash_amount_end >= 0 AND non_cash_tender >= 0)
);

DROP SEQUENCE supplier_id_seq;
CREATE SEQUENCE supplier_id_seq START WITH 10 INCREMENT BY 1 NOCACHE;
DROP TABLE suppliers CASCADE CONSTRAINTS;
CREATE TABLE suppliers (
  supplier_id NUMBER,
  supplier_name VARCHAR2(50) CONSTRAINT supplier_name_nn NOT NULL,
  address VARCHAR2(150) CONSTRAINT supplier_address_nn NOT NULL,
  notes VARCHAR2(150),
  CONSTRAINT suppliers_pk PRIMARY KEY (supplier_id),
  CONSTRAINT suppliers_name_uk UNIQUE (supplier_name)
);

DROP SEQUENCE sup_contact_id_seq;
CREATE SEQUENCE sup_contact_id_seq START WITH 1 INCREMENT BY 1 NOCACHE;
DROP TABLE supplier_contacts CASCADE CONSTRAINTS;
CREATE TABLE supplier_contacts (
  sup_contact_id NUMBER,
  supplier_id NUMBER CONSTRAINT sup_contact_supplier_id_nn NOT NULL,
  contact_number VARCHAR2(14) CONSTRAINT sup_contact_number_nn NOT NULL,
  extension VARCHAR2(10),
  fax VARCHAR2(14),
  first_name VARCHAR2(20),
  last_name VARCHAR2(20),
  notes VARCHAR2(150),
  email VARCHAR2(50),
  CONSTRAINT supplier_contacts_pk PRIMARY KEY (sup_contact_id),
  CONSTRAINT supplier_contacts_num_uk UNIQUE (contact_number),
  CONSTRAINT supplier_contacts_email_uk UNIQUE (email),
  CONSTRAINT supplier_contacts_fax_uk UNIQUE (fax)
);

DROP TABLE suppliers_per_products CASCADE CONSTRAINTS;
CREATE TABLE suppliers_per_products (
  supplier_id NUMBER,
  product_id NUMBER,
  CONSTRAINT suppliers_per_products_pk PRIMARY KEY (supplier_id, product_id)
);

DROP SEQUENCE invoice_number_seq;
CREATE SEQUENCE invoice_number_seq START WITH 1 INCREMENT BY 1 CACHE 100;
DROP TABLE supplier_invoices CASCADE CONSTRAINTS;
CREATE TABLE supplier_invoices (
  invoice_number NUMBER,
  supplier_id NUMBER CONSTRAINT sup_invoice_sup_id_nn NOT NULL,
  date_received date CONSTRAINT sup_invoice_date_nn NOT NULL,
  location_id NUMBER CONSTRAINT sup_invoice_location_nn NOT NULL,
  supplier_invoice_number VARCHAR2(50),
  staff_id NUMBER CONSTRAINT sup_invoice_staff_nn NOT NULL,
  notes VARCHAR2(150),
  CONSTRAINT supplier_invoices_pk PRIMARY KEY (invoice_number)
);

DROP SEQUENCE payment_record_id_seq;
CREATE SEQUENCE payment_record_id_seq START WITH 1 INCREMENT BY 1 CACHE 100;
DROP TABLE invoice_payments_records CASCADE CONSTRAINTS;
CREATE TABLE invoice_payments_records (
  payment_record_id NUMBER,
  invoice_number NUMBER CONSTRAINT payments_inv_num_nn NOT NULL,
  current_amount_due NUMBER(10,2) CONSTRAINT payments_due_nn NOT NULL,
  amount_paid NUMBER(10,2) CONSTRAINT payments_paid_nn NOT NULL,
  date_paid DATE CONSTRAINT payments_date_nn NOT NULL,
  staff_id NUMBER CONSTRAINT payments_staff_nn NOT NULL,
  CONSTRAINT invoice_payments_records_pk PRIMARY KEY (payment_record_id),
  CONSTRAINT invoice_payments_numeric_ck CHECK (amount_paid > 0 AND current_amount_due >=0)
);

DROP SEQUENCE sup_inv_line_id_seq;
CREATE SEQUENCE sup_inv_line_id_seq START WITH 1 INCREMENT BY 1 CACHE 100;
DROP TABLE supplier_invoice_line CASCADE CONSTRAINTS; 
CREATE TABLE supplier_invoice_line (
  sup_inv_line_id NUMBER,
  invoice_number NUMBER CONSTRAINT sup_inv_num_nn NOT NULL,
  product_id NUMBER CONSTRAINT sup_inv_prod_nn NOT NULL,
  quantity NUMBER CONSTRAINT sup_inv_quantity_nn NOT NULL,
  price_rate NUMBER(10,2) CONSTRAINT sup_inv_rate_nn NOT NULL,
  CONSTRAINT supplier_invoice_line_pk PRIMARY KEY (sup_inv_line_id),
  CONSTRAINT sup_inv_numeric_ck CHECK (quantity > 0 AND price_rate >= 0)
); 

DROP TABLE inventory_by_location CASCADE CONSTRAINTS;
CREATE TABLE inventory_by_location (
  product_id NUMBER,
  location_id NUMBER,
  quantity NUMBER CONSTRAINT inv_by_location_quantity_nn NOT NULL,
  min_stock_level NUMBER,
  reorder_level NUMBER,
  CONSTRAINT inventory_by_location_pk PRIMARY KEY (product_id, location_id),
  CONSTRAINT inv_by_location_numeric_ck CHECK (quantity >=0 
  AND min_stock_level >=0 AND reorder_level >=0)
);

DROP SEQUENCE category_id_seq;
CREATE SEQUENCE category_id_seq START WITH 10 INCREMENT BY 10 NOCACHE;
DROP TABLE product_category CASCADE CONSTRAINTS;
CREATE TABLE product_category (
  category_id NUMBER,
  category_name VARCHAR2(20) CONSTRAINT category_cat_name_nn NOT NULL,
  description VARCHAR2(150),
  CONSTRAINT product_category_pk PRIMARY KEY (category_id),
  CONSTRAINT category_name_uk UNIQUE (category_name)
);

DROP SEQUENCE m_item_id_seq;
CREATE SEQUENCE m_item_id_seq START WITH 1 INCREMENT BY 1 CACHE 10;
DROP TABLE missing_items CASCADE CONSTRAINTS;
CREATE TABLE missing_items (
  m_item_id NUMBER,
  product_id NUMBER CONSTRAINT missing_items_product_nn NOT NULL,
  date_recorded DATE CONSTRAINT missing_items_date_nn NOT NULL,
  quantity NUMBER CONSTRAINT missing_items_quantity_nn NOT NULL,
  CONSTRAINT missing_items_pk PRIMARY KEY (m_item_id),
  CONSTRAINT missing_items_quant_ck CHECK (quantity > 0)
);

DROP TABLE price_history CASCADE CONSTRAINTS;
CREATE TABLE price_history (
  product_id NUMBER,
  start_date DATE,
  price_rate NUMBER(10,2) CONSTRAINT price_hist_rate_nn NOT NULL,
  end_date DATE,
  CONSTRAINT price_history_pk PRIMARY KEY (product_id, start_date),
  CONSTRAINT price_hist_date_ck CHECK (start_date < end_date),
  CONSTRAINT price_hist_rate_ck CHECK (price_rate > 0)
);

DROP TABLE pending_price_rates CASCADE CONSTRAINTS;
CREATE TABLE pending_price_rates (
  product_id NUMBER,
  start_date DATE CONSTRAINT pending_price_startdate_nn NOT NULL,
  price_rate NUMBER(10,2) CONSTRAINT pending_price_rate_nn NOT NULL,
  CONSTRAINT pending_price_rates_pk PRIMARY KEY (product_id),
  CONSTRAINT pending_price_rate_ck CHECK (price_rate > 0)
);

DROP SEQUENCE tax_code_seq;
CREATE SEQUENCE tax_code_seq START WITH 1 INCREMENT BY 1 NOCACHE;
DROP TABLE tax_rates CASCADE CONSTRAINTS;
CREATE TABLE tax_rates (
  tax_code NUMBER,
  tax_rate NUMBER(5,2) CONSTRAINT tax_rates_rate_nn NOT NULL,
  description VARCHAR2(150),
  CONSTRAINT tax_rates_pk PRIMARY KEY (tax_code),
  CONSTRAINT tax_rates_rate_ck CHECK (tax_rate > 0)
);

DROP TABLE tax_rate_history CASCADE CONSTRAINTS;
CREATE TABLE tax_rate_history (
  tax_code NUMBER,
  start_date DATE,
  end_date DATE,
  tax_rate NUMBER(5,2) CONSTRAINT tax_rate_hist_rate_nn NOT NULL,
  CONSTRAINT tax_rate_hist_pk PRIMARY KEY (tax_code, start_date),
  CONSTRAINT tax_rate_hist_rate_ck CHECK (tax_rate > 0),
  CONSTRAINT tax_rate_hist_date_ck CHECK (start_date < end_date)
);

DROP TABLE pending_tax_changes CASCADE CONSTRAINTS;
CREATE TABLE pending_tax_changes (
  tax_code NUMBER,
  tax_rate NUMBER(5,2) CONSTRAINT pending_tax_rate_nn NOT NULL,
  start_date DATE CONSTRAINT pending_tax_startdate_nn NOT NULL,
  description VARCHAR2(150),
  CONSTRAINT pending_tax_changes_pk PRIMARY KEY (tax_code),
  CONSTRAINT pending_tax_changes_rate_ck CHECK (tax_rate > 0)
);

DROP SEQUENCE po_id_seq;
CREATE SEQUENCE po_id_seq START WITH 1 INCREMENT BY 1 CACHE 100;
DROP TABLE purchase_orders CASCADE CONSTRAINTS;
CREATE TABLE purchase_orders (
  po_id NUMBER,
  supplier_id NUMBER CONSTRAINT po_sid_nn NOT NULL,
  staff_id NUMBER CONSTRAINT po_staff_nn NOT NULL,
  location_id NUMBER CONSTRAINT po_location_nn NOT NULL,
  pending CHAR(1) CONSTRAINT po_pending_nn NOT NULL,
  approved CHAR(1) CONSTRAINT po_approved_nn NOT NULL,
  submitted_date DATE CONSTRAINT po_date_submitted_nn NOT NULL,
  date_approved DATE,
  CONSTRAINT purchase_orders_pk PRIMARY KEY (po_id),
  CONSTRAINT purchase_orders_date_ck CHECK (submitted_date <= date_approved),
  CONSTRAINT purchase_orders_pending_ck CHECK (pending = 'T' OR pending = 'F'),
  CONSTRAINT purchase_orders_approved_ck CHECK (approved = 'T' OR approved = 'F')
);

DROP TABLE unit_measures CASCADE CONSTRAINTS;
CREATE TABLE unit_measures (
  unit_measure VARCHAR2(5),
  description VARCHAR2(150),
  CONSTRAINT unit_measures_pk PRIMARY KEY (unit_measure)
);

DROP SEQUENCE po_line_id_seq;
CREATE SEQUENCE po_line_id_seq START WITH 1 INCREMENT BY 1 CACHE 100;
DROP TABLE purchase_order_lines CASCADE CONSTRAINTS;
CREATE TABLE purchase_order_lines (
  po_line_id NUMBER,
  po_id NUMBER CONSTRAINT po_line_poid_nn NOT NULL,
  product_id NUMBER CONSTRAINT po_line_product_nn NOT NULL,
  quantity NUMBER CONSTRAINT po_line_quant_nn NOT NULL,
  price_rate NUMBER(10,2),
  CONSTRAINT purchase_order_lines_pk PRIMARY KEY (po_line_id),
  CONSTRAINT po_lines_numberic_ck CHECK (quantity > 0)
);

DROP SEQUENCE transaction_id_seq;
CREATE SEQUENCE transaction_id_seq START WITH 1 INCREMENT BY 1 CACHE 500;
DROP TABLE cost_sales_tracker CASCADE CONSTRAINTS;
CREATE TABLE cost_sales_tracker (
  transaction_id NUMBER,
  product_id NUMBER CONSTRAINT cst_product_nn NOT NULL,
  direction VARCHAR2(3) CONSTRAINT cst_direction_nn NOT NULL,
  date_time DATE CONSTRAINT cst_date_nn NOT NULL,
  quantity NUMBER CONSTRAINT cst_quant_nn NOT NULL,
  total NUMBER CONSTRAINT cst_total_nn NOT NULL,
  average_cost_per_unit NUMBER(10,2) CONSTRAINT cst_avg_cost_nn NOT NULL,
  cost_per_unit NUMBER(10,2),
  CONSTRAINT cost_sales_tracker_pk PRIMARY KEY (transaction_id),
  CONSTRAINT cost_sales_numeric_ck CHECK (quantity != 0 AND total >= 0
  AND cost_per_unit > 0 AND average_cost_per_unit > 0),
  CONSTRAINT cost_sales_direction_ck CHECK (direction = 'IN' OR direction = 'OUT')
);

-- Add Foreign Key Constraints 
ALTER TABLE products ADD 
(
CONSTRAINT products_category_id_fk FOREIGN KEY (category_id) REFERENCES product_category(category_id),
CONSTRAINT products_unitmeasure_fk FOREIGN KEY (unit_measure) REFERENCES unit_measures(unit_measure),
CONSTRAINT products_taxcode_fk FOREIGN KEY (tax_code) REFERENCES tax_rates(tax_code)
);

ALTER TABLE pending_tax_changes ADD 
(
CONSTRAINT pend_tax_ch_taxcode_fk FOREIGN KEY (tax_code) REFERENCES tax_rates(tax_code)
);

ALTER TABLE tax_rate_history ADD 
(
CONSTRAINT tax_rt_hist_taxcode_fk FOREIGN KEY (tax_code) REFERENCES tax_rates(tax_code)
);

ALTER TABLE missing_items ADD 
(
CONSTRAINT missingitems_product_fk FOREIGN KEY (product_id) REFERENCES products(product_id)
);

ALTER TABLE price_history ADD 
(
CONSTRAINT price_hist_product_fk FOREIGN KEY (product_id) REFERENCES products(product_id)
);

ALTER TABLE pending_price_rates ADD 
(
CONSTRAINT pend_price_rt_product_fk FOREIGN KEY (product_id) REFERENCES products(product_id)
);

ALTER TABLE cost_sales_tracker ADD 
(
CONSTRAINT cost_sales_product_fk FOREIGN KEY (product_id) REFERENCES products(product_id)
);

ALTER TABLE supplier_invoice_line ADD 
(
CONSTRAINT sup_inv_ln_product_fk FOREIGN KEY (product_id) REFERENCES products(product_id),
CONSTRAINT sup_inv_ln_invoice_no_fk FOREIGN KEY (invoice_number) REFERENCES supplier_invoices(invoice_number)
);

ALTER TABLE supplier_invoices ADD 
(
CONSTRAINT sup_inv_supplier_fk FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id),
CONSTRAINT sup_inv_location_fk FOREIGN KEY (location_id) REFERENCES locations(location_id),
CONSTRAINT sup_inv_staff_fk FOREIGN KEY (staff_id) REFERENCES staff(staff_id)
);

ALTER TABLE suppliers_per_products ADD 
(
CONSTRAINT sup_per_prod_supplier_fk FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id),
CONSTRAINT sup_per_prod_product_fk FOREIGN KEY (product_id) REFERENCES products(product_id)
);

ALTER TABLE supplier_contacts ADD 
(
CONSTRAINT sup_contacts_supplier_fk FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id)
);

ALTER TABLE inventory_by_location ADD 
(
CONSTRAINT inv_loc_product_fk FOREIGN KEY (product_id) REFERENCES products(product_id),
CONSTRAINT inv_loc_location_fk FOREIGN KEY (location_id) REFERENCES locations(location_id)
);

ALTER TABLE purchase_order_lines ADD 
(
CONSTRAINT po_line_poid_fk FOREIGN KEY (po_id) REFERENCES purchase_orders(po_id),
CONSTRAINT po_line_product_fk FOREIGN KEY (product_id) REFERENCES products(product_id)
);

ALTER TABLE billed_items ADD 
(
CONSTRAINT billed_items_bill_fk FOREIGN KEY (bill_id) REFERENCES customer_bills(bill_id),
CONSTRAINT billed_items_product_fk FOREIGN KEY (product_id) REFERENCES products(product_id),
CONSTRAINT billed_items_taxcode_fk FOREIGN KEY (tax_code) REFERENCES tax_rates(tax_code)
);

ALTER TABLE customer_bills ADD 
(
CONSTRAINT cashier_assignment_fk FOREIGN KEY (assignment_id) REFERENCES cashier_drawer_assignments(assignment_id)
);

ALTER TABLE cashier_drawer_assignments ADD 
(
CONSTRAINT cash_draw_assign_staff_fk FOREIGN KEY (staff_id) REFERENCES staff(staff_id),
CONSTRAINT cash_draw_assign_station_fk FOREIGN KEY (station_id) REFERENCES cashier_stations(station_id)
);

ALTER TABLE cashier_stations ADD 
(
CONSTRAINT station_location_fk FOREIGN KEY (location_id) REFERENCES locations(location_id)
);

ALTER TABLE purchase_orders ADD 
(
CONSTRAINT p_orders_supplier_fk FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id),
CONSTRAINT p_orders_staff_fk FOREIGN KEY (staff_id) REFERENCES staff(staff_id),
CONSTRAINT p_orders_location_fk FOREIGN KEY (location_id) REFERENCES locations(location_id)
);

ALTER TABLE office_sections ADD 
(
CONSTRAINT office_sect_location_fk FOREIGN KEY (location_id) REFERENCES locations(location_id),
CONSTRAINT office_sect_staff_fk FOREIGN KEY (staff_id) REFERENCES staff(staff_id)
);

ALTER TABLE invoice_payments_records ADD 
(
CONSTRAINT inv_payments_inv_no_fk FOREIGN KEY (invoice_number) REFERENCES supplier_invoices(invoice_number),
CONSTRAINT inv_payments_staff_fk FOREIGN KEY (staff_id) REFERENCES staff(staff_id)
);

ALTER TABLE staff ADD 
(
CONSTRAINT staff_location_fk FOREIGN KEY (location_id) REFERENCES locations(location_id),
CONSTRAINT staff_job_fk FOREIGN KEY (job_id) REFERENCES job_posts(job_id)
);

ALTER TABLE job_posts_history ADD 
(
CONSTRAINT job_posts_hist_staff_fk FOREIGN KEY (staff_id) REFERENCES staff(staff_id),
CONSTRAINT job_posts_hist_job_fk FOREIGN KEY (job_id) REFERENCES job_posts(job_id)
);

ALTER TABLE payroll ADD 
(
CONSTRAINT payroll_staff_fk FOREIGN KEY (staff_id) REFERENCES staff(staff_id)
);

ALTER TABLE work_hours ADD 
(
CONSTRAINT work_hrs_staff_fk FOREIGN KEY (staff_id) REFERENCES staff(staff_id)
);


--Insert Sample Data  
INSERT INTO unit_measures VALUES 
('lb', 'pounds');
INSERT INTO unit_measures VALUES
('kg', 'kilograms');
INSERT INTO unit_measures VALUES
('oz','ounces');
INSERT INTO unit_measures VALUES
('ml','mililitre');
INSERT INTO unit_measures VALUES
('lt','liters');
INSERT INTO unit_measures VALUES
('pk','packs');
INSERT INTO unit_measures VALUES
('btl','bottles');
INSERT INTO unit_measures VALUES
('box','boxes');

INSERT INTO tax_rates VALUES 
(tax_code_seq.nextval, 12.5, 'VAT');
INSERT INTO tax_rates VALUES 
(tax_code_seq.nextval, 20, 'VAT + new tax (not real, example of scalability)');
INSERT INTO tax_rates VALUES 
(tax_code_seq.nextval, 5, 'reduced VAT (not real, example of scalability)');


INSERT INTO tax_rate_history VALUES 
(3, TO_DATE('2010-01-01','yyyy-mm-dd'), TO_DATE('2015-10-01','yyyy-mm-dd'), 10);
INSERT INTO tax_rate_history VALUES 
(1, TO_DATE('2015-01-01','yyyy-mm-dd'), TO_DATE('2015-12-31','yyyy-mm-dd'), 10);
INSERT INTO tax_rate_history VALUES 
(1, TO_DATE('2016-01-01','yyyy-mm-dd'), NULL, 12.5);

INSERT INTO product_category VALUES
(category_id_seq.nextval, 'Alcohol', 'Alcoholic beverages, drinks etc, that need a licence to sell');
INSERT INTO product_category VALUES
(category_id_seq.nextval, 'toiletries', 'soap, bath items etc.');
INSERT INTO product_category VALUES
(category_id_seq.nextval, 'meat', 'meats such as beef, chicken etc.');

INSERT INTO products 
(product_id, category_id, product_name, barcode, tax_code, price_rate, min_stock_level, reorder_level)
VALUES
(product_id_seq.nextval, 10, 'Forres Park Puncheon 750ml', '1234567879111', 1, 199.99, 2000, 1700);

INSERT INTO products 
(product_id, category_id, product_name, barcode, tax_code, price_rate, min_stock_level, reorder_level)
VALUES
(product_id_seq.nextval, 20, 'Dove Soap 3pk', '1234567879222', 1, 9.99, 500, 400);

INSERT INTO products 
(product_id, category_id, product_name, barcode, tax_code, price_rate, min_stock_level, reorder_level)
VALUES
(product_id_seq.nextval, 20, 'Colgate Max Fresh large', '1234567879333', 1, 19.99, 500, 400);

INSERT INTO products 
(product_id, category_id, unit_measure, product_name, price_lookup_code, tax_code, price_rate, min_stock_level, reorder_level)
VALUES
(product_id_seq.nextval, 30, 'kg', 'Imported Beef 50lb boxes', '021234', 1, 25.99, 1500, 1400);


INSERT INTO pending_price_rates VALUES
(1, TO_DATE('2017-01-01','yyyy-mm-dd'), 219.99);

INSERT INTO cost_sales_tracker VALUES
(transaction_id_seq.nextval, 1, 'IN', TO_DATE('2015-01-01','yyyy-mm-dd'), 1300, 1300, 150, 150);
INSERT INTO cost_sales_tracker VALUES
(transaction_id_seq.nextval, 2, 'IN', TO_DATE('2015-01-02','yyyy-mm-dd'), 300, 300, 5, 5);
INSERT INTO cost_sales_tracker VALUES
(transaction_id_seq.nextval, 3, 'IN', TO_DATE('2015-01-03','yyyy-mm-dd'), 250, 250, 15, 15);


INSERT INTO suppliers VALUES
(supplier_id_seq.nextval, 'Massy Distribution', 
'Corner Churchill Roosevelt Highway and Macoya Road, Trincity',
'They sell pringles');

INSERT INTO suppliers VALUES
(supplier_id_seq.nextval, 'Angostura', 
'Somewhere up North',
'They sell RUM');

INSERT INTO locations VALUES
(location_id_seq.nextval, 'Carlton Center', 'Branch', 'Carlton Center San Fernando');
INSERT INTO locations VALUES
(location_id_seq.nextval, 'Marabella Branch', 'Branch', 'Main Road Marabella');
INSERT INTO locations VALUES
(location_id_seq.nextval, 'S.F.C.S. Warehouse', 'Warehouse', 'St. James Street San Fernando');

INSERT INTO job_posts VALUES
(job_id_seq.nextval, 'general worker', 11, 'hour', 'week');
INSERT INTO job_posts VALUES
(job_id_seq.nextval, 'team leader', 15, 'hour', 'week');
INSERT INTO job_posts VALUES
(job_id_seq.nextval, 'cold storage', 19, 'hour', 'week');

INSERT INTO staff 
(staff_id, location_id, job_id, first_name, last_name, 
home_phone, hire_date, address, dob, wage_rate,
wage_interval, payment_schedule, gender, is_married,
is_active, is_permanent)
VALUES
(staff_id_seq.nextval, 10, 10, 'Harry', 'Potter', 
'333-9999', TO_DATE('2015-01-01','yyyy-mm-dd'), '101 trace Townsville', 
TO_DATE('1984-01-01','yyyy-mm-dd'), 11,
'hour', 'week', 'M', 'T',
'T', 'F');

INSERT INTO staff 
(staff_id, location_id, job_id, first_name, last_name, 
home_phone, hire_date, address, dob, wage_rate,
wage_interval, payment_schedule, gender, is_married,
is_active, is_permanent)
VALUES
(staff_id_seq.nextval, 10, 11, 'Sandy', 'Beach', 
'454-8587', TO_DATE('2015-02-02','yyyy-mm-dd'), '21 hello st. goodbyetown', 
TO_DATE('1975-02-04','yyyy-mm-dd'), 15,
'hour', 'week', 'F', 'T',
'T', 'F');

INSERT INTO staff 
(staff_id, location_id, job_id, first_name, last_name, 
home_phone, hire_date, address, dob, wage_rate,
wage_interval, payment_schedule, gender, is_married,
is_active, is_permanent)
VALUES
(staff_id_seq.nextval, 11, 12, 'Jason', 'Bourne', 
'457-8547', TO_DATE('2015-01-20','yyyy-mm-dd'), '22 nice to meet you village', 
TO_DATE('1983-03-03','yyyy-mm-dd'), 19,
'hour', 'week', 'M', 'F',
'T', 'T');

INSERT INTO work_hours VALUES 
(10, TO_DATE('2015-03-14','yyyy-mm-dd') - 7, 8);
INSERT INTO work_hours VALUES 
(11, TO_DATE('2015-03-14','yyyy-mm-dd') - 7, 8);
INSERT INTO work_hours VALUES 
(12, TO_DATE('2015-03-14','yyyy-mm-dd') - 7, 8);

INSERT INTO work_hours VALUES 
(10, TO_DATE('2015-03-14','yyyy-mm-dd') - 6, 7);
INSERT INTO work_hours VALUES 
(12, TO_DATE('2015-03-14','yyyy-mm-dd') - 6, 9);

INSERT INTO work_hours VALUES 
(10, TO_DATE('2015-03-14','yyyy-mm-dd') - 5, 8);
INSERT INTO work_hours VALUES 
(12, TO_DATE('2015-03-14','yyyy-mm-dd') - 5, 8);

INSERT INTO work_hours VALUES 
(10, TO_DATE('2015-03-14','yyyy-mm-dd') - 4, 8);
INSERT INTO work_hours VALUES 
(11, TO_DATE('2015-03-14','yyyy-mm-dd') - 4, 8);
INSERT INTO work_hours VALUES 
(12, TO_DATE('2015-03-14','yyyy-mm-dd') - 4, 9);

INSERT INTO work_hours VALUES 
(10, TO_DATE('2015-03-14','yyyy-mm-dd') - 3, 8);
INSERT INTO work_hours VALUES 
(12, TO_DATE('2015-03-14','yyyy-mm-dd') - 3, 8);

INSERT INTO work_hours VALUES 
(10, TO_DATE('2015-03-14','yyyy-mm-dd') - 2, 5);
INSERT INTO work_hours VALUES 
(11, TO_DATE('2015-03-14','yyyy-mm-dd') - 2, 8);
INSERT INTO work_hours VALUES 
(12, TO_DATE('2015-03-14','yyyy-mm-dd') - 2, 8);

INSERT INTO work_hours VALUES 
(10, TO_DATE('2015-03-14','yyyy-mm-dd') - 1, 8);
INSERT INTO work_hours VALUES 
(11, TO_DATE('2015-03-14','yyyy-mm-dd') - 1, 8);
INSERT INTO work_hours VALUES 
(12, TO_DATE('2015-03-14','yyyy-mm-dd') - 1, 8);

INSERT INTO work_hours VALUES 
(10, TO_DATE('2015-03-14','yyyy-mm-dd'), 8);
INSERT INTO work_hours VALUES 
(11, TO_DATE('2015-03-14','yyyy-mm-dd'), 8);
INSERT INTO work_hours VALUES 
(12, TO_DATE('2015-03-14','yyyy-mm-dd'), 8);

INSERT INTO work_hours VALUES 
(10, TO_DATE('2015-03-14','yyyy-mm-dd') + 1, 8);
INSERT INTO work_hours VALUES 
(11, TO_DATE('2015-03-14','yyyy-mm-dd') + 1, 8);
INSERT INTO work_hours VALUES 
(12, TO_DATE('2015-03-14','yyyy-mm-dd') + 2, 8);

INSERT INTO work_hours VALUES 
(10, TO_DATE('2015-03-14','yyyy-mm-dd') - 8, 8);
INSERT INTO work_hours VALUES 
(11, TO_DATE('2015-03-14','yyyy-mm-dd') - 9, 8);
INSERT INTO work_hours VALUES 
(12, TO_DATE('2015-03-14','yyyy-mm-dd') - 9, 8);

INSERT INTO cashier_stations VALUES 
(station_id_seq.nextval, 10, NULL);
INSERT INTO cashier_stations VALUES 
(station_id_seq.nextval, 10, NULL);
INSERT INTO cashier_stations VALUES 
(station_id_seq.nextval, 10, NULL);

INSERT INTO cashier_drawer_assignments VALUES
(assignment_id_seq.nextval, 11, 10, 
TO_DATE('2015-01-01,08:01:30', 'yyyy-mm-dd,HH24:MI:SS'),
TO_DATE('2015-01-01,12:02:10', 'yyyy-mm-dd,HH24:MI:SS'),
01, 500, 3000, NULL);

INSERT INTO cashier_drawer_assignments VALUES
(assignment_id_seq.nextval, 11, 10, 
TO_DATE('2015-01-01,12:05:30', 'yyyy-mm-dd,HH24:MI:SS'),
TO_DATE('2015-01-01,17:02:10', 'yyyy-mm-dd,HH24:MI:SS'),
01, 1000, 4500, 300);

INSERT INTO cashier_drawer_assignments VALUES
(assignment_id_seq.nextval, 11, 10, 
TO_DATE('2015-01-02,08:01:30', 'yyyy-mm-dd,HH24:MI:SS'),
TO_DATE('2015-01-02,12:02:10', 'yyyy-mm-dd,HH24:MI:SS'),
01, 500, 3000, 400);

INSERT INTO cashier_drawer_assignments VALUES
(assignment_id_seq.nextval, 11, 10, 
TO_DATE('2015-01-02,12:05:30', 'yyyy-mm-dd,HH24:MI:SS'),
TO_DATE('2015-01-02,17:02:10', 'yyyy-mm-dd,HH24:MI:SS'),
01, 200, 200, NULL);

INSERT INTO customer_bills VALUES
(bill_id_seq.nextval, 4, 
TO_DATE('2015-01-02,12:08:30','yyyy-mm-dd,HH:MI:SS'), 
NULL,
((199.99 *2) + (9.99 *10)), 0, NULL, 'unpaid'  
);

INSERT INTO billed_items VALUES
(bill_line_id_seq.nextval, 1, 1, 2, 199.99, 1, 10);
INSERT INTO billed_items VALUES
(bill_line_id_seq.nextval, 1, 2, 10, 9.99, 1, 10);

INSERT INTO customer_bills VALUES
(bill_id_seq.NEXTVAL, 4, 
TO_DATE('2015-01-02,12:06:30', 'yyyy-mm-dd,HH24:MI:SS'), 
NULL,
((199.99 *2) + (9.99 *10) + (19.99 *10)), 0, NULL, 'unpaid'  
);

INSERT INTO billed_items VALUES
(bill_line_id_seq.nextval, 2, 1, 2, 199.99, 1, 12.5);
INSERT INTO billed_items VALUES
(bill_line_id_seq.nextval, 2, 2, 10, 9.99, 1, 12.5);
INSERT INTO billed_items VALUES
(bill_line_id_seq.nextval, 2, 3, 10, 19.99, 3, 5);

INSERT INTO price_history VALUES
(1, TO_DATE('2014-01-01', 'yyyy-mm-dd'), 75.99, TO_DATE('2014-03-31', 'yyyy-mm-dd'));
INSERT INTO price_history VALUES
(1, TO_DATE('2014-04-01', 'yyyy-mm-dd'), 85.99, TO_DATE('2014-06-30', 'yyyy-mm-dd'));
INSERT INTO price_history VALUES
(1, TO_DATE('2014-07-01', 'yyyy-mm-dd'), 95.99, TO_DATE('2014-09-30', 'yyyy-mm-dd'));
INSERT INTO price_history VALUES
(1, TO_DATE('2014-10-01', 'yyyy-mm-dd'), 115.99, TO_DATE('2014-12-31', 'yyyy-mm-dd'));

INSERT INTO price_history VALUES
(2, TO_DATE('2014-01-01', 'yyyy-mm-dd'), 5.99, TO_DATE('2014-03-31', 'yyyy-mm-dd'));
INSERT INTO price_history VALUES
(2, TO_DATE('2014-04-01', 'yyyy-mm-dd'), 7.99, TO_DATE('2014-06-30', 'yyyy-mm-dd'));
INSERT INTO price_history VALUES
(2, TO_DATE('2014-07-01', 'yyyy-mm-dd'), 6.99, TO_DATE('2014-09-30', 'yyyy-mm-dd'));
INSERT INTO price_history VALUES
(2, TO_DATE('2014-10-01', 'yyyy-mm-dd'), 9.50, TO_DATE('2014-12-31', 'yyyy-mm-dd'));

INSERT INTO price_history VALUES
(3, TO_DATE('2015-01-01','yyyy-mm-dd'), 29.99, TO_DATE('2016-01-01','yyyy-mm-dd'));

INSERT INTO inventory_by_location VALUES 
(1, 10, 200, 500, 300);
INSERT INTO inventory_by_location VALUES 
(2, 10, 250, 200, 100);
INSERT INTO inventory_by_location VALUES 
(3, 10, 150, 300, 200);

INSERT INTO inventory_by_location VALUES 
(1, 11, 1100, 1000, 500);
INSERT INTO inventory_by_location VALUES 
(2, 11, 50, 520, 300);
INSERT INTO inventory_by_location VALUES 
(3, 11, 100, 900, 500);

INSERT INTO suppliers_per_products VALUES (11, 1);
INSERT INTO suppliers_per_products VALUES (10, 2);
INSERT INTO suppliers_per_products VALUES (10, 3);



INSERT INTO office_sections VALUES 
(office_id_seq.nextval, '123-4578', 101, 10, 'Front Desk', 10);
INSERT INTO office_sections VALUES 
(office_id_seq.nextval, '123-4578', 102, 10, 'Accounting', 11);
INSERT INTO office_sections VALUES 
(office_id_seq.nextval, '123-4578', 103, 10, 'Purchasing', 11);
INSERT INTO office_sections VALUES 
(office_id_seq.nextval, '888-4578', 101, 11, 'Front Desk', 12);
INSERT INTO office_sections VALUES 
(office_id_seq.nextval, '888-4578', 102, 11, 'Accounting', 11);
INSERT INTO office_sections VALUES 
(office_id_seq.nextval, '888-5678', NULL, 11, 'Warehouse', 10);

INSERT INTO supplier_contacts VALUES 
(sup_contact_id_seq.nextval, 10, '555-4545', NULL, NULL,
'Don', 'Prince', NULL, NULL);
INSERT INTO supplier_contacts VALUES 
(sup_contact_id_seq.nextval, 10, '555-4578', NULL, NULL,
'Crow', 'Nest', NULL, NULL);
INSERT INTO supplier_contacts VALUES 
(sup_contact_id_seq.nextval, 11, '555-2314', NULL, NULL,
'Lutchman', 'Rumsingh', NULL, NULL);

INSERT INTO payroll VALUES
(payroll_id_seq.nextval, 10,
TO_DATE('2015-05-01','yyyy-mm-dd'), TO_DATE('2015-05-07','yyyy-mm-dd'),
40, 8, NULL, 11, 12, 2, NULL, NULL, NULL, NULL, NULL, 
TO_DATE('2015-05-07','yyyy-mm-dd'), 572, 558, NULL);

INSERT INTO payroll VALUES
(payroll_id_seq.nextval, 10,
TO_DATE('2015-05-08','yyyy-mm-dd'), TO_DATE('2015-05-14','yyyy-mm-dd'),
40, 8, NULL, 11, 12, 2, NULL, NULL, NULL, NULL, NULL, 
TO_DATE('2015-05-14','yyyy-mm-dd'), 572, 558, NULL);

INSERT INTO payroll VALUES
(payroll_id_seq.nextval, 10,
TO_DATE('2015-05-15','yyyy-mm-dd'), TO_DATE('2015-05-21','yyyy-mm-dd'),
40, 8, NULL, 11, 12, 2, NULL, NULL, NULL, NULL, NULL, 
TO_DATE('2015-05-21','yyyy-mm-dd'), 572, 558, NULL);

INSERT INTO payroll VALUES
(payroll_id_seq.nextval, 11,
TO_DATE('2015-05-01','yyyy-mm-dd'), TO_DATE('2015-05-07','yyyy-mm-dd'),
40, 8, NULL, 11, 12, 2, NULL, NULL, NULL, NULL, NULL, 
TO_DATE('2015-05-07','yyyy-mm-dd'), 582, 568, NULL);

INSERT INTO payroll VALUES
(payroll_id_seq.nextval, 11,
TO_DATE('2015-05-08','yyyy-mm-dd'), TO_DATE('2015-05-14','yyyy-mm-dd'),
40, 8, NULL, 11, 12, 2, NULL, NULL, NULL, NULL, NULL, 
TO_DATE('2015-05-14','yyyy-mm-dd'), 582, 568, NULL);

INSERT INTO payroll VALUES
(payroll_id_seq.nextval, 11,
TO_DATE('2015-05-15','yyyy-mm-dd'), TO_DATE('2015-05-21','yyyy-mm-dd'),
40, 8, NULL, 11, 12, 2, NULL, NULL, NULL, NULL, NULL, 
TO_DATE('2015-05-21','yyyy-mm-dd'), 582, 568, NULL);

INSERT INTO payroll VALUES
(payroll_id_seq.nextval, 12,
TO_DATE('2015-05-01','yyyy-mm-dd'), TO_DATE('2015-05-07','yyyy-mm-dd'),
40, 8, NULL, 11, 12, 2, NULL, NULL, NULL, NULL, NULL, 
TO_DATE('2015-05-07','yyyy-mm-dd'), 562, 548, NULL);

INSERT INTO payroll VALUES
(payroll_id_seq.nextval, 12,
TO_DATE('2015-05-08','yyyy-mm-dd'), TO_DATE('2015-05-14','yyyy-mm-dd'),
40, 8, NULL, 11, 12, 2, NULL, NULL, NULL, NULL, NULL, 
TO_DATE('2015-05-14','yyyy-mm-dd'), 562, 548, NULL);

INSERT INTO payroll VALUES
(payroll_id_seq.nextval, 12,
TO_DATE('2015-05-15','yyyy-mm-dd'), TO_DATE('2015-05-21','yyyy-mm-dd'),
40, 8, NULL, 11, 12, 2, NULL, NULL, NULL, NULL, NULL, 
TO_DATE('2015-05-21','yyyy-mm-dd'), 562, 548, NULL);


INSERT INTO purchase_orders VALUES
(po_id_seq.nextval, 11, 10, 10, 'T', 'T', 
TO_DATE('2015-01-01','yyyy-mm-dd'), TO_DATE('2015-01-01','yyyy-mm-dd'));

INSERT INTO purchase_orders VALUES
(po_id_seq.nextval, 11, 10, 10, 'T', 'T', 
TO_DATE('2015-01-02','yyyy-mm-dd'), TO_DATE('2015-01-02','yyyy-mm-dd'));

INSERT INTO purchase_orders VALUES
(po_id_seq.nextval, 11, 10, 10, 'T', 'F', 
TO_DATE('2015-01-03','yyyy-mm-dd'), NULL);

INSERT INTO purchase_orders VALUES
(po_id_seq.nextval, 11, 10, 10, 'F', 'T', 
TO_DATE('2015-01-04','yyyy-mm-dd'), TO_DATE('2015-01-05','yyyy-mm-dd'));

INSERT INTO purchase_order_lines VALUES
(po_line_id_seq.nextval, 1, 1, 300, 177);
INSERT INTO purchase_order_lines VALUES
(po_line_id_seq.nextval, 1, 2, 50, 7);
INSERT INTO purchase_order_lines VALUES
(po_line_id_seq.nextval, 1, 3, 75, 12);

INSERT INTO purchase_order_lines VALUES
(po_line_id_seq.nextval, 2, 1, 300, 177);
INSERT INTO purchase_order_lines VALUES
(po_line_id_seq.nextval, 2, 2, 50, 7);
INSERT INTO purchase_order_lines VALUES
(po_line_id_seq.nextval, 2, 3, 75, 12);

INSERT INTO purchase_order_lines VALUES
(po_line_id_seq.nextval, 3, 1, 300, 177);
INSERT INTO purchase_order_lines VALUES
(po_line_id_seq.nextval, 3, 2, 50, 7);
INSERT INTO purchase_order_lines VALUES
(po_line_id_seq.nextval, 3, 3, 75, 12);

INSERT INTO purchase_order_lines VALUES
(po_line_id_seq.nextval, 4, 1, 300, 177);
INSERT INTO purchase_order_lines VALUES
(po_line_id_seq.nextval, 4, 2, 50, 7);
INSERT INTO purchase_order_lines VALUES
(po_line_id_seq.nextval, 4, 3, 75, 12);


DROP TABLE sold_products CASCADE CONSTRAINTS;
DROP SEQUENCE sold_products_seq;
CREATE SEQUENCE sold_products_seq START WITH 1 INCREMENT BY 1 CACHE 500;
CREATE TABLE sold_products (
    sold_products_id NUMBER, 
	product_id NUMBER,
	quantity NUMBER,
	CONSTRAINT sold_products_pk PRIMARY KEY (sold_products_id),
    CONSTRAINT sold_products_fk FOREIGN KEY (product_id) REFERENCES products(product_id)
);
