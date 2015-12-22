CREATE TABLE [dbo].[rpt_glopi_eu_h]
(
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[debit] [float] NOT NULL,
[credit] [float] NOT NULL,
[beginning_balance] [float] NOT NULL,
[ending_balance] [float] NOT NULL,
[bal_fwd_flag] [smallint] NOT NULL,
[account_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[beginning_balance1] [float] NOT NULL,
[asteric] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_glopi_eu_h] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_glopi_eu_h] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_glopi_eu_h] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_glopi_eu_h] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_glopi_eu_h] TO [public]
GO
