CREATE TABLE [dbo].[SSI_SCH]
(
[SCHEMAID] [int] NOT NULL,
[SCHEMANAME] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[USERID] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SCHEMANOTE] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[SSI_SCH] ADD CONSTRAINT [PK_SSI_SCH] PRIMARY KEY CLUSTERED  ([SCHEMAID]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[SSI_SCH] TO [epicoradmin]
GO
GRANT INSERT ON  [dbo].[SSI_SCH] TO [epicoradmin]
GO
GRANT DELETE ON  [dbo].[SSI_SCH] TO [epicoradmin]
GO
GRANT UPDATE ON  [dbo].[SSI_SCH] TO [epicoradmin]
GO
GRANT REFERENCES ON  [dbo].[SSI_SCH] TO [public]
GO
GRANT SELECT ON  [dbo].[SSI_SCH] TO [public]
GO
GRANT INSERT ON  [dbo].[SSI_SCH] TO [public]
GO
GRANT DELETE ON  [dbo].[SSI_SCH] TO [public]
GO
GRANT UPDATE ON  [dbo].[SSI_SCH] TO [public]
GO
