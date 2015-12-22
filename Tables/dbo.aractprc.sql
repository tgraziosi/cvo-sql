CREATE TABLE [dbo].[aractprc]
(
[timestamp] [timestamp] NOT NULL,
[price_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_last_inv] [int] NOT NULL,
[date_last_cm] [int] NOT NULL,
[date_last_adj] [int] NOT NULL,
[date_last_wr_off] [int] NOT NULL,
[date_last_pyt] [int] NOT NULL,
[date_last_nsf] [int] NOT NULL,
[date_last_fin_chg] [int] NOT NULL,
[date_last_late_chg] [int] NOT NULL,
[date_last_comm] [int] NOT NULL,
[amt_last_inv] [float] NOT NULL,
[amt_last_cm] [float] NOT NULL,
[amt_last_adj] [float] NOT NULL,
[amt_last_wr_off] [float] NOT NULL,
[amt_last_pyt] [float] NOT NULL,
[amt_last_nsf] [float] NOT NULL,
[amt_last_fin_chg] [float] NOT NULL,
[amt_last_late_chg] [float] NOT NULL,
[amt_last_comm] [float] NOT NULL,
[amt_age_bracket1] [float] NOT NULL,
[amt_age_bracket2] [float] NOT NULL,
[amt_age_bracket3] [float] NOT NULL,
[amt_age_bracket4] [float] NOT NULL,
[amt_age_bracket5] [float] NOT NULL,
[amt_age_bracket6] [float] NOT NULL,
[amt_on_order] [float] NOT NULL,
[amt_inv_unposted] [float] NOT NULL,
[last_inv_doc] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[last_cm_doc] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[last_adj_doc] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[last_wr_off_doc] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[last_pyt_doc] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[last_nsf_doc] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[last_fin_chg_doc] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[last_late_chg_doc] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[high_amt_ar] [float] NOT NULL,
[high_amt_inv] [float] NOT NULL,
[high_date_ar] [int] NOT NULL,
[high_date_inv] [int] NOT NULL,
[num_inv] [int] NOT NULL,
[num_inv_paid] [int] NOT NULL,
[num_overdue_pyt] [int] NOT NULL,
[avg_days_pay] [int] NOT NULL,
[avg_days_overdue] [int] NOT NULL,
[last_trx_time] [int] NOT NULL,
[amt_balance] [float] NOT NULL,
[amt_age_b1_oper] [float] NOT NULL,
[amt_age_b2_oper] [float] NOT NULL,
[amt_age_b3_oper] [float] NOT NULL,
[amt_age_b4_oper] [float] NOT NULL,
[amt_age_b5_oper] [float] NOT NULL,
[amt_age_b6_oper] [float] NOT NULL,
[amt_on_order_oper] [float] NOT NULL,
[amt_inv_unp_oper] [float] NOT NULL,
[high_amt_ar_oper] [float] NOT NULL,
[high_amt_inv_oper] [float] NOT NULL,
[amt_balance_oper] [float] NOT NULL,
[last_inv_cur] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[last_cm_cur] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[last_adj_cur] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[last_wr_off_cur] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[last_pyt_cur] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[last_nsf_cur] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[last_fin_chg_cur] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[last_late_chg_cur] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[last_age_upd_date] [int] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [aractprc_ind_0] ON [dbo].[aractprc] ([price_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[aractprc] TO [public]
GO
GRANT SELECT ON  [dbo].[aractprc] TO [public]
GO
GRANT INSERT ON  [dbo].[aractprc] TO [public]
GO
GRANT DELETE ON  [dbo].[aractprc] TO [public]
GO
GRANT UPDATE ON  [dbo].[aractprc] TO [public]
GO
