CREATE TABLE [dbo].[tdc_app_source]
(
[source] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_app_source] ADD CONSTRAINT [PK_tdc_app_source] PRIMARY KEY CLUSTERED  ([source]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_app_source] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_app_source] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_app_source] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_app_source] TO [public]
GO
