CREATE TABLE [dbo].[apactpto]
(
[timestamp] [timestamp] NOT NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pay_to_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_last_vouch] [int] NOT NULL,
[date_last_dm] [int] NOT NULL,
[date_last_adj] [int] NOT NULL,
[date_last_pyt] [int] NOT NULL,
[date_last_void] [int] NOT NULL,
[amt_last_vouch] [float] NOT NULL,
[amt_last_dm] [float] NOT NULL,
[amt_last_adj] [float] NOT NULL,
[amt_last_pyt] [float] NOT NULL,
[amt_last_void] [float] NOT NULL,
[amt_age_bracket1] [float] NOT NULL,
[amt_age_bracket2] [float] NOT NULL,
[amt_age_bracket3] [float] NOT NULL,
[amt_age_bracket4] [float] NOT NULL,
[amt_age_bracket5] [float] NOT NULL,
[amt_age_bracket6] [float] NOT NULL,
[amt_on_order] [float] NOT NULL,
[amt_vouch_unposted] [float] NOT NULL,
[last_vouch_doc] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[last_dm_doc] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[last_adj_doc] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[last_pyt_doc] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[last_pyt_acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[last_void_doc] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[last_void_acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[high_amt_ap] [float] NOT NULL,
[high_amt_vouch] [float] NOT NULL,
[high_date_ap] [int] NOT NULL,
[high_date_vouch] [int] NOT NULL,
[num_vouch] [int] NOT NULL,
[num_vouch_paid] [int] NOT NULL,
[num_overdue_pyt] [int] NOT NULL,
[avg_days_pay] [int] NOT NULL,
[avg_days_overdue] [int] NOT NULL,
[last_trx_time] [int] NOT NULL,
[amt_balance] [float] NOT NULL,
[last_vouch_cur] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[last_dm_cur] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[last_adj_cur] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[last_pyt_cur] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[last_void_cur] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[amt_age_bracket1_oper] [float] NULL,
[amt_age_bracket2_oper] [float] NULL,
[amt_age_bracket3_oper] [float] NULL,
[amt_age_bracket4_oper] [float] NULL,
[amt_age_bracket5_oper] [float] NULL,
[amt_age_bracket6_oper] [float] NULL,
[amt_balance_oper] [float] NULL,
[amt_on_order_oper] [float] NULL,
[amt_vouch_unposted_oper] [float] NULL,
[high_amt_ap_oper] [float] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [apactpto_ind_0] ON [dbo].[apactpto] ([vendor_code], [pay_to_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[apactpto] TO [public]
GO
GRANT SELECT ON  [dbo].[apactpto] TO [public]
GO
GRANT INSERT ON  [dbo].[apactpto] TO [public]
GO
GRANT DELETE ON  [dbo].[apactpto] TO [public]
GO
GRANT UPDATE ON  [dbo].[apactpto] TO [public]
GO
