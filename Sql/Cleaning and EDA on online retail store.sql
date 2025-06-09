-- CREATE A TABLE CALLED STORE--
DROP TABLE IF EXISTS store; -- this drops tables if the store table already exists --

CREATE TABLE store(
	Invoice	VARCHAR,
	StockCode VARCHAR,
	Description	TEXT,
	Quantity FLOAT,	
	InvoiceDate	TIMESTAMP,
	Price NUMERIC,
	CustomerID VARCHAR,
	Country VARCHAR
);


-- EXPLORE THE DATA --
SELECT * FROM store; -- view the table called store --

SELECT MAX(invoicedate), MIN(invoicedate) -- explore length of the transactions --
FROM store

-- confirm total data set --
SELECT COUNT(*) -- result show 541,910 --
FROM store;

-- Missing values in description --
SELECT COUNT(description) -- Count number of null values in description, date, storeid, customerid,
FROM store
WHERE description = '';

-- Explore and clean the dataset --
-- perform some standardization of the data --
/* description column has the text in upper case 
standardize the text data and ensure consistency */
SELECT INITCAP(description)
FROM store;

SELECT INITCAP(Country)
FROM store;

-- Now update the records on the table --
UPDATE store
SET description = INITCAP(description)
	Country = INITCAP(Country);

-- investigate for missing values --
-- Missing values in customerid --
SELECT COUNT(customerid) -- Count number of null values in description, date, storeid, customerid,
FROM store
WHERE customerid = ''; -- we used IS NULL and it gave zero count which is incorrect when exploring with distinct so we used ''--

-- DATA CLEANING AND EDA--
-- Show the correlation between missing values and date --
SELECT CORR(CASE WHEN customerid IS NULL OR customerid = '' 
				THEN 1 ELSE 0 END, EXTRACT(DAY FROM invoicedate)) -- note that you cannot correlate a time and an integer --
FROM store; -- there is a negative correlation here --

-- Lets view customerid with empty values by dates, months and years  --
SELECT EXTRACT(DAY FROM invoicedate) AS days,EXTRACT(MONTH FROM invoicedate) AS months,
		EXTRACT(YEAR FROM invoicedate) AS years,
		COUNT(CASE WHEN customerid IS NULL OR customerid = '' 
			THEN 1 ELSE 0 END) AS emptyval -- note that you cannot correlate a time and an integer --
FROM store
GROUP BY days, months, years
ORDER BY emptyval DESC; -- 8th and 6th have the highest empty cells --

-- also check quarters with high empty values --
SELECT EXTRACT(QUARTER FROM invoicedate) AS quarters,
		COUNT(CASE WHEN customerid IS NULL OR customerid = '' 
			THEN 1 ELSE 0 END) AS emptyval -- note that you cannot correlate a time and an integer --
FROM store
GROUP BY quarters
ORDER BY emptyval DESC; -- The last quarter had the largest amount of missing values --

-- Lets view day of the week with high empty values in the customerid --
SELECT TO_CHAR(invoicedate, 'Day') AS dow,
		COUNT(CASE WHEN customerid IS NULL OR customerid = '' 
			THEN 1 ELSE 0 END) AS emptyval -- note that you cannot correlate a time and an integer --
FROM store
GROUP BY dow
ORDER BY emptyval DESC; -- thursdays and Tuesdays have the highest empty cells --

/* let's investigate correlation between missing description and missing customerid -*/
SELECT CORR(CASE WHEN customerid IS NULL OR customerid = '' 
				THEN 1 ELSE 0 END, 
			CASE WHEN description IS NULL OR description = '' 
				THEN 1 ELSE 0 END)
FROM store; -- no correlation between the two variables --


-- using delete to remove missing customerid rows --
DELETE FROM store
WHERE customerid = '';

-- using delete to remove missing description rows --
DELETE FROM store
WHERE description = '';

SELECT TRIM(invoice), TRIM(customerid),
		TRIM(description), TRIM(country),
		TRIM(stockcode)
FROM store;

-- update the records --
UPDATE store
SET invoice = TRIM(invoice),
	description = TRIM(description),
	customerid = TRIM(customerid),
	stockcode = TRIM(stockcode),
	country = TRIM(country);

