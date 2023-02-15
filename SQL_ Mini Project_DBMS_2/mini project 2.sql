create database Mini_project_2;
use Mini_project_2;
select * from cust_dimen cd
select * from market_fact mf
select * from orders_dimen od 
select * from prod_dimen pd 
select * from shipping_dimen sd


# 1.	Join all the tables and create a new table called combined_table.
# (market_fact, cust_dimen, orders_dimen, prod_dimen, shipping_dimen)

create table combined_table as 
select mf.* , cd.customer_name , cd.province, cd.region , cd.customer_segment,
od.Order_ID Order_ID_od , od.order_date ,od.order_priority,
pd.product_category,pd.product_sub_category,
sd.order_id,sd.ship_mode,sd.ship_date
from market_fact mf inner join cust_dimen cd
on mf.cust_id =cd.cust_id
inner join orders_dimen od 
on mf.ord_id =od.ord_id
inner join prod_dimen pd 
on mf.prod_id =pd.prod_id
inner join shipping_dimen sd
on mf.ship_id =sd.ship_id

select * from combined_table

# 2.	Find the top 3 customers who have the maximum number of orders
select * from cust_dimen cd
select * from market_fact mf

select * from 
(select cust_id, customer_name, order_count, dense_rank() over(order by order_count desc) toprank from 
(select * , count(order_quantity) as order_count from combined_table group by cust_id) temp) top3
where top3.toprank <=3;

# 3.	Create a new column DaysTakenForDelivery that contains the date difference of Order_Date and Ship_Date.
select * from cust_dimen cd
select * from market_fact mf
select * from orders_dimen od 
select * from prod_dimen pd 
select * from shipping_dimen sd

UPDATE orders_dimen SET order_date = STR_TO_DATE(order_date, '%d-%m-%Y');
alter table orders_dimen modify order_date date;
UPDATE shipping_dimen SET Ship_Date = STR_TO_DATE(ship_date, '%d-%m-%Y');
alter table shipping_dimen modify Ship_Date  date;

select sd.Order_ID, od.order_date, sd.ship_date,   datediff( od.order_date ,sd.ship_date) as DaysTakenForDelivery
from shipping_dimen sd join orders_dimen od 
on sd.Order_ID=od.Order_ID;  
# 4.	Find the customer whose order took the maximum time to get delivered.
select * from cust_dimen cd;
select * from market_fact mf;
select * from orders_dimen od ;
select * from prod_dimen pd ;
select * from shipping_dimen sd;

SELECT CUSTOMER_NAME, datediff(ORDER_DATE,SHIP_DATE) AS MAX_DAYS 
FROM combined_table ORDER BY MAX_DAYS LIMIT 1;

5.	Retrieve total sales made by each product from the data (use Windows function)
select distinct mf.prod_id, pd.product_category, pd.product_sub_category, 
round(Sum(sales) over( partition by mf.prod_id order by mf.Prod_id),2) `Total Sales`
from market_fact mf, prod_dimen pd
where mf.prod_id = pd.Prod_id;


6.	Retrieve total profit made from each product from the data (use windows function)

select distinct mf.prod_id, pd.product_category, pd.product_sub_category, 
round(Sum(profit) over( partition by mf.prod_id order by mf.Prod_id),2) `Total profit`
from market_fact mf, prod_dimen pd
where mf.prod_id = pd.Prod_id;
# 7.	Count the total number of unique customers in January and how many of them came back 
 # every month over the entire year in 2011
select * from combined_table;

select count(distinct cust_id) as `Unique customers of 2011` from combined_table 
where month(order_date) = all (select distinct month(order_date) from combined_table) and 
cust_id in (select distinct cust_id from combined_table where month(order_date) = 1 and year(order_date) = 2011) ;

 8.	Retrieve month-by-month customer retention rate since the start of the business. (using views)

-- Tips: 
#1: Create a view where each user’s visits are logged by month, 
-- allowing for the possibility that these will have occurred over multiple # years since whenever business started operations
# 2: Identify the time lapse between each visit. So, for each person and for each month, we see when the next visit is.
# 3: Calculate the time gaps between visits
# 4: categorise the customer with time gap 1 as retained, >1 as irregular and NULL as churned
# 5: calculate the retention month wise


-- #1 MONTH WISE VIEW OF CUSTOMERS VISITS LOGGED 
create view month_wise as
select distinct cust_id, year(order_date) Year, month(order_date) month, 
count(ord_id) over(PARTITION BY cust_id, year(order_date), month(order_date)) no_of_visits 
from combined_table order by cust_id, year, month;

select * from month_wise

-- #2 TIMELAPSE BETWEEN VISITS OF CUSTOMERS MONTH WISE
select *, lead(month) over(partition by cust_id, year) as next_visit_month from month_wise;


-- #3 TIME GAP BETWEEN VISITS
select *, (next_visit_month-month) as difference from (
select *, lead(month) over(partition by cust_id, year) as next_visit_month from month_wise)t1;


-- #4 CATEGORISING CUSTOMERS BASED ON TIME GAP '1 AS RETAINED', '>1 AS IRREGULAR' AND 'NULL AS CHURNED'
select *, case
when difference = 1 then 'Retained'
when difference > 1 then 'Irregular'
else 'Churned'
end as categories from
(select *, (next_visit_month-month) as difference from (
select *, lead(month) over(partition by cust_id, year) as next_visit_month from month_wise)t)f1; 

 
-- # 5 MONTH-MONTH RETENTION RATE OF CUSTOMERS FROM THE BUSINESS START OPERATIONS
select year, month, (count(if(categories = 'retained',1,null))/count(cust_id))*100 as retention_rate from (
select *, case
when difference = 1 then 'Retained'
when difference > 1 then 'Irregular'
else 'Churned'
end as categories from
(select *, (next_visit_month-month) as difference from (
select *, lead(month) over(partition by cust_id, year) as next_visit_month from month_wise)t2)f1)q1 
GROUP BY year, month order by year, month;