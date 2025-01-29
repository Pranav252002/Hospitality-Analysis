use hospitalty_project_group_4;
-- SQL Queries for Hotel Metrics

-- 1. Total Revenue
SELECT SUM(revenue_realized) AS Total_Revenue
FROM fact_bookings;

-- 2. Total Bookings
SELECT COUNT(booking_id) AS Total_Bookings
FROM fact_bookings;

-- 3. Total Capacity
SELECT SUM(capacity) AS Total_Capacity
FROM fact_aggregated_bookings;

-- 4. Total Successful Bookings
SELECT SUM(successful_bookings) AS Total_Successful_Bookings
FROM fact_aggregated_bookings;

-- 5. Occupancy Percentage
SELECT SUM(capacity) AS Total_Capacity, SUM(successful_bookings) AS Total_Successful_Bookings,
    CONCAT(ROUND((SUM(successful_bookings) * 100.0 / SUM(capacity)),2),'%') AS Occupancy_Percentage
FROM fact_aggregated_bookings;

-- 6. Average Rating
SELECT max(ratings_given)Max_Rating,Min(ratings_given)Min_Rating,
Round (AVG(ratings_given),1) AS Average_Rating
FROM fact_bookings where ratings_given>0;

-- 7. Total Days in Dataset
SELECT DATEDIFF(Max(date), Min(date))+1 AS Total_Days
FROM dim_date;
SELECT min(date)Starting_date,max(date)Ending_date,datediff(max(date),min(date))+1`Total no of Days`  from dim_date;
select count(date) from dim_date;
select count(distinct check_in_date) from fact_bookings;

-- 8. Total Cancelled Bookings
SELECT COUNT(*) AS Total_Cancelled_Bookings
FROM fact_bookings
WHERE booking_status = 'Cancelled';

-- 9. Cancellation Percentage
SELECT COUNT(booking_id) AS Total_Bookings,COUNT(CASE WHEN booking_status = 'Cancelled' THEN 1 END) AS Total_Cancelled_Bookings,
    CONCAT(ROUND((COUNT(CASE WHEN booking_status = 'Cancelled' THEN 1 END) * 100.0 / COUNT(*)),2),'%') AS Cancellation_Percentage
FROM fact_bookings;

-- 10. Total Checked-Out Bookings
SELECT COUNT(*) AS Total_Checked_Out
FROM fact_bookings
WHERE booking_status = 'Checked Out';

-- 11. Total No-Show Bookings
SELECT COUNT(*) AS Total_No_Show
FROM fact_bookings
WHERE booking_status = 'No Show';

SELECT booking_status AS 'Booking Status',COUNT(*) AS 'Count'FROM fact_bookings GROUP BY 1;


-- 12. No-Show Rate Percentage
SELECT COUNT(booking_id) AS Total_Bookings,COUNT(CASE WHEN booking_status = 'No show' THEN 1 END) AS `Total No Show Bookings`,
    CONCAT(ROUND((COUNT(CASE WHEN booking_status = 'No Show' THEN 1 END) * 100.0 / COUNT(*)),2),'%') AS No_Show_Rate_Percentage
FROM fact_bookings;

-- 13. Bookings by Platform Percentage
SELECT 
    booking_platform AS `Booking Platform`,
    CONCAT(ROUND((COUNT(*) * 100.0 / SUM(COUNT(*)) OVER()), 2), '%') AS Platform_Percentage
FROM fact_bookings
GROUP BY 1;


-- 14. Bookings by Room Class Percentage
SELECT 
    a.room_class,
    CONCAT(ROUND((COUNT(*) * 100.0 / SUM(COUNT(*)) OVER()), 2), '%') AS Room_Class_Percentage
FROM fact_bookings b
JOIN dim_rooms a ON b.room_category = a.room_id
GROUP BY a.room_class;


-- 15. Average Daily Rate (ADR)
SELECT 
    (SUM(revenue_realized) / COUNT(booking_id)) AS ADR
FROM fact_bookings;
select round((sum(revenue_realized)/count(*)),2)`Averege Daily Revenue` from fact_bookings;

