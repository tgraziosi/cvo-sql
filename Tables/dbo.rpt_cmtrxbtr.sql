CREATE TABLE [dbo].[rpt_cmtrxbtr]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_document] [int] NOT NULL,
[batch_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cash_acct_code_from] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cash_acct_code_to] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[acct_code_trans_from] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[acct_code_trans_to] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[from_reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[to_reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[from_expense_reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[to_expense_reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_desc_from] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_desc_to] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_trans_desc_from] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_trans_desc_to] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[curr_code_from] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[curr_symbol_from] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[curr_precision_from] [smallint] NOT NULL,
[curr_code_to] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[curr_symbol_to] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[curr_precision_to] [smallint] NOT NULL,
[curr_trans_code_from] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[curr_trans_symbol_from] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[curr_trans_precision_from] [smallint] NOT NULL,
[curr_trans_code_to] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[curr_trans_symbol_to] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[curr_trans_precision_to] [smallint] NOT NULL,
[user_id] [smallint] NOT NULL,
[gl_trx_id] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_posted] [int] NOT NULL,
[date_applied] [int] NOT NULL,
[date_entered] [int] NOT NULL,
[trx_type_cls_from] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type_cls_to] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amount_from] [float] NOT NULL,
[amount_to] [float] NOT NULL,
[bank_charge_amt_from] [float] NOT NULL,
[bank_charge_amt_to] [float] NOT NULL,
[auto_rec_flag] [smallint] NOT NULL,
[hold_flag] [smallint] NOT NULL,
[user_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[from_org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[to_org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[from_region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_cmtrxbtr] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_cmtrxbtr] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_cmtrxbtr] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_cmtrxbtr] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_cmtrxbtr] TO [public]
GO
