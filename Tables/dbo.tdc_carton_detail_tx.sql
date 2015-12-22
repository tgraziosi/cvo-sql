CREATE TABLE [dbo].[tdc_carton_detail_tx]
(
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL,
[carton_no] [int] NOT NULL,
[tx_date] [datetime] NOT NULL,
[line_no] [int] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[price] [decimal] (18, 2) NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rec_date] [datetime] NULL,
[bom_line_no] [int] NULL,
[void] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pack_qty] [decimal] (24, 8) NOT NULL,
[serial_no] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[version_no] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tran_num] [int] NULL,
[warranty_track] [bit] NOT NULL CONSTRAINT [DF_tdc_carton_detail_tx_warranty_track] DEFAULT ((0)),
[serial_no_raw] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty_to_pack] [decimal] (24, 8) NOT NULL,
[pack_tx] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [tdc_carton_detail_idx_1] ON [dbo].[tdc_carton_detail_tx] ([carton_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_carton_detail_idx_6] ON [dbo].[tdc_carton_detail_tx] ([carton_no], [part_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_carton_detail_idx_2] ON [dbo].[tdc_carton_detail_tx] ([order_no], [order_ext]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_carton_detail_idx_3] ON [dbo].[tdc_carton_detail_tx] ([order_no], [order_ext], [part_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_carton_detail_idx_4] ON [dbo].[tdc_carton_detail_tx] ([order_no], [order_ext], [part_no], [line_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_carton_detail_idx_7] ON [dbo].[tdc_carton_detail_tx] ([part_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_carton_detail_idx_5] ON [dbo].[tdc_carton_detail_tx] ([tran_num], [serial_no]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_carton_detail_tx] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_carton_detail_tx] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_carton_detail_tx] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_carton_detail_tx] TO [public]
GO
