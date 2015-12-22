CREATE TABLE [dbo].[lot_bin_phy]
(
[timestamp] [timestamp] NOT NULL,
[phy_no] [int] NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_tran] [datetime] NOT NULL,
[date_expires] [datetime] NOT NULL,
[qty] [decimal] (20, 8) NOT NULL,
[qty_physical] [decimal] (20, 8) NOT NULL,
[close_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[phy_batch] [int] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [binlotphy2] ON [dbo].[lot_bin_phy] ([phy_no]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [bin_lot_phy] ON [dbo].[lot_bin_phy] ([phy_no], [lot_ser], [phy_batch], [bin_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[lot_bin_phy] TO [public]
GO
GRANT SELECT ON  [dbo].[lot_bin_phy] TO [public]
GO
GRANT INSERT ON  [dbo].[lot_bin_phy] TO [public]
GO
GRANT DELETE ON  [dbo].[lot_bin_phy] TO [public]
GO
GRANT UPDATE ON  [dbo].[lot_bin_phy] TO [public]
GO
