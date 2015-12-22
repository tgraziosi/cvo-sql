CREATE TABLE [dbo].[rpt_aruwroffsum]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[settlement_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[batch_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[user_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_entered] [int] NOT NULL,
[date_applied] [int] NOT NULL,
[max_wr_off] [float] NOT NULL,
[amt_tot_chg] [float] NOT NULL,
[amt_paid_to_date] [float] NOT NULL,
[days_past_due] [int] NOT NULL,
[hold_flag] [smallint] NOT NULL,
[apply_to_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[balance] [float] NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_home] [float] NOT NULL,
[rate_oper] [float] NOT NULL,
[currency_mask] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[writeoff_code] [varchar] (13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[writeoff_amount] [float] NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_aruwroffsum] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_aruwroffsum] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_aruwroffsum] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_aruwroffsum] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_aruwroffsum] TO [public]
GO
