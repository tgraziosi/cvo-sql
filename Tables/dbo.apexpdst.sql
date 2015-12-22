CREATE TABLE [dbo].[apexpdst]
(
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[check_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cash_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[print_batch_num] [int] NOT NULL,
[payment_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[payment_type] [smallint] NOT NULL,
[voucher_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[amt_dist] [float] NOT NULL,
[gl_exp_acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[posted_flag] [smallint] NOT NULL,
[printed_flag] [smallint] NOT NULL,
[overflow_flag] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [apexpdst_ind_1] ON [dbo].[apexpdst] ([vendor_code], [check_num], [cash_acct_code]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [apexpdst_ind_0] ON [dbo].[apexpdst] ([vendor_code], [payment_num], [voucher_num], [sequence_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[apexpdst] TO [public]
GO
GRANT SELECT ON  [dbo].[apexpdst] TO [public]
GO
GRANT INSERT ON  [dbo].[apexpdst] TO [public]
GO
GRANT DELETE ON  [dbo].[apexpdst] TO [public]
GO
GRANT UPDATE ON  [dbo].[apexpdst] TO [public]
GO
