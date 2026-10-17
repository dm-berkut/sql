-- SQL 1-я неделя. Базовый SQL
-- Задание 1

SELECT model->>'en' AS model_name
FROM airplanes_data
WHERE range > 5000
ORDER BY range DESC

-- Задание 2

SELECT count(*)
FROM airplanes_data
WHERE range < 4000

-- Задание 3

SELECT flight_id, route_no
FROM flights f 
WHERE status = 'Cancelled'
ORDER BY flight_id 
LIMIT 10

-- Задание 4

SELECT 
	airport_code,
	airport_name->>'ru' AS ru_airport_name,
	airport_name->>'en' AS en_airport_name
FROM airports_data
WHERE city->>'en' = 'Moscow'
ORDER BY airport_code

-- Задание 5

SELECT COUNT(*) as business_seat_count
FROM seats
WHERE airplane_code = '32N' AND fare_conditions = 'Business'

-- Задание 6

SELECT
	book_ref,
	total_amount,
	book_date
FROM bookings
ORDER BY total_amount 
LIMIT 5

-- Задание 7

SELECT 
	airplane_code,
	model->>'ru' AS ru_model_name
FROM airplanes_data
WHERE model->>'ru' LIKE 'Боинг%'

-- Задание 8

SELECT
	MIN(book_date) as first_booking,
	MAX(book_date) as last_booking
FROM bookings

-- Задание 9

SELECT
	timezone,
	COUNT(airport_code) as airport_count
FROM airports_data
GROUP BY timezone
ORDER BY airport_count DESC

-- Задание 10

SELECT 
       passenger_name,
       passenger_id
FROM prod.tickets
ORDER BY LENGTH(SPLIT_PART(passenger_name, ' ', 1))
LIMIT 10;

-- Задание 11

SELECT ROUND(AVG(price), 2) as average_ticket_price
FROM segments

-- Задание 12

SELECT 
	fare_conditions,
	ROUND(AVG(price), 2) as average_price
FROM segments
GROUP BY fare_conditions
ORDER BY average_price DESC

-- Задание 13

SELECT 
	flight_id,
	SUM(price) as revenue
FROM segments
GROUP BY flight_id 
HAVING SUM(price) > 20000000
ORDER BY revenue DESC

-- Задание 14

-- Join на случай, если в какие то аэропорты из справочника уже не летают рейсы

SELECT DISTINCT city->>'ru' as ru_town_name
FROM routes r JOIN airports_data ad 
    ON r.arrival_airport = ad.airport_code
ORDER BY ru_town_name

-- Задание 15

SELECT
	status,
	COUNT(status) as count
FROM flights
GROUP BY status
ORDER BY count DESC

-- Задание 16

SELECT
	airplane_code,
	model->>'ru' as ru_model,
	speed
FROM airplanes_data
ORDER BY speed DESC, ru_model
LIMIT 5

-- Задание 17

SELECT SUM(total_amount) as total_revenue
FROM bookings

-- Задание 18

SELECT
	passenger_name,
	passenger_id 
FROM tickets
WHERE ticket_no = '0005432000284'

-- Задание 19

SELECT DISTINCT fare_conditions 
FROM seats

-- Задание 20

SELECT 
	airport_code,
	airport_name->>'ru' as name,
	city->>'ru' as city
FROM airports_data
WHERE timezone LIKE '%Moscow'
ORDER BY airport_code

-- Задание 21

SELECT
	ticket_no,
	passenger_name 
FROM tickets
WHERE book_ref = 'KOS1KJ'

-- Задание 22

SELECT
	route_no,
	departure_airport,
	arrival_airport,
	duration
FROM routes
ORDER BY duration DESC, route_no DESC
LIMIT 5

-- Задание 23

-- Join чтобы увидеть названия аэропортов, помимо кода

SELECT 
	ad.airport_name ->>'en' as airport_name,
	r.departure_airport as airport_code,
	COUNT(DISTINCT arrival_airport) as cnt
FROM routes r JOIN airports_data ad 
	ON r.departure_airport  = ad.airport_code 
GROUP BY ad.airport_name ->>'en', r.departure_airport
ORDER BY cnt DESC
LIMIT 12