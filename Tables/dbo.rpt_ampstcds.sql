CREATE TABLE [dbo].[rpt_ampstcds]
(
[posting_code] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[posting_code_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_type_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account] [char] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_ampstcds] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_ampstcds] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_ampstcds] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_ampstcds] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_ampstcds] TO [public]
GO
