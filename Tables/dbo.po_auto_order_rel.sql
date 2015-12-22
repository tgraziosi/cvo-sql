CREATE TABLE [dbo].[po_auto_order_rel]
(
[timestamp] [timestamp] NOT NULL,
[row_id] [int] NOT NULL IDENTITY(1, 1),
[releases_row_id] [int] NOT NULL,
[group_no] [int] NOT NULL,
[hdr_ind] [int] NOT NULL,
[list_ind] [int] NOT NULL,
[order_flag] [char] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[o_back_ord_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[o_location] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[o_req_ship_date] [datetime] NULL,
[o_sch_ship_date] [datetime] NULL,
[o_note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[o_si] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[o_tax_id] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[o_routing] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[o_fob] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[o_forwarder] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[o_freight_to] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[o_freight_allow_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[o_salesperson] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[o_ship_to_region] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[o_posting_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[o_remit] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[o_terms_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[o_dest_zone_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[o_hold_reason] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[o_attention] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[o_phone] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[o_tot_freight] [decimal] (20, 8) NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[price] [decimal] (20, 8) NULL,
[price_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[discount] [decimal] (20, 8) NULL,
[back_ord_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[create_po_ind] [int] NULL,
[gl_rev_acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tax_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[conv_factor] [decimal] (20, 8) NULL,
[l_ordered] [decimal] (20, 8) NULL,
[sch_ship_date] [datetime] NULL,
[ordered] [decimal] (20, 8) NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [po_auto_order_rel1] ON [dbo].[po_auto_order_rel] ([releases_row_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [po_auto_order_rel2] ON [dbo].[po_auto_order_rel] ([row_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[po_auto_order_rel] TO [public]
GO
GRANT SELECT ON  [dbo].[po_auto_order_rel] TO [public]
GO
GRANT INSERT ON  [dbo].[po_auto_order_rel] TO [public]
GO
GRANT DELETE ON  [dbo].[po_auto_order_rel] TO [public]
GO
GRANT UPDATE ON  [dbo].[po_auto_order_rel] TO [public]
GO
