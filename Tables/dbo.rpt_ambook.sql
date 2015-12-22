CREATE TABLE [dbo].[rpt_ambook]
(
[book_code] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[book_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[depr_if_less_than_yr] [tinyint] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_ambook] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_ambook] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_ambook] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_ambook] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_ambook] TO [public]
GO
