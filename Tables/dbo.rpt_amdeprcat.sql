CREATE TABLE [dbo].[rpt_amdeprcat]
(
[category_code] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[category_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[posting_code] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[posting_code_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[book_code] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[effective_date] [datetime] NOT NULL,
[depr_rule_code] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rule_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_amdeprcat] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_amdeprcat] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_amdeprcat] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_amdeprcat] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_amdeprcat] TO [public]
GO
