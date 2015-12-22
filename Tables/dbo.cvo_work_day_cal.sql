CREATE TABLE [dbo].[cvo_work_day_cal]
(
[workday] [smalldatetime] NOT NULL,
[date_type] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_work_day_cal] ADD CONSTRAINT [PK_cvo_work_day_cal_new] PRIMARY KEY CLUSTERED  ([workday], [date_type]) ON [PRIMARY]
GO
