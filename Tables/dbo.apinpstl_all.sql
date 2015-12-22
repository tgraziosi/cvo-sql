CREATE TABLE [dbo].[apinpstl_all]
(
[timestamp] [timestamp] NOT NULL,
[settlement_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pay_to_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[hold_flag] [smallint] NOT NULL,
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
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[nat_cur_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_count_expected] [int] NOT NULL,
[doc_count_entered] [int] NOT NULL,
[doc_sum_expected] [float] NOT NULL,
[doc_sum_entered] [float] NOT NULL,
[vo_total_home] [float] NOT NULL,
[vo_total_oper] [float] NOT NULL,
[rate_type_home] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_home] [float] NOT NULL,
[rate_type_oper] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_oper] [float] NOT NULL,
[vo_amt_nat] [float] NOT NULL,
[amt_doc_nat] [float] NOT NULL,
[amt_dist_nat] [float] NOT NULL,
[amt_on_acct] [float] NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [apinpstl_all_ind_1] ON [dbo].[apinpstl_all] ([settlement_ctrl_num]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[apinpstl_all] TO [public]
GO
GRANT SELECT ON  [dbo].[apinpstl_all] TO [public]
GO
GRANT INSERT ON  [dbo].[apinpstl_all] TO [public]
GO
GRANT DELETE ON  [dbo].[apinpstl_all] TO [public]
GO
GRANT UPDATE ON  [dbo].[apinpstl_all] TO [public]
GO
