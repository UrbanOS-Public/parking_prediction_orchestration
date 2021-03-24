drop table [dbo].[cln_parkmobile];
CREATE TABLE [dbo].[cln_parkmobile](
	[cln_id] [bigint] IDENTITY(1,1) NOT NULL,
	[zone] [varchar](10) NOT NULL,
	[startdate] [datetime] NOT NULL,
	[enddate] [datetime] NOT NULL,
	[stg_id] [bigint] NOT NULL,
 CONSTRAINT [PK_cln_parkmobile] PRIMARY KEY CLUSTERED 
(
	[cln_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY];

INSERT INTO [dbo].[cln_parkmobile]
           ([zone]
           ,[startdate]
           ,[enddate]
           ,[stg_id])
select
[zone]
---- trim seconds to zeros
,dateadd(minute,datediff(minute,0,[parking_start_date]),0) startdate
,dateadd(minute,datediff(minute,0,[parking_end_date]),0) enddate
,[stg_id]
from [dbo].[stgcfm_parkmobile]
where
isdate([parking_start_date]) = 1
and
isdate([parking_end_date]) = 1
and
(
[parking_start_date] is not NULL
or
[parking_end_date] is not NULL
)
and
dateadd(minute,datediff(minute,0,[parking_start_date]),0) < 
	dateadd(minute,datediff(minute,0,[parking_end_date]),0)
and
datediff(minute, [parking_start_date], [parking_end_date]) >= 3
order by
[zone]
,[parking_start_date]
,[parking_end_date];
