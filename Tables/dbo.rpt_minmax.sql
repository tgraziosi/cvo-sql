CREATE TABLE [dbo].[rpt_minmax]
(
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[in_stock] [float] NULL,
[po_on_order] [float] NULL,
[qty_alloc] [float] NULL,
[min_stock] [float] NULL,
[min_order] [float] NULL,
[commit_ed] [float] NULL,
[vendor] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[po_order_date] [datetime] NULL,
[max_stock] [float] NULL,
[hold_mfg] [float] NULL,
[hold_ord] [float] NULL,
[hold_rcv] [float] NULL,
[hold_xfr] [float] NULL,
[need_qty] [float] NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[buyer] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_minmax] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_minmax] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_minmax] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_minmax] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_minmax] TO [public]
GO
