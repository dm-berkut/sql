-- SQL 2-я неделя. Множества, условия, соединения
-- Задание 1

SELECT DISTINCT airport_code
FROM (
	SELECT departure_airport as airport_code
	FROM prod.routes
	
	UNION
	
	SELECT arrival_airport as airport_code
	FROM prod.routes
) AS all_airports
ORDER BY airport_code;

-- Задание 2

SELECT *
FROM (
	SELECT	
		flight_id,
		'Departure' as event_type,
		scheduled_departure as event_time
	FROM prod.flights
	
	UNION ALL
	
	SELECT
		flight_id,
		'Arrival' as event_type,
		scheduled_arrival as event_time
	FROM prod.flights
)
ORDER BY event_time;

-- Задание 3

SELECT DISTINCT ad.airplane_code 
FROM prod.airplanes_data ad 
JOIN prod.seats s 
	ON ad.airplane_code = s.airplane_code
WHERE s.fare_conditions IN ('Business', 'Comfort');

-- Задание 4

SELECT DISTINCT s.seat_no
FROM prod.flights AS f
JOIN prod.routes AS r
    ON f.route_no = r.route_no
JOIN prod.seats AS s
    ON r.airplane_code = s.airplane_code
LEFT JOIN prod.boarding_passes AS bp
    ON f.flight_id = bp.flight_id
   AND s.seat_no = bp.seat_no
WHERE f.flight_id = 1275
  AND bp.seat_no IS NULL
ORDER BY s.seat_no;

-- Задание 5

SELECT 
	ticket_no,
	passenger_name,
	CASE
		WHEN outbound = true THEN 'Туда'
		WHEN outbound = false THEN 'Обратно'
	END AS direction
FROM prod.tickets;

-- Задание 6

SELECT 
	airplane_code,
	model->>'en' as model,
	CASE
		WHEN range < 4000 THEN 'Ближнемагистральный'
		WHEN range BETWEEN 4000 and 8000 THEN 'Среднемагистральный'
		WHEN range > 8000 THEN 'Дальнемагистральный'
	END as range_category
FROM prod.airplanes_data
ORDER BY range;

-- Задание 7

SELECT
	flight_id,
	status,
	CASE
		WHEN status = 'Scheduled' OR status = 'On Time' OR status = 'Delayed' THEN 'Ожидается'
		WHEN status = 'Boarding' OR status = 'Departed' THEN 'В процессе'
		WHEN status = 'Arrived' THEN 'Завершен'
		WHEN status = 'Cancelled' THEN 'Отменен'
	END as simple_status,
	scheduled_departure 
FROM prod.flights
WHERE scheduled_departure > prod.now() - INTERVAL '3 days'
ORDER BY scheduled_departure DESC;

-- Задание 8

SELECT 
	ticket_no,
	flight_id,
	fare_conditions,
	price,
	CASE
		WHEN price > 5000 AND fare_conditions = 'Economy' THEN 'Подозрительно дорогой эконом'
		WHEN price < 15000 AND fare_conditions = 'Business' THEN 'Подозрительно дешевый бизнес'
		ELSE 'Норма'
	END as price_alert
FROM prod.segments;

-- Задание 9

SELECT 
	flight_id,
	scheduled_departure_local,
	CASE
		WHEN EXTRACT(hour FROM scheduled_departure_local) BETWEEN 6 AND 11 THEN 'Утро' 
		WHEN EXTRACT(hour FROM scheduled_departure_local) BETWEEN 12 AND 17 THEN 'День'
		WHEN EXTRACT(hour FROM scheduled_departure_local) BETWEEN 18 AND 23 THEN 'Вечер'
		ELSE 'Ночь'
	END as time_of_day
FROM prod.timetable;

-- Задание 10

SELECT 
	CASE
		WHEN EXTRACT(hour FROM scheduled_departure_local) BETWEEN 6 AND 11 THEN 'Утро' 
		WHEN EXTRACT(hour FROM scheduled_departure_local) BETWEEN 12 AND 17 THEN 'День'
		WHEN EXTRACT(hour FROM scheduled_departure_local) BETWEEN 18 AND 23 THEN 'Вечер'
		ELSE 'Ночь'
	END as time_of_day,
	COUNT(*) as flights_count
FROM prod.timetable
GROUP BY time_of_day
ORDER BY flights_count DESC;

-- Задание 11

SELECT 
	ad.airplane_code,
	model->>'en' as model,
	COUNT(ad.airplane_code) as seats_count
FROM prod.airplanes_data ad
JOIN prod.seats s 
	ON ad.airplane_code = s.airplane_code
GROUP BY ad.model, ad.airplane_code 
ORDER BY seats_count DESC;

-- Задание 12

SELECT 
    b.book_ref,
    b.book_date,
    b.total_amount,
    STRING_AGG(t.passenger_name, ', ') AS passengers
FROM prod.bookings b
JOIN prod.tickets t
    ON b.book_ref = t.book_ref
WHERE b.total_amount > 900000
GROUP BY b.book_ref, b.book_date, b.total_amount
ORDER BY b.total_amount DESC
LIMIT 10;

-- Задание 13

SELECT 
	r.route_no,
	ad.city->>'en' as departure_city,
	ad2.city->>'en' as arrival_city
FROM prod.routes r 
JOIN prod.airports_data ad 
	ON r.departure_airport = ad.airport_code
JOIN prod.airports_data ad2 
	ON r.arrival_airport = ad2.airport_code;

-- Задание 14

SELECT
	t.ticket_no,
	t.passenger_name,
	s.fare_conditions
FROM prod.flights f 
NATURAL JOIN prod.segments s
NATURAL JOIN prod.tickets t
WHERE f.flight_id = 123;

-- Задание 15

SELECT s.seat_no 
FROM prod.timetable t 
JOIN prod.seats s 
	ON t.airplane_code = s.airplane_code 
LEFT JOIN prod.boarding_passes bp 
	ON s.seat_no = bp.seat_no
	AND t.flight_id = bp.flight_id
WHERE t.flight_id = 23405 AND bp.seat_no IS NULL;

-- Задание 16

SELECT 
	ad.model->>'en' as model_name,
	COUNT(*) as flights_count
FROM prod.flights f
JOIN prod.routes r 
	ON f.route_no = r.route_no 
JOIN prod.airplanes_data ad 
	ON r.airplane_code = ad.airplane_code 
WHERE status = 'Scheduled'
GROUP BY ad.model->>'en'
ORDER BY flights_count DESC

-- Задание 17

SELECT DISTINCT
	t.passenger_name,
	f.route_no,
	f.scheduled_departure,
	ad1.city->>'en' as departure,
	ad2.city->>'en' as arival
FROM prod.tickets t 
JOIN prod.segments s 
	ON t.ticket_no = s.ticket_no 
JOIN prod.flights f
	ON s.flight_id = f.flight_id
JOIN prod.routes r 
	ON f.route_no = r.route_no
JOIN prod.airports_data ad1
	ON r.departure_airport = ad1.airport_code 
JOIN prod.airports_data ad2
	ON r.arrival_airport = ad2.airport_code 
WHERE t.ticket_no = '0005432000987';