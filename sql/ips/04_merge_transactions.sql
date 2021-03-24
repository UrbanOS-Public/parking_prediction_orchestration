drop table [dbo].[stg_parking_tranxn];

CREATE TABLE [dbo].[stg_parking_tranxn](
	[trxn_id] [bigint] IDENTITY(1,1) NOT NULL,
	[parkingenddate] [varchar](250) NULL,
	[parkingstartdate] [varchar](250) NULL,
	[pole] [varchar](250) NULL
 CONSTRAINT [PK__stg_park__89223392DCCFBFB0] PRIMARY KEY CLUSTERED 
(
	[trxn_id] ASC
) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY];

insert into [dbo].[stg_parking_tranxn] (parkingenddate, parkingstartdate, pole)
SELECT endtime, starttime, meterid from [dbo].[stg_parking_tranxn_source];