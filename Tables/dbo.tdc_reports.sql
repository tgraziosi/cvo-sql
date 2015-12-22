CREATE TABLE [dbo].[tdc_reports]
(
[category] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[report] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_reports] ADD CONSTRAINT [report_key] PRIMARY KEY CLUSTERED  ([category], [description]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_reports] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_reports] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_reports] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_reports] TO [public]
GO
