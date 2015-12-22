CREATE TABLE [dbo].[SSI_PPR_1]
(
[SESSIONID] [int] NOT NULL,
[PRJNAMEENUM] [int] NOT NULL,
[PRJNAME] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PRJVALUE] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PRJTYPE] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[SSI_PPR_1] TO [epicoradmin]
GO
GRANT INSERT ON  [dbo].[SSI_PPR_1] TO [epicoradmin]
GO
GRANT DELETE ON  [dbo].[SSI_PPR_1] TO [epicoradmin]
GO
GRANT UPDATE ON  [dbo].[SSI_PPR_1] TO [epicoradmin]
GO
GRANT REFERENCES ON  [dbo].[SSI_PPR_1] TO [public]
GO
GRANT SELECT ON  [dbo].[SSI_PPR_1] TO [public]
GO
GRANT INSERT ON  [dbo].[SSI_PPR_1] TO [public]
GO
GRANT DELETE ON  [dbo].[SSI_PPR_1] TO [public]
GO
GRANT UPDATE ON  [dbo].[SSI_PPR_1] TO [public]
GO
