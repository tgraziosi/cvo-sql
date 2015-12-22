CREATE TABLE [dbo].[rpt_ordertemp]
(
[order_no] [int] NOT NULL,
[order_ctrl_num] [char] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ext] [int] NOT NULL,
[date_entered] [datetime] NOT NULL,
[cust_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[total_amt_order] [float] NOT NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[orig_no] [int] NOT NULL,
[type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_ordertemp] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_ordertemp] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_ordertemp] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_ordertemp] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_ordertemp] TO [public]
GO
