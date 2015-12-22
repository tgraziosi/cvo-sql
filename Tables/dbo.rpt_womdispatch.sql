CREATE TABLE [dbo].[rpt_womdispatch]
(
[sched_name] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[resource_id] [int] NULL,
[resource_code] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[resource_name] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sched_process_id] [int] NULL,
[prod_no] [int] NULL,
[prod_ext] [int] NULL,
[source_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[uom_qty] [decimal] (20, 8) NULL,
[uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sched_operation_id] [int] NULL,
[operation_step] [int] NULL,
[work_datetime] [datetime] NULL,
[done_datetime] [datetime] NULL,
[operation_status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[so_sched_order_id] [int] NULL,
[so_location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[so_done_datetime] [datetime] NULL,
[so_part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[im_description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[so_uom_qty] [decimal] (20, 8) NULL,
[so_uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[so_order_priority_id] [int] NULL,
[so_source_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[so_order_no] [int] NULL,
[so_order_ext] [int] NULL,
[so_order_line] [int] NULL,
[so_order_line_kit] [int] NULL,
[co_cust_code] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[co_cust_name] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_womdispatch] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_womdispatch] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_womdispatch] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_womdispatch] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_womdispatch] TO [public]
GO
