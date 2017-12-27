CREATE TABLE [dbo].[cvo_daily_cycle_count]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[part_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cc_date] [datetime] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_daily_cycle_count] ADD CONSTRAINT [PK__cvo_daily_cycle___543463C8] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
