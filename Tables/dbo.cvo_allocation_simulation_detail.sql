CREATE TABLE [dbo].[cvo_allocation_simulation_detail]
(
[user_spid] [int] NULL,
[order_no] [int] NULL,
[order_ext] [int] NULL,
[order_no_ext] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cust_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cust_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_date] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[so_priority] [int] NULL,
[cust_type] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[promotion] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty] [decimal] (20, 8) NULL,
[bin_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bin_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT DELETE ON  [dbo].[cvo_allocation_simulation_detail] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_allocation_simulation_detail] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_allocation_simulation_detail] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_allocation_simulation_detail] TO [public]
GO
