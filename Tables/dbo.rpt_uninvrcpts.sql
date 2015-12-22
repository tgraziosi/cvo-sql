CREATE TABLE [dbo].[rpt_uninvrcpts]
(
[r_receipt_no] [int] NULL,
[r_vendor] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[r_po_po] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[r_recv_date] [datetime] NULL,
[r_part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[r_quantity] [decimal] (20, 8) NULL,
[r_unit_cost] [decimal] (20, 8) NULL,
[r_location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[r_unit_measure] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[r_status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[v_vendor_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[r_over_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[r_account_no] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[r_tax_included] [decimal] (20, 8) NULL,
[r_curr_factor] [decimal] (20, 8) NULL,
[r_conv_factor] [decimal] (20, 8) NULL,
[m_apply_date] [datetime] NULL,
[p_end_date] [int] NULL,
[r_unit_cost_precision] [int] NULL,
[r_qty_precision] [int] NULL,
[g_currency_mask] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[g_curr_precision] [smallint] NULL,
[g_rounding_factor] [int] NULL,
[g_position] [int] NULL,
[g_neg_num_format] [int] NULL,
[g_symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[g_symbol_space] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[g_dec_separator] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[g_thou_separator] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[g_account_format_mask] [varchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[r_amt_nonrecoverable_tax] [decimal] (20, 8) NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_uninvrcpts] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_uninvrcpts] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_uninvrcpts] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_uninvrcpts] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_uninvrcpts] TO [public]
GO
