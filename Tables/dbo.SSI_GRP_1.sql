CREATE TABLE [dbo].[SSI_GRP_1]
(
[GROUPID] [int] NOT NULL,
[PARTITIONID] [int] NOT NULL,
[GROUPNAME] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FORMULAVALUE] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LASTMODIFIEDBY] [int] NOT NULL,
[LASTMODIFIED] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GROUPNOTE] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[SSI_GRP_1] ADD CONSTRAINT [PK__SSI_GRP_1__5B7BF1C4] PRIMARY KEY CLUSTERED  ([GROUPID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[SSI_GRP_1] ADD CONSTRAINT [FK__SSI_GRP_1__LASTM__5D643A36] FOREIGN KEY ([LASTMODIFIEDBY]) REFERENCES [dbo].[SSI_USR] ([USERID])
GO
ALTER TABLE [dbo].[SSI_GRP_1] ADD CONSTRAINT [FK__SSI_GRP_1__PARTI__5C7015FD] FOREIGN KEY ([PARTITIONID]) REFERENCES [dbo].[SSI_PART_1] ([PARTITIONID])
GO
GRANT SELECT ON  [dbo].[SSI_GRP_1] TO [epicoradmin]
GO
GRANT INSERT ON  [dbo].[SSI_GRP_1] TO [epicoradmin]
GO
GRANT DELETE ON  [dbo].[SSI_GRP_1] TO [epicoradmin]
GO
GRANT UPDATE ON  [dbo].[SSI_GRP_1] TO [epicoradmin]
GO
GRANT SELECT ON  [dbo].[SSI_GRP_1] TO [public]
GO
GRANT INSERT ON  [dbo].[SSI_GRP_1] TO [public]
GO
GRANT DELETE ON  [dbo].[SSI_GRP_1] TO [public]
GO
GRANT UPDATE ON  [dbo].[SSI_GRP_1] TO [public]
GO
