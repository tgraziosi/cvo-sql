CREATE TABLE [dbo].[SSI_TAG_1]
(
[TAGNAME] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[TAGTYPE] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TAGDESC] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LASTMODIFIEDBY] [int] NULL,
[LASTMODIFIED] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[SSI_TAG_1] TO [epicoradmin]
GO
GRANT INSERT ON  [dbo].[SSI_TAG_1] TO [epicoradmin]
GO
GRANT DELETE ON  [dbo].[SSI_TAG_1] TO [epicoradmin]
GO
GRANT UPDATE ON  [dbo].[SSI_TAG_1] TO [epicoradmin]
GO
GRANT SELECT ON  [dbo].[SSI_TAG_1] TO [public]
GO
GRANT INSERT ON  [dbo].[SSI_TAG_1] TO [public]
GO
GRANT DELETE ON  [dbo].[SSI_TAG_1] TO [public]
GO
GRANT UPDATE ON  [dbo].[SSI_TAG_1] TO [public]
GO
