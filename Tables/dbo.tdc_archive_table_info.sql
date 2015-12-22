CREATE TABLE [dbo].[tdc_archive_table_info]
(
[table_name] [varchar] (75) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[table_description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[last_archive_date] [datetime] NULL,
[archived_prior_to] [datetime] NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_archive_table_info] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_archive_table_info] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_archive_table_info] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_archive_table_info] TO [public]
GO
