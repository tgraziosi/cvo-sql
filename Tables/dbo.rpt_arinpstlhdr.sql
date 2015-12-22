CREATE TABLE [dbo].[rpt_arinpstlhdr]
(
[settlement_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[hold_flag] [smallint] NULL,
[date_entered] [int] NULL,
[date_applied] [int] NULL,
[user_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[doc_count_expected] [int] NULL,
[doc_count_entered] [int] NULL,
[doc_sum_expected] [float] NULL,
[doc_sum_entered] [float] NULL,
[cr_total_home] [float] NULL,
[cr_total_oper] [float] NULL,
[oa_cr_total_home] [float] NULL,
[oa_cr_total_oper] [float] NULL,
[cm_total_home] [float] NULL,
[cm_total_oper] [float] NULL,
[inv_total_home] [float] NULL,
[inv_total_oper] [float] NULL,
[disc_total_home] [float] NULL,
[disc_total_oper] [float] NULL,
[wroff_total_home] [float] NULL,
[wroff_total_oper] [float] NULL,
[onacct_total_home] [float] NULL,
[onacct_total_oper] [float] NULL,
[gain_total_home] [float] NULL,
[gain_total_oper] [float] NULL,
[loss_total_home] [float] NULL,
[loss_total_oper] [float] NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[batch_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[inv_amt_nat] [float] NULL,
[amt_doc_nat] [float] NULL,
[amt_dist_nat] [float] NULL,
[amt_on_acct] [float] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_arinpstlhdr] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_arinpstlhdr] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_arinpstlhdr] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_arinpstlhdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_arinpstlhdr] TO [public]
GO
