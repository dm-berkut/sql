-- В данном запросе была заменена БД bookings на prod, так как в БД bookings на данный момент 
-- нет таких таблиц как запросе

WITH flight_metrics AS (
    SELECT 
        f.flight_id,
        r.route_no,
        DATE(f.scheduled_departure) AS flight_date,
        r.airplane_code,
        COUNT(s.ticket_no) AS sold_tickets,
        SUM(s.price) AS total_revenue
    FROM prod.flights f
    JOIN prod.routes r ON f.route_no = r.route_no AND r.validity @> f.scheduled_departure
    JOIN prod.segments s ON f.flight_id = s.flight_id
    WHERE f.status IN ('Departed', 'Arrived')
    GROUP BY 
        f.flight_id, 
        r.route_no, 
        DATE(f.scheduled_departure), 
        r.airplane_code
),
advanced_metrics AS (
    SELECT 
        fm.flight_id,
        fm.route_no,
        fm.flight_date,
        fm.sold_tickets,
        fm.total_revenue,
        AVG(fm.total_revenue) OVER (PARTITION BY fm.route_no) AS avg_route_revenue,
        (SELECT COUNT(*) FROM prod.seats st WHERE st.airplane_code = fm.airplane_code) AS max_seats
    FROM flight_metrics fm
)

SELECT 
    flight_id,
    route_no,
    flight_date,
    sold_tickets,
    max_seats,
    ROUND((sold_tickets::numeric / max_seats) * 100, 1) AS load_factor_percent, -- загрузка в %
    total_revenue,
    ROUND(avg_route_revenue, 2) AS avg_route_revenue
FROM advanced_metrics
WHERE 
    -- (продано меньше половины мест)
    sold_tickets < (max_seats / 2) 
    -- (выручка больше, чем в среднем по этому маршруту)
    AND total_revenue > avg_route_revenue
ORDER BY 
    total_revenue DESC;