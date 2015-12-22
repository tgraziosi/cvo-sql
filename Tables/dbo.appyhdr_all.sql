CREATE TABLE [dbo].[appyhdr_all]
(
[timestamp] [timestamp] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[batch_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_posted] [int] NOT NULL,
[date_applied] [int] NOT NULL,
[date_doc] [int] NOT NULL,
[date_entered] [int] NOT NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pay_to_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[approval_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cash_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[payment_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[state_flag] [smallint] NOT NULL,
[void_flag] [smallint] NOT NULL,
[amt_net] [float] NOT NULL,
[amt_discount] [float] NOT NULL,
[amt_on_acct] [float] NOT NULL,
[payment_type] [smallint] NOT NULL,
[doc_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[user_id] [smallint] NOT NULL,
[journal_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[print_batch_num] [int] NOT NULL,
[process_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[currency_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_type_home] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_type_oper] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_home] [float] NOT NULL,
[rate_oper] [float] NOT NULL,
[payee_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[settlement_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [appyhdr_all_ind_1] ON [dbo].[appyhdr_all] ([doc_ctrl_num], [cash_acct_code]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [appyhdr_all_ind_0] ON [dbo].[appyhdr_all] ([trx_ctrl_num]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [appyhdr_all_ind_2] ON [dbo].[appyhdr_all] ([trx_ctrl_num], [settlement_ctrl_num]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[appyhdr_all] TO [public]
GO
GRANT INSERT ON  [dbo].[appyhdr_all] TO [public]
GO
GRANT DELETE ON  [dbo].[appyhdr_all] TO [public]
GO
GRANT UPDATE ON  [dbo].[appyhdr_all] TO [public]
GO
