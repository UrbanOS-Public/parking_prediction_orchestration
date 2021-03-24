drop table [dbo].[stg_ips_group_parking_meter_inventory_2020];
CREATE TABLE [dbo].[stg_ips_group_parking_meter_inventory_2020](
	[active] [varchar](250) NULL,
	[areaname] [varchar](250) NULL,
	[configid] [varchar](250) NULL,
	[lat] [varchar](250) NULL,
	[long] [varchar](250) NULL,
	[meter_number] [varchar](250) NULL,
	[subareaname] [varchar](250) NULL,
	[zonename] [varchar](250) NULL
) ON [PRIMARY];

drop table [dbo].[stg_parking_tranxn_source];
CREATE TABLE [dbo].[stg_parking_tranxn_source](
	[endtime] [varchar](250) NULL,
	[meterid] [varchar](250) NULL,
	[starttime] [varchar](250) NULL);

drop table [dbo].[stg_parkmobile];
CREATE TABLE [dbo].[stg_parkmobile](
	[parking_end_date] [varchar](250) NULL,
	[parking_start_date] [varchar](250) NULL,
	[zone] [varchar](250) NULL);