CREATE TABLE [dbo].[tdc_replenishment_log]
(
[TranId] [int] NULL,
[tran_date] [datetime] NOT NULL,
[proc_name] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[proc_in_location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[proc_in_part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[proc_in_bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[proc_in_delta_qty] [decimal] (20, 8) NULL,
[proc_in_qty_from_lbs] [decimal] (20, 8) NULL,
[repl_table_replenish_min_lvl] [decimal] (20, 0) NULL,
[repl_table_replenish_max_lvl] [decimal] (20, 0) NULL,
[repl_table_replenish_qty] [decimal] (20, 0) NULL,
[repl_table_last_modified_date] [datetime] NULL,
[repl_table_modified_by] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[repl_table_auto_replen] [int] NULL,
[current_bin_qty] [decimal] (20, 8) NULL,
[qty_to_move] [decimal] (20, 8) NULL,
[repl_from_lb_bin] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[repl_from_lb_qty] [decimal] (20, 8) NULL,
[inventory_vw_total_qty] [decimal] (20, 8) NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_replenishment_log] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_replenishment_log] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_replenishment_log] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_replenishment_log] TO [public]
GO
