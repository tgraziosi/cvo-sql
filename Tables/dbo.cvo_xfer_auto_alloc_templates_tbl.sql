CREATE TABLE [dbo].[cvo_xfer_auto_alloc_templates_tbl]
(
[priority] [int] NOT NULL,
[criteria_template_code] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[process_template_code] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_xfer_auto_alloc_templates_tbl] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_xfer_auto_alloc_templates_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_xfer_auto_alloc_templates_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_xfer_auto_alloc_templates_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_xfer_auto_alloc_templates_tbl] TO [public]
GO
