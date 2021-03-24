drop table [dbo].[stgcfm_parkmobile];
CREATE TABLE [dbo].[stgcfm_parkmobile](
	[stg_id] [bigint] IDENTITY(1,1) NOT NULL,
	[parking_start_date] [datetime] NOT NULL,
	[parking_end_date] [datetime] NOT NULL,
	[zone] [varchar](10) NOT NULL,
 CONSTRAINT [PK_stgcfm_parkmobile] PRIMARY KEY CLUSTERED 
(
	[stg_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY];

INSERT INTO [dbo].[stgcfm_parkmobile]
           ([parking_start_date]
           ,[parking_end_date]
           ,[zone])
SELECT cast(trim([parking_start_date]) as datetime)
      ,cast(trim([parking_end_date]) as datetime)
      ,trim([zone])
  FROM [dbo].[stg_parkmobile]
  order by
  trim([zone])
  ,cast(trim([parking_start_date]) as datetime);

