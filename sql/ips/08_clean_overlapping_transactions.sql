drop table [dbo].[clean_overlapping_set];

CREATE TABLE [dbo].[clean_overlapping_set](
	[cmp_id] [bigint] NOT NULL,
	[meter] [varchar](50) NOT NULL,
	[startdate] [datetime] NOT NULL,
	[enddate] [datetime] NOT NULL,
	[cln_id] [bigint] NOT NULL,
	[trxn_id] [bigint] NOT NULL,
 CONSTRAINT [PK__clean_ovl__181977ED929001] PRIMARY KEY CLUSTERED 
(
	[cmp_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY];

INSERT INTO [dbo].[clean_overlapping_set]
           ([cmp_id]
           ,[meter]
           ,[startdate]
           ,[enddate]
		   ,[cln_id]
           ,[trxn_id])
SELECT distinct
t.cmp_id - 1  -- matching id to remove overlapped records
,t.meter
,t.startdate
,t.enddate
,t.[cln_id]
,t.trxn_id
FROM [dbo].[clean_compressed] t
inner join [dbo].[clean_compressed_bk] b
	on b.meter = t.meter
where
b.cmp_id < t.cmp_id
and
t.startdate < b.enddate
and
t.enddate > b.enddate;

update t
set t.enddate = o.startdate 
from [dbo].[clean_compressed] t
inner join [dbo].[clean_overlapping_set] o
	on t.cmp_id = o.cmp_id
where
t.enddate > o.startdate;
