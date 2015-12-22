CREATE TABLE [dbo].[apinppyt_all]
(
[timestamp] [timestamp] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[batch_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cash_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_entered] [int] NOT NULL,
[date_applied] [int] NOT NULL,
[date_doc] [int] NOT NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pay_to_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[approval_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[payment_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[payment_type] [smallint] NOT NULL,
[amt_payment] [float] NOT NULL,
[amt_on_acct] [float] NOT NULL,
[posted_flag] [smallint] NOT NULL,
[printed_flag] [smallint] NOT NULL,
[hold_flag] [smallint] NOT NULL,
[approval_flag] [smallint] NOT NULL,
[gen_id] [int] NOT NULL,
[user_id] [smallint] NOT NULL,
[void_type] [smallint] NOT NULL,
[amt_disc_taken] [float] NOT NULL,
[print_batch_num] [int] NOT NULL,
[company_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[process_group_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rate_type_home] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rate_type_oper] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rate_home] [float] NULL,
[rate_oper] [float] NULL,
[payee_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[settlement_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[doc_amount] [float] NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [apinppyt_all_ind_1] ON [dbo].[apinppyt_all] ([posted_flag], [date_applied]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [apinppyt_all_ind_2] ON [dbo].[apinppyt_all] ([trx_ctrl_num], [posted_flag], [date_applied]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [apinppyt_all_ind_4] ON [dbo].[apinppyt_all] ([trx_ctrl_num], [settlement_ctrl_num]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [apinppyt_all_ind_3] ON [dbo].[apinppyt_all] ([trx_type], [printed_flag]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[apinppyt_all] TO [public]
GO
GRANT SELECT ON  [dbo].[apinppyt_all] TO [public]
GO
GRANT INSERT ON  [dbo].[apinppyt_all] TO [public]
GO
GRANT DELETE ON  [dbo].[apinppyt_all] TO [public]
GO
GRANT UPDATE ON  [dbo].[apinppyt_all] TO [public]
GO
