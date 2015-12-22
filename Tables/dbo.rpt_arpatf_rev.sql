CREATE TABLE [dbo].[rpt_arpatf_rev]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rev_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[apply_amt] [float] NOT NULL,
[account_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_format_mask] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_arpatf_rev] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_arpatf_rev] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_arpatf_rev] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_arpatf_rev] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_arpatf_rev] TO [public]
GO
