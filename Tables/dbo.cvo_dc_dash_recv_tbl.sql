CREATE TABLE [dbo].[cvo_dc_dash_recv_tbl]
(
[due_days] [int] NULL,
[inhouse_date] [datetime] NULL,
[vendor_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[po_key] [int] NULL,
[category] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[line] [int] NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[item_type] [varchar] (13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[unit_measure] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[weight_ea] [decimal] (20, 8) NULL,
[qty_ordered] [decimal] (20, 8) NULL,
[qty_received] [decimal] (20, 8) NULL,
[qty_open] [decimal] (21, 8) NULL,
[Last_Receipt] [int] NULL,
[Last_receipt_date] [datetime] NULL,
[recv_days] [int] NULL,
[Pk_lst] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status_desc] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[e4_wu] [int] NULL,
[e12_wu] [int] NULL,
[qty_avl] [decimal] (38, 8) NULL,
[open_ord] [decimal] (38, 8) NULL,
[Info_tag] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Method] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[type_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_dash_recv] ON [dbo].[cvo_dc_dash_recv_tbl] ([po_key]) ON [PRIMARY]
GO
GRANT DELETE ON  [dbo].[cvo_dc_dash_recv_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_dc_dash_recv_tbl] TO [public]
GO
GRANT REFERENCES ON  [dbo].[cvo_dc_dash_recv_tbl] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_dc_dash_recv_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_dc_dash_recv_tbl] TO [public]
GO
