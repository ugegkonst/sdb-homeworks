# Домашнее задание к занятию «Индексы»

### Инструкция по выполнению домашнего задания

1. Сделайте fork [репозитория c шаблоном решения](https://github.com/netology-code/sys-pattern-homework) к себе в Github и переименуйте его по названию или номеру занятия, например, https://github.com/имя-вашего-репозитория/gitlab-hw или https://github.com/имя-вашего-репозитория/8-03-hw).
2. Выполните клонирование этого репозитория к себе на ПК с помощью команды `git clone`.
3. Выполните домашнее задание и заполните у себя локально этот файл README.md:
   - впишите вверху название занятия и ваши фамилию и имя;
   - в каждом задании добавьте решение в требуемом виде: текст/код/скриншоты/ссылка;
   - для корректного добавления скриншотов воспользуйтесь инструкцией [«Как вставить скриншот в шаблон с решением»](https://github.com/netology-code/sys-pattern-homework/blob/main/screen-instruction.md);
   - при оформлении используйте возможности языка разметки md. Коротко об этом можно посмотреть в [инструкции по MarkDown](https://github.com/netology-code/sys-pattern-homework/blob/main/md-instruction.md).
4. После завершения работы над домашним заданием сделайте коммит (`git commit -m "comment"`) и отправьте его на Github (`git push origin`).
5. Для проверки домашнего задания преподавателем в личном кабинете прикрепите и отправьте ссылку на решение в виде md-файла в вашем Github.
6. Любые вопросы задавайте в чате учебной группы и/или в разделе «Вопросы по заданию» в личном кабинете.

Желаем успехов в выполнении домашнего задания.

### Задание 1

Напишите запрос к учебной базе данных, который вернёт процентное отношение общего размера всех индексов к общему размеру всех таблиц.

```sql
SELECT 
    table_schema AS 'databaseName',
    #ROUND(SUM(index_length) / 1024 / 1024, 2) AS 'Index_Size_MB',
    ROUND(SUM(INDEX_LENGTH) / (SUM(INDEX_LENGTH)+SUM(DATA_LENGTH)) * 100, 2) AS 'indexToTOtalSize in MB,%'
    #ROUND(SUM(index_length) / SUM(data_length) * 100, 2) AS 'indexToDataPercentage',
    #ROUND(SUM(data_length) / 1024 / 1024, 2) AS 'dataSize in MB',
    #ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'totalSize in MB'
FROM information_schema.TABLES
WHERE table_schema = 'sakila';
```
![task 1](https://github.com/ugegkonst/sdb-homeworks/blob/e4590fe0d9de0e078e5ce215b2089ebf75ed0860/relationalDB/05-Indexes/img/05-Indexes-1.png)

### Задание 2

Выполните explain analyze следующего запроса:
```sql
select distinct concat(c.last_name, ' ', c.first_name), sum(p.amount) over (partition by c.customer_id, f.title)
from payment p, rental r, customer c, inventory i, film f
where date(p.payment_date) = '2005-07-30' and p.payment_date = r.rental_date and r.customer_id = c.customer_id and i.inventory_id = r.inventory_id
```
- перечислите узкие места;
- оптимизируйте запрос: внесите корректировки по использованию операторов, при необходимости добавьте индексы.

```sql
-> Table scan on <temporary>  (cost=2.5..2.5 rows=0) (actual time=10827..10827 rows=391 loops=1)
    -> Temporary table with deduplication  (cost=0..0 rows=0) (actual time=10827..10827 rows=391 loops=1)
        -> Window aggregate with buffering: sum(payment.amount) OVER (PARTITION BY c.customer_id,f.title )   (actual time=4889..10474 rows=642000 loops=1)
            -> Sort: c.customer_id, f.title  (actual time=4889..4986 rows=642000 loops=1)
                -> Stream results  (cost=22e+6 rows=16.1e+6) (actual time=1.88..3832 rows=642000 loops=1)
                    -> Nested loop inner join  (cost=22e+6 rows=16.1e+6) (actual time=1.86..3342 rows=642000 loops=1)
                        -> Nested loop inner join  (cost=20.4e+6 rows=16.1e+6) (actual time=1.85..3000 rows=642000 loops=1)
                            -> Nested loop inner join  (cost=18.8e+6 rows=16.1e+6) (actual time=1.83..2635 rows=642000 loops=1)
                                -> Inner hash join (no condition)  (cost=1.61e+6 rows=16.1e+6) (actual time=1.79..76.5 rows=634000 loops=1)
                                    -> Filter: (cast(p.payment_date as date) = '2005-07-30')  (cost=1.68 rows=16086) (actual time=0.793..11.8 rows=634 loops=1)
                                        -> Table scan on p  (cost=1.68 rows=16086) (actual time=0.76..8.41 rows=16044 loops=1)
                                    -> Hash
                                        -> Covering index scan on f using idx_title  (cost=103 rows=1000) (actual time=0.0975..0.749 rows=1000 loops=1)
                                -> Covering index lookup on r using rental_date (rental_date=p.payment_date)  (cost=0.969 rows=1) (actual time=0.00286..0.00378 rows=1.01 loops=634000)
                            -> Single-row index lookup on c using PRIMARY (customer_id=r.customer_id)  (cost=250e-6 rows=1) (actual time=278e-6..320e-6 rows=1 loops=642000)
                        -> Single-row covering index lookup on i using PRIMARY (inventory_id=r.inventory_id)  (cost=250e-6 rows=1) (actual time=248e-6..290e-6 rows=1 loops=642000)
```

По выводу видно, что таблица film не нужна, убираем ее, а также проверку по inventory_id

```sql
EXPLAIN ANALYZE 
select distinct 
	concat(c.last_name, ' ', c.first_name), 
	sum(p.amount) over (partition by c.customer_id)
from payment p, rental r, customer c
where date(p.payment_date) = '2005-07-30' 
	and p.payment_date = r.rental_date 
	and r.customer_id = c.customer_id;

-> Table scan on <temporary>  (cost=2.5..2.5 rows=0) (actual time=17.3..17.4 rows=391 loops=1)
    -> Temporary table with deduplication  (cost=0..0 rows=0) (actual time=17.3..17.3 rows=391 loops=1)
        -> Window aggregate with buffering: sum(payment.amount) OVER (PARTITION BY c.customer_id )   (actual time=15.1..17 rows=642 loops=1)
            -> Sort: c.customer_id  (actual time=15.1..15.2 rows=642 loops=1)
                -> Stream results  (cost=24455 rows=16086) (actual time=0.54..14.8 rows=642 loops=1)
                    -> Nested loop inner join  (cost=24455 rows=16086) (actual time=0.533..14.4 rows=642 loops=1)
                        -> Nested loop inner join  (cost=18825 rows=16086) (actual time=0.52..12.9 rows=642 loops=1)
                            -> Filter: (cast(p.payment_date as date) = '2005-07-30')  (cost=1633 rows=16086) (actual time=0.497..10.1 rows=634 loops=1)
                                -> Table scan on p  (cost=1633 rows=16086) (actual time=0.477..7.63 rows=16044 loops=1)
                            -> Covering index lookup on r using rental_date (rental_date=p.payment_date)  (cost=0.969 rows=1) (actual time=0.00318..0.00416 rows=1.01 loops=634)
                        -> Single-row index lookup on c using PRIMARY (customer_id=r.customer_id)  (cost=0.25 rows=1) (actual time=0.00196..0.00201 rows=1 loops=642)
  
```
Работа скрипта заметно ускорилась.
Далее подключил JOIN

```sql
# Подключил JOIN                     
EXPLAIN ANALYZE 
select distinct 
	concat(c.last_name, ' ', c.first_name), 
	sum(p.amount) over (partition by c.customer_id)
from payment p
JOIN rental r ON p.payment_date = r.rental_date
JOIN customer c ON r.customer_id = c.customer_id
JOIN inventory i ON r.inventory_id = i.inventory_id
where date(p.payment_date) = '2005-07-30' 
	and p.payment_date = r.rental_date 
	and r.customer_id = c.customer_id;

-> Table scan on <temporary>  (cost=2.5..2.5 rows=0) (actual time=21.2..21.3 rows=391 loops=1)
    -> Temporary table with deduplication  (cost=0..0 rows=0) (actual time=21.2..21.2 rows=391 loops=1)
        -> Window aggregate with buffering: sum(payment.amount) OVER (PARTITION BY c.customer_id )   (actual time=18.8..20.8 rows=642 loops=1)
            -> Sort: c.customer_id  (actual time=18.7..18.8 rows=642 loops=1)
                -> Stream results  (cost=30085 rows=16086) (actual time=0.579..18.4 rows=642 loops=1)
                    -> Nested loop inner join  (cost=30085 rows=16086) (actual time=0.571..17.9 rows=642 loops=1)
                        -> Nested loop inner join  (cost=24455 rows=16086) (actual time=0.562..15.7 rows=642 loops=1)
                            -> Nested loop inner join  (cost=18825 rows=16086) (actual time=0.55..14.1 rows=642 loops=1)
                                -> Filter: (cast(p.payment_date as date) = '2005-07-30')  (cost=1633 rows=16086) (actual time=0.525..11 rows=634 loops=1)
                                    -> Table scan on p  (cost=1633 rows=16086) (actual time=0.503..8.2 rows=16044 loops=1)
                                -> Covering index lookup on r using rental_date (rental_date=p.payment_date)  (cost=0.969 rows=1) (actual time=0.00345..0.00448 rows=1.01 loops=634)
                            -> Single-row index lookup on c using PRIMARY (customer_id=r.customer_id)  (cost=0.25 rows=1) (actual time=0.00213..0.00218 rows=1 loops=642)
                        -> Single-row covering index lookup on i using PRIMARY (inventory_id=r.inventory_id)  (cost=0.25 rows=1) (actual time=0.00322..0.00326 rows=1 loops=642)
```

Заменил OVER PARTITION BY на GROUP BY и добавил индекс на payment_date

```sql
# Заменил OVER PARTITION BY на GROUP BY   

CREATE INDEX ind_payment_date ON payment(payment_date);
EXPLAIN ANALYZE
select distinct 
	concat(c.last_name, ' ', c.first_name), 
	sum(p.amount)
from payment p
JOIN rental r ON p.payment_date = r.rental_date
JOIN customer c ON r.customer_id = c.customer_id
JOIN inventory i ON r.inventory_id = i.inventory_id
where date(p.payment_date) = '2005-07-30' 
	and p.payment_date = r.rental_date 
	and r.customer_id = c.customer_id
GROUP BY c.customer_id;                   
                   
                       
# Добавил CREATE INDEX ind_payment_date ON payment(payment_date);                      
-> Sort with duplicate removal: `concat(c.last_name, ' ', c.first_name)`, `sum(p.amount)`  (actual time=18.6..18.6 rows=391 loops=1)
    -> Table scan on <temporary>  (actual time=18.2..18.2 rows=391 loops=1)
        -> Aggregate using temporary table  (actual time=18.2..18.2 rows=391 loops=1)
            -> Nested loop inner join  (cost=30085 rows=16086) (actual time=0.578..17.2 rows=642 loops=1)
                -> Nested loop inner join  (cost=24455 rows=16086) (actual time=0.569..15 rows=642 loops=1)
                    -> Nested loop inner join  (cost=18825 rows=16086) (actual time=0.557..13.4 rows=642 loops=1)
                        -> Filter: (cast(p.payment_date as date) = '2005-07-30')  (cost=1633 rows=16086) (actual time=0.533..10.4 rows=634 loops=1)
                            -> Table scan on p  (cost=1633 rows=16086) (actual time=0.511..7.83 rows=16044 loops=1)
                        -> Covering index lookup on r using rental_date (rental_date=p.payment_date)  (cost=0.969 rows=1) (actual time=0.00339..0.00444 rows=1.01 loops=634)
                    -> Single-row index lookup on c using PRIMARY (customer_id=r.customer_id)  (cost=0.25 rows=1) (actual time=0.00206..0.00211 rows=1 loops=642)
                -> Single-row covering index lookup on i using PRIMARY (inventory_id=r.inventory_id)  (cost=0.25 rows=1) (actual time=0.00312..0.00317 rows=1 loops=642)                             
```

По итогу время выполнения скрипта сократилось с 9,5 секунд до 0,021 секунды

![task 2](https://github.com/ugegkonst/sdb-homeworks/blob/553a22f271f95355df0bb4685e916e15773cdcb5/relationalDB/05-Indexes/img/05-Indexes-2.png)

## Дополнительные задания (со звёздочкой*)
Эти задания дополнительные, то есть не обязательные к выполнению, и никак не повлияют на получение вами зачёта по этому домашнему заданию. Вы можете их выполнить, если хотите глубже шире разобраться в материале.

### Задание 3*

Самостоятельно изучите, какие типы индексов используются в PostgreSQL. Перечислите те индексы, которые используются в PostgreSQL, а в MySQL — нет.

*Приведите ответ в свободной форме.*
