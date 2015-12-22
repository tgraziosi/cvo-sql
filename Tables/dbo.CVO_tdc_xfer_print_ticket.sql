CREATE TABLE [dbo].[CVO_tdc_xfer_print_ticket]
(
[row_id] [int] NOT NULL IDENTITY(1, 1),
[print_value] [varchar] (300) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[process_id] [int] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[CVO_tdc_xfer_print_ticket] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_tdc_xfer_print_ticket] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_tdc_xfer_print_ticket] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_tdc_xfer_print_ticket] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_tdc_xfer_print_ticket] TO [public]
GO
