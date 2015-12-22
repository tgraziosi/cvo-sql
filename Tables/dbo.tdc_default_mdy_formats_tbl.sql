CREATE TABLE [dbo].[tdc_default_mdy_formats_tbl]
(
[language] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[mdy_format] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_def_mdy_format_idx1] ON [dbo].[tdc_default_mdy_formats_tbl] ([mdy_format], [language]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_default_mdy_formats_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_default_mdy_formats_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_default_mdy_formats_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_default_mdy_formats_tbl] TO [public]
GO
