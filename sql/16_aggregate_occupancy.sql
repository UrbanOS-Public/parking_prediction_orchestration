drop table [dbo].[parking_zone_occupancy_aggr];
CREATE TABLE [dbo].[parking_zone_occupancy_aggr](
	[zocc_id] [bigint] IDENTITY(1,1) NOT NULL,
	[zone_name] [varchar](50) NOT NULL,
	[semihour] [datetime] NOT NULL,
	[occu_min] [numeric](8, 2) NOT NULL,
	[occu_mtr_cnt] [int] NOT NULL,
	[no_trxn_one_day_flg] [smallint] NULL,
	[no_trxn_one_week_flg] [smallint] NULL,
	[load_on] [datetime] NOT NULL,
	[total_cnt] [int] NULL,
	[occu_min_rate] [numeric](8, 6) NULL,
	[occu_cnt_rate] [numeric](8, 6) NULL,
	[city_holiday] [char](1) NULL,
	[shortnorth_event] [char](1) NULL,
	[no_data] [tinyint] NULL,
 CONSTRAINT [PK__parking___22234ALE360863364] PRIMARY KEY CLUSTERED 
(
	[zocc_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY];
ALTER TABLE [dbo].[parking_zone_occupancy_aggr] ADD  CONSTRAINT [DF__parking_za__occu___0880433F]  DEFAULT ((0)) FOR [occu_min];
ALTER TABLE [dbo].[parking_zone_occupancy_aggr] ADD  CONSTRAINT [DF__parking_za__occu___09746778]  DEFAULT ((0)) FOR [occu_mtr_cnt];
ALTER TABLE [dbo].[parking_zone_occupancy_aggr] ADD  CONSTRAINT [DF__parking_za__no_tr__0A688BB1]  DEFAULT ((0)) FOR [no_trxn_one_day_flg];
ALTER TABLE [dbo].[parking_zone_occupancy_aggr] ADD  CONSTRAINT [DF__parking_za__no_tr__0B5CAFEA]  DEFAULT ((0)) FOR [no_trxn_one_week_flg];

/* insert records of zone occupancy from ips */
INSERT INTO [dbo].[parking_zone_occupancy_aggr] --7888320 rows
           ([zone_name]
           ,[semihour]
           ,[occu_min]
           ,[occu_mtr_cnt]
           ,[no_trxn_one_day_flg]
           ,[no_trxn_one_week_flg]
           ,[load_on]
           ,[total_cnt]
           ,[occu_min_rate]
           ,[occu_cnt_rate]
           ,[city_holiday]
           ,[shortnorth_event]
           ,[no_data])
SELECT o.[zone_name]
      ,[semihour]
      ,[occu_min]
      ,[occu_mtr_cnt]
      ,[no_trxn_one_day_flg]
      ,[no_trxn_one_week_flg]
      ,cast(getdate() as datetime) load_on
      ,[mtr_cnt_month]
      ,[occu_min_rate]
      ,[occu_cnt_rate]
      ,[city_holiday]
      ,[shortnorth_event]
      ,[no_data]
FROM [dbo].[parking_zone_occupancy] o
inner join ref_zone z
on o.zone_name = z.zone_name
and z.zone_eff_flg = 1 and z.pred_eff_flg = 1
order by zocc_id;

/* insert records of zone occupancy from park mobile only */
INSERT INTO [dbo].[parking_zone_occupancy_aggr] --823440 rows
           ([zone_name]
           ,[semihour]
           ,[occu_min]
           ,[occu_mtr_cnt]
           ,[no_trxn_one_day_flg]
           ,[no_trxn_one_week_flg]
           ,[load_on]
           ,[total_cnt]
           ,[occu_min_rate]
           ,[occu_cnt_rate]
           ,[city_holiday]
           ,[shortnorth_event]
           ,[no_data])
SELECT o.[zone_name]
      ,[semihour]
      ,[occu_min]
      ,[occu_vcnt]
      ,[no_trxn_one_day]
      ,[no_trxn_one_week]
	  ,cast(getdate() as datetime) load_on
      ,o.[total_cnt]
      ,[occu_min_rate]
      ,[occu_cnt_rate]
      ,[city_holiday]
      ,[shortnorth_event]
      ,[no_data]
  FROM [dbo].[parkmobile_zone_occupancy] o
  inner join ref_zone z
  on o.zone_name = z.zone_name
  and z.zone_eff_flg = 1 and z.pred_eff_flg = 1 and z.pm_only = 1
  order by occ_id;


/* update from parkmobile_zone_occupancy with pm_only = 0 */
update a  --312117 rows
set
	[occu_min] = a.[occu_min] + pmo.[occu_min]
   ,[occu_mtr_cnt] = a.[occu_mtr_cnt] + pmo.[occu_vcnt]
   ,[no_trxn_one_day_flg] = (case when (a.no_trxn_one_day_flg = 1 and pmo.no_trxn_one_day = 0)
							then 0 else a.no_trxn_one_day_flg end)
   ,[no_trxn_one_week_flg] = (case when (a.no_trxn_one_week_flg = 1 and pmo.no_trxn_one_week = 0)
							then 0 else a.no_trxn_one_week_flg end)
   ,[total_cnt] = (case when a.total_cnt = pmo.total_cnt then pmo.total_cnt else -1 end)
   ,[no_data] = (case when a.no_data > pmo.no_data then pmo.no_data else a.no_data end)
from [dbo].[parking_zone_occupancy_aggr] a
inner join
(
SELECT o.[zone_name]
      ,[semihour]
      ,[occu_min]
      ,[occu_vcnt]
      ,[no_trxn_one_day]
      ,[no_trxn_one_week]
      ,o.[total_cnt]
      ,[occu_min_rate]
      ,[occu_cnt_rate]
      ,[no_data]
  FROM [dbo].[parkmobile_zone_occupancy] o
  inner join ref_zone z
  on o.zone_name = z.zone_name
  and z.zone_eff_flg = 1 and z.pred_eff_flg = 1 and z.pm_only = 0
  and occu_vcnt > 0
  ) pmo
  on a.zone_name = pmo.zone_name
  and a.semihour = pmo.semihour;

BEGIN
      DECLARE @yearidx as int
      DECLARE @maxyear as int

      set @maxyear = 2020
      set @yearidx = 2015
      BEGIN
      while (@yearidx <= @maxyear)
      begin
            /* update total_cnt when meter number info not available for that month */
            update aggr    --1446 rows
            set [total_cnt] = o_ref.total_cnt
            from [dbo].[parking_zone_occupancy_aggr] aggr
            inner join
                  (
                  select a.[zone_name]
                              ,month(a.semihour) mon
                              ,max(a.[occu_mtr_cnt]) total_cnt
                  FROM [dbo].[parking_zone_occupancy_aggr] a
                  inner join
                  (
                  SELECT [zone_name]
                        ,month(semihour) as mon
                  FROM [dbo].[parking_zone_occupancy_aggr]
                  where total_cnt = -1
                  group by zone_name, month(semihour)
                  ) o
                  on a.zone_name = o.zone_name
                  and year(a.semihour) = @yearidx
                  and month(a.semihour) =  mon
                  group by a.zone_name, month(a.semihour) ) o_ref
            on aggr.zone_name = o_ref.zone_name
            and month(aggr.semihour) = o_ref.mon
            and aggr.total_cnt = -1

            set @yearidx = @yearidx + 1
      END
      END
END;

---update occu_min_rate , occu_cnt_rate
UPDATE o   --7906806
SET 
	o.occu_cnt_rate = o.occu_mtr_cnt/(total_cnt*1.0)
	,o.occu_min_rate = o.occu_min/(total_cnt*30.0)
FROM [dbo].[parking_zone_occupancy_aggr] o
WHERE o.total_cnt > 0;

UPDATE o   --759834 rows 
SET 
	o.occu_cnt_rate = 0.0
	,o.occu_min_rate = 0.0
FROM [dbo].[parking_zone_occupancy_aggr] o
WHERE o.total_cnt = 0;

--adjust the rate to 1 if the it is greater than 1 after aggregated from the two
update o  --129597 rows
set occu_cnt_rate = (case when occu_cnt_rate > 1 then 1 else occu_cnt_rate end),
	 occu_min_rate = (case when occu_min_rate > 1 then 1 else occu_min_rate end)
from [dbo].[parking_zone_occupancy_aggr] o
where occu_cnt_rate > 1 or occu_min_rate > 1;
