/* Flag out for no transaction days
*/
update z
set z.no_trxn_one_day = 1
FROM [dbo].[parkmobile_zone_occupancy] z
inner join
(
SELECT
[zone_name]
,cast([semihour] as date) by_date
--,sum([occu_min]) min_sum
FROM [dbo].[parkmobile_zone_occupancy]
where
cast(semihour as date) >= (select cast(min(start_floor) as date) 
	from [dbo].[transf_parkmobile])
	and
cast(semihour as date) <= (select cast(max(end_ceiling) as date) 
	from [dbo].[transf_parkmobile])
group by
[zone_name]
,cast([semihour] as date)
having(sum([occu_min]) = 0)
) b
	on b.zone_name =  z.zone_name
	and b.by_date = cast(z.semihour as date);

/* Flag out for no transaction weeks
*/
update z
set z.no_trxn_one_week = 1
from [dbo].[parkmobile_zone_occupancy] z
inner join
(
SELECT
[zone_name]
--,[semihour]
,year([semihour]) as yr
,datepart(week, [semihour]) by_week
--,sum([occu_mtr_cnt]) mtr_cnt
from  [dbo].[parkmobile_zone_occupancy]
where
cast(semihour as date) >= (select cast(min(start_floor) as date) 
	from [dbo].[transf_parkmobile])
	and
cast(semihour as date) <= (select cast(max(end_ceiling) as date) 
	from [dbo].[transf_parkmobile])
group by
[zone_name]
,year([semihour])
,datepart(week, [semihour])
having(sum([occu_min]) = 0)
) b
	on b.zone_name = z.zone_name
	and b.yr = year(z.semihour)
	and b.by_week = datepart(week, z.[semihour]);

/* update city_holiday and no_data fields */
UPDATE o  --18842256 rows affected
SET o.city_holiday = c.city_holiday
   ,o.shortnorth_event = c.shortnorth_event
FROM [dbo].[parkmobile_zone_occupancy] o
INNER JOIN [dbo].[ref_calendar_parking] c
on datepart(year,o.semihour) = datepart(year,c.date)
AND datepart(dayofyear,o.semihour) = datepart(dayofyear,c.date);

UPDATE o  --13420704 rows affected
SET o.no_data = 1
FROM [dbo].[parkmobile_zone_occupancy] o
INNER JOIN 
(SELECT * FROM 
	(SELECT year_of_date
	,mon_of_year
	,day_of_mon
	,sum(occu_min) as sum_occu_min
	 FROM 
	(SELECT datepart(year, semihour) year_of_date
			,datepart(month, semihour) mon_of_year
			,datepart(day, semihour) day_of_mon
			,occu_min
			,city_holiday
	 FROM [dbo].[parkmobile_zone_occupancy]
	 where ((DATEPART(dw, semihour) + @@DATEFIRST) % 7) NOT IN (1) ) m
	 group by year_of_date, mon_of_year, day_of_mon) p
	 where sum_occu_min = 0) no_dt
on  datepart(year,o.semihour) = no_dt.year_of_date
AND datepart(month,o.semihour) = no_dt.mon_of_year
AND datepart(day,o.semihour) = no_dt.day_of_mon;

UPDATE o   --5421552 rows affected
SET o.no_data = 0
FROM [dbo].[parkmobile_zone_occupancy] o
where o.no_data is null;

UPDATE o --3081360 rows
SET o.occu_cnt_rate = o.occu_vcnt/(total_cnt*1.0)
	, o.occu_min_rate = o.occu_min/(total_cnt*30.0)
FROM dbo.parkmobile_zone_occupancy o
WHERE o.total_cnt > 0;


UPDATE o   --0 rows
SET o.occu_cnt_rate = NULL
	, o.occu_min_rate = NULL
FROM dbo.parkmobile_zone_occupancy o
WHERE o.total_cnt = NULL or o.total_cnt = 0;


--- QA -----
update o  --45522 rows
set occu_cnt_rate = (case when occu_cnt_rate > 1 then 1 else occu_cnt_rate end),
	 occu_min_rate = (case when occu_min_rate > 1 then 1 else occu_min_rate end)
--select
--(case when occu_cnt_rate > 1 then 1 else occu_cnt_rate end),
--(case when occu_min_rate > 1 then 1 else occu_min_rate end)
from dbo.parkmobile_zone_occupancy o
where occu_cnt_rate > 1 or occu_min_rate > 1;


select * from  dbo.parkmobile_zone_occupancy -- 0 rows
where occu_cnt_rate > 1 or occu_min_rate > 1;

