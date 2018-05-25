CREATE TABLE [dbo].[cvo_svc_filters]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[invite_id] [int] NULL,
[filter_name] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[filter_value] [varchar] (256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_svc_filters] ADD CONSTRAINT [PK__cvo_svc_filters__71A4CB1E] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_svc_filters] ADD CONSTRAINT [fk_filter_invite_id] FOREIGN KEY ([invite_id]) REFERENCES [dbo].[cvo_svc_invites] ([id])
GO
