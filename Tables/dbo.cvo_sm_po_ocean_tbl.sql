CREATE TABLE [dbo].[cvo_sm_po_ocean_tbl]
(
[po_key] [int] NULL,
[po_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty_ocean] [int] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_sm_po_ocean_tbl] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_sm_po_ocean_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_sm_po_ocean_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_sm_po_ocean_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_sm_po_ocean_tbl] TO [public]
GO
