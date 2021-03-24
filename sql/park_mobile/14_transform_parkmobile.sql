drop table [dbo].[transf_parkmobile];
CREATE TABLE [dbo].[transf_parkmobile](
	[transf_id] [bigint] IDENTITY(1,1) NOT NULL,
	[zone] [varchar](10) NOT NULL,
	[startdate] [datetime] NOT NULL,
	[start_floor] [datetime] NOT NULL,
	[start_ceiling] [datetime] NOT NULL,
	[enddate] [datetime] NOT NULL,
	[end_floor] [datetime] NOT NULL,
	[end_ceiling] [datetime] NOT NULL,
	[total_parking_min] [int] NOT NULL,
	[start_min] [int] NOT NULL,
	[end_min] [int] NOT NULL,
	[semihourly_min] [int] NOT NULL,
	[semihourly_min_cnt] [int] NOT NULL,
	[cln_id] [bigint] NOT NULL,
	[stg_id] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[transf_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY];

INSERT INTO [dbo].[transf_parkmobile]
           ([zone]
           ,[startdate]
           ,[start_floor]
           ,[start_ceiling]
           ,[enddate]
           ,[end_floor]
           ,[end_ceiling]
           ,[total_parking_min]
           ,[start_min]
           ,[end_min]
           ,[semihourly_min]
           ,[semihourly_min_cnt]
           ,[cln_id]
           ,[stg_id])
SELECT  -- TOP (10000) 
[zone]
,[startdate]
,dateadd(minute,(datediff(minute,0,[startdate])/30)*30, 0) start_floor
,dateadd(minute,(datediff(minute,0,[startdate])/30)*30 + 30, 0) start_ceiling
,[enddate]
,dateadd(minute,(datediff(minute,0,[enddate])/30)*30, 0) end_floor
,dateadd(minute,(datediff(minute,0,[enddate])/30)*30 + 30, 0) end_ceiling
,datediff([MINUTE], startdate, [enddate]) total_parking_min
,case
	-- enddate > start_ceiling
	when [enddate] > dateadd(minute,(datediff(minute,0,[startdate])/30)*30 + 30, 0) 
	then 
		datediff([MINUTE], startdate, dateadd(minute,(datediff(minute,0,[startdate])/30)*30 + 30, 0)) 
	else -- enddate <= start_ceiling
		datediff([MINUTE], startdate, [enddate])
	end start_min -- parking time in the first 30 minutes semihourly
,case  -- enddate > start_ceiling
	when enddate > dateadd(minute,(datediff(minute,0,[startdate])/30)*30 + 30, 0)
	then datediff([MINUTE], dateadd(minute,(datediff(minute,0,[enddate])/30)*30, 0), [enddate]) 
	else 0  -- enddate <= start_ceiling
	end end_min -- parking time in the last 30 minutes semihourly
,case -- enddate > start_ceiling
	when enddate > dateadd(minute,(datediff(minute,0,[startdate])/30)*30 + 30, 0)
	then datediff([MINUTE], dateadd(minute,(datediff(minute,0,[startdate])/30)*30 + 30, 0), 
		dateadd(minute,(datediff(minute,0,[enddate])/30)*30, 0)) 
	else 0
	end semihourly_min -- total parking time semihourly only
,case -- enddate > start_ceiling
	when enddate > dateadd(minute,(datediff(minute,0,[startdate])/30)*30 + 30, 0)
	then datediff([MINUTE], dateadd(minute,(datediff(minute,0,[startdate])/30)*30 + 30, 0), 
		dateadd(minute,(datediff(minute,0,[enddate])/30)*30, 0)) / 30
	else 0
	end semihourly_min_cnt  -- count of 30 minutes in the total parking time semihourly only
,[cln_id]
,[stg_id]
FROM [dbo].[cln_parkmobile]
order by [cln_id];

drop table [dbo].[parkmobile_zone_occupancy];
CREATE TABLE [dbo].[parkmobile_zone_occupancy](
	[occ_id] [bigint] IDENTITY(1,1) NOT NULL,
	[zone_name] [varchar](50) NOT NULL,
	[semihour] [datetime] NOT NULL,
	[occu_min] [int] NOT NULL,
	[occu_vcnt] [int] NOT NULL,
	[no_trxn_one_day] [smallint] NULL,
	[no_trxn_one_week] [smallint] NULL,
	[total_cnt] [int] NULL,
	[occu_min_rate] [numeric](8, 6) NULL,
	[occu_cnt_rate] [numeric](8, 6) NULL,
	[city_holiday] [char](1) NULL,
	[shortnorth_event] [char](1) NULL,
	[no_data] [tinyint] NULL,
 CONSTRAINT [PK__parking___22234AE360863367] PRIMARY KEY CLUSTERED 
(
	[occ_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY];

ALTER TABLE [dbo].[parkmobile_zone_occupancy] ADD  DEFAULT ((0)) FOR [occu_min];

ALTER TABLE [dbo].[parkmobile_zone_occupancy] ADD  DEFAULT ((0)) FOR [occu_vcnt];

ALTER TABLE [dbo].[parkmobile_zone_occupancy] ADD  CONSTRAINT [DF_parkmobile_zone_occupancy_no_trxn_one_day]  DEFAULT ((0)) FOR [no_trxn_one_day];

ALTER TABLE [dbo].[parkmobile_zone_occupancy] ADD  CONSTRAINT [DF_parkmobile_zone_occupancy_no_trxn_one_week]  DEFAULT ((0)) FOR [no_trxn_one_week];

INSERT INTO [dbo].[parkmobile_zone_occupancy]
           ([zone_name]
           ,[semihour])
SELECT
 z.[zone_name]
,t.[semihour]
FROM [dbo].[ref_zone] z
cross join [dbo].[ref_semihourly_timetable] t
where z.zone_eff_flg = 1
order by
z.[zone_name]
,t.semihour;

/* Load start_min from all parking records
*/
update o
set o.occu_min = o.occu_min + t.start_min
	,o.[occu_vcnt] = o.[occu_vcnt] + t.occu_vcnt
from [dbo].[parkmobile_zone_occupancy] o
inner join 
(
select
zone
,start_floor
,sum(start_min) as start_min
,count(transf_id) as occu_vcnt
from [dbo].[transf_parkmobile]
group by 
zone
,start_floor
) t
	on t.zone = o.zone_name
	and t.start_floor = o.semihour;

/* Load end_min from all parking records
*/
update o
set o.occu_min = o.occu_min + t.end_min
	,o.[occu_vcnt] = o.[occu_vcnt] + t.occu_vcnt
from [dbo].[parkmobile_zone_occupancy] o
inner join 
(
select
zone
,end_floor
,sum(end_min) as end_min
,count(transf_id) as occu_vcnt
from [dbo].[transf_parkmobile]
where
end_min > 0
group by 
zone
,end_floor
) t
	on t.zone = o.zone_name
	and t.end_floor = o.semihour;

BEGIN
/* load semihour 30 minutes
*/
DECLARE @Maxnum_semihr as int
DECLARE @Lpindx as int

set @Maxnum_semihr = (select max(semihourly_min_cnt) from [dbo].[transf_parkmobile])
set @Lpindx = 1

while exists (select 1 from [dbo].[transf_parkmobile]  where semihourly_min_cnt > 0)
begin
	
	update o
	set o.occu_min = o.occu_min + t.semihour_min
		,o.occu_vcnt = o.occu_vcnt + t.semihour_vcnt
	from [dbo].[parkmobile_zone_occupancy] o
	inner join 
	(
	select --top 100
	zone
	,dateadd(minute, 30 * (@Lpindx - 1), start_ceiling) as start_ceiling
	,30 * count(transf_id) as semihour_min
	,count(transf_id) as semihour_vcnt
	from [dbo].[transf_parkmobile] 
	where 
	semihourly_min > 0
	and
	semihourly_min_cnt >= @Lpindx
	group by
	zone
	,dateadd(minute, 30 * (@Lpindx - 1), start_ceiling)
	) t
		on t.zone = o.zone_name
		and t.start_ceiling = o.semihour

	set @Lpindx = @Lpindx + 1
	if @Lpindx > @Maxnum_semihr break
	continue
end
END;