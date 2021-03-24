drop table [dbo].[transf_parking_time];

CREATE TABLE [dbo].[transf_parking_time](
	[transf_id] [bigint] IDENTITY(1,1) NOT NULL,
	[meter] [varchar](50) NOT NULL,
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
	[cmp_id] [bigint] NOT NULL,
	[cln_id] [bigint] NOT NULL,
	[trxn_id] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[transf_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY];

INSERT INTO [dbo].[transf_parking_time]
           ([meter]
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
           ,[cmp_id]
           ,[cln_id]
           ,[trxn_id])		   
SELECT
[meter]
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
,[cmp_id]
,[cln_id]
,[trxn_id]
FROM [dbo].[clean_compressed]
order by
[cmp_id];
