CREATE TABLE [dbo].[tdc_sia_postal_code_filter_tbl]
(
[userid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[template_code] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[postal_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_sia_postal_code_filter_tbl_indx1] ON [dbo].[tdc_sia_postal_code_filter_tbl] ([userid], [template_code], [postal_code]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_sia_postal_code_filter_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_sia_postal_code_filter_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_sia_postal_code_filter_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_sia_postal_code_filter_tbl] TO [public]
GO
