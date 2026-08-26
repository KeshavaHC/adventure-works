SELECT * FROM adventureworks.dimcustomer;
desc dimcustomer;
select count(*) from dimcustomer;
select * from dimcustomer limit 10;
select YearlyIncome from dimcustomer limit 5;
select * from dimcustomer where YearlyIncome = " ";
select birthdate from dimcustomer limit 5;

alter table dimcustomer
modify YearlyIncome decimal(10,2);

delete from dimcustomer
where `ï»¿CustomerKey` is null;

desc dimdate;
select FullDateAlternateKey from dimdate limit 5;

select * from dimproduct limit 10;
drop table dimproduct;

select * from dimproductcategory;
desc dimproductcategory;

select * from dimproductsubcategory;
desc dimproductsubcategory;

select * from dimsalesterritory;
desc dimsalesterritory;
delete from dimsalesterritory where SalesTerritoryAlternateKey  is null;

drop table dimproduct;
drop table if exists dimproduct;

DROP TABLE IF EXISTS dimproduct_raw;

desc dimproduct;
select * from dimproduct;

alter table dimproduct 
modify `unit price` decimal(10,2);

desc fact_internet_sales_new;
desc factinternetsales;
select * from fact_internet_sales_new limit 10;
select * from factinternetsales limit 10;



CREATE TABLE sales AS
SELECT 
    ï»¿ProductKey,
    OrderDateKey,
    DueDateKey,
    ShipDateKey,
    CustomerKey,
    SalesAmount,
    OrderQuantity,
    UnitPrice
FROM fact_internet_sales_new

UNION ALL

SELECT 
   ï»¿ProductKey,
    OrderDateKey,
    DueDateKey,
    ShipDateKey,
    CustomerKey,
    SalesAmount,
    OrderQuantity,
    UnitPrice
FROM factinternetsales;

select * from sales;
desc sales;

alter table sales
modify `salesamount` decimal(10,2),
modify `unitprice` decimal(10,2);

delete from sales where `salesamount` is null;
delete from sales where `salesamount`<0;

select * from sales where ï»¿ProductKey is null;

select sum(salesamount)
from sales;

select sum(orderquantity)
from sales;

desc dimcustomer;
desc sales;
desc dimdate;


/* changed customer key column name and added index. */
alter table dimcustomer add primary key(customerkey);
show create table dimcustomer;
alter table dimcustomer change `ï»¿CustomerKey` Customerkey int;
alter table sales
add index(Customerkey);


select count(*) from sales s left join dimcustomer d on s.customerkey = d.ï»¿CustomerKey where s.customerkey is null;
select count(*) from sales s left join dimdate d on s.orderdatekey = d.ï»¿DateKey where s.customerkey is null;
select count(*) from sales s left join dimproduct d on s.ï»¿ProductKey = d.ï»¿ProductKey where s.customerkey is null;

alter table sales
add constraint fk_customer_3
foreign key(Customerkey)
references dimcustomer(Customerkey);

show table status where Name = 'sales';   ##to check whether it has connected to the engine or not
show table status where Name = 'dimcustomer';

/*building Reltionship with dimdate and sales, Basically data Modelling,adding primary key to the datekey*/

desc dimdate;
desc sales;
alter table dimdate change `ï»¿DateKey` Datekey int;
alter table dimdate 
add primary key(datekey);

alter table sales
add constraint fk_orderdate
foreign key(orderdatekey)
references dimdate(datekey);

/*building Reltionship with dimproductcategory and productsubcategory , Basically data Modelling,adding primary key to the productkey*  (snowflake schema) category is primary key wheras sub category is foriegn key*/
desc dimproductcategory;
desc dimproductsubcategory;

alter table dimproductcategory change `ï»¿ProductCategoryKey` productcategorykey int;
alter table dimproductcategory add primary key(productcategorykey);

alter table dimproductsubcategory
add constraint fk_category
foreign key(productcategorykey)
references dimproductcategory(Productcategorykey);


/*building Reltionship with productsubcategory and product, Basically data Modelling,adding primary key to the productsubcatkey*  (snowflake schema) subcategory is primary key wheras productkey is foriegn key*/
desc dimproductsubcategory;
desc dimproduct;
ALTER TABLE dimproductsubcategory change `ï»¿ProductSubcategoryKey` productsubcategorykey int;

ALTER TABLE dimproductsubcategory
ADD PRIMARY KEY (ProductSubcategoryKey);

