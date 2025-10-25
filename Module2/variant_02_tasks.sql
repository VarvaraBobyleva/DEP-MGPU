-- ===============================================================================
-- Скрипт: variant_02_tasks.sql
-- Автор:  Бобылева Варвара
-- Группа: БД-251м
-- Назначение: Выполнение индивидуальных заданий для лабораторной работы 1.2
-- Описание: Содержит скрипты выполнения заданий по варианту
-- ===============================================================================

----------------------------------------------------------------------------------
-- ЗАДАНИЕ 1: СОЗДАТЬ ТАБЛИЦУ С СУММОЙ ПРОДАЖ ПО РЕГИОНАМ
----------------------------------------------------------------------------------

/*Создание таблицы regional_sales_summary в схеме dw.
  Эта таблица будет содержать столбец для названия региона и столбец для суммы продаж.
*/
DROP TABLE IF EXISTS dw.regional_sales_summary ;
CREATE TABLE dw.regional_sales_summary (
    region VARCHAR(20),
    total_sales NUMERIC(21, 4)
);

--Заполнение созданной таблицы regional_sales_summary данными. 
INSERT INTO dw.regional_sales_summary (region, total_sales)
SELECT
    gd.state AS region,
    SUM(sf.sales) AS total_sales
FROM
    dw.sales_fact sf
JOIN
    dw.geo_dim gd ON sf.geo_id = gd.geo_id
GROUP BY
    gd.state;

/*
Пояснения к запросу:
- SELECT gd.state AS region, SUM(sf.sales) AS total_sales: Эта часть выбирает столбец state из таблицы geo_dim и вычисляет общую сумму продаж.
- FROM dw.sales_fact sf JOIN dw.geo_dim gd ON sf.geo_id = gd.geo_id: Здесь таблицы sales_fact и geo_dim объединяются по общему ключу geo_id.
- GROUP BY gd.state: Группировка данных по регионам, чтобы агрегатная функция SUM правильно вычислила общую сумму для каждого региона.
*/

--Проверка заполнения таблицы regional_sales_summary данными (результат выполнения представлен в файле select_regional_sales_summary.csv)
SELECT * FROM dw.regional_sales_summary ;


----------------------------------------------------------------------------------
-- ЗАДАНИЕ 2: НАЙТИ ТОП-5 ПРОДУКТОВ ПО ВЫРУЧКЕ
----------------------------------------------------------------------------------
--Выборка данных по определению топ-5 продуктов по выручке (результат выполнения выборки представлен в файле select_top5.csv)
SELECT
    pd.product_name,
    SUM(sf.sales) AS total_revenue
FROM
    dw.sales_fact sf
JOIN
    dw.product_dim pd ON sf.prod_id = pd.prod_id
GROUP BY
    pd.product_name
ORDER BY
    total_revenue DESC
LIMIT 5;

/*
- SELECT pd.product_name, SUM(sf.sales) AS total_revenue: Выбирает название продукта из таблицы product_dim и вычисляет общую сумму продаж (sales) для каждого продукта, присваивая этому столбцу псевдоним total_revenue.
- FROM dw.sales_fact sf JOIN dw.product_dim pd ON sf.prod_id = pd.prod_id: Объединяет таблицы sales_fact и product_dim по общему идентификатору продукта (prod_id).
- GROUP BY pd.product_name: Группирует результаты по названию продукта, чтобы SUM вычислялся отдельно для каждого продукта.
- ORDER BY total_revenue DESC: Сортирует сгруппированные результаты по убыванию общей выручки, чтобы самые продаваемые продукты оказались вверху списка.
- LIMIT 5: Ограничивает результат первыми пятью строками, что и дает "топ-5" продуктов.
*/

----------------------------------------------------------------------------------
-- ЗАДАНИЕ 3: РАССЧИТАТЬ ПРОЦЕНТ СКИДОК ПО КАТЕГОРИЯМ
----------------------------------------------------------------------------------

--Выборка данных для рассчета процента скидок по категориям (результат выполнения расчета представлен в файле select_AVG_discount.csv) 
--Этот запрос покажет средний процент скидки для каждой категории, указанной в базе данных.

SELECT
    pd.category,
    AVG(sf.discount) AS average_discount_percentage
FROM
    dw.sales_fact sf
JOIN
    dw.product_dim pd ON sf.prod_id = pd.prod_id
GROUP BY
    pd.category
ORDER BY
    average_discount_percentage DESC;

/*
- SELECT pd.category, AVG(sf.discount) AS average_discount_percentage: Выбирает название категории из таблицы product_dim и вычисляет среднее значение (AVG) для столбца discount из таблицы sales_fact. Результату присваивается псевдоним average_discount_percentage.
- FROM dw.sales_fact sf JOIN dw.product_dim pd ON sf.prod_id = pd.prod_id: Объединяет таблицы по общему ключу prod_id.
- GROUP BY pd.category: Группирует данные по категориям, чтобы среднее значение скидки вычислялось отдельно для каждой.
- ORDER BY average_discount_percentage DESC: Сортирует результат по убыванию, чтобы видеть, в каких категориях предоставляются самые большие скидки.
*/