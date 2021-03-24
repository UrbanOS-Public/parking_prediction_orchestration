drop table [dbo].[clean_second_null_dup_sub_bk];

CREATE TABLE [dbo].[clean_second_null_dup_sub_bk](
	[cln_id] [bigint] NOT NULL,
	[meter] [varchar](50) NOT NULL,
	[startdate] [datetime] NOT NULL,
	[enddate] [datetime] NOT NULL,
	[trxn_id] [bigint] NOT NULL,
 CONSTRAINT [PK__clean_se__1819BK77ED928996] PRIMARY KEY CLUSTERED 
(
	[cln_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY];

insert into [dbo].[clean_second_null_dup_sub_bk] select * from [dbo].[clean_second_null_dup_sub];

delete t
from [dbo].[clean_second_null_dup_sub] t
inner join [dbo].[clean_second_null_dup_sub_bk] b
	on t.meter = b.meter
where
b.startdate < t.startdate 
and
t.enddate <= b.enddate;
