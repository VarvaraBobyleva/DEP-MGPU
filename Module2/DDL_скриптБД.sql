-- ===============================================================================
-- Скрипт: DDL_скриптБД.sql
-- Автор:  Бобылева Варвара
-- Группа: БД-251м
-- Назначение: Создание начальной схемы базы данных для лабораторной работы 1.2
-- Описание: Содержит DDL для схем stg, public, dw, а также таблиц к ним
-- ===============================================================================

-- --------------------------------------------------------
-- СЕКЦИЯ 1: СОЗДАНИЕ СХЕМ БАЗЫ ДАННЫХ
-- --------------------------------------------------------
create schema stg;
create schema dw;

-- --------------------------------------------------------
-- СЕКЦИЯ 2: УДАЛЕНИЕ СУЩЕСТВУЮЩИХ ОБЪЕКТОВ
-- --------------------------------------------------------
DROP TABLE IF EXISTS stg.orders;
DROP TABLE IF EXISTS returns;
DROP TABLE IF EXISTS people;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS dw.shipping_dim ;
DROP TABLE IF EXISTS dw.customer_dim ;
DROP TABLE IF EXISTS dw.geo_dim ;
DROP TABLE IF EXISTS dw.product_dim ;
DROP TABLE IF EXISTS dw.calendar_dim ;
DROP TABLE IF EXISTS dw.sales_fact ;

-- --------------------------------------------------------
-- СЕКЦИЯ 3: СОЗДАНИЕ ТАБЛИЦ
-- --------------------------------------------------------
--Создание таблиц для схемы stg

--Создаем таблицу с полями, согласно имеющимся данным по столбцам из исходного файла, задаем типы и размерность для этих полей
CREATE TABLE stg.orders(
   Row_ID        INTEGER  NOT NULL PRIMARY KEY 
  ,Order_ID      VARCHAR(14) NOT NULL
  ,Order_Date    DATE  NOT NULL
  ,Ship_Date     DATE  NOT NULL
  ,Ship_Mode     VARCHAR(14) NOT NULL
  ,Customer_ID   VARCHAR(8) NOT NULL
  ,Customer_Name VARCHAR(22) NOT NULL
  ,Segment       VARCHAR(11) NOT NULL
  ,Country       VARCHAR(13) NOT NULL
  ,City          VARCHAR(17) NOT NULL
  ,State         VARCHAR(20) NOT NULL
  ,Postal_Code   VARCHAR(50) --varchar because can start from 0
  ,Region        VARCHAR(7) NOT NULL
  ,Product_ID    VARCHAR(15) NOT NULL
  ,Category      VARCHAR(15) NOT NULL
  ,SubCategory   VARCHAR(11) NOT NULL
  ,Product_Name  VARCHAR(127) NOT NULL
  ,Sales         NUMERIC(9,4) NOT NULL
  ,Quantity      INTEGER  NOT NULL
  ,Discount      NUMERIC(4,2) NOT NULL
  ,Profit        NUMERIC(21,16) NOT NULL
);

---------------------------------------------------------------------------------------------
--Создаем таблицы для схемы public (raw data layer)
--Создаем таблицы с очищенными данными из исходного файла

--Создаем таблицу orders, задаем типы и размерности полей
CREATE TABLE orders(
   Row_ID        INTEGER  NOT NULL PRIMARY KEY 
  ,Order_ID      VARCHAR(14) NOT NULL
  ,Order_Date    DATE  NOT NULL
  ,Ship_Date     DATE  NOT NULL
  ,Ship_Mode     VARCHAR(14) NOT NULL
  ,Customer_ID   VARCHAR(8) NOT NULL
  ,Customer_Name VARCHAR(22) NOT NULL
  ,Segment       VARCHAR(11) NOT NULL
  ,Country       VARCHAR(13) NOT NULL
  ,City          VARCHAR(17) NOT NULL
  ,State         VARCHAR(20) NOT NULL
  ,Postal_Code   INTEGER 
  ,Region        VARCHAR(7) NOT NULL
  ,Product_ID    VARCHAR(15) NOT NULL
  ,Category      VARCHAR(15) NOT NULL
  ,SubCategory   VARCHAR(11) NOT NULL
  ,Product_Name  VARCHAR(127) NOT NULL
  ,Sales         NUMERIC(9,4) NOT NULL
  ,Quantity      INTEGER  NOT NULL
  ,Discount      NUMERIC(4,2) NOT NULL
  ,Profit        NUMERIC(21,16) NOT NULL
);

