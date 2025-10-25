-- ===============================================================================
-- Скрипт: Create_tables.sql
-- Автор:  Бобылева Варвара
-- Группа: БД-251м
-- Назначение: Создание таблиц базы данных для лабораторной работы 1.2
-- Описание: Содержит запросы создания таблиц для схем stg, public, dw
-- ===============================================================================

--Создание таблиц для схемы stg

--Создаем таблицу с полями, согласно имеющимся данным по столбцам из исходного файла, задаем типы и размерность для этих полей
/*
   Таблица для хранения исходных (сырых) данных по заказам.
   Содержит поля идентификаторов заказов, менеджеров, товаров. 
*/
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
/*
   Таблица для хранения очищенных данных по заказам.
   Содержит поля идентификаторов заказов, менеджеров, товаров. 
*/
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
/*
   Таблица для хранения очищенных данных по менеджерам.
   Содержит поля распределения менеджеров по регионам. 
*/
CREATE TABLE people(
   Person VARCHAR(17) NOT NULL PRIMARY KEY
  ,Region VARCHAR(7) NOT NULL
);

--Создаем таблицу returns, задаем типы и размерности полей
/*
   Таблица для хранения очищенных данных по возвратам товаров.
   Содержит поля распределения возвратов товаров по регионам. 
*/
CREATE TABLE returns(
   Person   VARCHAR(17) NOT NULL, 
   Region   VARCHAR(20) NOT NULL
);

---------------------------------------------------------------------------------------------
--Создаем таблицы для схемы dw
--Создаем таблицы с размеченными данными, полученные из исходных данных схемы stg

--Создаем таблицу dw.shipping_dim, задаем типы, размерности полей, задаем типы ключей для связей таблиц
/*
   Таблица для хранения качественных данных по классу доставки.
   Содержит поля распределения возвратов товаров по регионам. 
*/
CREATE TABLE dw.shipping_dim
(
 ship_id       serial NOT NULL,
 shipping_mode varchar(14) NOT NULL,
 CONSTRAINT PK_shipping_dim PRIMARY KEY ( ship_id )
);

--Создаем таблицу dw.customer_dim, задаем типы, размерности полей, задаем типы ключей для связей таблиц
/*
   Таблица для хранения качественных данных по сведениям о покупателях.
   Содержит поля идентификатора пользователя и его имя. 
*/
CREATE TABLE dw.customer_dim
(
cust_id serial NOT NULL,
customer_id   varchar(8) NOT NULL, --id can't be NULL
 customer_name varchar(22) NOT NULL,
 CONSTRAINT PK_customer_dim PRIMARY KEY ( cust_id )
);

--Создаем таблицу dw.geo_dim, задаем типы, размерности полей, задаем типы ключей для связей таблиц
/*
   Таблица для хранения качественных данных по информации о горадах распределения заказов.
   Содержит поля информации о стране, городе, штате и его индексе. 
*/
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
/*
   Таблица для хранения качественных данных по сведениям о товарах.
   Содержит поля идентификатора товара, его наименовании, категории, подкатегории, сегменте. 
*/
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
/*
   Таблица для хранения данных по календарю с разбивкой даты.
   Содержит поля полной даты, выделенные поля из полной даты по году, кварталу, месяцу, неделе, дню. 
*/
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
/*
   Таблица для хранения метрики по данным о заказах с их привязкой к региону, с перечнем товаров и их покупателями.
   Содержит поля идентификаторов заказов, товаров, дате заказов, стране, а также с данными по продаже, прибыли и количестве проданных товаров. 
*/
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