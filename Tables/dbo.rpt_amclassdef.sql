CREATE TABLE [dbo].[rpt_amclassdef]
(
[company_id] [smallint] NOT NULL,
[classification_id] [int] NOT NULL,
[classification_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[acct_level] [tinyint] NOT NULL,
[start_col] [smallint] NOT NULL,
[length] [smallint] NOT NULL,
[override_default] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_amclassdef] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_amclassdef] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_amclassdef] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_amclassdef] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_amclassdef] TO [public]
GO
