-- select * from citibike_trips limit 10;

-- Question 1: How does CitiBike station utilization vary by time of day and day of week,
--             and what does that reveal about commuter vs recreational usage patterns?

-- Question 1.a: Which stations have the most number of rides originating from them?

select start_station_name, count(*) as total_rides
from citibike_trips
group by start_station_name
order by total_rides desc
limit 10;

-- Question 1.b: Which stations have the most number of rides ending at them?

select end_station_name, count(*) as total_rides
from citibike_trips
group by end_station_name
order by total_rides desc
limit 10;

-- Question 1.c: Which stations are busiest departure stations by hour and day of week?

select start_station_name, count(*) as total_rides,
       to_char(started_at, 'Day') as day_of_week,
       extract(HOUR from started_at) as hour_of_day
from citibike_trips
group by day_of_week, hour_of_day, start_station_name
order by total_rides desc;

--Question 1.d: Which stations are busiest arrival stations by hour and day of week?

select end_station_name, count(*) as total_rides,
       to_char(ended_at, 'Day') as day_of_week,
       extract(HOUR from ended_at) as hour_of_day
from citibike_trips
group by day_of_week, hour_of_day, end_station_name
order by total_rides desc;


-- Question 2: How do member and casual riders differ in behavior,
--            and what does that imply for infrastructure and pricing decisions?

-- Question 2.a: Ride duration by rider type?

select member_casual, extract(EPOCH from avg(ended_at - started_at))/60 as duration
from citibike_trips
group by member_casual
order by duration desc;

-- Question 2.b: Ride time and day by rider type?

select member_casual, count(*) as total_rides,
       to_char(started_at, 'Day') as day_of_week,
       extract(HOUR from started_at) as hour_of_day
from citibike_trips
group by day_of_week, hour_of_day, member_casual
order by total_rides desc;

-- Question 2.c: Bike type by rider type?

select member_casual, rideable_type, count(*) as total_rides
from citibike_trips
group by member_casual, rideable_type;

-- Question 2.d: Which are the top departure stations for members vs casual riders, and do they differ?

-- For members
select member_casual, start_station_name, count(*) as total_rides
from citibike_trips
where member_casual = 'member'
group by member_casual, start_station_name
order by total_rides desc;

-- For casuals
select member_casual, start_station_name, count(*) as total_rides
from citibike_trips
where member_casual = 'casual'
group by member_casual, start_station_name
order by total_rides desc;


-- Question 3: How well is CitiBike infrastructure distributed across Jersey City area based on ride demand?

-- Question 3.a: Which stations show the highest bike flow imbalance relative to their total ride volume?

WITH departures AS (
    select start_station_name, count(*) as total_rides, started_at::date as started_date, to_char(started_at,'Day') as start_day
    from citibike_trips
    group by start_station_name, started_date, start_day
),
arrivals AS (
    select end_station_name, count(*) as total_rides, ended_at::date as ended_date, to_char(ended_at,'Day') as end_day
    from citibike_trips
    group by end_station_name, ended_date, end_day
),
flow AS (
    SELECT COALESCE(dep.start_station_name, arr.end_station_name) as station_name, dep.total_rides as departures,
       arr.total_rides as arrivals, COALESCE(dep.total_rides,0) - COALESCE(arr.total_rides,0) as bike_flow,
       coalesce(dep.started_date, arr.ended_date) as ride_date, coalesce(dep.start_day, arr.end_day) as ride_day
    FROM departures dep
    FULL OUTER JOIN arrivals arr ON dep.start_station_name = arr.end_station_name and dep.started_date = arr.ended_date
),
imbalance as (
    SELECT *, (abs(bike_flow)/ CAST (COALESCE (departures, 0)+ COALESCE (arrivals, 0) AS FLOAT)) * 100 AS imbalance_percentage
    FROM flow
    WHERE departures+arrivals >25
    ORDER BY imbalance_percentage DESC
)
select station_name, sum(departures) as total_departures,
       sum(arrivals) as total_arrivals, avg(bike_flow) as average_flow, avg(imbalance_percentage) as average_imbalance
from imbalance
GROUP BY station_name
ORDER BY average_imbalance desc;

-- Question 3.b: Which stations have very low ride volume?
-- Redundant as this has been cumulatively answered by Question 1 and 3. So this question is being dropped.

-- Question 3.c: Which areas have a higher concentration of stations and which areas are less densely covered?
-- Will be covered with tableau.


-- Question 4: How does ride duration vary by hour and day of week,
--             and what does that reveal about needs for commuter vs recreational demand?

select count(*) as total_rides, round(extract(EPOCH from avg(ended_at - started_at))/60 :: numeric,2) as average_ride_duration,
       extract(HOUR from started_at) as hour_of_day,
       to_char(started_at, 'DAY') as day_of_week, member_casual
from citibike_trips
group BY member_casual, day_of_week, hour_of_day
ORDER BY average_ride_duration desc;