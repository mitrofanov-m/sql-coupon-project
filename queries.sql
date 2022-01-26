use promo;

/*
 *  1) найти 3 магазина,которые имеют самое 
 *     большое количество нахождений
 *     в избранном  у пользователей.
 */
WITH most_liked_shops_indices AS (
    SELECT shop_id, COUNT(*) as likes
    FROM (
        SELECT * FROM ios_shops_users
        UNION ALL 
        SELECT * FROM android_shops_users
    ) as shops_users
    GROUP BY shop_id
    ORDER BY likes DESC
    LIMIT 3
)
SELECT shop FROM shops
INNER JOIN most_liked_shops_indices as ls
ON shops.id = ls.shop_id
ORDER BY likes DESC;

-- Другой вариант
-- Но с WITH выглядит красивее :)
-- Поэтому дальше будем использовать WITH
SELECT shop FROM shops
INNER JOIN (
    SELECT shop_id, COUNT(*) as likes
    FROM (
        SELECT * FROM ios_shops_users
        UNION ALL SELECT * FROM android_shops_users
    ) as shops_users
    GROUP BY shop_id
    ORDER BY likes DESC
    LIMIT 3
) as ls
ON shops.id = ls.shop_id
ORDER BY likes DESC


/*
 *  2) наиболее посещаемый магазин с девайсов
 */

-- Запрос на получение магазинов, в которых скоро кончатся промокоды
WITH hot_shops AS (
    SELECT shop_id, expiration_date, adding_date FROM promocodes
    WHERE
        (UNIX_TIMESTAMP(expiration_date) - UNIX_TIMESTAMP(adding_date)) != 864000
    AND
        DATE(adding_date) <= CURDATE()
    ORDER BY expiration_date ASC
)
SELECT DISTINCT shop_id FROM hot_shops
LIMIT 10;

-- Запрос на получение магазинов, в которых есть pinned промокоды,
-- то есть их adding_date > CURDATE().
-- В приложении это отображается как закрепленные промокоды
WITH shops_with_pinned_coupons AS (
    SELECT shop_id, adding_date FROM promocodes
    WHERE DATE(adding_date) > CURDATE()
    ORDER BY expiration_date ASC
)

-- return format is: ('category', 'priority', 'shop name')
-- Запрос на поиск магазинов по приоритетам, сортируем внутри категорий
SELECT c.category, s.shop, s.priority
FROM categories as c
INNER JOIN shops as s
    ON s.category_id = c.id
ORDER BY c.category ASC, s.priority DESC; 

/*
 *  3) магазин обладающим большим количеством промокодов
 */
WITH shops_indices_having_many_promocodes AS (
    SELECT shop_id, COUNT(*) as promocodes_number
    FROM promocodes
    GROUP BY shop_id
    ORDER BY promocodes_number DESC
    LIMIT 3
)
SELECT shop FROM shops
INNER JOIN shops_indices_having_many_promocodes as si
ON shops.id = si.shop_id
ORDER BY promocodes_number DESC;


/*
 *  4) найти магазин, 
 *     обладающий самым длинным по времени промокодом
 */
WITH longest_promocodes AS (
    SELECT shop_id, 
           TIMESTAMPDIFF(DAY,adding_date,expiration_date) as days
    FROM promocodes
    WHERE TIMESTAMPDIFF(SECOND,adding_date,expiration_date) > 0
    ORDER BY days DESC
    LIMIT 1
)
SELECT shop FROM shops
INNER JOIN longest_promocodes as lp
ON shops.id = lp.shop_id;


/*
 *  5) Категории, у которых число входящих магазинов больше,
 *     чем общее среднее количество магазинов в категории по всей таблице.
 */
WITH aggregated_shops_categories AS (
    WITH joined_shops_categories AS (
        SELECT s.shop, c.category
        FROM shops as s
        LEFT OUTER JOIN categories as c
        ON s.category_id = c.id
    )
    SELECT category, COUNT(shop) as shops_counter
    FROM joined_shops_categories
    GROUP BY category
)
SELECT category, shops_counter as shops_in_category FROM aggregated_shops_categories
WHERE shops_counter > (SELECT AVG(shops_counter) FROM aggregated_shops_categories)
ORDER BY shops_counter DESC;
