CREATE TABLE [dbo].[rpt_glnonfin]
(
[nonfin_budget_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[nonfin_budget_desc] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[period_end_date] [int] NOT NULL,
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[unit_of_measure] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[quantity] [float] NOT NULL,
[ytd_quantity] [float] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_glnonfin] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_glnonfin] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_glnonfin] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_glnonfin] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_glnonfin] TO [public]
GO