-- REMOVING DUPLICATES --
/* Check for duplicates and remove EXACT duplicates from the store table** 
confirm the exact duplicates in the dataset and
Preview duplicates which you would remove */
WITH Rankeditem AS (
    SELECT *, 
           ROW_NUMBER() OVER(PARTITION BY customerid, invoice, StockCode, price ORDER BY StockCode) AS duplicates
    FROM store
)SELECT *
FROM Rankeditem -- this shows exact duplicates, that is where all items are exactly the same --
WHERE duplicates > 1; -- filtered out only exact duplicates --


-- Remove duplicates --
WITH Rankeditem AS (
    SELECT ctid, -- this ctid is a unique identifier that identifies the duplicates here -- 
           ROW_NUMBER() OVER(PARTITION BY customerid, invoice, StockCode, price ORDER BY StockCode) AS duplicates
    FROM store -- the row_number is used to identifier duplicated stockcode description --
)DELETE FROM store
WHERE ctid IN (
	SELECT ctid -- so the ctid is used to uniquely filter and delete duplicate stockcode descriptions --
	FROM Rankeditem
	WHERE duplicates > 1
); -- removes duplicated customerid, invoices, stockcode, and price --


-- confirm that duplicates has been removed from the store table --
WITH Rankeditem AS (
    SELECT *, 
           ROW_NUMBER() OVER(PARTITION BY customerid, invoice, StockCode, price ORDER BY StockCode) AS duplicates
    FROM store
)SELECT *
FROM Rankeditem -- this shows exact duplicates, that is where all items are exactly the same --
WHERE duplicates > 1; 

-- stockcode with more than 1 descriptions --
SELECT DISTINCT stockcode, description
FROM store
WHERE stockcode IN (SELECT stockcode
		FROM store 
		GROUP BY stockcode
		HAVING COUNT(DISTINCT description) > 1)
ORDER BY stockcode;

-- clean the data and ensure each unique stockcode maintains a unique description --
DROP TABLE product_clean;
CREATE TEMP TABLE product_clean AS(
SELECT stockcode,
       MIN(description) AS description  -- or use MAX(description) if preferred
FROM store
WHERE description IS NOT NULL
GROUP BY stockcode);

-- update the main record such that the changes are effected --
UPDATE store AS s
SET description = p.description
FROM product_clean AS p
WHERE s.stockcode = p.stockcode
  AND s.description IS DISTINCT FROM p.description;


-- remove stockcode with more than 1 descriptions --
SELECT stockcode, COUNT(DISTINCT description) AS desc_variants
FROM store
GROUP BY stockcode
HAVING COUNT(DISTINCT description) > 1;

-- create a temporary table --
DROP TABLE IF EXISTS dup_description
CREATE TEMP TABLE dup_description AS( -- created a temporary table to store the duplicate description --
	SELECT stockcode, MIN(ctid) AS keepid
	FROM store
	WHERE stockcode IN( -- this limits the query to only stockcodes with more than 1 description --
		SELECT stockcode
		FROM store
		GROUP BY stockcode
		HAVING COUNT(DISTINCT DESCRIPTION) > 1) -- this query gives us stockcode with more than 1 description --
	GROUP BY stockcode -- this groups the stockcode and enables us to keep just one
);

-- removing duplicates stored in the temp table from the store table --
DELETE FROM store
WHERE stockcode IN (
	SELECT stockcode
	FROM dup_description
) AND ctid IN( -- This CTID is a unique identifier as our table does not have a primary key or unique identifier. --
	SELECT keepid
	FROM dup_description
);


-- Explore price range --
SELECT MAX(price), MIN(price)
FROM store;

-- Explore quantity range --
SELECT MAX(quantity), MIN(quantity) -- negative quantity was observed --
FROM store;

-- Explore the negative quantity --
SELECT customerid, price, quantity
FROM store
WHERE price <= 0 OR quantity < 1; -- question is, can quantity be less than 1? --

-- Explore items with less than 1 --
SELECT invoice, 
		stockcode,
		customerid,
		price, 
		quantity -- observe that invoice that started with C were cancelled or returned --
