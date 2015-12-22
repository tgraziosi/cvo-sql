CREATE TABLE [dbo].[rpt_womscheduling]
(
[sched_name] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[min_stock] [decimal] (20, 8) NULL,
[vendor] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor_name] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[buyer] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[buyer_name] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[planned_ind] [int] NOT NULL,
[supply_ind] [int] NOT NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tran_date] [datetime] NOT NULL,
[tran_qty] [decimal] (20, 8) NOT NULL,
[inv_qty] [decimal] (20, 8) NOT NULL,
[tran_no] [int] NULL,
[tran_ext] [int] NULL,
[tran_line] [int] NULL,
[tran_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tran_descr] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dep_part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dep_location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tran_table] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[forecast_qty] [decimal] (20, 8) NULL,
[forecast_date] [datetime] NULL,
[supply_qty] [decimal] (20, 8) NOT NULL,
[demand_qty] [decimal] (20, 8) NOT NULL,
[running_bal] [decimal] (20, 8) NOT NULL,
[group1] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group2] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group3] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group4] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[row_id] [int] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_womscheduling] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_womscheduling] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_womscheduling] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_womscheduling] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_womscheduling] TO [public]
GO
