CREATE TABLE [dbo].[rpt_aprptvad]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[rec_company_code_old] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rec_company_code_new] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[gl_exp_acct_old] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[gl_exp_acct_new] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[reference_code_old] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[reference_code_new] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[item_code] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[line_desc] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[unit_price] [float] NOT NULL,
[amt_discount] [float] NOT NULL,
[amt_extended] [float] NOT NULL,
[account_mask_old] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_mask_new] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_adjusted] [float] NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_aprptvad] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_aprptvad] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_aprptvad] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_aprptvad] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_aprptvad] TO [public]
GO
