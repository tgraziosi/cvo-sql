CREATE TABLE [dbo].[SSI_DAT]
(
[SCHEMAID] [int] NOT NULL,
[DATNAMEENUM] [int] NULL,
[DATNAME] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DATVALUE] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DATTYPE] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[SSI_DAT] TO [epicoradmin]
GO
GRANT INSERT ON  [dbo].[SSI_DAT] TO [epicoradmin]
GO
GRANT DELETE ON  [dbo].[SSI_DAT] TO [epicoradmin]
GO
GRANT UPDATE ON  [dbo].[SSI_DAT] TO [epicoradmin]
GO
GRANT REFERENCES ON  [dbo].[SSI_DAT] TO [public]
GO
GRANT SELECT ON  [dbo].[SSI_DAT] TO [public]
GO
GRANT INSERT ON  [dbo].[SSI_DAT] TO [public]
GO
GRANT DELETE ON  [dbo].[SSI_DAT] TO [public]
GO
GRANT UPDATE ON  [dbo].[SSI_DAT] TO [public]
GO
