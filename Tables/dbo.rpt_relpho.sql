CREATE TABLE [dbo].[rpt_relpho]
(
[order_no] [int] NULL,
[order_ext] [int] NULL,
[cust_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[total_order_amt] [float] NULL,
[total_order_cost] [float] NULL,
[ship_to_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[salesperson] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_entered] [datetime] NULL,
[curr_factor] [float] NULL,
[printed] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[reason] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[blanket] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_relpho] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_relpho] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_relpho] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_relpho] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_relpho] TO [public]
GO
