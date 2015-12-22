CREATE TABLE [dbo].[SSI_PRP]
(
[SCHEMAID] [int] NOT NULL,
[TABLETYPE] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[TABLENAME] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[COLINDEX] [int] NOT NULL,
[MEASEVENTCOL] [int] NULL,
[COLTYPE] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[COLNAME] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[REFNAME] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[REFKEY] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[REFDESCID] [int] NULL,
[MEASFORM] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ASSOCIATOR] [int] NULL,
[TOTALKEY] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GROUPBYDEF] [int] NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[SSI_PRP] TO [epicoradmin]
GO
GRANT INSERT ON  [dbo].[SSI_PRP] TO [epicoradmin]
GO
GRANT DELETE ON  [dbo].[SSI_PRP] TO [epicoradmin]
GO
GRANT UPDATE ON  [dbo].[SSI_PRP] TO [epicoradmin]
GO
GRANT REFERENCES ON  [dbo].[SSI_PRP] TO [public]
GO
GRANT SELECT ON  [dbo].[SSI_PRP] TO [public]
GO
GRANT INSERT ON  [dbo].[SSI_PRP] TO [public]
GO
GRANT DELETE ON  [dbo].[SSI_PRP] TO [public]
GO
GRANT UPDATE ON  [dbo].[SSI_PRP] TO [public]
GO
