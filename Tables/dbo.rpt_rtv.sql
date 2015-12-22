CREATE TABLE [dbo].[rpt_rtv]
(
[match_ctrl_int] [int] NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor_remit_to] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[printed_flag] [smallint] NULL,
[amt_net] [float] NULL,
[amt_discount] [float] NULL,
[amt_tax] [float] NULL,
[amt_freight] [float] NULL,
[amt_misc] [float] NULL,
[amt_due] [float] NULL,
[match_posted_flag] [smallint] NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[amt_tax_included] [float] NULL,
[apply_date] [datetime] NULL,
[aging_date] [datetime] NULL,
[due_date] [datetime] NULL,
[discount_date] [datetime] NULL,
[invoice_receive_date] [datetime] NULL,
[vendor_invoice_date] [datetime] NULL,
[vendor_invoice_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_match] [datetime] NULL,
[vendor_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pay_to_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[match_line_num] [int] NULL,
[po_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[item_desc] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty_ordered] [float] NULL,
[unit_price] [float] NULL,
[qty_invoiced] [float] NULL,
[vend_addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vend_addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vend_addr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vend_addr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vend_addr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vend_addr6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pay_addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pay_addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pay_addr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pay_addr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pay_addr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pay_addr6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[match_unit_price] [float] NULL,
[process_group_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rtv_no] [int] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_rtv] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_rtv] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_rtv] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_rtv] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_rtv] TO [public]
GO
