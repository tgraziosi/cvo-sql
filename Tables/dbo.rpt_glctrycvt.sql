CREATE TABLE [dbo].[rpt_glctrycvt]
(
[country_code] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[code] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[code_type] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[code_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[code_int] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_glctrycvt] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_glctrycvt] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_glctrycvt] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_glctrycvt] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_glctrycvt] TO [public]
GO
