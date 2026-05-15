
-- 1.1. Количество строк во всех таблицах (Snowflake-схема)
select 'dim_customer' as table_name, count(*) as row_count from dim_customer
union all
select 'dim_pet_type', count(*) from dim_pet_type
union all
select 'dim_pet_breed', count(*) from dim_pet_breed
union all
select 'dim_pet', count(*) from dim_pet
union all
select 'dim_seller', count(*) from dim_seller
union all
select 'dim_category', count(*) from dim_category
union all
select 'dim_brand', count(*) from dim_brand
union all
select 'dim_product', count(*) from dim_product
union all
select 'dim_location', count(*) from dim_location
union all
select 'dim_store', count(*) from dim_store
union all
select 'dim_supplier', count(*) from dim_supplier
union all
select 'fact_sales', count(*) from fact_sales
order by table_name;

-- 1.2. Проверка NULL-ключей в fact_sales
select
    count(*) as fact_rows,
    count(*) filter (where customer_key is null) as customer_nulls,
    count(*) filter (where pet_key is null) as pet_nulls,
    count(*) filter (where seller_key is null) as seller_nulls,
    count(*) filter (where product_key is null) as product_nulls,
    count(*) filter (where store_key is null) as store_nulls,
    count(*) filter (where supplier_key is null) as supplier_nulls
from fact_sales;

-- 1.3. Общая сумма всех продаж
select round(sum(sale_total_price), 2) as total_sales_sum
from fact_sales;



-- 2.1. Топ-10 стран по сумме продаж
select
    c.customer_country,
    round(sum(f.sale_total_price), 2) as total
from fact_sales f
join dim_customer c on c.customer_key = f.customer_key
group by c.customer_country
order by total desc
limit 10;

-- 2.2. Топ-10 товаров по сумме продаж (с категорией и брендом)
select
    p.product_name,
    cat.category_name,
    br.brand_name,
    sum(f.sale_quantity) as qty,
    round(sum(f.sale_total_price), 2) as total
from fact_sales f
join dim_product p on p.product_key = f.product_key
left join dim_category cat on cat.category_key = p.category_key
left join dim_brand br on br.brand_key = p.brand_key
group by p.product_name, cat.category_name, br.brand_name
order by total desc
limit 10;

-- 2.3. Продажи по категориям товаров
select
    cat.category_name,
    count(*) as sales_count,
    sum(f.sale_quantity) as total_qty,
    round(sum(f.sale_total_price), 2) as total
from fact_sales f
join dim_product p on p.product_key = f.product_key
left join dim_category cat on cat.category_key = p.category_key
group by cat.category_name
order by total desc;

-- 2.4. Продажи по брендам
select
    br.brand_name,
    count(*) as sales_count,
    round(sum(f.sale_total_price), 2) as total
from fact_sales f
join dim_product p on p.product_key = f.product_key
left join dim_brand br on br.brand_key = p.brand_key
group by br.brand_name
order by total desc
limit 10;

-- 2.5. Продажи по магазинам (с локацией)
select
    s.store_name,
    l.location_city,
    l.location_country,
    count(*) as sales_count,
    round(sum(f.sale_total_price), 2) as total
from fact_sales f
join dim_store s on s.store_key = f.store_key
left join dim_location l on l.location_key = s.location_key
group by s.store_name, l.location_city, l.location_country
order by total desc
limit 10;

-- 2.6. Средний чек по странам
select
    c.customer_country,
    round(avg(f.sale_total_price), 2) as avg_check,
    count(*) as sales_count
from fact_sales f
join dim_customer c on c.customer_key = f.customer_key
group by c.customer_country
order by avg_check desc
limit 10;

-- 2.7. Продажи по типам питомцев
select
    pt.pet_type_name,
    count(*) as sales_count,
    round(sum(f.sale_total_price), 2) as total
from fact_sales f
join dim_pet p on p.pet_key = f.pet_key
left join dim_pet_type pt on pt.pet_type_key = p.pet_type_key
group by pt.pet_type_name
order by total desc;

-- 2.8. Продажи по породам питомцев
select
    pb.pet_breed_name,
    pb.pet_category,
    count(*) as sales_count,
    round(sum(f.sale_total_price), 2) as total
from fact_sales f
join dim_pet p on p.pet_key = f.pet_key
left join dim_pet_breed pb on pb.pet_breed_key = p.pet_breed_key
group by pb.pet_breed_name, pb.pet_category
order by total desc
limit 10;

-- 2.9. Количество продаж по месяцам
select
    extract(year from sale_date) as year,
    extract(month from sale_date) as month,
    count(*) as sales_count,
    round(sum(sale_total_price), 2) as total
from fact_sales
group by extract(year from sale_date), extract(month from sale_date)
order by year, month;

-- 2.10. Самая дорогая продажа
select
    sale_key,
    sale_total_price,
    sale_date,
    customer_key,
    product_key
from fact_sales
order by sale_total_price desc
limit 5;


-- 3.1. Дубликаты в fact_sales (должно быть 0)
select 'fact_sales duplicates' as check_name, count(*) as issue_count
from fact_sales
group by sale_key
having count(*) > 1;

-- 3.2. Продажи без даты
select count(*) as sales_without_date
from fact_sales
where sale_date is null;

-- 3.3. Продажи с отрицательной ценой или количеством
select count(*) as negative_price_or_qty
from fact_sales
where sale_total_price < 0 or sale_quantity < 0;

-- 3.4. Проверка, что все source_file ссылаются на существующие файлы
select source_file, count(*) as cnt
from fact_sales
group by source_file
order by source_file;
