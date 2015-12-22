CREATE TABLE [dbo].[SSI_LIST]
(
[LISTTYPE] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[LISTVALUE] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[SSI_LIST] TO [epicoradmin]
GO
GRANT INSERT ON  [dbo].[SSI_LIST] TO [epicoradmin]
GO
GRANT DELETE ON  [dbo].[SSI_LIST] TO [epicoradmin]
GO
GRANT UPDATE ON  [dbo].[SSI_LIST] TO [epicoradmin]
GO
GRANT REFERENCES ON  [dbo].[SSI_LIST] TO [public]
GO
GRANT SELECT ON  [dbo].[SSI_LIST] TO [public]
GO
GRANT INSERT ON  [dbo].[SSI_LIST] TO [public]
GO
GRANT DELETE ON  [dbo].[SSI_LIST] TO [public]
GO
GRANT UPDATE ON  [dbo].[SSI_LIST] TO [public]
GO