-- 16. Realisation Percentage
SELECT COUNT(booking_id) AS Total_Bookings, COUNT(CASE WHEN booking_status = 'Checked out' THEN 1 END) AS Total_Succesful_Bookings,
    CONCAT(ROUND((1.0 - (
        (COUNT(CASE WHEN booking_status = 'Cancelled' THEN 1 END) + 
         COUNT(CASE WHEN booking_status = 'No Show' THEN 1 END))
        * 1.0 / COUNT(*)
    )) * 100,2),'%') AS Realisation_Percentage
FROM fact_bookings;

-- 17. Revenue Per Available Room (RevPAR)
SELECT 
   (SUM(a.revenue_realized) / SUM(b.capacity)) AS RevPAR
FROM fact_bookings a
JOIN fact_aggregated_bookings b ON a.property_id = b.property_id;

-- option 2
select (select sum(revenue_realized) from fact_bookings)/(select sum(capacity) from fact_aggregated_bookings) RevPAR;

-- 18. Daily Booked Room Nights (DBRN)
SELECT 
    (SUM(1) * 1.0 / DATEDIFF(MAX(dim_date.date), MIN(dim_date.date))) AS DBRN
FROM fact_bookings 
JOIN dim_date ON fact_bookings.check_in_date = dim_date.date;

-- option 2 
select(select count(booking_status) from fact_bookings)/(select count(date) from dim_date)DBRN;

-- 19. Daily Sellable Room Nights (DSRN)
UPDATE fact_aggregated_bookings
SET check_in_date = STR_TO_DATE(check_in_date, '%d-%b-%y');
ALTER TABLE fact_aggregated_bookings
MODIFY check_in_date DATE;
desc fact_aggregated_bookings;

SELECT 
    (SUM(capacity)/ DATEDIFF(MAX(dim_date.date), MIN(dim_date.date))) AS DSRN
FROM fact_aggregated_bookings
JOIN dim_date  ON fact_aggregated_bookings.check_in_date = dim_date.date;

-- option 2
select sum(capacity)/count(distinct check_in_date)DSRN from fact_aggregated_bookings;

-- 20. Daily Utilized Room Nights (DURN)
SELECT 
    (COUNT(CASE WHEN booking_status = 'Checked Out' THEN 1 END)/ DATEDIFF(MAX(dim_date.date), MIN(dim_date.date))) AS DURN
FROM fact_bookings
join dim_date  ON fact_bookings.check_in_date = dim_date.date;

-- option 2
select(COUNT(CASE WHEN booking_status = 'Checked out' THEN 1 END)/count(distinct check_in_date))DURN from fact_bookings;

-- 21. Week-over-Week Change for Revenue
WITH Revenue_CTE AS (
    SELECT 
        extract(week from check_in_date) AS Week_Number,
        extract(year from check_in_date) AS Year_Number,
        SUM(revenue_realized) AS Weekly_Revenue
    FROM fact_bookings
    GROUP BY extract(week from check_in_date) , extract(year from check_in_date)
)
SELECT 
    Current_Week.Week_Number,
    Current_Week.Year_Number,
    CONCAT(ROUND(((Current_Week.Weekly_Revenue - Previous_Week.Weekly_Revenue) * 100.0 / Previous_Week.Weekly_Revenue),2),'%') AS Revenue_WoW_Change
FROM Revenue_CTE Current_Week
LEFT JOIN Revenue_CTE Previous_Week
    ON Current_Week.Week_Number = Previous_Week.Week_Number + 1
    AND Current_Week.Year_Number = Previous_Week.Year_Number;
    
-- option 2
select year,week,current_week_revenue,prev_week_revenue,
concat(round(((current_week_revenue - prev_week_revenue) / prev_week_revenue) * 100,2),' %') revenue_growth_percentage
from(
select year(check_in_date) as year, week(check_in_date,0)+1 as week, sum(revenue_realized) as current_week_revenue,
lag(sum(revenue_realized)) over(order by year(check_in_date), week(check_in_date,0)+1) as prev_week_revenue
from fact_bookings
group by year(check_in_date), week(check_in_date)+1
) as WeeklyData
order by year, week;


