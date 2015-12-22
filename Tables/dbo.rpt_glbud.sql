CREATE TABLE [dbo].[rpt_glbud]
(
[timestamp] [timestamp] NOT NULL,
[budget_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[budget_description] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[reference_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[net_change] [float] NOT NULL,
[current_balance] [float] NOT NULL,
[net_change_oper] [float] NOT NULL,
[current_balance_oper] [float] NOT NULL,
[nat_net_change] [float] NOT NULL,
[nat_current_balance] [float] NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[period_end_date] [int] NOT NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[curr_precision] [smallint] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_glbud] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_glbud] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_glbud] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_glbud] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_glbud] TO [public]
GO
