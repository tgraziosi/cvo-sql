CREATE TABLE [dbo].[rpt_amstatuscode]
(
[status_code] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[status_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_amstatuscode] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_amstatuscode] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_amstatuscode] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_amstatuscode] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_amstatuscode] TO [public]
GO
