CREATE TABLE [dbo].[TDC_templates]
(
[template_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[TDC_templates] TO [public]
GO
GRANT INSERT ON  [dbo].[TDC_templates] TO [public]
GO
GRANT DELETE ON  [dbo].[TDC_templates] TO [public]
GO
GRANT UPDATE ON  [dbo].[TDC_templates] TO [public]
GO
