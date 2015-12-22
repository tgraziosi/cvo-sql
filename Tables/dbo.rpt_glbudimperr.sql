CREATE TABLE [dbo].[rpt_glbudimperr]
(
[budget_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[budget_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[error_code] [int] NOT NULL,
[err_desc] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_glbudimperr] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_glbudimperr] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_glbudimperr] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_glbudimperr] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_glbudimperr] TO [public]
GO
