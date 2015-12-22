CREATE TABLE [dbo].[inv_list_import]
(
[part_no] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bin_no] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[avg_cost] [float] NULL,
[avg_direct_dolrs] [float] NULL,
[avg_ovhd_dolrs] [float] NULL,
[avg_util_dolrs] [float] NULL,
[in_stock] [float] NULL,
[hold_qty] [float] NULL,
[rank_class] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[min_stock] [float] NULL,
[max_stock] [float] NULL,
[min_order] [float] NULL,
[issued_mtd] [float] NULL,
[issued_ytd] [float] NULL,
[lead_time] [float] NULL,
[status] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[labor] [float] NULL,
[qty_year_end] [float] NULL,
[qty_month_end] [float] NULL,
[qty_physical] [float] NULL,
[entered_who] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[entered_date] [datetime] NULL,
[void] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_who] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_date] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[std_cost] [float] NULL,
[std_labor] [float] NULL,
[std_direct_dolrs] [float] NULL,
[std_ovhd_dolrs] [float] NULL,
[std_util_dolrs] [float] NULL,
[setup_labor] [float] NULL,
[freight_unit] [float] NULL,
[note] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cycle_date] [datetime] NULL,
[acct_code] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[eoq] [float] NULL,
[row_id] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dock_to_stock] [float] NULL,
[order_multiple] [float] NULL,
[abc_code] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[abc_code_frozen_flag] [float] NULL,
[po_uom] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[so_uom] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qc_qty] [float] NULL,
[so_qty_increment] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[inv_list_import] TO [public]
GO
GRANT INSERT ON  [dbo].[inv_list_import] TO [public]
GO
GRANT DELETE ON  [dbo].[inv_list_import] TO [public]
GO
GRANT UPDATE ON  [dbo].[inv_list_import] TO [public]
GO
