CREATE TABLE [dbo].[rpt_glopi_eu_d]
(
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[journal_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_applied] [int] NOT NULL,
[document_1] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[document_2] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[balance] [float] NOT NULL,
[balance_oper] [float] NOT NULL,
[period_start_date] [int] NOT NULL,
[period_end_date] [int] NOT NULL,
[period_description] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_glopi_eu_d] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_glopi_eu_d] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_glopi_eu_d] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_glopi_eu_d] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_glopi_eu_d] TO [public]
GO
