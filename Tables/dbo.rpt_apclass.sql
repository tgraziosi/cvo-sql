CREATE TABLE [dbo].[rpt_apclass]
(
[class_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_apclass] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_apclass] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_apclass] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_apclass] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_apclass] TO [public]
GO
