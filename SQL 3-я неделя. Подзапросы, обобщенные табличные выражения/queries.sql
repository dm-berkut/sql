-- SQL 3-я неделя. Подзапросы, обобщенные табличные выражения

-- Задание 1

SELECT
	airplane_code,
	model->>'ru' as model_name_ru,
	range
FROM prod.airplanes_data
WHERE range > (SELECT AVG(range) FROM prod.airplanes_data)
ORDER BY range DESC;

-- Задание 2

SELECT 
	book_ref,
	total_amount 
FROM prod.bookings
WHERE book_ref IN (
	SELECT book_ref 
	FROM prod.tickets
	WHERE passenger_name = 'Franklin Meyer'
	);

-- Задание 3

SELECT MAX(price) as second_max
FROM prod.segments 
WHERE price < (SELECT MAX(price) FROM prod.segments);

-- Задание 4

SELECT
	book_ref,
	total_amount,
	(SELECT COUNT(*) FROM prod.tickets t WHERE t.book_ref = b.book_ref) as ticket_num
FROM prod.bookings b
ORDER BY ticket_num DESC
LIMIT 10;

-- Задание 5

WITH flight_revenue AS (
    SELECT 
        flight_id,
        SUM(price) AS revenue
    FROM prod.segments
    GROUP BY flight_id
)
SELECT 
    f.flight_id,
    COALESCE(f.actual_departure, f.scheduled_departure) AS departure_time,
    fr.revenue
FROM prod.flights f
JOIN flight_revenue fr
    ON fr.flight_id = f.flight_id
WHERE fr.revenue > 15000000;

-- Задание 6

WITH total_pass AS (
    SELECT 
        bp.flight_id,
        COUNT(*) AS total_passengers
    FROM prod.boarding_passes bp 
    GROUP BY bp.flight_id
)
SELECT 
    f.flight_id,
    f.route_no,
    f.status,
    f.scheduled_departure,
    f.scheduled_arrival,
    f.actual_departure,
    f.actual_arrival,
    tp.total_passengers
FROM prod.flights f
JOIN total_pass tp
    ON f.flight_id = tp.flight_id
WHERE status = 'Departed' OR status = 'Arrived';

-- Задание 7

SELECT 
	flight_id,
	route_no,
	scheduled_departure,
	actual_departure,
	actual_departure - scheduled_departure as departure_delay
FROM prod.flights
WHERE actual_departure IS NOT NULL
ORDER BY departure_delay DESC
LIMIT 5;

-- Задание 8

WITH all_seats AS (
	SELECT
	    f.flight_id,
	    COUNT(s.seat_no) AS total_seats
	FROM prod.flights f
	JOIN prod.routes r
	    ON r.route_no = f.route_no
	   AND f.scheduled_departure <@ r.validity
	JOIN prod.seats s
	    ON s.airplane_code = r.airplane_code
	GROUP BY f.flight_id
	),
booked_seats AS (
	SELECT 
	    bp.flight_id,
	    COUNT(*) AS occupied_seats
	FROM prod.boarding_passes bp
	GROUP BY bp.flight_id
	)

SELECT 
	a.flight_id,
	bs.occupied_seats,
	a.total_seats,
	ROUND(bs.occupied_seats * 100.0 / a.total_seats, 2) as occupancy_rate
FROM all_seats a
JOIN booked_seats bs
    ON bs.flight_id = a.flight_id;

-- Задание 9

WITH avg_price AS (
    SELECT
        f.route_no,
        ROUND(AVG(s.price), 2) AS avg_price
    FROM prod.flights f
    JOIN prod.segments s 
        ON s.flight_id = f.flight_id
    GROUP BY f.route_no
),
routes_unique AS (
    SELECT DISTINCT
        route_no,
        departure_airport,
        arrival_airport
    FROM prod.routes
)
SELECT
    r.route_no,
    r.departure_airport,
    r.arrival_airport,
    ap.avg_price
FROM routes_unique r
JOIN avg_price ap
    ON ap.route_no = r.route_no;

-- Задание 10

SELECT 
	ad.airport_name ->> 'en' as airport_name,
	ad.city ->> 'en' as city,
	COUNT(DISTINCT r.route_no) as routes_count
FROM prod.routes r
JOIN prod.airports_data ad 
	ON r.departure_airport = ad.airport_code
GROUP BY 
	ad.airport_name ->> 'en',
	ad.city ->> 'en'
ORDER BY routes_count DESC;

-- Задание 11

WITH total_revenue AS (
	SELECT 
		flight_id,
		SUM(price) as total_revenue
	FROM prod.segments
	GROUP BY flight_id
),
business_revenue AS (
	SELECT 
		flight_id,
		SUM(price) as business_revenue
	FROM prod.segments
	WHERE fare_conditions = 'Business'
	GROUP BY flight_id
)

SELECT 
	tr.flight_id,
	tr.total_revenue,
	br.business_revenue,
	ROUND(br.business_revenue * 100.0 / tr.total_revenue, 2) as business_percentage
FROM total_revenue tr
JOIN business_revenue br
	ON tr.flight_id = br.flight_id;

-- Задание 12

SELECT
	f.flight_id,
	DATE_TRUNC('minute', f.actual_arrival  - f.actual_departure) as actual_time,
	r.duration as planned_time
FROM prod.flights f
JOIN prod.routes r 
	ON f.route_no = r.route_no
	AND f.scheduled_departure  <@ r.validity 
WHERE f.actual_departure IS NOT NULL
	AND f.actual_arrival IS NOT NULL;