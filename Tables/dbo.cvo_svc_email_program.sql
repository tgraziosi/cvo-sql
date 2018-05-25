CREATE TABLE [dbo].[cvo_svc_email_program]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[invite_id] [int] NOT NULL,
[program_id] [int] NOT NULL,
[show_min_qty] [int] NOT NULL,
[order_min_qty] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_svc_email_program] ADD CONSTRAINT [PK__cvo_svc_email_pr__5F861AE3] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_svc_email_program] ADD CONSTRAINT [fk_invite_id] FOREIGN KEY ([invite_id]) REFERENCES [dbo].[cvo_svc_invites] ([id])
GO
ALTER TABLE [dbo].[cvo_svc_email_program] ADD CONSTRAINT [fk_program_id] FOREIGN KEY ([program_id]) REFERENCES [dbo].[cvo_svc_programs] ([program_id])
GO
