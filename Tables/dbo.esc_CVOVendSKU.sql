CREATE TABLE [dbo].[esc_CVOVendSKU]
(
[PARTNO] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[VENDORNO] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[VENDPART] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[VENDORCOST] [float] NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[esc_CVOVendSKU] TO [public]
GO
GRANT INSERT ON  [dbo].[esc_CVOVendSKU] TO [public]
GO
GRANT DELETE ON  [dbo].[esc_CVOVendSKU] TO [public]
GO
GRANT UPDATE ON  [dbo].[esc_CVOVendSKU] TO [public]
GO
