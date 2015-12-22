CREATE TABLE [dbo].[apinptmp]
(
[timestamp] [timestamp] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_applied] [int] NOT NULL,
[date_doc] [int] NOT NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[payment_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[code_1099] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cash_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_payment] [float] NOT NULL,
[amt_disc_taken] [float] NOT NULL,
[payment_type] [smallint] NOT NULL,
[approval_flag] [smallint] NOT NULL,
[user_id] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [apinptmp_ind_0] ON [dbo].[apinptmp] ([trx_ctrl_num]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[apinptmp] TO [public]
GO
GRANT SELECT ON  [dbo].[apinptmp] TO [public]
GO
GRANT INSERT ON  [dbo].[apinptmp] TO [public]
GO
GRANT DELETE ON  [dbo].[apinptmp] TO [public]
GO
GRANT UPDATE ON  [dbo].[apinptmp] TO [public]
GO
