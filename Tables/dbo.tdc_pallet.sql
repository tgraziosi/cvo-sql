CREATE TABLE [dbo].[tdc_pallet]
(
[pallet] [int] NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[mixed] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_pallet_idx2] ON [dbo].[tdc_pallet] ([location], [bin_no]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [tdc_pallet_idx1] ON [dbo].[tdc_pallet] ([pallet]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_pallet] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_pallet] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_pallet] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_pallet] TO [public]
GO
