CREATE TABLE [dbo].[rpt_apactpto]
(
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pay_to_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_last_dm] [real] NOT NULL,
[amt_last_adj] [real] NOT NULL,
[amt_last_pyt] [real] NOT NULL,
[amt_last_void] [real] NOT NULL,
[amt_age_bracket1] [real] NOT NULL,
[amt_age_bracket2] [real] NOT NULL,
[amt_age_bracket3] [real] NOT NULL,
[amt_age_bracket4] [real] NOT NULL,
[amt_age_bracket5] [real] NOT NULL,
[amt_age_bracket6] [real] NOT NULL,
[amt_on_order] [real] NOT NULL,
[amt_vouch_unposted] [real] NOT NULL,
[last_vouch_doc] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[last_dm_doc] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[last_adj_doc] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[last_pyt_doc] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[last_void_acct] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ast_void_doc] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[last_pyt_acct] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[high_amt_ap] [real] NOT NULL,
[high_amt_vouch] [real] NOT NULL,
[high_date_ap] [int] NOT NULL,
[high_date_vouch] [int] NOT NULL,
[num_vouch] [int] NOT NULL,
[num_vouch_paid] [int] NOT NULL,
[num_overdue_pyt] [int] NOT NULL,
[avg_days_pay] [int] NOT NULL,
[avg_days_overdue] [int] NOT NULL,
[last_trx_time] [int] NOT NULL,
[amt_balance] [real] NOT NULL,
[amt_on_order_oper] [real] NOT NULL,
[amt_vouch_unposted_oper] [real] NOT NULL,
[amt_age_bracket1_oper] [real] NOT NULL,
[amt_age_bracket2_oper] [real] NOT NULL,
[amt_age_bracket3_oper] [real] NOT NULL,
[amt_age_bracket4_oper] [real] NOT NULL,
[amt_age_bracket5_oper] [real] NOT NULL,
[amt_age_bracket6_oper] [real] NOT NULL,
[amt_balance_oper] [real] NOT NULL,
[high_amt_ap_oper] [real] NOT NULL,
[last_vouch_cur] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[last_dm_cur] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[last_adj_cur] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[last_pyt_cur] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[last_void_cur] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pay_to_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_last_vouch] [int] NOT NULL,
[date_last_dm] [int] NOT NULL,
[date_last_adj] [int] NOT NULL,
[date_last_pyt] [int] NOT NULL,
[date_last_void] [int] NOT NULL,
[amt_last_vouch] [real] NOT NULL,
[pyt_symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vch_symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[dm_symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[adj_symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[void_symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_apactpto] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_apactpto] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_apactpto] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_apactpto] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_apactpto] TO [public]
GO
