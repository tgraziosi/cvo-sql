CREATE TABLE [dbo].[SSI_PGPR_1]
(
[SESSIONID] [int] NOT NULL,
[GROUPID] [int] NOT NULL,
[PRJNAMEENUM] [int] NOT NULL,
[PRJNAME] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PRJVALUE] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PRJTYPE] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[SSI_PGPR_1] ADD CONSTRAINT [FK__SSI_PGPR___GROUP__65055BFE] FOREIGN KEY ([GROUPID]) REFERENCES [dbo].[SSI_GRP_1] ([GROUPID])
GO
ALTER TABLE [dbo].[SSI_PGPR_1] ADD CONSTRAINT [FK__SSI_PGPR___SESSI__641137C5] FOREIGN KEY ([SESSIONID]) REFERENCES [dbo].[EFORECAST_SESSION] ([SESSIONID])
GO
GRANT SELECT ON  [dbo].[SSI_PGPR_1] TO [epicoradmin]
GO
GRANT INSERT ON  [dbo].[SSI_PGPR_1] TO [epicoradmin]
GO
GRANT DELETE ON  [dbo].[SSI_PGPR_1] TO [epicoradmin]
GO
GRANT UPDATE ON  [dbo].[SSI_PGPR_1] TO [epicoradmin]
GO
GRANT SELECT ON  [dbo].[SSI_PGPR_1] TO [public]
GO
GRANT INSERT ON  [dbo].[SSI_PGPR_1] TO [public]
GO
GRANT DELETE ON  [dbo].[SSI_PGPR_1] TO [public]
GO
GRANT UPDATE ON  [dbo].[SSI_PGPR_1] TO [public]
GO
