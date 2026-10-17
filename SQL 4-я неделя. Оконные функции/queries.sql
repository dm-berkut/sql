-- SQL 4-я неделя. Оконные функции

-- Задание 1

WITH day_total AS (
	SELECT
		book_date::date as book_date,
		SUM(total_amount) as day_total
	FROM prod.bookings
	GROUP BY book_date::date
)

SELECT
	book_date,
	SUM(day_total) OVER(
		ORDER BY book_date
		ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as running_total
FROM day_total;

-- Задание 2

SELECT 
	ticket_no,
	flight_id,
	price
FROM (
	SELECT
		ticket_no,
		flight_id,
		price,
		DENSE_RANK() OVER (PARTITION BY flight_id ORDER BY price DESC) as rank
	FROM prod.segments
)
WHERE rank <= 3;

-- Задание 3

SELECT 
    flight_id,
    fare_conditions,
    price,
    avg_class_price,
    diff_from_avg
FROM (
    SELECT 
        flight_id,
        fare_conditions,
        price,
        ROUND(AVG(price) OVER (PARTITION BY fare_conditions), 2) AS avg_class_price,
        ROUND(price - AVG(price) OVER (PARTITION BY fare_conditions), 2) AS diff_from_avg,
        ROW_NUMBER() OVER (PARTITION BY flight_id, fare_conditions, price ORDER BY flight_id) AS rn
    FROM prod.segments)
WHERE rn = 1
ORDER BY flight_id, fare_conditions, price;

-- Задание 4

SELECT
	passenger_name,
	flight_id,
	actual_departure,
	actual_departure - LAG(actual_departure) OVER (ORDER BY actual_departure) as time_since_last_flight
FROM (
	SELECT
		t.passenger_name,
		f.flight_id,
		f.actual_departure
	FROM prod.tickets t 
		JOIN prod.segments s 
			ON t.ticket_no = s.ticket_no 
		JOIN prod.flights f 
			ON s.flight_id = f.flight_id
	WHERE t.passenger_name = 'Franklin Meyer'
	ORDER BY actual_departure);

-- Задание 5

SELECT 
    *,
    total_amount * 100.0 / SUM(total_amount) OVER () AS day_percent
FROM prod.bookings
WHERE DATE(book_date) = '2025-10-12'
LIMIT 50;

-- Задание 6

SELECT
	ticket_no,
	flight_id,
	seat_no,
	ROW_NUMBER() OVER (ORDER BY boarding_time) as new_boarding_no,
	boarding_time
FROM prod.boarding_passes
WHERE flight_id = 15;

-- Задание 7

SELECT
	dep_date,
	departure_airport,
	flight_id,
	scheduled_departure
FROM (
	SELECT
		DATE(f.scheduled_departure) as dep_date,
		r.departure_airport,
		f.flight_id,
		f.scheduled_departure,
		ROW_NUMBER() OVER (
			PARTITION BY DATE(f.scheduled_departure) 
			ORDER BY f.scheduled_departure
		) as rn
	FROM prod.flights f
		JOIN prod.routes r 
			ON f.route_no = r.route_no
	WHERE f.scheduled_departure <@ r.validity 
		AND r.departure_airport = 'AER'
)
WHERE rn = 1
ORDER BY dep_date;

-- Задание 8

WITH daily_revenue AS (
	SELECT
		DATE(book_date) as date,
		SUM(total_amount) as day_revenue
	FROM prod.bookings
	GROUP BY DATE(book_date)
)

SELECT
	*,
	ROUND(AVG(day_revenue) OVER (
		ORDER BY date
		ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
	), 2) as moving_avg
FROM daily_revenue;