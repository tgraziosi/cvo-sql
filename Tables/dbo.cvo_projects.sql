CREATE TABLE [dbo].[cvo_projects]
(
[row] [int] NOT NULL IDENTITY(1, 1),
[Project] [nvarchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ProjectLevel] [nvarchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[cvo_projects] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_projects] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_projects] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_projects] TO [public]
GO
