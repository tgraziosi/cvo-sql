CREATE TABLE [dbo].[arsumslp]
(
[timestamp] [timestamp] NOT NULL,
[salesperson_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_from] [int] NOT NULL,
[date_thru] [int] NOT NULL,
[num_inv] [int] NOT NULL,
[num_inv_paid] [int] NOT NULL,
[num_cm] [int] NOT NULL,
[num_adj] [int] NOT NULL,
[num_wr_off] [int] NOT NULL,
[num_pyt] [int] NOT NULL,
[num_overdue_pyt] [int] NOT NULL,
[num_nsf] [int] NOT NULL,
[num_fin_chg] [int] NOT NULL,
[num_late_chg] [int] NOT NULL,
[amt_inv] [float] NOT NULL,
[amt_cm] [float] NOT NULL,
[amt_adj] [float] NOT NULL,
[amt_wr_off] [float] NOT NULL,
[amt_pyt] [float] NOT NULL,
[amt_nsf] [float] NOT NULL,
[amt_fin_chg] [float] NOT NULL,
[amt_late_chg] [float] NOT NULL,
[amt_profit] [float] NOT NULL,
[prc_profit] [float] NOT NULL,
[amt_comm] [float] NOT NULL,
[amt_disc_given] [float] NOT NULL,
[amt_disc_taken] [float] NOT NULL,
[amt_disc_lost] [float] NOT NULL,
[amt_freight] [float] NOT NULL,
[amt_tax] [float] NOT NULL,
[avg_days_pay] [int] NOT NULL,
[avg_days_overdue] [int] NOT NULL,
[last_trx_time] [int] NOT NULL,
[amt_inv_oper] [float] NOT NULL,
[amt_cm_oper] [float] NOT NULL,
[amt_adj_oper] [float] NOT NULL,
[amt_wr_off_oper] [float] NOT NULL,
[amt_pyt_oper] [float] NOT NULL,
[amt_nsf_oper] [float] NOT NULL,
[amt_fin_chg_oper] [float] NOT NULL,
[amt_late_chg_oper] [float] NOT NULL,
[amt_disc_g_oper] [float] NOT NULL,
[amt_disc_t_oper] [float] NOT NULL,
[amt_freight_oper] [float] NOT NULL,
[amt_tax_oper] [float] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [arsumslp_ind_0] ON [dbo].[arsumslp] ([salesperson_code], [date_thru]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arsumslp] TO [public]
GO
GRANT SELECT ON  [dbo].[arsumslp] TO [public]
GO
GRANT INSERT ON  [dbo].[arsumslp] TO [public]
GO
GRANT DELETE ON  [dbo].[arsumslp] TO [public]
GO
GRANT UPDATE ON  [dbo].[arsumslp] TO [public]
GO
