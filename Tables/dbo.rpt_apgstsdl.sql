CREATE TABLE [dbo].[rpt_apgstsdl]
(
[date_applied] [int] NULL,
[disc_taken_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tax_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[disc_amt_by_tax_code] [float] NULL,
[appyhdr_trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[apvodet_trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_apgstsdl] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_apgstsdl] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_apgstsdl] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_apgstsdl] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_apgstsdl] TO [public]
GO
