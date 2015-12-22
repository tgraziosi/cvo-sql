CREATE TABLE [dbo].[appystl_all]
(
[timestamp] [timestamp] NOT NULL,
[settlement_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pay_to_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_entered] [int] NOT NULL,
[date_applied] [int] NOT NULL,
[user_id] [smallint] NOT NULL,
[batch_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[process_group_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[state_flag] [smallint] NOT NULL,
[disc_total_home] [float] NOT NULL,
[disc_total_oper] [float] NOT NULL,
[debit_memo_total_home] [float] NOT NULL,
[debit_memo_total_oper] [float] NOT NULL,
[on_acct_pay_total_home] [float] NOT NULL,
[on_acct_pay_total_oper] [float] NOT NULL,
[payments_total_home] [float] NOT NULL,
[payments_total_oper] [float] NOT NULL,
[put_on_acct_total_home] [float] NOT NULL,
[put_on_acct_total_oper] [float] NOT NULL,
[gain_total_home] [float] NOT NULL,
[gain_total_oper] [float] NOT NULL,
[loss_total_home] [float] NOT NULL,
[loss_total_oper] [float] NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [appystl_all_ind_1] ON [dbo].[appystl_all] ([settlement_ctrl_num]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[appystl_all] TO [public]
GO
GRANT SELECT ON  [dbo].[appystl_all] TO [public]
GO
GRANT INSERT ON  [dbo].[appystl_all] TO [public]
GO
GRANT DELETE ON  [dbo].[appystl_all] TO [public]
GO
GRANT UPDATE ON  [dbo].[appystl_all] TO [public]
GO
