CREATE TABLE [dbo].[tdc_custom_kits_packed_tbl]
(
[carton_no] [int] NOT NULL,
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL,
[line_no] [int] NOT NULL,
[kit_part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sub_kit_part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qty] [decimal] (24, 8) NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_custom_kits_packed_tbl_IDX1] ON [dbo].[tdc_custom_kits_packed_tbl] ([carton_no], [order_no], [order_ext], [line_no], [kit_part_no], [lot_ser], [bin_no], [qty]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_custom_kits_packed_tbl_IDX2] ON [dbo].[tdc_custom_kits_packed_tbl] ([carton_no], [order_no], [order_ext], [line_no], [kit_part_no], [sub_kit_part_no], [lot_ser], [bin_no], [qty]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_custom_kits_packed_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_custom_kits_packed_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_custom_kits_packed_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_custom_kits_packed_tbl] TO [public]
GO
