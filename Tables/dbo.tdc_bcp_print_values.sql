CREATE TABLE [dbo].[tdc_bcp_print_values]
(
[row_id] [int] NULL,
[print_value] [varchar] (300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[time_spid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_bcp_print_values] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_bcp_print_values] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_bcp_print_values] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_bcp_print_values] TO [public]
GO
