CREATE TABLE [dbo].[cvo_xrefcategory]
(
[Megasys Code] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Megasys Text Desc] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Epicor Code] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[cvo_xrefcategory] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_xrefcategory] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_xrefcategory] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_xrefcategory] TO [public]
GO
