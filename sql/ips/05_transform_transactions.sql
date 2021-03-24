drop table [dbo].[clean_second_null_dup_sub];

CREATE TABLE [dbo].[clean_second_null_dup_sub](
	[cln_id] [bigint] IDENTITY(1,1) NOT NULL,
	[meter] [varchar](50) NOT NULL,
	[startdate] [datetime] NOT NULL,
	[enddate] [datetime] NOT NULL,
	[trxn_id] [bigint] NOT NULL,
 CONSTRAINT [PK__clean_se__1819BE77ED928996] PRIMARY KEY CLUSTERED 
(
	[cln_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY];

INSERT INTO [dbo].[clean_second_null_dup_sub]
           ([meter]
           ,[startdate]
           ,[enddate]
	       ,[trxn_id])
select
[pole] as meter
,[startdate]
,[enddate]
,[trxn_id]
from
(
SELECT
[trxn_id]
,[pole]
,startdate
,enddate
,RANK() OVER(PARTITION BY [pole], [startdate] ORDER BY [enddate] desc, [trxn_id]) rk
FROM 
(
SELECT 
[trxn_id]
,[pole]
-- trim seconds to zeros
,dateadd(minute,datediff(minute,0,[parkingstartdate]),0) startdate
,dateadd(minute,datediff(minute,0,[parkingenddate]),0) enddate
FROM [dbo].[stg_parking_tranxn]
where
isdate([parkingstartdate]) = 1
and
isdate([parkingenddate]) = 1
and
len(trim([parkingenddate])) = 23
and
len(trim([pole])) > 1
and
(
pole is not NULL
or
[parkingstartdate] is not NULL
or
[parkingenddate] is not NULL
)
and
dateadd(minute,datediff(minute,0,[parkingstartdate]),0) < 
	dateadd(minute,datediff(minute,0,[parkingenddate]),0)
) src
where
datediff(minute, startdate, enddate) >= 3
and
datediff(minute, startdate, enddate) <= 720
) rkd
where
rk = 1
order by
[pole]
,[startdate]
,[enddate];

