CREATE TABLE [dbo].[rpt_invcost]
(
[part_no] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[type_code] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[in_stock] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[po_on_order] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty_alloc] [decimal] (18, 0) NULL,
[min_stock] [decimal] (18, 0) NULL,
[recv_mtd] [decimal] (18, 0) NULL,
[issued_mtd] [decimal] (18, 0) NULL,
[usage_mtd] [decimal] (18, 0) NULL,
[sales_qty_mtd] [decimal] (18, 0) NULL,
[recv_ytd] [decimal] (18, 0) NULL,
[issued_ytd] [decimal] (18, 0) NULL,
[usage_ytd] [decimal] (18, 0) NULL,
[sales_qty_ytd] [decimal] (18, 0) NULL,
[vendor] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cost] [decimal] (18, 0) NULL,
[avg_cost] [decimal] (18, 0) NULL,
[avg_direct_dolrs] [decimal] (18, 0) NULL,
[avg_ovhd_dolrs] [decimal] (18, 0) NULL,
[avg_util_dolrs] [decimal] (18, 0) NULL,
[std_cost] [decimal] (18, 0) NULL,
[std_direct_dolrs] [decimal] (18, 0) NULL,
[std_ovhd_dolrs] [decimal] (18, 0) NULL,
[std_util_dolrs] [decimal] (18, 0) NULL,
[last_cost] [decimal] (18, 0) NULL,
[sales_amt_mtd] [decimal] (18, 0) NULL,
[sales_amt_ytd] [decimal] (18, 0) NULL,
[oe_on_order] [decimal] (18, 0) NULL,
[location] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[labor] [decimal] (18, 0) NULL,
[std_labor] [decimal] (18, 0) NULL,
[hold_qty] [decimal] (18, 0) NULL,
[hold_mfg] [decimal] (18, 0) NULL,
[hold_ord] [decimal] (18, 0) NULL,
[hold_rcv] [decimal] (18, 0) NULL,
[hold_xfr] [decimal] (18, 0) NULL,
[on_hold_qty] [decimal] (18, 0) NULL,
[total_qty] [decimal] (18, 0) NULL,
[matl_cost] [decimal] (18, 0) NULL,
[direct_cost] [decimal] (18, 0) NULL,
[ovhd_cost] [decimal] (18, 0) NULL,
[util_cost] [decimal] (18, 0) NULL,
[total_cost] [decimal] (18, 0) NULL,
[total_cost_ext] [decimal] (18, 0) NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_invcost] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_invcost] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_invcost] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_invcost] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_invcost] TO [public]
GO
