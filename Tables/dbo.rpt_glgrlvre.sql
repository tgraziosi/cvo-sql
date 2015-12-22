CREATE TABLE [dbo].[rpt_glgrlvre]
(
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[journal_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_applied] [datetime] NULL,
[journal_description] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[balance] [float] NULL,
[nat_balance] [float] NULL,
[rate] [float] NULL,
[rate_oper] [float] NULL,
[trx_type_desc] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[document_2] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[journal_type] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[period_start] [datetime] NULL,
[period_end] [datetime] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_glgrlvre] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_glgrlvre] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_glgrlvre] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_glgrlvre] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_glgrlvre] TO [public]
GO
