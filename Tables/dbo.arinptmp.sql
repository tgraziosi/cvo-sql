CREATE TABLE [dbo].[arinptmp]
(
[timestamp] [timestamp] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_doc] [int] NOT NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[payment_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_payment] [float] NOT NULL,
[prompt1_inp] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[prompt2_inp] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[prompt3_inp] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[prompt4_inp] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_disc_taken] [float] NOT NULL,
[cash_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [arinptmp_ind_0] ON [dbo].[arinptmp] ([customer_code], [trx_ctrl_num], [doc_ctrl_num]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arinptmp] TO [public]
GO
GRANT SELECT ON  [dbo].[arinptmp] TO [public]
GO
GRANT INSERT ON  [dbo].[arinptmp] TO [public]
GO
GRANT DELETE ON  [dbo].[arinptmp] TO [public]
GO
GRANT UPDATE ON  [dbo].[arinptmp] TO [public]
GO
