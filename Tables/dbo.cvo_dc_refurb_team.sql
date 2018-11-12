CREATE TABLE [dbo].[cvo_dc_refurb_team]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[user_login] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fname] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lname] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[added_date] [datetime] NULL CONSTRAINT [DF__cvo_dc_re__added__18F46DC0] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_dc_refurb_team] ADD CONSTRAINT [PK__cvo_dc_refurb_te__18004987] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
