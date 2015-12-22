CREATE TABLE [dbo].[EAI_pur_prod_xref]
(
[FO_prod_id] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[order_no] [int] NOT NULL,
[ext] [int] NOT NULL,
[line_no] [int] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[serial_no] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FO_parent_id1] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[EAI_pur_prod_xref] ADD CONSTRAINT [EAI_pur_prod_xref_status_cc1] CHECK (([status]='R' OR [status]='A'))
GO
ALTER TABLE [dbo].[EAI_pur_prod_xref] ADD CONSTRAINT [EAI_pur_prod_xref_pk] PRIMARY KEY CLUSTERED  ([FO_prod_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[EAI_pur_prod_xref] TO [public]
GO
GRANT SELECT ON  [dbo].[EAI_pur_prod_xref] TO [public]
GO
GRANT INSERT ON  [dbo].[EAI_pur_prod_xref] TO [public]
GO
GRANT DELETE ON  [dbo].[EAI_pur_prod_xref] TO [public]
GO
GRANT UPDATE ON  [dbo].[EAI_pur_prod_xref] TO [public]
GO
