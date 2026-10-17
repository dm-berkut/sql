-- SQL 5-я неделя. Представления

-- Задание 1

CREATE OR REPLACE VIEW sandbox.berkut_v_departure_time AS
SELECT 
	route_no,
	scheduled_departure_local::time as departure_time,
	arrival_airport,
	CONCAT(LEFT(t2.passenger_name, 1), '***') as pass_name,
	0::numeric AS price
FROM prod.timetable t
	JOIN prod.segments s 
		USING(flight_id)
	JOIN prod.tickets t2 
		USING(ticket_no)
WHERE t.scheduled_departure_local::date = CURRENT_DATE;

-- Задание 2

CREATE OR REPLACE VIEW sandbox.berkut_v_routes_financial_report AS
	WITH routes_cities AS (
		SELECT
			r.route_no,
			dep.city ->> 'ru' as dep_city,
			arr.city ->> 'ru' as arr_city
		FROM prod.routes r 
			JOIN prod.airports_data dep
				ON r.departure_airport = dep.airport_code
			JOIN prod.airports_data arr
				ON r.arrival_airport = arr.airport_code
	)
	SELECT 
		CONCAT(rc.dep_city, ' - ', rc.arr_city) as route,
		ROUND(AVG(s.price), 2) as ticket_avg_price,
		ROUND(SUM(s.price),2) as route_revenue
	FROM prod.timetable t 
		JOIN prod.segments s 
			USING(flight_id)
		JOIN routes_cities rc
			USING(route_no)
	GROUP BY CONCAT(rc.dep_city, ' - ', rc.arr_city);

-- Задание 3

CREATE OR REPLACE VIEW sandbox.berkut_v_7m7_price_stats AS
-- Для ускорения запроса сначала фильруем посадочные талоны с местами 1А
WITH seat_1a AS (
    SELECT
        flight_id,
        ticket_no,
        seat_no
    FROM prod.boarding_passes
    WHERE seat_no = '1A'
)
-- Далее собираем другие данные и фильруем по модели самолета
SELECT
	MAX(bp.seat_no),
    MIN(s.price) AS min_price,
    ROUND(AVG(s.price), 2) AS avg_price,
    MAX(s.price) AS max_price
FROM seat_1a bp
JOIN prod.segments s
    USING (flight_id, ticket_no)
JOIN prod.flights f
    USING (flight_id)
JOIN prod.routes r
    ON r.route_no = f.route_no
   AND r.validity @> f.scheduled_departure
WHERE r.airplane_code = '7M7';