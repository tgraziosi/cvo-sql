CREATE TABLE [dbo].[tdc_carrier_code_filter_tbl]
(
[carrier_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[userid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[order_type] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_carrier_code_filter_tbl_indx1] ON [dbo].[tdc_carrier_code_filter_tbl] ([carrier_code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_carrier_code_filter_tbl_indx2] ON [dbo].[tdc_carrier_code_filter_tbl] ([order_type], [userid]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_carrier_code_filter_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_carrier_code_filter_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_carrier_code_filter_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_carrier_code_filter_tbl] TO [public]
GO
