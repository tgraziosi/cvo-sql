CREATE TABLE [dbo].[tdc_tx_print_detail_config]
(
[module] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trans] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trans_source] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[format_id] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[detail_lines] [int] NOT NULL,
[print_detail_sort] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_tx_print_detail_config] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_tx_print_detail_config] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_tx_print_detail_config] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_tx_print_detail_config] TO [public]
GO
