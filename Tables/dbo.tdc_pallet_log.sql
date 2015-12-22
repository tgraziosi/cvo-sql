CREATE TABLE [dbo].[tdc_pallet_log]
(
[pallet] [int] NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty] [decimal] (20, 8) NOT NULL,
[mixed] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tran_date] [datetime] NOT NULL,
[UserID] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[module] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trans] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tran_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tran_ext] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_pallet_log_idx2] ON [dbo].[tdc_pallet_log] ([location], [part_no], [bin_no], [lot_ser]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_pallet_log_idx3] ON [dbo].[tdc_pallet_log] ([module], [trans], [tran_no], [tran_ext]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_pallet_log_idx1] ON [dbo].[tdc_pallet_log] ([pallet]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_pallet_log_idx4] ON [dbo].[tdc_pallet_log] ([tran_date], [UserID]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_pallet_log] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_pallet_log] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_pallet_log] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_pallet_log] TO [public]
GO