-- 22. Week-over-Week Change for Occupanccy
WITH Occupancy_CTE AS (SELECT extract(week from check_in_date) AS Week_Number,extract(year from check_in_date) AS Year_Number,
COUNT(CASE WHEN booking_status = 'Checked Out' THEN 1 END) AS Weekly_Occupancy FROM fact_bookings
GROUP BY extract(week from check_in_date), extract(year from check_in_date))
SELECT Current_Week.Week_Number,Current_Week.Year_Number,
CONCAT(ROUND(((Current_Week.Weekly_Occupancy - Previous_Week.Weekly_Occupancy) * 100.0 / Previous_Week.Weekly_Occupancy),2),'%') AS Occupancy_WoW_Change
FROM Occupancy_CTE Current_Week LEFT JOIN Occupancy_CTE Previous_Week
ON Current_Week.Week_Number = Previous_Week.Week_Number + 1
AND Current_Week.Year_Number = Previous_Week.Year_Number;
    
-- option 2
select year,week,current_week_total_occupancy,prev_week_occupancy,
concat(round(((current_week_total_occupancy- prev_week_occupancy) / prev_week_occupancy)*100,2)," %") occupancy_growth_percentage
 from (
select year(check_in_date) as year, week(check_in_date,0)+1 as week,
(concat(round((SUM(successful_bookings) * 100.0 / SUM(capacity)),2)," %")) as current_week_total_occupancy,
lag (concat(round((SUM(successful_bookings) * 100.0 / SUM(capacity)),2)," %"))
 over(order by year(check_in_date),  week(check_in_date,0)+1) as prev_week_occupancy
from fact_aggregated_bookings
group by year(check_in_date),  week(check_in_date,0)+1
) as OccupancyData order by year, week;
    
    
-- 23. Week-over-Week Change for ADR
WITH ADR_CTE AS (SELECT extract(week from check_in_date) AS Week_Number,extract(year from check_in_date) AS Year_Number,
SUM(revenue_realized) AS Weekly_Revenue,COUNT(CASE WHEN booking_status = 'Checked out' THEN 1 END) AS Rooms_Sold
FROM fact_bookings GROUP BY extract(week from check_in_date), extract(year from check_in_date))
SELECT Current_Week.Week_Number,Current_Week.Year_Number,
CASE WHEN Previous_Week.Rooms_Sold = 0 THEN NULL  -- Prevent division by zero
ELSE CONCAT(ROUND(((Current_Week.ADR - Previous_Week.ADR) * 100.0 / Previous_Week.ADR),2),'%')
END AS ADR_WoW_Change FROM (SELECT Week_Number,Year_Number,Weekly_Revenue / Rooms_Sold AS ADR,Rooms_Sold
FROM ADR_CTE WHERE Rooms_Sold > 0  -- Ensure that rooms were sold for the week
) Current_Week LEFT JOIN (SELECT Week_Number,Year_Number,Weekly_Revenue / Rooms_Sold AS ADR,Rooms_Sold
FROM ADR_CTE WHERE Rooms_Sold > 0) Previous_Week
ON (Current_Week.Week_Number = Previous_Week.Week_Number + 1
AND Current_Week.Year_Number = Previous_Week.Year_Number);
    
-- option 2
select year, week, average_daily_rate AS current_week_adr, prev_week_adr,
concat(round((((average_daily_rate - prev_week_adr) / prev_week_adr) * 100),2)," %") adr_growth_percentage
FROM (
select year(check_in_date) as year, week(check_in_date)+1 as week, SUM(revenue_realized) / count(booking_id) as average_daily_rate,
lag(sum(revenue_realized) / count(booking_id)) over (order by year(check_in_date), week(check_in_date)+1) as prev_week_adr
from fact_bookings group by year(check_in_date), week(check_in_date)+1) as AdrData
order by year, week;

-- 24.  Week-over-Week Change RevPAR

