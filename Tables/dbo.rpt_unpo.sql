CREATE TABLE [dbo].[rpt_unpo]
(
[po_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[release_date] [datetime] NULL,
[vendor_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[quantity] [float] NULL,
[uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sched_item_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[operation_qty] [float] NULL,
[order_qty] [float] NULL,
[transfer_qty] [float] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_unpo] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_unpo] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_unpo] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_unpo] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_unpo] TO [public]
GO
