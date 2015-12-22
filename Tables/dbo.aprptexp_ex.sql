CREATE TABLE [dbo].[aprptexp_ex]
(
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[voucher_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[amt_dist] [float] NOT NULL,
[gl_exp_acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[aprptexp_ex] TO [public]
GO
GRANT SELECT ON  [dbo].[aprptexp_ex] TO [public]
GO
GRANT INSERT ON  [dbo].[aprptexp_ex] TO [public]
GO
GRANT DELETE ON  [dbo].[aprptexp_ex] TO [public]
GO
GRANT UPDATE ON  [dbo].[aprptexp_ex] TO [public]
GO
