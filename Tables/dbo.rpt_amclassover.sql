CREATE TABLE [dbo].[rpt_amclassover]
(
[classification_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_type_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[override_account_flag] [tinyint] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_amclassover] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_amclassover] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_amclassover] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_amclassover] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_amclassover] TO [public]
GO
