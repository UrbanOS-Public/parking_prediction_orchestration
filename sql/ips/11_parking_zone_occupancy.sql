drop table [dbo].[parking_zone_occupancy];

CREATE TABLE [dbo].[parking_zone_occupancy](
	[zocc_id] [bigint] IDENTITY(1,1) NOT NULL,
	[zone_name] [varchar](50) NOT NULL,
	[semihour] [datetime] NOT NULL,
	[occu_min] [numeric](8, 2) NOT NULL,
	[occu_mtr_cnt] [int] NOT NULL,
	[no_trxn_one_day_flg] [smallint] NULL,
	[no_trxn_one_week_flg] [smallint] NULL,
	[load_on] [datetime] NOT NULL,
	[mtr_cnt_month] [int] NULL,
	[mtr_cnt] [int] NULL,
	[occu_min_rate] [numeric](8, 6) NULL,
	[occu_cnt_rate] [numeric](8, 6) NULL,
	[city_holiday] [char](1) NULL,
	[shortnorth_event] [char](1) NULL,
	[no_data] [tinyint] NULL,
 CONSTRAINT [PK__parking___22234AE360863364] PRIMARY KEY CLUSTERED 
(
	[zocc_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY];

ALTER TABLE [dbo].[parking_zone_occupancy] ADD  CONSTRAINT [DF__parking_z__occu___0880433F]  DEFAULT ((0)) FOR [occu_min];

ALTER TABLE [dbo].[parking_zone_occupancy] ADD  CONSTRAINT [DF__parking_z__occu___09746778]  DEFAULT ((0)) FOR [occu_mtr_cnt];

ALTER TABLE [dbo].[parking_zone_occupancy] ADD  CONSTRAINT [DF__parking_z__no_tr__0A688BB1]  DEFAULT ((0)) FOR [no_trxn_one_day_flg];

ALTER TABLE [dbo].[parking_zone_occupancy] ADD  CONSTRAINT [DF__parking_z__no_tr__0B5CAFEA]  DEFAULT ((0)) FOR [no_trxn_one_week_flg];

INSERT INTO [dbo].[parking_zone_occupancy]
           ([zone_name]
           ,[semihour]
           ,[occu_min]
           ,[occu_mtr_cnt]
           ,[load_on])
SELECT
z.zone_name
,o.[semihour]
,sum(o.occu_min) occu_min
,sum(o.occu_flg) occu_mtr_cnt
,cast(getdate() as datetime) load_on
from [dbo].[parking_occupancy] o
inner join [dbo].[ref_meter] m
	on m.meter = o.meter
inner join [dbo].[ref_zone] z
	on z.zone_name = m.zone_name
where
z.zone_eff_flg = 1
group by
z.zone_name
,o.[semihour]
order by
z.zone_name
,o.[semihour];

/* Flag out for no transaction days
*/
update z
set z.no_trxn_one_day_flg = 1
from [dbo].[parking_zone_occupancy] z
inner join
(
SELECT 
[zone_name]
,cast([semihour] as date) by_date
--,sum([occu_mtr_cnt]) mtr_cnt
FROM [dbo].[parking_zone_occupancy]
group by
[zone_name]
,cast([semihour] as date)
having(sum([occu_mtr_cnt]) = 0)
) b
	on b.zone_name =  z.zone_name
	and b.by_date = cast(z.semihour as date);

/* Flag out for no transaction weeks
*/
update z
set z.no_trxn_one_week_flg = 1
from [dbo].[parking_zone_occupancy] z
inner join
(
SELECT 
[zone_name]
,year([semihour]) yr
,datepart(week, [semihour]) by_week
--,sum([occu_mtr_cnt]) mtr_cnt
FROM [dbo].[parking_zone_occupancy]
group by
[zone_name]
,year([semihour])
,datepart(week, [semihour])
having(sum([occu_mtr_cnt]) = 0)
) b
	on b.zone_name = z.zone_name
	and b.yr = year(z.semihour)
	and b.by_week = datepart(week, z.[semihour]);

/* update city_holiday and no_data fields */
UPDATE o  --11481888 rows affected
SET o.city_holiday = c.city_holiday
   ,o.shortnorth_event = c.shortnorth_event
FROM [dbo].[parking_zone_occupancy] o
INNER JOIN [dbo].[ref_calendar_parking] c
on datepart(year,o.semihour) = datepart(year,c.date)
AND datepart(dayofyear,o.semihour) = datepart(dayofyear,c.date);

/* no_data = 1 when there is not any transaction records on that day and it is not Sunday */
UPDATE o  --308112 rows affected
SET o.no_data = 1
FROM [dbo].[parking_zone_occupancy] o
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
	FROM [dbo].[parking_zone_occupancy]
	where ((DATEPART(dw, semihour) + @@DATEFIRST) % 7) NOT IN (1) ) m
	group by year_of_date, mon_of_year, day_of_mon ) p
where sum_occu_min = 0 ) no_dt
on  datepart(year,o.semihour) = no_dt.year_of_date
AND datepart(month,o.semihour) = no_dt.mon_of_year
AND datepart(day,o.semihour) = no_dt.day_of_mon;

UPDATE o   --11173776 rows affected
SET o.no_data = 0
FROM [dbo].[parking_zone_occupancy] o
where o.no_data is null;