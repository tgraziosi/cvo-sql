CREATE TABLE [dbo].[tdc_master_pack_ctn_tbl]
(
[pack_no] [int] NOT NULL,
[carton_no] [int] NOT NULL,
[create_date] [datetime] NOT NULL,
[created_by] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_master_pack_ctn_tbl_idx2] ON [dbo].[tdc_master_pack_ctn_tbl] ([carton_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_master_pack_ctn_tbl_idx1] ON [dbo].[tdc_master_pack_ctn_tbl] ([pack_no], [carton_no]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_master_pack_ctn_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_master_pack_ctn_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_master_pack_ctn_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_master_pack_ctn_tbl] TO [public]
GO
