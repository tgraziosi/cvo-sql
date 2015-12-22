CREATE TABLE [dbo].[rpt_invinv]
(
[part_no] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[type_code] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[in_stock] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[po_on_order] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty_alloc] [float] NOT NULL,
[min_stock] [float] NOT NULL,
[min_order] [float] NOT NULL,
[commit_ed] [float] NOT NULL,
[recv_mtd] [float] NOT NULL,
[issued_mtd] [float] NOT NULL,
[usage_mtd] [float] NOT NULL,
[sales_qty_mtd] [float] NOT NULL,
[recv_ytd] [float] NOT NULL,
[issued_ytd] [float] NOT NULL,
[usage_ytd] [float] NOT NULL,
[sales_qty_ytd] [float] NOT NULL,
[vendor] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cost] [float] NOT NULL,
[avg_cost] [float] NOT NULL,
[avg_direct_dolrs] [float] NOT NULL,
[avg_ovhd_dolrs] [float] NOT NULL,
[avg_util_dolrs] [float] NOT NULL,
[std_cost] [float] NOT NULL,
[std_direct_dolrs] [float] NOT NULL,
[std_ovhd_dolrs] [float] NOT NULL,
[std_util_dolrs] [float] NOT NULL,
[last_cost] [float] NOT NULL,
[sales_amt_mtd] [float] NOT NULL,
[sales_amt_ytd] [float] NOT NULL,
[oe_on_order] [float] NOT NULL,
[location] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[labor] [float] NOT NULL,
[std_labor] [float] NOT NULL,
[hold_qty] [float] NOT NULL,
[hold_mfg] [float] NOT NULL,
[hold_ord] [float] NOT NULL,
[hold_rcv] [float] NOT NULL,
[hold_xfr] [float] NOT NULL,
[on_hold_qty] [float] NOT NULL,
[available] [float] NOT NULL,
[matl_cost] [float] NOT NULL,
[direct_cost] [float] NOT NULL,
[ovhd_cost] [float] NOT NULL,
[util_cost] [float] NOT NULL,
[total_cost] [float] NOT NULL,
[total_cost_ext] [float] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_invinv] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_invinv] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_invinv] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_invinv] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_invinv] TO [public]
GO
