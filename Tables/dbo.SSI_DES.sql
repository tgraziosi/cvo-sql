CREATE TABLE [dbo].[SSI_DES]
(
[SCHEMAID] [int] NOT NULL,
[REFDESCID] [int] NOT NULL,
[DESCTYPE] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[REFDESC] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RURDOPTIONPOS] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ISITEM] [int] NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[SSI_DES] TO [epicoradmin]
GO
GRANT INSERT ON  [dbo].[SSI_DES] TO [epicoradmin]
GO
GRANT DELETE ON  [dbo].[SSI_DES] TO [epicoradmin]
GO
GRANT UPDATE ON  [dbo].[SSI_DES] TO [epicoradmin]
GO
GRANT REFERENCES ON  [dbo].[SSI_DES] TO [public]
GO
GRANT SELECT ON  [dbo].[SSI_DES] TO [public]
GO
GRANT INSERT ON  [dbo].[SSI_DES] TO [public]
GO
GRANT DELETE ON  [dbo].[SSI_DES] TO [public]
GO
GRANT UPDATE ON  [dbo].[SSI_DES] TO [public]
GO
