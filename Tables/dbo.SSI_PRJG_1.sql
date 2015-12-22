CREATE TABLE [dbo].[SSI_PRJG_1]
(
[SESSIONID] [int] NOT NULL,
[GROUPID] [int] NOT NULL,
[SESSTIMESTAMP] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[FOREDESC] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AUTHOR] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TAG] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SESSNOTE] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[SSI_PRJG_1] ADD CONSTRAINT [FK__SSI_PRJG___GROUP__6228EF53] FOREIGN KEY ([GROUPID]) REFERENCES [dbo].[SSI_GRP_1] ([GROUPID])
GO
ALTER TABLE [dbo].[SSI_PRJG_1] ADD CONSTRAINT [FK__SSI_PRJG___SESSI__6134CB1A] FOREIGN KEY ([SESSIONID]) REFERENCES [dbo].[EFORECAST_SESSION] ([SESSIONID])
GO
GRANT SELECT ON  [dbo].[SSI_PRJG_1] TO [epicoradmin]
GO
GRANT INSERT ON  [dbo].[SSI_PRJG_1] TO [epicoradmin]
GO
GRANT DELETE ON  [dbo].[SSI_PRJG_1] TO [epicoradmin]
GO
GRANT UPDATE ON  [dbo].[SSI_PRJG_1] TO [epicoradmin]
GO
GRANT SELECT ON  [dbo].[SSI_PRJG_1] TO [public]
GO
GRANT INSERT ON  [dbo].[SSI_PRJG_1] TO [public]
GO
GRANT DELETE ON  [dbo].[SSI_PRJG_1] TO [public]
GO
GRANT UPDATE ON  [dbo].[SSI_PRJG_1] TO [public]
GO
