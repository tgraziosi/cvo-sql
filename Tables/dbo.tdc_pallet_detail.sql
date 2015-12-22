CREATE TABLE [dbo].[tdc_pallet_detail]
(
[pallet] [int] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty] [decimal] (20, 8) NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_pallet_detail_idx1] ON [dbo].[tdc_pallet_detail] ([pallet], [part_no], [lot_ser]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_pallet_detail] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_pallet_detail] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_pallet_detail] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_pallet_detail] TO [public]
GO
