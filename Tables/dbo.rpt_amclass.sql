CREATE TABLE [dbo].[rpt_amclass]
(
[classification_code] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[classification_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[gl_override] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_amclass] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_amclass] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_amclass] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_amclass] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_amclass] TO [public]
GO