WITH RevPAR_CTE AS (
    SELECT 
        extract(week from check_in_date) AS Week_Number,
        extract(year from check_in_date) AS Year_Number,
        SUM(revenue_realized) AS Weekly_Revenue,
        COUNT(CASE WHEN booking_status = 'Checked out' THEN 1 END) AS Rooms_Sold,
        COUNT(DISTINCT check_in_date) AS Total_Available_Rooms  -- Total rooms available for booking (distinct days)
    FROM fact_bookings
    GROUP BY extract(week from check_in_date), extract(year from check_in_date)
)
SELECT 
    Current_Week.Week_Number,
    Current_Week.Year_Number,
    CASE 
        WHEN Previous_Week.Total_Available_Rooms = 0 THEN NULL  -- Prevent division by zero
        ELSE CONCAT(ROUND(((Current_Week.RevPAR - Previous_Week.RevPAR) * 100.0 / Previous_Week.RevPAR), 2), '%')
    END AS RevPAR_WoW_Change
FROM (
    SELECT 
        Week_Number,
        Year_Number,
        Weekly_Revenue / Total_Available_Rooms AS RevPAR,
        Total_Available_Rooms
    FROM RevPAR_CTE
    WHERE Total_Available_Rooms > 0  -- Ensure that rooms are available for the week
) Current_Week
LEFT JOIN (
    SELECT 
        Week_Number,
        Year_Number,
        Weekly_Revenue / Total_Available_Rooms AS RevPAR,
        Total_Available_Rooms
    FROM RevPAR_CTE
    WHERE Total_Available_Rooms > 0
) Previous_Week
    ON (Current_Week.Week_Number = Previous_Week.Week_Number + 1
    AND Current_Week.Year_Number = Previous_Week.Year_Number);
    -- option 2
SELECT r.year,r.week,r.total_revenue / c.total_capacity AS Current_week_RevPAR,
LAG(r.total_revenue / c.total_capacity) 
OVER (ORDER BY r.year, r.week) AS prev_week_RevPAR,
CONCAT(ROUND(((r.total_revenue / c.total_capacity - LAG(r.total_revenue / c.total_capacity) OVER (ORDER BY r.year, r.week)) 
      / LAG(r.total_revenue / c.total_capacity) OVER (ORDER BY r.year, r.week)) * 100, 2), " %") AS RevPAR_growth_percentage
FROM (
    select year(check_in_date) AS year,week(check_in_date) + 1 AS week,SUM(revenue_realized) AS total_revenue
    FROM fact_bookings
    GROUP BY year(check_in_date), week(check_in_date) + 1) r
JOIN (
    SELECT year(check_in_date) AS year,week(check_in_date) + 1 AS week,SUM(capacity) AS total_capacity
    FROM fact_aggregated_bookings
    GROUP BY year(check_in_date), week(check_in_date) + 1) c
ON r.year = c.year AND r.week = c.week
ORDER BY r.year, r.week;

-- 25. realisaltion wow%
select year, week ,Current_week_Realisation,Prev_week_Realisation,
    concat(round(((Current_week_Realisation - prev_week_Realisation) /prev_week_Realisation) * 100,2)," %")as Realisation_WoW_percentage
from (
select year(check_in_date) as year, week(check_in_date)+1 as week, 
concat(round((COUNT(case when booking_status = 'checked out' then 1 end)  / (count(booking_id))*100),2),' %')as Current_week_Realisation,
lag(concat(round((count(case when booking_status = 'checked out' then 1 end)  / (count(booking_id))*100),2),' %')) 
over (order by year(check_in_date), week(check_in_date)+1) as prev_week_Realisation
from fact_bookings 
group by year(check_in_date), week(check_in_date)+1) as Realisation_Data
order by year, week;


