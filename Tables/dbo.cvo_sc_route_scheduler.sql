CREATE TABLE [dbo].[cvo_sc_route_scheduler]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[prospect_id] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[territory] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sched_date] [datetime] NULL,
[isActive] [tinyint] NULL CONSTRAINT [DF__cvo_sc_ro__isAct__0AFB5424] DEFAULT ((1)),
[notes] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_sc_route_scheduler] ADD CONSTRAINT [PK__cvo_sc_route_sch__0A072FEB] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
