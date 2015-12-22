CREATE TABLE [dbo].[arinpstlhdr_all]
(
[timestamp] [timestamp] NOT NULL,
[settlement_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[hold_flag] [smallint] NOT NULL,
[posted_flag] [smallint] NOT NULL,
[date_entered] [int] NOT NULL,
[date_applied] [int] NOT NULL,
[user_id] [smallint] NOT NULL,
[process_group_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[doc_count_expected] [int] NOT NULL,
[doc_count_entered] [int] NOT NULL,
[doc_sum_expected] [float] NOT NULL,
[doc_sum_entered] [float] NOT NULL,
[cr_total_home] [float] NOT NULL,
[cr_total_oper] [float] NOT NULL,
[oa_cr_total_home] [float] NOT NULL,
[oa_cr_total_oper] [float] NOT NULL,
[cm_total_home] [float] NOT NULL,
[cm_total_oper] [float] NOT NULL,
[inv_total_home] [float] NOT NULL,
[inv_total_oper] [float] NOT NULL,
[disc_total_home] [float] NOT NULL,
[disc_total_oper] [float] NOT NULL,
[wroff_total_home] [float] NOT NULL,
[wroff_total_oper] [float] NOT NULL,
[onacct_total_home] [float] NOT NULL,
[onacct_total_oper] [float] NOT NULL,
[gain_total_home] [float] NOT NULL,
[gain_total_oper] [float] NOT NULL,
[loss_total_home] [float] NOT NULL,
[loss_total_oper] [float] NOT NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[batch_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rate_type_home] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_home] [float] NOT NULL,
[rate_type_oper] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_oper] [float] NOT NULL,
[inv_amt_nat] [float] NOT NULL,
[amt_doc_nat] [float] NOT NULL,
[amt_dist_nat] [float] NOT NULL,
[amt_on_acct] [float] NOT NULL,
[settle_flag] [smallint] NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [arinpstlhdr_all_ind_0] ON [dbo].[arinpstlhdr_all] ([settlement_ctrl_num]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [arinpstlhdr_all_ind_1] ON [dbo].[arinpstlhdr_all] ([settlement_ctrl_num], [customer_code]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[arinpstlhdr_all] TO [public]
GO
GRANT INSERT ON  [dbo].[arinpstlhdr_all] TO [public]
GO
GRANT DELETE ON  [dbo].[arinpstlhdr_all] TO [public]
GO
GRANT UPDATE ON  [dbo].[arinpstlhdr_all] TO [public]
GO
