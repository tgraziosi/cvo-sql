CREATE TABLE [dbo].[rpt_invreconsum]
(
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[g_balance] [decimal] (20, 8) NULL,
[g_nat_balance] [decimal] (20, 8) NULL,
[g_balance_oper] [decimal] (20, 8) NULL,
[d_balance] [decimal] (20, 8) NULL,
[d_nat_balance] [decimal] (20, 8) NULL,
[d_balance_oper] [decimal] (20, 8) NULL,
[t_beginning_balance] [decimal] (20, 8) NULL,
[t_inv_amount] [decimal] (20, 8) NULL,
[t_ending_balance] [decimal] (20, 8) NULL,
[group_typ] [int] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_invreconsum] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_invreconsum] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_invreconsum] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_invreconsum] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_invreconsum] TO [public]
GO
