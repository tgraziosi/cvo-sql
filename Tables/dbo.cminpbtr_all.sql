CREATE TABLE [dbo].[cminpbtr_all]
(
[timestamp] [timestamp] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_applied] [int] NOT NULL,
[date_document] [int] NOT NULL,
[date_entered] [int] NOT NULL,
[cash_acct_code_from] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cash_acct_code_to] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[currency_code_from] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[currency_code_to] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amount_from] [float] NOT NULL,
[amount_to] [float] NOT NULL,
[bank_charge_amt_from] [float] NOT NULL,
[bank_charge_amt_to] [float] NOT NULL,
[trx_type_cls_from] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type_cls_to] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[exchange_rate] [float] NOT NULL,
[hold_flag] [smallint] NOT NULL,
[prc_gl_flag] [smallint] NOT NULL,
[posted_flag] [smallint] NOT NULL,
[user_id] [smallint] NOT NULL,
[batch_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[process_group_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[to_reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[to_expense_account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[to_expense_reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[from_reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[from_expense_account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[from_expense_reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[from_org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[to_org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [cminpbtr_all_ind_0] ON [dbo].[cminpbtr_all] ([trx_ctrl_num], [doc_ctrl_num]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cminpbtr_all] TO [public]
GO
GRANT SELECT ON  [dbo].[cminpbtr_all] TO [public]
GO
GRANT INSERT ON  [dbo].[cminpbtr_all] TO [public]
GO
GRANT DELETE ON  [dbo].[cminpbtr_all] TO [public]
GO
GRANT UPDATE ON  [dbo].[cminpbtr_all] TO [public]
GO
