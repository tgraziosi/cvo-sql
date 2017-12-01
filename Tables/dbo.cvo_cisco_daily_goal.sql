CREATE TABLE [dbo].[cvo_cisco_daily_goal]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[pr_date] [datetime] NULL,
[goal_no] [int] NULL,
[goal_agent] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[goal_agent_ext] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[goal_time] [datetime] NULL,
[goal_highlight] [tinyint] NULL CONSTRAINT [DF__cvo_cisco__goal___38C1537D] DEFAULT ((0))
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_cisco_daily_goal] ADD CONSTRAINT [PK__cvo_cisco_daily___37CD2F44] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
