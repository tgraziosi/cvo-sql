CREATE TABLE [dbo].[so_usrcateg_staging]
(
[code] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[so_usrcateg_staging] TO [public]
GO
GRANT INSERT ON  [dbo].[so_usrcateg_staging] TO [public]
GO
GRANT DELETE ON  [dbo].[so_usrcateg_staging] TO [public]
GO
GRANT UPDATE ON  [dbo].[so_usrcateg_staging] TO [public]
GO
