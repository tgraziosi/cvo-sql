CREATE TABLE [dbo].[apchkpar_ex]
(
[print_batch_num] [int] NOT NULL,
[print_acct_num] [int] NOT NULL,
[payment_memo] [int] NOT NULL,
[voucher_classification] [int] NOT NULL,
[voucher_memo] [int] NOT NULL,
[micr_font] [varchar] (256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sig_font] [varchar] (256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[logo_font] [varchar] (256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[apchkpar_ex] TO [public]
GO
GRANT SELECT ON  [dbo].[apchkpar_ex] TO [public]
GO
GRANT INSERT ON  [dbo].[apchkpar_ex] TO [public]
GO
GRANT DELETE ON  [dbo].[apchkpar_ex] TO [public]
GO
GRANT UPDATE ON  [dbo].[apchkpar_ex] TO [public]
GO
