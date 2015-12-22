CREATE TABLE [dbo].[rpt_artrxpyt]
(
[amt_disc_taken] [float] NOT NULL,
[inv_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[inv_cust_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pay_doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pay_cust_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[disc_taken_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[settlement_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sales_tax_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tax_type_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_tax] [float] NOT NULL,
[amt_tax_invoice] [float] NOT NULL,
[amt_invoice] [float] NOT NULL,
[prc_flag] [int] NOT NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_artrxpyt] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_artrxpyt] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_artrxpyt] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_artrxpyt] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_artrxpyt] TO [public]
GO
