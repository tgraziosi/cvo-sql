CREATE TABLE [dbo].[CVO_xrefCustType]
(
[TYPE] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DESCRIPTION] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EPICOR CODE] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[CVO_xrefCustType] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_xrefCustType] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_xrefCustType] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_xrefCustType] TO [public]
GO
