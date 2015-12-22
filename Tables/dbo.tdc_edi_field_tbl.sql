CREATE TABLE [dbo].[tdc_edi_field_tbl]
(
[fieldname] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[active] [int] NOT NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_edi_field_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_edi_field_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_edi_field_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_edi_field_tbl] TO [public]
GO
