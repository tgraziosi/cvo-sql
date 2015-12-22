CREATE TABLE [dbo].[tdc_edi_msg_layout_tbl]
(
[segment] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[fieldname] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[startpos] [int] NOT NULL,
[endpos] [int] NOT NULL,
[line_no] [int] NOT NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_edi_msg_layout_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_edi_msg_layout_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_edi_msg_layout_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_edi_msg_layout_tbl] TO [public]
GO
