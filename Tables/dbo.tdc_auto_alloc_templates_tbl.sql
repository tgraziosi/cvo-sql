CREATE TABLE [dbo].[tdc_auto_alloc_templates_tbl]
(
[priority] [int] NOT NULL,
[criteria_template_code] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[process_template_code] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_auto_alloc_templates_tbl] ADD CONSTRAINT [UQ__tdc_auto_alloc_t__50B051DB] UNIQUE NONCLUSTERED  ([priority]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [tdc_auto_alloc_templates_tbl_idx_1] ON [dbo].[tdc_auto_alloc_templates_tbl] ([criteria_template_code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_auto_alloc_templates_tbl_idx_2] ON [dbo].[tdc_auto_alloc_templates_tbl] ([criteria_template_code], [process_template_code]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_auto_alloc_templates_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_auto_alloc_templates_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_auto_alloc_templates_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_auto_alloc_templates_tbl] TO [public]
GO
