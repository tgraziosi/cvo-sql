CREATE TABLE [dbo].[arcrtran]
(
[timestamp] [timestamp] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cash_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [arcrtran_ind_0] ON [dbo].[arcrtran] ([trx_ctrl_num]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arcrtran] TO [public]
GO
GRANT SELECT ON  [dbo].[arcrtran] TO [public]
GO
GRANT INSERT ON  [dbo].[arcrtran] TO [public]
GO
GRANT DELETE ON  [dbo].[arcrtran] TO [public]
GO
GRANT UPDATE ON  [dbo].[arcrtran] TO [public]
GO
