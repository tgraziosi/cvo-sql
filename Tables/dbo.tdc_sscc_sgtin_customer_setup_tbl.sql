CREATE TABLE [dbo].[tdc_sscc_sgtin_customer_setup_tbl]
(
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_to_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[uom_filter] [int] NOT NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_sscc_sgtin_customer_setup_tbl_idx1] ON [dbo].[tdc_sscc_sgtin_customer_setup_tbl] ([customer_code], [ship_to_code]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_sscc_sgtin_customer_setup_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_sscc_sgtin_customer_setup_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_sscc_sgtin_customer_setup_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_sscc_sgtin_customer_setup_tbl] TO [public]
GO
