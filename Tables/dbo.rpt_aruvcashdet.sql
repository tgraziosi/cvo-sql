CREATE TABLE [dbo].[rpt_aruvcashdet]
(
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[apply_to_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[apply_trx_type] [smallint] NOT NULL,
[date_doc] [int] NOT NULL,
[trx_type_desc] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_inv] [float] NOT NULL,
[inv_amt_applied] [float] NOT NULL,
[line_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_tot_chg] [float] NOT NULL,
[inv_amt_disc_taken] [float] NOT NULL,
[wr_off_flag] [smallint] NOT NULL,
[amt_paid_to_date] [float] NOT NULL,
[void_flag] [smallint] NOT NULL,
[amt_tot_chg_paid_to_date] [float] NOT NULL,
[gain_home] [float] NOT NULL,
[gain_oper] [float] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[inv_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_applied] [float] NOT NULL,
[amt_disc_taken] [float] NOT NULL,
[amt_max_wr_off] [float] NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_aruvcashdet] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_aruvcashdet] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_aruvcashdet] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_aruvcashdet] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_aruvcashdet] TO [public]
GO
