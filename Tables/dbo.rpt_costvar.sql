CREATE TABLE [dbo].[rpt_costvar]
(
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_and_desc] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cost] [decimal] (20, 13) NULL,
[avg_cost] [decimal] (20, 13) NULL,
[last_cost] [decimal] (20, 13) NULL,
[avg_direct_dolrs] [decimal] (20, 13) NULL,
[avg_ovhd_dolrs] [decimal] (20, 13) NULL,
[avg_util_dolrs] [decimal] (20, 13) NULL,
[in_stock] [decimal] (20, 13) NULL,
[hold_qty] [decimal] (20, 13) NULL,
[min_stock] [decimal] (20, 13) NULL,
[qty_alloc] [decimal] (20, 13) NULL,
[po_on_order] [decimal] (20, 13) NULL,
[vendor] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[issued_mtd] [decimal] (20, 13) NULL,
[issued_ytd] [decimal] (20, 13) NULL,
[recv_mtd] [decimal] (20, 13) NULL,
[recv_ytd] [decimal] (20, 13) NULL,
[category] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[type_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[usage_mtd] [decimal] (20, 13) NULL,
[usage_ytd] [decimal] (20, 13) NULL,
[sales_qty_mtd] [decimal] (20, 13) NULL,
[sales_qty_ytd] [decimal] (20, 13) NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[oe_on_order] [decimal] (20, 13) NULL,
[labor] [decimal] (20, 13) NULL,
[sales_amt_mtd] [decimal] (20, 13) NULL,
[sales_amt_ytd] [decimal] (20, 13) NULL,
[std_cost] [decimal] (20, 13) NULL,
[std_labor] [decimal] (20, 13) NULL,
[std_direct_dolrs] [decimal] (20, 13) NULL,
[std_ovhd_dolrs] [decimal] (20, 13) NULL,
[total_avg_cost] [decimal] (20, 13) NULL,
[total_std_cost] [decimal] (20, 13) NULL,
[std_util_dolrs] [decimal] (20, 13) NULL,
[average_price] [decimal] (20, 13) NULL,
[cost_variance] [decimal] (20, 13) NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_costvar] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_costvar] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_costvar] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_costvar] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_costvar] TO [public]
GO
