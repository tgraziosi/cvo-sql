CREATE TABLE [dbo].[rpt_cust_info]
(
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_begin_bal] [float] NOT NULL,
[amt_charge] [float] NOT NULL,
[amt_payment] [float] NOT NULL,
[amt_adjustment] [float] NOT NULL,
[parent] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[child_1] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[child_2] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[child_3] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[child_4] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[child_5] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[child_6] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[child_7] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[child_8] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[child_9] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tier_level] [smallint] NOT NULL,
[trx_flag] [smallint] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_cust_info] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_cust_info] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_cust_info] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_cust_info] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_cust_info] TO [public]
GO
