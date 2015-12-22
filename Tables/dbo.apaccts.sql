CREATE TABLE [dbo].[apaccts]
(
[timestamp] [timestamp] NOT NULL,
[posting_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ap_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[purc_ret_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[freight_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[disc_taken_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[disc_given_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[restock_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[misc_chg_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sales_tax_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tax_rounding_acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cash_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[dm_on_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[suspense_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[a_ap_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[a_purc_ret_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[a_freight_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[a_disc_taken_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[a_disc_given_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[a_restock_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[a_misc_chg_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[a_sales_tax_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[a_tax_rounding_acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[a_dm_on_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[a_suspense_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [apaccts_ind_0] ON [dbo].[apaccts] ([posting_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[apaccts] TO [public]
GO
GRANT SELECT ON  [dbo].[apaccts] TO [public]
GO
GRANT INSERT ON  [dbo].[apaccts] TO [public]
GO
GRANT DELETE ON  [dbo].[apaccts] TO [public]
GO
GRANT UPDATE ON  [dbo].[apaccts] TO [public]
GO
