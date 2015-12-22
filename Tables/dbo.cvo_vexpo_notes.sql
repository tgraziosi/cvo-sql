CREATE TABLE [dbo].[cvo_vexpo_notes]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[appt_id] [int] NULL,
[isAttended] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[short_note] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[notes] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[followup_required] [smallint] NULL CONSTRAINT [DF__cvo_vexpo__follo__0F5B20BA] DEFAULT ((0)),
[action_notes] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[reschedule_date] [datetime] NULL,
[customer_option] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[added_date] [datetime] NULL CONSTRAINT [DF__cvo_vexpo__added__104F44F3] DEFAULT (getdate())
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_vexpo_notes] ADD CONSTRAINT [PK__cvo_vexpo_notes__0E66FC81] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
