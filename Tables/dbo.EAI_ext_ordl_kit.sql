CREATE TABLE [dbo].[EAI_ext_ordl_kit]
(
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL,
[line_no] [int] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qty_per] [decimal] (20, 8) NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[EAI_ext_ordl_kit] TO [public]
GO
GRANT SELECT ON  [dbo].[EAI_ext_ordl_kit] TO [public]
GO
GRANT INSERT ON  [dbo].[EAI_ext_ordl_kit] TO [public]
GO
GRANT DELETE ON  [dbo].[EAI_ext_ordl_kit] TO [public]
GO
GRANT UPDATE ON  [dbo].[EAI_ext_ordl_kit] TO [public]
GO
