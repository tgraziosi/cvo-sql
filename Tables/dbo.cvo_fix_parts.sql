CREATE TABLE [dbo].[cvo_fix_parts]
(
[part_no] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[category_3] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[cvo_fix_parts] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_fix_parts] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_fix_parts] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_fix_parts] TO [public]
GO
