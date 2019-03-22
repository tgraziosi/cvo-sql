CREATE TABLE [dbo].[cvo_invitation_programs]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[prog_key] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[prog_name] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[added_date] [datetime] NULL CONSTRAINT [DF__cvo_invit__added__797BC267] DEFAULT (getdate()),
[isActive] [tinyint] NULL CONSTRAINT [DF__cvo_invit__isAct__7A6FE6A0] DEFAULT ((1))
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_invitation_programs] ADD CONSTRAINT [PK__cvo_invitation_p__78879E2E] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