--Создаем таблицу people, задаем типы и размерности полей
CREATE TABLE people(
   Person VARCHAR(17) NOT NULL PRIMARY KEY
  ,Region VARCHAR(7) NOT NULL
);

--Создаем таблицу returns, задаем типы и размерности полей
CREATE TABLE returns(
   Person   VARCHAR(17) NOT NULL, 
   Region   VARCHAR(20) NOT NULL
);

---------------------------------------------------------------------------------------------
--Создаем таблицы для схемы dw
--Создаем таблицы с размеченными данными, полученные из исходных данных схемы stg

--Создаем таблицу dw.shipping_dim, задаем типы, размерности полей, задаем типы ключей для связей таблиц
CREATE TABLE dw.shipping_dim
(
 ship_id       serial NOT NULL,
 shipping_mode varchar(14) NOT NULL,
 CONSTRAINT PK_shipping_dim PRIMARY KEY ( ship_id )
);

--Создаем таблицу dw.customer_dim, задаем типы, размерности полей, задаем типы ключей для связей таблиц
CREATE TABLE dw.customer_dim
(
cust_id serial NOT NULL,
customer_id   varchar(8) NOT NULL, --id can't be NULL
 customer_name varchar(22) NOT NULL,
 CONSTRAINT PK_customer_dim PRIMARY KEY ( cust_id )
);

--Создаем таблицу dw.geo_dim, задаем типы, размерности полей, задаем типы ключей для связей таблиц
CREATE TABLE dw.geo_dim
(
 geo_id      serial NOT NULL,
 country     varchar(13) NOT NULL,
 city        varchar(17) NOT NULL,
 state       varchar(20) NOT NULL,
 postal_code varchar(20) NULL,       --can't be integer, we lost first 0
 CONSTRAINT PK_geo_dim PRIMARY KEY ( geo_id )
);

--Создаем таблицу dw.product_dim, задаем типы, размерности полей, задаем типы ключей для связей таблиц
CREATE TABLE dw.product_dim
(
 prod_id   serial NOT NULL, --we created surrogated key
 product_id   varchar(50) NOT NULL,  --exist in ORDERS table
 product_name varchar(127) NOT NULL,
 category     varchar(15) NOT NULL,
 sub_category varchar(11) NOT NULL,
 segment      varchar(11) NOT NULL,
 CONSTRAINT PK_product_dim PRIMARY KEY ( prod_id )
);

--Создаем таблицу dw.calendar_dim, задаем типы, размерности полей, задаем типы ключей для связей таблиц
CREATE TABLE dw.calendar_dim
(
dateid serial  NOT NULL,
year        int NOT NULL,
quarter     int NOT NULL,
month       int NOT NULL,
week        int NOT NULL,
date        date NOT NULL,
week_day    varchar(20) NOT NULL,
leap  varchar(20) NOT NULL,
CONSTRAINT PK_calendar_dim PRIMARY KEY ( dateid )
);

--Создаем таблицу метрики dw.sales_fact по данным схемы dw, задаем типы, размерности полей, задаем типы ключей для связей таблиц
CREATE TABLE dw.sales_fact
(
 sales_id      serial NOT NULL,
 cust_id integer NOT NULL,
 order_date_id integer NOT NULL,
 ship_date_id integer NOT NULL,
 prod_id  integer NOT NULL,
 ship_id     integer NOT NULL,
 geo_id      integer NOT NULL,
 order_id    varchar(25) NOT NULL,
 sales       numeric(9,4) NOT NULL,
 profit      numeric(21,16) NOT NULL,
 quantity    int4 NOT NULL,
 discount    numeric(4,2) NOT NULL,
 CONSTRAINT PK_sales_fact PRIMARY KEY ( sales_id ));


-- --------------------------------------------------------
-- СЕКЦИЯ 4: ОЧИЩЕНИЕ СТРОК ТАБЛИЦ СХЕМЫ dw
-- --------------------------------------------------------
--Запросы по очищению строк для таблиц схемы dw от данных с сохранением ее структуры

--deleting rows
truncate table dw.shipping_dim;
truncate table dw.customer_dim;
truncate table dw.geo_dim;
truncate table dw.product_dim ;
truncate table dw.calendar_dim;

-- --------------------------------------------------------
-- СЕКЦИЯ 5: ЗАПОЛНЕНИЕ ТАБЛИЦ СХЕМЫ dw
-- --------------------------------------------------------
--Запросы по заполнению данных для таблиц схемы dw из исходных данных схемы stg

