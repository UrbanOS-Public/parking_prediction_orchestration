drop table [dbo].[ref_meter];
CREATE TABLE [dbo].[ref_meter](
	[meter] [varchar](50) NOT NULL,
	[zone_name] [int] NULL);

drop table [dbo].[ref_zone];
CREATE TABLE [dbo].[ref_zone](
	[pm_only] [smallint] NULL,
	[pred_eff_flg] [smallint] NULL,
	[total_cnt] [int] NULL,
	[zone_eff_flg] [smallint] NULL,
	[zone_name] [varchar](50) NOT NULL)

drop table [dbo].[ref_semihourly_timetable];
CREATE TABLE [dbo].[ref_semihourly_timetable](
	[time_id] [bigint] IDENTITY(1,1) NOT NULL,
	[semihour] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[time_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY];

drop table [dbo].[ref_calendar_parking];
CREATE TABLE [dbo].[ref_calendar_parking](
	[calendarid] [int] NOT NULL,
	[date] [date] NOT NULL,
	[weekday] [varchar](50) NOT NULL,
	[month] [varchar](50) NOT NULL,
	[city_holiday] [char](1) NULL,
	[shortnorth_event] [char](1) NULL,
 CONSTRAINT [PK_calendar_parking] PRIMARY KEY CLUSTERED 
(
	[calendarid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY];