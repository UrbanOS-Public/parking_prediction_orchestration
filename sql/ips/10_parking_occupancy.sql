drop table [dbo].[parking_occupancy];

CREATE TABLE [dbo].[parking_occupancy](
	[occ_id] [bigint] IDENTITY(1,1) NOT NULL,
	[meter] [varchar](50) NOT NULL,
	[semihour] [datetime] NOT NULL,
	[occu_min] [numeric](5, 2) NOT NULL,
	[occu_flg] [tinyint] NOT NULL,
	[meter_id] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[occ_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY];

ALTER TABLE [dbo].[parking_occupancy] ADD  DEFAULT ((0)) FOR [occu_min];

ALTER TABLE [dbo].[parking_occupancy] ADD  DEFAULT ((0)) FOR [occu_flg];

INSERT INTO [dbo].[parking_occupancy]
           ([meter]
           ,[semihour])
SELECT p.[meter] ,t.[semihour]      
FROM [dbo].[ref_meter] p
cross join [dbo].[ref_semihourly_timetable] t
where meter in (select distinct meter from [dbo].[transf_parking_time])
order by
p.[meter]
,t.semihour; 

-- select top 2000 * from [dbo].[parking_occupancy];

-- semihour = '2019-01-02 12:30:00.000' and zone_name = '31001'

/* Load start_min from all parking records
*/
update o
set o.occu_min = o.occu_min + t.start_min
from [dbo].[parking_occupancy] o
inner join 
(
select
t0.meter
,t0.start_floor
,sum(t0.start_min) as start_min
from [dbo].[transf_parking_time] t0
group by 
t0.meter
,t0.start_floor
) t
	on t.meter = o.meter
	and t.start_floor = o.semihour;

-- select top 2000 * from [dbo].[parking_occupancy] where occu_min > 0;

/* Load end_min from all parking records
*/
update o
set o.occu_min = o.occu_min + t.end_min
from [dbo].[parking_occupancy] o
inner join 
(
select
t0.meter
,t0.end_floor
,sum(t0.end_min) as end_min
from [dbo].[transf_parking_time] t0
where
t0.end_min > 0
group by
t0.meter
,t0.end_floor
) t
	on t.meter = o.meter
	and t.end_floor = o.semihour;

-- select top 2000 * from [dbo].[parking_occupancy] where occu_min > 0;

/* load semihour 30 minutes
*/
BEGIN
	DECLARE @Maxnum_semihr as int
	DECLARE @Lpindx as int
	set @Maxnum_semihr = (select max(semihourly_min_cnt) from [dbo].[transf_parking_time])
	set @Lpindx = 1

	while exists (select 1 from [dbo].[transf_parking_time] where semihourly_min_cnt > 0)
	Begin
		update o
		set o.occu_min = o.occu_min + 30
		from [dbo].[parking_occupancy] o
		inner join [dbo].[transf_parking_time] t
			on t.meter = o.meter
			and dateadd(minute, 30 * (@Lpindx - 1), t.start_ceiling) = o.semihour
		where 
		semihourly_min > 0
		and
		semihourly_min_cnt >= @Lpindx

		set @Lpindx = @Lpindx + 1
		if @Lpindx > @Maxnum_semihr break
		continue
	end

	update [dbo].[parking_occupancy]
	set [occu_flg] = 1  -- 37161207
	where [occu_min] > 0
END;
