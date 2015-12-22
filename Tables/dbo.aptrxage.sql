CREATE TABLE [dbo].[aptrxage]
(
[timestamp] [timestamp] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ref_id] [int] NOT NULL,
[apply_to_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[apply_trx_type] [smallint] NOT NULL,
[date_doc] [int] NOT NULL,
[date_applied] [int] NOT NULL,
[date_due] [int] NOT NULL,
[date_aging] [int] NOT NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pay_to_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[class_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[branch_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amount] [float] NOT NULL,
[amt_paid_to_date] [float] NOT NULL,
[cash_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[paid_flag] [smallint] NOT NULL,
[date_paid] [int] NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_home] [float] NOT NULL,
[rate_oper] [float] NOT NULL,
[journal_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [aptrxage_ind_1] ON [dbo].[aptrxage] ([apply_to_num], [apply_trx_type]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [aptrxage_ind_4] ON [dbo].[aptrxage] ([branch_code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [aptrxage_ind_3] ON [dbo].[aptrxage] ([class_code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [aptrxage_ind_6] ON [dbo].[aptrxage] ([doc_ctrl_num], [cash_acct_code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [aptrxage_ind_5] ON [dbo].[aptrxage] ([pay_to_code]) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [aptrxage_ind_0] ON [dbo].[aptrxage] ([trx_ctrl_num], [trx_type], [date_aging]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [aptrxage_ind_2] ON [dbo].[aptrxage] ([vendor_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[aptrxage] TO [public]
GO
GRANT SELECT ON  [dbo].[aptrxage] TO [public]
GO
GRANT INSERT ON  [dbo].[aptrxage] TO [public]
GO
GRANT DELETE ON  [dbo].[aptrxage] TO [public]
GO
GRANT UPDATE ON  [dbo].[aptrxage] TO [public]
GO
