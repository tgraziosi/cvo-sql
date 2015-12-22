CREATE TABLE [dbo].[rpt_gllvrehdr]
(
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[beginning_balance] [float] NOT NULL,
[beginning_balance_oper] [float] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_gllvrehdr] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_gllvrehdr] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_gllvrehdr] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_gllvrehdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_gllvrehdr] TO [public]
GO
