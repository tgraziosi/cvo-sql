CREATE TABLE [dbo].[cvo_daily_cycle_count_activity]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[cycle_id] [int] NULL,
[location] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group_code] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bin_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[item_count] [int] NULL,
[activity_user] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[activity_date] [datetime] NULL,
[part_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_daily_cycle_count_activity] ADD CONSTRAINT [PK__cvo_daily_cycle___561CAC3A] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
