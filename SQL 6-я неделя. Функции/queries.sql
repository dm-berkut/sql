-- SQL 6-я неделя. Функции

-- Задание 1

CREATE OR REPLACE FUNCTION berkut_f_get_client_segment(p_passenger_id text)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE v_client_segment text;
BEGIN
		-- Создание CTE для нахождения выручки по клиенту за все время (Customer Lifetime Value) 
	WITH customer_lifetime_value AS ( 
		SELECT SUM(price) as clv
		FROM prod.segments s 
		WHERE s.ticket_no IN (
			SELECT 
				ticket_no
			FROM prod.tickets t 
			WHERE t.passenger_id = p_passenger_id
		)
	)
	--Берем из CTE значение CLV и определяем сегмент клиента. Результат возвращаем из функции.
	SELECT
	    CASE 
	        WHEN clv < 50000 THEN 'Standard'
	        WHEN clv BETWEEN 50000 AND 150000 THEN 'Silver'
	        WHEN clv BETWEEN 150000 AND 300000 THEN 'Gold'
	        WHEN clv > 300000 THEN 'Platinum'
	    END AS customer_segment
	INTO v_client_segment
	FROM customer_lifetime_value;

	RETURN v_client_segment;
END;

-- Задание 2

CREATE OR REPLACE FUNCTION berkut_f_refund_ticket_price(p_ticket_no text)
RETURNS numeric
LANGUAGE plpgsql
AS $$
DECLARE v_refund_amount numeric;
BEGIN
	SELECT
	    SUM( --Суммируем, если нашлось несколько перелетов в рамках одного билета
	        CASE
	            WHEN f.scheduled_departure::date = CURRENT_DATE
	                THEN 0::numeric
	            WHEN f.scheduled_departure >= NOW() + INTERVAL '1 day'
	             AND f.scheduled_departure <  NOW() + INTERVAL '3 days'
	                THEN s.price * 0.3::numeric
	            WHEN f.scheduled_departure >= NOW() + INTERVAL '3 days'
	             AND f.scheduled_departure <  NOW() + INTERVAL '14 days'
	                THEN s.price * 0.7::numeric
	            WHEN f.scheduled_departure >= NOW() + INTERVAL '14 days'
	                THEN s.price::numeric
	        END
	    ) AS refund_amount
	INTO v_refund_amount
	FROM prod.segments s
	JOIN prod.flights f
	    USING (flight_id)
	WHERE s.ticket_no = p_ticket_no
	GROUP BY s.ticket_no;

	RETURN v_refund_amount;
END;
$$;

-- Задание 3

CREATE OR REPLACE FUNCTION berkut_f_free_seats(p_flight_id int4, p_segment text)
RETURNS int
LANGUAGE plpgsql
AS $$
DECLARE v_free_seats numeric;
BEGIN
-- CTE для поиска всех мест нужного рейса и класса;
	WITH all_seats AS (
	    SELECT
	        f.flight_id,
	        COUNT(st.seat_no) AS total_seats
	    FROM prod.flights f
	    JOIN prod.routes r
	        ON r.route_no = f.route_no
	       AND f.scheduled_departure <@ r.validity
	    JOIN prod.seats st
	        ON st.airplane_code = r.airplane_code
	    WHERE f.flight_id = p_flight_id
	      AND st.fare_conditions = p_segment
	    GROUP BY f.flight_id
	),
-- CTE для поиска занятых мест нужного рейса и класса;
	booked_seats AS (
	    SELECT 
	        bp.flight_id,
	        COUNT(*) AS occupied_seats
	    FROM prod.boarding_passes bp
	    JOIN prod.segments s 
	        USING (flight_id, ticket_no)
	    WHERE bp.flight_id = p_flight_id
	      AND s.fare_conditions = p_segment
	    GROUP BY bp.flight_id
	)
-- Считаем кол-во свободных мест
	SELECT 
	    a.total_seats - COALESCE(bs.occupied_seats, 0) AS free_seats
	INTO v_free_seats
	FROM all_seats a
	LEFT JOIN booked_seats bs
	    ON bs.flight_id = a.flight_id;

	RETURN v_free_seats;
END;
$$;

-- Задание 4

CREATE OR REPLACE FUNCTION berkut_f_passenger_list(p_flight_id int4)
RETURNS TABLE (
	passenger_name text,
	seat_no text
)
LANGUAGE plpgsql
AS $$
BEGIN
	RETURN QUERY
	SELECT
		t.passenger_name,
		bp.seat_no 
	FROM prod.segments s 
		JOIN prod.boarding_passes bp 
			USING(flight_id, ticket_no)
		JOIN prod.tickets t 
			USING(ticket_no)
	WHERE s.flight_id = p_flight_id;
END;
$$;