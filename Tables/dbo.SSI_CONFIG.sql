CREATE TABLE [dbo].[SSI_CONFIG]
(
[TYPE] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[NAMEENUM] [int] NOT NULL,
[NAME] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[INTVALUE] [int] NULL,
[TEXTVALUE] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[SSI_CONFIG] TO [epicoradmin]
GO
GRANT INSERT ON  [dbo].[SSI_CONFIG] TO [epicoradmin]
GO
GRANT DELETE ON  [dbo].[SSI_CONFIG] TO [epicoradmin]
GO
GRANT UPDATE ON  [dbo].[SSI_CONFIG] TO [epicoradmin]
GO
GRANT REFERENCES ON  [dbo].[SSI_CONFIG] TO [public]
GO
GRANT SELECT ON  [dbo].[SSI_CONFIG] TO [public]
GO
GRANT INSERT ON  [dbo].[SSI_CONFIG] TO [public]
GO
GRANT DELETE ON  [dbo].[SSI_CONFIG] TO [public]
GO
GRANT UPDATE ON  [dbo].[SSI_CONFIG] TO [public]
GO