--Заполнение таблицы dw.shipping_dim по данным из схемы stg
--generating ship_id and inserting ship_mode from orders
insert into dw.shipping_dim 
select 100+row_number() over(), ship_mode from (select distinct ship_mode from stg.orders ) a;

--Заполнение таблицы dw.customer_dim по данным из схемы stg
insert into dw.customer_dim 
select 100+row_number() over(), customer_id, customer_name from (select distinct customer_id, customer_name from stg.orders ) a;

--Заполнение таблицы dw.geo_dim по данным из схемы stg
--generating geo_id and inserting rows from orders
insert into dw.geo_dim 
select 100+row_number() over(), country, city, state, postal_code from (select distinct country, city, state, postal_code from stg.orders ) a;
--data quality check
select distinct country, city, state, postal_code from dw.geo_dim
where country is null or city is null or postal_code is null;

--Заполнение таблицы dw.product_dim по данным из схемы stg
insert into dw.product_dim 
select 100+row_number() over () as prod_id ,product_id, product_name, category, subcategory, segment from (select distinct product_id, product_name, category, subcategory, segment from stg.orders ) a;

--Заполнение таблицы dw.calendar_dim по данным из схемы stg
insert into dw.calendar_dim 
select 
to_char(date,'yyyymmdd')::int as date_id,  
       extract('year' from date)::int as year,
       extract('quarter' from date)::int as quarter,
       extract('month' from date)::int as month,
       extract('week' from date)::int as week,
       date::date,
       to_char(date, 'dy') as week_day,
       extract('day' from
               (date + interval '2 month - 1 day')
              ) = 29
       as leap
  from generate_series(date '2000-01-01',
                       date '2030-01-01',
                       interval '1 day')
       as t(date);

--Заполнение метрики dw.sales_fact по данным из схемы stg
insert into dw.sales_fact 
select
	 100+row_number() over() as sales_id
	 ,cust_id
	 ,to_char(order_date,'yyyymmdd')::int as  order_date_id
	 ,to_char(ship_date,'yyyymmdd')::int as  ship_date_id
	 ,p.prod_id
	 ,s.ship_id
	 ,geo_id
	 ,o.order_id
	 ,sales
	 ,profit
     ,quantity
	 ,discount
from stg.orders o 
inner join dw.shipping_dim s on o.ship_mode = s.shipping_mode
inner join dw.geo_dim g on o.postal_code = g.postal_code and g.country=o.country and g.city = o.city and o.state = g.state --City Burlington doesn't have postal code
inner join dw.product_dim p on o.product_name = p.product_name and o.segment=p.segment and o.subcategory=p.sub_category and o.category=p.category and o.product_id=p.product_id 
inner join dw.customer_dim cd on cd.customer_id=o.customer_id and cd.customer_name=o.customer_name 

-- ------------------------------------------------------------
-- СЕКЦИЯ 6: КОНТРОЛЬ СОЗДАННЫХ ЗАПИСЕЙ ТАБЛИЦ СХЕМЫ dw
-- ------------------------------------------------------------
--Запросы по выборке данных из таблиц для контроля заполнения их данными

--SHIPPING
select * from dw.shipping_dim sd;
--CUSTOMER
select * from dw.customer_dim cd; 
--GEOGRAPHY
select * from dw.geo_dim cd; 
--PRODUCT
select * from dw.product_dim cd; 
--CALENDAR
select * from dw.calendar_dim; 
--Проверка метрики на верную загрузку кол-во строк
select count(*) from dw.sales_fact sf
inner join dw.shipping_dim s on sf.ship_id=s.ship_id
inner join dw.geo_dim g on sf.geo_id=g.geo_id
inner join dw.product_dim p on sf.prod_id=p.prod_id
inner join dw.customer_dim cd on sf.cust_id=cd.cust_id;

-- ------------------------------------------------------------
-- СЕКЦИЯ 7: ОНОВЛЕНИЕ СУЩЕСТВУЮЩИХ ЗАПИСЕЙ ТАБЛИЦ СХЕМЫ dw
-- ------------------------------------------------------------
--Запросы по обновлению/изменению данных в таблицах схемы dw, для улучшения качества данных

--Выборка данных с некачественными данными
select distinct country, city, state, postal_code from dw.geo_dim
where country is null or city is null or postal_code is null;

--Обновление информации в записях
-- City Burlington, Vermont doesn't have postal code
update dw.geo_dim
set postal_code = '05401'
where city = 'Burlington'  and postal_code is null;

--also update source file
update stg.orders
set postal_code = '05401'
where city = 'Burlington'  and postal_code is null;