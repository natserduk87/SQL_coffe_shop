--Практическое задание по SQL | ДА-101 | Сердюк Н.А.


--Преварительный просмотр таблицы sales.
select *
from coffe_shop.sales


--1.Найти все транзакции, которые совершал Calvin Potter
select *
from coffe_shop.sales
where customer_name = 'Calvin Potter'


--2.Посчитать средний чек покупателей по дням
select
transaction_date,
avg(unit_price * quantity) as avg_bill
from coffe_shop.sales
group by 1
order by 1


--3.Преобразуйте дату транзакции в нужный формат: год, месяц, день. Приведите названия продуктов к стандартному виду в нижнемрегистре.
select transaction_date,
date_part('year', date(transaction_date)) as trans_year,
date_part('month', date(transaction_date)) as trans_month,
date_part('day', date(transaction_date)) as trans_day,
lower (product_name) as product_name 
from coffe_shop.sales


/*4.Сделать анализ покупателей и разделить их по категориям.
Посчитать количество транзакций, сделанных каждым покупателем.
Разделить их на категории: Частые гости (>= 23транзакций), Редкие посетители (< 10 транзакций), Стандартные посетители (все остальные)*/
select
customer_id,
customer_name,
count(transaction_id) as transactions,
case
when count(transaction_id) >= 23 then 'Частый гость'
when count(transaction_id) < 10 then 'Редкий гость'
else 'Стандартный гость'
end as customer_category
from coffe_shop.sales
where customer_id != 0
group by 1,2
order by transactions desc


--5.Посчитать количество уникальных посетителей в каждом магазине каждый день.
select
transaction_date,
store_address,
count(distinct customer_id) as customers
from coffe_shop.sales
group by 1,2
order by 2


--6.Посчитать количество клиентов по поколениям.
with customer_data_mart as (
select*
from coffe_shop.customer as c
left join coffe_shop.generations as g
on c.birth_year = g.birth_year 
)
select
generation,
count(distinct customer_id) as customers_count
from customer_data_mart
group by 1
order by 2 desc


--7.Найдите топ 10 самых продаваемых товаров каждый день и проранжируйте их по дням и кол-ву проданных штук.
with daily_product_sales as (
select distinct
sr.transaction_date,
p.product_name,
sum(sr.quantity) as quantity_sold_per_day
from coffe_shop.sales_reciepts as sr 
left join coffe_shop.product as p 
ON sr.product_id  = p.product_id
group by 1,2
order by 1,2
),
daily_top_products as (
select *,
row_number() over (partition by transaction_date order by quantity_sold_per_day desc) as rating
from daily_product_sales
)
select *
from daily_top_products
where rating <= 10
order by transaction_date, quantity_sold_per_day desc
   

--еще вариант
select transaction_date, product_name, quantity_sold_per_day, rating
from (
select
transaction_date,
product_name,
quantity_sold_per_day,
row_number() over (partition by transaction_date order by quantity_sold_per_day desc) as rating
from (
select
transaction_date,
product_name,
sum(quantity) as quantity_sold_per_day
from coffe_shop.sales_reciepts sr
left join coffe_shop.product p 
on sr.product_id = p.product_id
group by 1,2
) as daily_product_sales
) as daily_top_products
where rating <= 10
order by transaction_date, rating;


--8.Выведите только те названия регионов, где продавался продукт “Columbian Medium Roast” с последней датой продажи.
select *
from coffe_shop.sales_outlet

select
so.neighborhood,
max(s.transaction_date) as last_transaction
from coffe_shop.sales as s
left join coffe_shop.sales_outlet as so
on s.sales_outlet_id  = so.sales_outlet_id
where product_name = 'Columbian Medium Roast'
group by 1


/*9.Соберите витрину из следующих полей
Transaction_date, sales_outlet_id, store_address, product_id, product_name, customer_id, customer_name, 
gender (заменить на Male, Female, Not Defined если пустое значение), unit_price, quantity, line_item_amount*/
with sales_data_mart as (
select
sr.transaction_date,
so.sales_outlet_id,
so.store_address,
p.product_id,
p.product_name,
c.customer_id,
c.customer_name,
case
when gender = 'M' then 'Male'
when gender = 'F' then 'Female'
else 'Not Defined'
end as gender,
sr.unit_price,
sr.quantity,
sr.line_item_amount 
from coffe_shop.sales_reciepts as sr
left join coffe_shop.sales_outlet as so
on sr.sales_outlet_id = so.sales_outlet_id
left join coffe_shop.product as p
on sr.product_id = p.product_id
left join coffe_shop.customer as c 
on sr.customer_id = c.customer_id
)
select *
from sales_data_mart
order by 1


--10.Найдите разницу между максимальной и минимальной ценой товара в категории.
with sales_prep as (
select
product_category,
product_type,
product_name,
replace(current_retail_price, '$', '')::numeric as retail_price,
max(replace(current_retail_price, '$', '')::numeric) over (partition by product_category) as max_price_category,
min(replace(current_retail_price, '$', '')::numeric) over (partition by product_category) as min_price_category
from coffe_shop.product
)
select *,
max_price_category - min_price_category as difference
from sales_prep;


--*1. Сделать справочник клиентов. Посчитать возраст клиентов, разделить имя и фамилию на 2 отдельных поля.
select *
from coffe_shop.customer

select
customer_id,
customer_name as customer_full_name,
split_part(customer_name, ' ', 1) as customer_name,
split_part(customer_name, ' ', 2) as customer_surname,
birthdate,
age(date(birthdate)) as customer_age
from coffe_shop.customer


--*2. Используя витрину в качестве табличного выражения или подзапроса, посчитайте количество транзакций по полю gender.
with sales_data_mart as (
select
sr.transaction_id,
sr.transaction_date,
so.sales_outlet_id,
so.store_address,
p.product_id,
p.product_name,
c.customer_id,
c.customer_name,
case
when gender = 'M' then 'Male'
when gender = 'F' then 'Female'
else 'Not Defined'
end as gender,
sr.unit_price,
sr.quantity,
sr.line_item_amount 
from coffe_shop.sales_reciepts as sr
left join coffe_shop.sales_outlet as so
on sr.sales_outlet_id = so.sales_outlet_id
left join coffe_shop.product as p
on sr.product_id = p.product_id
left join coffe_shop.customer as c 
on sr.customer_id = c.customer_id
)
select
gender,
count(distinct transaction_id)
from sales_data_mart
group by 1
order by 2


--еще вариант
with customer_data_mart as (
select
sr.transaction_id,
case
when gender = 'M' then 'Male'
when gender = 'F' then 'Female'
else 'Not Defined'
end as gender
from coffe_shop.sales_reciepts as sr
left join coffe_shop.customer as c 
on sr.customer_id = c.customer_id
left join coffe_shop.generations as g
on c.birth_year = g.birth_year 
)
select
gender,
count(distinct transaction_id)
from customer_data_mart
group by 1
order by 2
