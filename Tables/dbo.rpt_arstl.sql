CREATE TABLE [dbo].[rpt_arstl]
(
[settlement_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[curr_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_applied] [datetime] NULL,
[amt_orig] [float] NOT NULL,
[amt_app_this_trx] [float] NOT NULL,
[amt_app_prev] [float] NOT NULL,
[amt_remain_oa] [float] NOT NULL,
[home_oper_rate] [float] NOT NULL,
[home_oper_amt_app] [float] NOT NULL,
[home_oper_amt_remain_oa] [float] NOT NULL,
[disc] [float] NOT NULL,
[wr_off] [float] NOT NULL,
[gain] [float] NOT NULL,
[loss] [float] NOT NULL,
[nat_cur_symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_arstl] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_arstl] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_arstl] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_arstl] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_arstl] TO [public]
GO
