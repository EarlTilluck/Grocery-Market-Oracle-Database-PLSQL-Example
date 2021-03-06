# Grocery-Market-Oracle-Database-PLSQL-Example
 Database design for real world supermarket using Oracle PLSQL

## About
This was a project assignment for a class on Database Design.  
The goal was to create a real life database example and supply 25 PLSQL constructs that would be useful to the organization.  
The project is based on [JTA Supermarkets](https://jtasupermarkets.com/home/) but is not affiliated with them.

## Instructions

### Files
* JTA_Create_Database.sql: Creates all tables and inserts sample data.
* JTA_Packages.sql: Creates 25 packages and triggers. Each construct has been given a number via a comment in the code.
* JTA_Test_Code.sql: Anonymous blocks and SQL statements that can be used to test each of the 25 constructs.  
* ERD_High_quality.png: PNG image of the database ERD (design). 

### About Triggers:
To test logon and logoff triggers (no: 25), it may be necessary to run the database on a local installation of Oracle Express 11g.
We created a user account from the main Sys account using the following commands:
```
CREATE USER admin123 IDENTIFIED BY admin123;
GRANT CONNECT TO admin123;
GRANT CREATE SESSION TO admin123; 
GRANT all PRIVILEGES TO admin123;
GRANT UNLIMITED TABLESPACE TO admin123;
```
Then we logged onto the database using that account, created the database and packages in that schema and tested by disconnecting and reconnecting to the database.  

## Report
### Business Overview:
JTA supermarket Limited is one of the most well known and largest grocery chains in south Trinidad. It was founded as a small grocery store named J.T. Allum & Co., Ltd. in 1934 and has since grown over the decades into a major business group dealing with property development and retail. The organization's strategy for the future involves expanding its brand into other parts of the country, eventually becoming the premier food retailer in Trinidad and Tobago. Currently, the organization owns and operates 5 grocery store locations situated in and nearby the San Fernando area, including Marabella and Corinth. As such, the organization's information needs will continue to change as the company grows and diversifies.

### Project Overview:
This project focuses only on the retail part of the organization. Our plan is to design and implement a database that serves the information needs of the 5 existing branches. The database will be made with scalability in mind and therefore will still be able to serve the needs of the organization if it expands its operations.


### Business Rules:
The following business rules apply to the organization. 

#### Products
* Purchase orders are usually made by sales representatives and are sent to the purchasing department for approval.
* Purchase orders may not always be fulfilled due to stock shortages and so on.
* Tax rates are applied to products, these rates may change over time.
* The company must pay taxes on goods sold. Failure to make accurate payments can lead to severe penalties.
* The average cost of items change over time. 
* Prices change regularly. Every day there will be at least a few changes. 
* A price change will usually only take place at the beginning of the day before the grocery opens for business.
* The grocery tries to maintain a minimum level of stock for each item with rotation of goods.
* Some items have barcodes that uniquely identify them while other items such as meats are packaged in-store and is identified with a price look up code. (see appendix)
* Some items like meats, beans and vegetables are measured. The measurements may vary in type. Some may be in pounds, others kilograms.
* Items are categorized and shelved into distinct lanes for customer convenience. 
* Each branch has its own warehouse. In the future, JTA will also maintain warehouses that are separate from branches. 
* Products are often exchanged between warehouses and/or branches.
* Items may get stolen or damaged. These need to be tracked and reported.

#### Suppliers
* Usually there is only one wholesaler that sells a particular brand product to the company. 
* The company may have many contacts for the same supplier.
* Payments to suppliers may not be made on the same day that goods arrive at the branches.
* Each branch may purchase goods from suppliers for their own inventory. The head office processes and makes payments on all invoices.
* The price of goods being bought change over time.

#### Staff
* Personal Information on staff members are recorded, including name address, contact information and so on.
* Some staff members are paid weekly, fortnightly and monthly. 
* Some staff members get paid a flat rate, while others get paid per hour.
* Payment rates may go up over time.
* Employees who get paid by the hour can get overtime and double-time pay rates depending on how long they work and on what days.
* Employees can get paid for a fraction of an hour, e.g. 8.5 hours worked.
* Staff may be asked to work multiple locations in a week
* Deductions are made on staff pay. Not all deductions may apply to each person. An Example of a deduction would be National Insurance payments or a pension plan payment.

#### Bills
* Cashier names and the lane number must be attached to bills.
* The amount of money cashiers take at the beginning of their shift and the amount they replace at the end must be tracked and accurately accounted for. 
* There are several ways to pay for bills, including cash and non-cash methods like linx and credit-card.
* Bills may not be paid at the same time they are created. Although very rare, some customers are allowed to leave and pay later.


### Additional Notes on Database Design:

#### Immutable data:
Data falls under two categories: immutable and mutable or transactional. Data can change from mutable to immutable at the end of a transaction. An example of immutable data would be the VAT tax rate applied to a product sold in January 2016. The tax rate associated with that item should never change at any time after the product was sold, even if the VAT tax rate has changed since then. 
Since we are dealing with sensitive data where accuracy is very important, it is wise to store immutable data instead of attempting to derive the value using formulas that may change over time. This improves the speed of the database and guarantees accuracy while at the same time sacrificing a nominal amount of data storage space.

#### Redundancy:
When dealing with tables that will potentially have millions of records in them, the need to quickly access data begins to surpass the need for saving storage space. We can save a lot of precious time if we choose to store some values (especially in big tables) where we would otherwise derive them.

#### No Need for Indexes:
As far as we have seen there is no need to create indexes for the tables in the database. According to Oracle, we should not bother with indexes if tables are updated frequently or if they are really small. They also don't recommend indexing columns that are frequently referenced as part of expressions. Our tables tend to pass at least one these criteria.

#### Numbers:
All numbers in Oracle are stored internally in a variable length format. Therefore there is no need to restrict the scale and precision of the number in the hopes of saving space. Restrictions are used on monetary values, only to prevent possible user errors such as entering a value with 3 decimal places instead of 2.
 
#### Commits:
Most Transactions in the database 'jta' package commit immediately upon success. This is so that you don’t lose all pending transactions during a power outage or similar event. This has been known to happen often in the past. 

#### Triggers:
While it is tempting to create triggers to automatically update tables, we have found that they can be unpredictable, especially since they fire only once per transaction. Instead we opted to have procedures designed to perform task (e.g. receive payment on bill) call or invoke various other functions/procedures (e.g. remove items from inventory that was on a bill) to perform the additional tasks required. According to Oracle's learning material, triggers should not be used for things that can easily be done otherwise with SQL or PL/SQL constructs.

### Barcodes, Price Lookup and how they work

GS1 is an international organization that provides unique Barcode numbers for companies around the world to use on their products.  Barcodes fall into 2 categories: UPC codes which are 12 digits and are prevalent in the United States and Canada and EAN codes which are 13 digits and serves as the standard for European and Latin American countries.  

Barcodes are useful for pre-packaged goods like tins of sardine or packets or ketchup. For these items, a standard price rate for each item is applied. However, not all items sold in the business are sold at the same rate. Weighted items such as packages of meat or bags of vegetables will have a different price rate for each individual package. The problem of identifying these items as well as the finding the variable price is resolved by using a Price Lookup code.  

Price Lookup codes or PLU's are 12 or 13 digit codes that resemble barcodes. When these codes are scanned into the point of sale system using a barcode scanner, the software recognizes the code as a PLU and is able to find out the id and unique price for that item.  

How to create a PLU:

1. The PLU code should be the same length of a regular barcode number. We will be using 12 digits in our case.
2. The code should start with the number 2. This is the globally recognized prefix used to identify a PLU. UPC and EAN codes will never start with the number 2.
3. The following 4 digits are used as an id number for each product. 
4. After this a check digit is added to validate the id number. 
5. The next 5 digits are used for the price, this gives us a maximum value of $999.99
6. Finally, the last digit is a check digit used to validate the entire code to ensure it was read correctly.

Example of a Price Lookup Code  

2|1234|5|01206|7
-|----|-|-----|-
Prefix | Item ID | Check Digit | Price ($12.06) | Check Digit



 



