CREATE TABLE [dbo].[EAI_ord_xref]
(
[BO_order_no] [int] NOT NULL,
[BO_order_ext] [int] NOT NULL,
[FO_order_no] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[source] [char] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[EAI_ord_xref] TO [public]
GO
GRANT SELECT ON  [dbo].[EAI_ord_xref] TO [public]
GO
GRANT INSERT ON  [dbo].[EAI_ord_xref] TO [public]
GO
GRANT DELETE ON  [dbo].[EAI_ord_xref] TO [public]
GO
GRANT UPDATE ON  [dbo].[EAI_ord_xref] TO [public]
GO
