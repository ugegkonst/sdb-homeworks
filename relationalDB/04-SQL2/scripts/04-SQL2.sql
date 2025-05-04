show databases;
use sakila;
show tables;

# 1
SELECT 
	s_Str.store_id,
	CONCAT(s_Stf.first_name, ' ', s_Stf.last_name) AS staffNameSurname,
	s_Ct.city,
	s_Addr.address,
	COUNT(s_Cust.customer_id) AS clientsNumber
FROM sakila.store AS s_Str
INNER JOIN sakila.staff AS s_Stf ON s_Stf.store_id = s_Str.store_id
INNER JOIN sakila.customer AS s_Cust ON s_Cust.store_id = s_Str.store_id
INNER JOIN sakila.address AS s_Addr ON s_Addr.address_id = s_Str.address_id
INNER JOIN sakila.city AS s_Ct ON s_Ct.city_id = s_Addr.city_id
GROUP BY s_Str.store_id, s_Ct.city, s_Addr.address, staffNameSurname
HAVING COUNT(s_Cust.customer_id) > 300;

# 2
SELECT 
		COUNT(film_id) AS 'fQLongerThanAverageFilm'
FROM sakila.film
WHERE length > (SELECT AVG(length) FROM sakila.film);


#(SELECT AVG(length) FROM sakila.film) AS averageLength,
#(SELECT COUNT(film_id) FROM sakila.film) AS 'filmQuantity',

# 3
SELECT
	SUBSTRING_INDEX(DATE(payment_date),'-',2) AS yearMonth,
	COUNT(payment_id) AS numberOfPayments,
	SUM(amount)
FROM sakila.payment
GROUP BY yearMonth
ORDER BY COUNT(payment_id) DESC LIMIT 1;


	#CASE
	#	WHEN MONTH(payment_date) = 01 THEN 'January'
	#	WHEN MONTH(payment_date) = 02 THEN 'February'
	#	WHEN MONTH(payment_date) = 03 THEN 'March'
	#	WHEN MONTH(payment_date) = 04 THEN 'April'
	#	WHEN MONTH(payment_date) = 05 THEN 'May'
	#	WHEN MONTH(payment_date) = 06 THEN 'June'
	#	WHEN MONTH(payment_date) = 07 THEN 'July'
	#	WHEN MONTH(payment_date) = 08 THEN 'August'
	#	WHEN MONTH(payment_date) = 09 THEN 'September'
	#	WHEN MONTH(payment_date) = 10 THEN 'October'
	#	WHEN RIGHT(SUBSTRING_INDEX(DATE(payment_date),'-',2),2) = 11 THEN 'November'
	#	ELSE 'December'
	#END AS Month,


# 4
SELECT 
	CONCAT(sS.first_name, ' ', sS.last_name) AS nameSurname,
	COUNT(sP.payment_id) AS numberOfPayments,
	CASE 
		WHEN COUNT(sP.payment_id) > 8000 THEN 'Yes'
		ELSE 'No'
	END AS Prime
FROM sakila.payment sP
JOIN sakila.staff sS ON sS.staff_id = sP.staff_id
GROUP BY sP.staff_id;

# 5
SELECT 
	#COUNT(sF.title),
	sF.title,
	sF.film_id,
	sI.film_id,
	sI.inventory_id AS invInINV,
	sR.inventory_id AS invInRental,
	sR.rental_id
FROM sakila.film AS sF
LEFT JOIN sakila.inventory as sI ON sI.film_id = sF.film_id
LEFT JOIN sakila.rental AS sR ON sR.inventory_id = sI.inventory_id
WHERE 
	sR.inventory_id IS NULL
	OR sI.inventory_id IS NULL
	OR sR.rental_id IS NULL;








