ALTER TABLE dimproduct
ADD CONSTRAINT fk_product_subcategory
FOREIGN KEY (ProductSubcategoryKey)
REFERENCES dimproductsubcategory(ProductSubcategoryKey);

/*building Reltionship with dimproduct and sales, Basically data Modelling,adding primary key to the datekey*/

desc dimproduct;
desc sales;
alter table dimproduct change `ï»¿ProductKey` productkey int;
alter table sales change `ï»¿ProductKey` productkey int;

ALTER TABLE dimproduct
MODIFY ListPrice DECIMAL(10,2),
MODIFY StandardCost DECIMAL(10,2);

alter table dimproduct 
add primary key(productkey);

select s.productkey from sales s left join dimproduct p on s.productkey = p.productkey;
select s.productkey from sales s left join dimproduct p on s.productkey = p.productkey where p.productkey is null;
DELETE s
FROM sales s
LEFT JOIN dimproduct p 
ON s.ProductKey = p.ProductKey
WHERE p.ProductKey IS NULL;

ALTER TABLE sales
ADD CONSTRAINT fk_sales_customer
FOREIGN KEY (CustomerKey)
REFERENCES dimcustomer(CustomerKey);

desc sales;
select * from sales;

##KPI's
## 1.Total Sales
select sum(salesamount) as TotalSales from sales;

##2.Total Orders
select count(*)as Total_orders from sales;

##3.Total Customers
select count(distinct customerkey) as Total_Customers from sales;


## Business Analysis


## Sales By Year
select d.CalendarYear,sum(s.salesamount) As Total_Sales from sales s join dimdate d on s.OrderDateKey=d.datekey group by d.CalendarYear order by d.CalendarYear;


## sales by category
SELECT c.EnglishProductCategoryName,
       SUM(s.SalesAmount) AS TotalSales
FROM sales s
JOIN dimproduct p
ON s.ProductKey = p.ProductKey
JOIN dimproductsubcategory sc
ON p.ProductSubcategoryKey = sc.ProductSubcategoryKey
JOIN dimproductcategory c
ON sc.ProductCategoryKey = c.ProductCategoryKey
GROUP BY c.EnglishProductCategoryName
ORDER BY TotalSales DESC;


#Sales by Top 10 Product
SELECT 
    p.EnglishProductName,
    SUM(s.SalesAmount) AS TotalSales
FROM sales s
JOIN dimproduct p
    ON s.ProductKey = p.ProductKey
GROUP BY p.ProductKey, p.EnglishProductName
ORDER BY TotalSales DESC
LIMIT 10;

##creating view (to hide complexity of queries we need to use this

#sales by Product wise in view.

CREATE VIEW view_sales_by_product AS
SELECT p.EnglishProductName,
       SUM(s.SalesAmount) AS TotalSales
FROM sales s
JOIN dimproduct p
ON s.ProductKey = p.ProductKey
GROUP BY p.ProductKey, p.EnglishProductName;

##to check table

select * from view_sales_by_product;

## Total Sales KPI using View

create view View_Total_sales As
select sum(salesamount) as TotalSales from sales;

##To run the query
select * from view_total_sales;

#Stored procedures

##Yearwise sales

DELIMITER //

CREATE PROCEDURE GetSalesByYear(IN input_year INT)
BEGIN
    SELECT d.CalendarYear,
           SUM(s.SalesAmount) AS TotalSales
    FROM sales s
    JOIN dimdate d
        ON s.OrderDateKey = d.DateKey
    WHERE d.CalendarYear = input_year
    GROUP BY d.CalendarYear;
END //

DELIMITER ;

##To run This 
call GetSalesByYear(2013);
call GetSalesByYear(2012);

DELIMITER //

create procedure GetTopProducts(in Top_n Int)
begin
   select p.EnglishProductName,sum(s.salesamount) As Total_sales from Sales s
   join dimproduct p on s.productkey = p.productkey
   group by p.productkey, p.Englishproductname
   order by Total_sales desc
   limit top_n;
   end //
   
   DELIMITER 
   
   call GetTopProducts(20);
   call GetTopProducts(5);
   
   
   ##Functions
   
   DELIMITER //
   Create function gettotalsales()
   returns decimal(15,2)
   deterministic
   begin 
       return (select sum(salesamount) from sales);
       end //
       
       DELIMITER ;
       
       SELECT gettotalsales();
