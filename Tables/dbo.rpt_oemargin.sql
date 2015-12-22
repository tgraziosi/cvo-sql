CREATE TABLE [dbo].[rpt_oemargin]
(
[cust_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_no] [int] NULL,
[order_ext] [int] NULL,
[part_no] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[shipped] [float] NULL,
[price_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[price] [float] NULL,
[cost] [float] NULL,
[salesperson] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_shipped] [datetime] NULL,
[who_entered] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[margin] [float] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_oemargin] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_oemargin] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_oemargin] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_oemargin] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_oemargin] TO [public]
GO
