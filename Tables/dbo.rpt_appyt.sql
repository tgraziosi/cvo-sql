CREATE TABLE [dbo].[rpt_appyt]
(
[timestamp] [timestamp] NOT NULL,
[code_1099] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[form_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[field_desc] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[min_amt] [float] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_appyt] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_appyt] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_appyt] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_appyt] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_appyt] TO [public]
GO