FROM store
WHERE quantity < 1 AND price > 0; -- from observation, these items were returned or cancelled since they have a price tag --


-- Explore prices with less than 1 --
SELECT invoice, price, quantity  -- from observation, there are no items with less than 1 quantity --
FROM store
WHERE price <= 0; -- we can say that these items are free items--



-- NORMALIZE THE TABLE --
/* Introduce the following table to normalize the flat file and 
and establish relationships between the tables*/
-- Create a products table --
DROP TABLE IF EXISTS product;
CREATE TABLE product(
	stockcode VARCHAR PRIMARY KEY, -- aim is to make stockcode a primary key --
	description VARCHAR 
);
INSERT INTO product (stockcode, description)
SELECT stockcode, MIN(description) -- this ensures that we keep only one unique stocks id --
FROM store
GROUP BY stockcode;


-- Create a customer's table --
DROP TABLE IF EXISTS customers
CREATE TABLE customers(
	customerid VARCHAR PRIMARY KEY, -- make customerid a primary key --
	country VARCHAR
);
INSERT INTO customers (customerid, country)
SELECT customerid, MIN(country) -- handles multiple country from one customer --
FROM store
WHERE customerid IS NOT NULL -- exclude null values --
GROUP BY customerid
ON CONFLICT (customerid) DO NOTHING; -- let's SQL know that it should do nothing when customer ID is multiple --

-- create a cancelled table --
DROP TABLE cancelled; -- dropped the cancelled table if it exist, so this is orders that were cancelled --
CREATE TABLE cancelled(
	cancelledid SERIAL PRIMARY KEY, -- this creates a primary key for the cancelled table --
	invoice VARCHAR,
	customerid VARCHAR,
	quantity NUMERIC,
	price NUMERIC,
	FOREIGN KEY (customerid) REFERENCES customers(customerid)
);
-- insert into the cancelled table --
INSERT INTO cancelled (invoice, customerid, quantity, price)
SELECT invoice,
		customerid,
		quantity,
		price-- took the total number of orders cancelled per customer and per invoice --
FROM store
WHERE quantity < 0 AND price <> 0; -- we have established that price = 0 are free purchases --


-- create an invoices table --
DROP TABLE invoices -- dropped the invoices table if it exist --
CREATE TABLE invoices (
	invoice VARCHAR PRIMARY KEY,
	customerid VARCHAR,
	invoicedate TIMESTAMP
);
--insert into the invoice table--
INSERT INTO invoices (invoice, customerid, invoicedate)
SELECT invoice, 
		MAX(customerid), -- this was used because each customer is tied to one invoice --
		MIN(invoicedate) -- this was because invoicedate has multiple date entry which is possible for one invoice with different stockcodes --
FROM store
GROUP BY invoice;

-- create an orders table --
-- Build a model by establishing a relationship between the tables--
DROP TABLE IF EXISTS orders
CREATE TABLE orders (
    id SERIAL PRIMARY KEY, -- the main store table does not have an id for orders hence we used serial to do this --
    invoice VARCHAR,
    stockcode VARCHAR,
    customerid VARCHAR,
    quantity INT,
    price NUMERIC,
    FOREIGN KEY (invoice) REFERENCES invoices(invoice),
    FOREIGN KEY (stockcode) REFERENCES product(stockcode),
    FOREIGN KEY (customerid) REFERENCES customers(customerid)
);
INSERT INTO orders(invoice, stockcode, customerid, quantity, price) -- insert the required information from store --
SELECT invoice, stockcode,
		customerid, quantity,
		price
FROM store
WHERE quantity > 0;


--INTRODUCE A REVENUE COLUMN TO THE ORDERS --
-- introduced a revenues column and updated it with a product of the quantity and price --
ALTER TABLE orders
ADD COLUMN revenue FLOAT;
-- update the revenue table --
UPDATE orders
SET revenue = quantity * price;

--INTRODUCE A NEGATIVE REVENUE COLUMN TO THE CANCELLED TABLE --
ALTER TABLE cancelled
ADD COLUMN revenue FLOAT;
-- update the records --
UPDATE cancelled
SET revenue = quantity * price;

DROP TABLE IF EXISTS store; -- drop this table --

