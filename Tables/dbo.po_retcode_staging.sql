CREATE TABLE [dbo].[po_retcode_staging]
(
[category_code] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[category_desc] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[po_retcode_staging] TO [public]
GO
GRANT INSERT ON  [dbo].[po_retcode_staging] TO [public]
GO
GRANT DELETE ON  [dbo].[po_retcode_staging] TO [public]
GO
GRANT UPDATE ON  [dbo].[po_retcode_staging] TO [public]
GO
