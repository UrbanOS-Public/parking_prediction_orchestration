drop table [dbo].[clean_compressed];

CREATE TABLE [dbo].[clean_compressed](
	[cmp_id] [bigint] IDENTITY(1,1) NOT NULL,
	[meter] [varchar](50) NOT NULL,
	[startdate] [datetime] NOT NULL,
	[enddate] [datetime] NOT NULL,
	[cln_id] [bigint] NOT NULL,
	[trxn_id] [bigint] NOT NULL,
 CONSTRAINT [PK__clean_cmp__1819BE77ED929001] PRIMARY KEY CLUSTERED 
(
	[cmp_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY];

insert into [dbo].[clean_compressed] (meter, startdate, enddate, cln_id, trxn_id)
select meter, startdate, enddate, cln_id, trxn_id from [dbo].[clean_second_null_dup_sub];

drop table [dbo].[clean_compressed_bk];
select * into [dbo].[clean_compressed_bk] from [dbo].[clean_compressed]; -- This is used in the next step