-- 26 Week-over-Week Change for DSRN
WITH DSRN_CTE AS (
    SELECT 
        extract(week from check_in_date) AS Week_Number,
        extract(year from check_in_date) AS Year_Number,
        COUNT(CASE WHEN booking_status = 'Checked Out' THEN 1 END) AS Rooms_Sold,
        COUNT(DISTINCT check_in_date) AS Total_Available_Rooms  -- Total distinct days
    FROM fact_bookings
    GROUP BY extract(week from check_in_date), extract(year from check_in_date)
)
SELECT 
    Current_Week.Week_Number,
    Current_Week.Year_Number,
    CASE 
        WHEN Previous_Week.Total_Available_Rooms = 0 THEN NULL  -- Prevent division by zero
        ELSE CONCAT(ROUND(((Current_Week.DSRN - Previous_Week.DSRN) * 100.0 / Previous_Week.DSRN), 2), '%')
    END AS DSRN_WoW_Change
FROM (
    SELECT 
        Week_Number,
        Year_Number,
        Rooms_Sold / Total_Available_Rooms AS DSRN,  -- DSRN = Rooms Sold / Available Rooms (per day)
        Total_Available_Rooms
    FROM DSRN_CTE
    WHERE Total_Available_Rooms > 0  -- Ensure that there are available rooms for the week
) Current_Week
LEFT JOIN (
    SELECT 
        Week_Number,
        Year_Number,
        Rooms_Sold / Total_Available_Rooms AS DSRN,  -- DSRN = Rooms Sold / Available Rooms (per day)
        Total_Available_Rooms
    FROM DSRN_CTE
    WHERE Total_Available_Rooms > 0
) Previous_Week
    ON (Current_Week.Week_Number = Previous_Week.Week_Number + 1
    AND Current_Week.Year_Number = Previous_Week.Year_Number);

-- option 2
SELECT current.week_no + 1 as current_week, current.total_dsrn as total_dsrn,
previous.total_dsrn as previous_week_dsrn,
CONCAT(ROUND(((current.total_dsrn - previous.total_dsrn) / previous.total_dsrn) * 100, 2), "%") AS wow_total_dsrn
from 
    (select week(fact_aggregated_bookings.check_in_date) as week_no,
         sum(fact_bookings.revenue_realized)/sum(fact_aggregated_bookings.successful_bookings) as total_dsrn
     from 
         fact_aggregated_bookings inner join fact_bookings
     on fact_bookings.check_in_date = fact_aggregated_bookings.check_in_date
     group by week(fact_aggregated_bookings.check_in_date)) as current
left join (select week(fact_aggregated_bookings.check_in_date) as week_no,
	sum(fact_bookings.revenue_realized)/ sum(fact_aggregated_bookings.successful_bookings) as total_dsrn
     from fact_aggregated_bookings inner join fact_bookings 
     on fact_bookings.check_in_date = fact_aggregated_bookings.check_in_date
     group by week(fact_aggregated_bookings.check_in_date)) as previous
on current.week_no = previous.week_no + 1
order by current.week_no;

# weekend and weekdays wise revenue and booking - 
SELECT dd.day_type AS Day_Type, COUNT(fb.booking_id) AS Total_Bookings,SUM(fb.revenue_generated) AS Total_Revenue
FROM fact_bookings fb
JOIN dim_date dd ON fb.check_in_date = dd.date
WHERE fb.booking_status = 'Checked Out'
GROUP BY dd.day_type;


#Booking Platform analysis info-
select booking_platform, booking_status ,count(booking_status)`No of Booking` ,
sum(revenue_generated)revenue_generated,sum(revenue_realized)revenue_realized from fact_bookings
group by 1,2 order by 1,5 desc;

#class wise count & revenue - 
select dr.room_class as Class,count(booking_id)Count_Booking,sum(fb.revenue_realized) as Revenue
from fact_bookings fb 
join dim_rooms dr on dr.room_id = fb.room_category group by class;



#revenue by city and Hotel - 
select dh.State as State, dh.property_name as Hotel , sum(fb.revenue_realized)Revenue
from fact_bookings fb
join dim_hotels dh on fb.property_id = dh.property_id group by 1,2 order by 1,3 desc;

#-- Platform Wise Revenue -- 
select booking_platform,concat(round(sum(revenue_generated)/10000000,0),' Cr') as revenue from fact_bookings
group by booking_platform 
order by 2 desc;

