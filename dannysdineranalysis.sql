--Alert name schema 
ALTER SCHEMA dannys_diner
TRANSFER dbo.sales;

ALTER SCHEMA dannys_diner
TRANSFER dbo.menu;

ALTER SCHEMA dannys_diner
TRANSFER dbo.members;
-----------------------------------------------
--show all data 
SELECT *
FROM dannys_diner.members

SELECT *
FROM dannys_diner.menu

SELECT *
FROM dannys_diner.sales
------------------------------
-- data intialization

-- prerpare primary key to members
ALTER TABLE dannys_diner.members
ALTER COLUMN customer_id VARCHAR(1) NOT NULL

ALTER TABLE dannys_diner.members
ADD CONSTRAINT PK_members PRIMARY KEY (customer_id);

-- prerpare primary key to menu
ALTER TABLE dannys_diner.menu
ALTER COLUMN product_id VARCHAR(1) NOT NULL

alter table dannys_diner.menu
add constraint PK_menu Primary Key (Product_id)

--add column as a primary key in sales
ALTER TABLE  dannys_diner.sales
ADD Order_id INT IDENTITY(1,1) PRIMARY KEY 
------------------------------------------------------
--What is the total amount each customer spent at the restaurant?
select s.customer_id , SUM(m.price) as total_amount
from dannys_diner.sales as s
inner join dannys_diner.menu as m
on s.product_id = m.product_id
group by  s.customer_id 
---------------------------------------
--How many days has each customer visited the restaurant? 
SELECT s.customer_id, COUNT(DISTINCT s.order_date) AS visited_days
FROM dannys_diner.sales AS s
GROUP BY s.customer_id;
----------------------------------------
--What was the first item from the menu purchased by each customer?
with rank_ItembyDate as (
select distinct s.customer_id , m.product_name,dense_rank() over ( partition by s.customer_id order by s.order_date) as rank_item
from dannys_diner.sales as s
inner join dannys_diner.menu as m
on s.product_id = m.product_id)
select  customer_id ,  STRING_AGG(product_name, ' , ') AS products
from rank_ItembyDate
where rank_item = 1
group by customer_id 
----------------------------------------
--What is the most purchased item on the menu and how many times was it been purchased by all customers? 
SELECT TOP 1
    m.product_name,
    COUNT(s.product_id) AS total_purchases
from dannys_diner.sales as s
inner join dannys_diner.menu as m
    ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY total_purchases DESC;
--------------------------------------------------------
--Which item was the most popular for each customer? 
-- Q5: no need to join members
WITH rank_most_popular_item AS (
    SELECT 
        s.customer_id,
        m.product_name,
        COUNT(*) AS total_purchases,
        RANK() OVER (PARTITION BY s.customer_id ORDER BY COUNT(*) DESC) AS rank_1
    FROM dannys_diner.sales AS s
    INNER JOIN dannys_diner.menu AS m
        ON s.product_id = m.product_id
    GROUP BY s.customer_id, m.product_name
)
SELECT customer_id, product_name, total_purchases
FROM rank_most_popular_item
WHERE rank_1 = 1;
------------------------------------
--Which item was purchased first by the customer after they became a member?
with rank_most_popular_item  as (
SELECT 
    m.product_name,
	c.customer_id,
	s.order_date ,
	rank() over (partition by c.customer_id  order by s.order_date  ) as rank_1
from dannys_diner.sales as s
inner join dannys_diner.menu as m
    ON s.product_id = m.product_id
inner join dannys_diner.members as c
on s.customer_id = c.customer_id
where s.order_date >= c.join_date
 )

select distinct customer_id ,  STRING_AGG(product_name, ' , ') AS products
from rank_most_popular_item 
where rank_1 = 1
group by customer_id 
------------------------------------------
--Which item was purchased just before the customer became a member? 
with rank_most_popular_item  as (
SELECT 
    m.product_name,
	c.customer_id,
	s.order_date ,
	c.join_date,
	rank() over (partition by c.customer_id  order by s.order_date  desc ) as rank_1
from dannys_diner.sales as s
inner join dannys_diner.menu as m
    ON s.product_id = m.product_id
inner join dannys_diner.members as c
on s.customer_id = c.customer_id
where s.order_date < c.join_date
 )

select distinct customer_id ,  STRING_AGG(product_name, ' , ') AS products
from rank_most_popular_item 
where rank_1 = 1
group by customer_id 
----------------------------------------------------------
-- What is the total items and amount spent on each member before they became a member? 
with CustomerInfoPerSalea as (
select c.customer_id ,s.product_id,m.price
from  dannys_diner.sales as s
inner join dannys_diner.menu as m
ON s.product_id = m.product_id
inner join dannys_diner.members as c
on s.customer_id = c.customer_id
where  s.order_date<c.join_date )

select customer_id ,COUNT(product_id ) as totalitem , SUM(price) as totalamount
from CustomerInfoPerSalea
group by customer_id 
---another solve
SELECT 
    s.customer_id,
    COUNT(s.product_id) AS total_items,
    SUM(m.price) AS total_amount
FROM dannys_diner.sales AS s
INNER JOIN dannys_diner.menu AS m
    ON s.product_id = m.product_id
INNER JOIN dannys_diner.members AS mb
    ON s.customer_id = mb.customer_id
WHERE s.order_date < mb.join_date
GROUP BY s.customer_id;
---------------------------------------------------------------------
--If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have? 
SELECT 
    s.customer_id,
	sum (
	case 
	   when m.product_name = 'sushi' then  m.price * 10*2
	   else m.price*10
	end ) as points
FROM dannys_diner.sales AS s
INNER JOIN dannys_diner.menu AS m
    ON s.product_id = m.product_id
group by s.customer_id

--------------------------------------------------
-- In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January? 

SELECT 
    c.customer_id,
	sum (
	case 
	   when s.order_date between  c.join_date and  DATEADD(DAY, 6, c.join_date) then  m.price * 10*2
	   when m.product_name = 'sushi' then  m.price * 10*2
	   else m.price*10
	end ) as points
FROM dannys_diner.sales AS s
INNER JOIN dannys_diner.menu AS m
    ON s.product_id = m.product_id
inner join dannys_diner.members as c
on s.customer_id = c.customer_id
WHERE s.order_date <= '2021-01-31'
group by c.customer_id
------------------------------------------------------------
--Recreate Customer Purchase History with Membership Status
create view  CustomerPurchaseHistory 
as 
 SELECT 
    s.customer_id,
    s.order_date,
    m.product_name,
    m.price,
    member=
      case 
       when s.order_date >= c.join_date then  'y'
       else 'N'
      end
 FROM dannys_diner.sales AS s
  INNER JOIN dannys_diner.menu AS m
    ON s.product_id = m.product_id
  left join dannys_diner.members as c
    on s.customer_id = c.customer_id ;

select * 
from CustomerPurchaseHistory
------------------------------------------------------
--Customer Purchase Ranking After Membership
SELECT
    customer_id,
    order_date,
    product_name,
    price,
    member,
    CASE 
        WHEN member = 'Y' THEN
            DENSE_RANK() OVER (
                PARTITION BY customer_id, member
                ORDER BY order_date
            )
    END AS ranking
FROM CustomerPurchaseHistory
ORDER BY customer_id, order_date;


