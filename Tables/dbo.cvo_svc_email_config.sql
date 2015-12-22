CREATE TABLE [dbo].[cvo_svc_email_config]
(
[id] [smallint] NOT NULL IDENTITY(1, 1),
[territory] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sv_email] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qop_email] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[eor_email] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[suns_email] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[closeout_email] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_svc_email_config] ADD CONSTRAINT [PK__cvo_svc_email_co__5D338C53] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
