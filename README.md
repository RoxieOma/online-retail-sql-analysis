## PROJECT OVERVIEW – Online Retail Data Analysis (SQL-Based)
This project shows how to transform, structure, normalize, and analyze transactional online retail data using purely SQL. 
The original dataset is a CSV file, which was sourced from [Kaggle](https://www.kaggle.com/datasets/tunguz/online-retail) and contains information on customers' transactions. 

The goal of this project is to transform messy e-Commerce raw files strictly using SQL (PostgreSQL) into clean data with structured relational schemas where meaningful insights that mimic real-life situations can be derived. 

## Dataset
 * **Source:** kaggle (online retail)
 * **Format:** CSV
 * **Content:** invoices, stockcode, customer’s ID, description of the product, country, price and quantity 

## PROJECT OBJECTIVE
  *	Explore and clean the messy data
  *	Normalize the flat CSV file into structured SQL tables such as the ORDERS table, CANCELLED table, INVOICES table, PRODUCTS table, and CUSTOMERS table.
  * Implement FOREIGN KEYS and Constraints to provide data quality and referential integrity.
  *	Create a CANCELLED table to properly isolate returned/cancelled orders.
  *	Populate a revenue column with the ORDERS and CANCELLED tables.
  *	Answer key business questions through SQL queries.

## PROJECT PHASE
The project would be divided into two phases:
  *	Phase 1: This would deal with cleaning the data and creating schemas.
  *	Phase 2: This phase tackles business questions and possible visualizations using Power BI.

## TABLES CREATED
Tables created for this project are: 
|Table Name |	 Description                                                                                            |
|-----------|---------------------------------------------------------------------------------------------------------|
|Orders:    |  All purchase orders where quantity > 0 and contain invoiceID, stockid, quantity, price, and customerid |
|Cancelled	|  All purchase orders where quantity < 0                                                                 |
|Customers	|  Each row contains the unique ID of the customer, with the most frequent country of that customer       |
|Invoices	  |  Each row contains a unique invoice ID with the date the invoices were issued                           |
|Products	  |  Each row contains a unique invoice ID with the date the invoices were issued                           |

## SCHEMA
 ![image](https://github.com/user-attachments/assets/6c44c91a-5b5d-41de-8f7f-19f55ce85936)

## TOOLS
The tools used are 
  *	PostgreSQL for data manipulation and querying the database
  *	PgAdmin4 GUI.
  *	GitHub Desktop.

## RESOURCES
  *	Data source: https://www.kaggle.com/datasets/tunguz/online-retail
  *	SQL for Data Analysis by Cathy Tanimura
  *	Stackoverflow

