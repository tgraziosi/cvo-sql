CREATE TABLE [dbo].[cvo_lot_bin_stock_exclusions]
(
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty] [decimal] (20, 8) NULL,
[non_allocating] [smallint] NULL,
[inv_exclude] [smallint] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_lot_bin_stock_exclusions_ind0] ON [dbo].[cvo_lot_bin_stock_exclusions] ([location], [bin_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_lot_bin_stock_exclusions_ind3] ON [dbo].[cvo_lot_bin_stock_exclusions] ([location], [bin_no], [inv_exclude]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_lot_bin_stock_exclusions_ind2] ON [dbo].[cvo_lot_bin_stock_exclusions] ([location], [bin_no], [non_allocating]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_lot_bin_stock_exclusions_ind1] ON [dbo].[cvo_lot_bin_stock_exclusions] ([location], [bin_no], [part_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_lot_bin_stock_exclusions_ind4] ON [dbo].[cvo_lot_bin_stock_exclusions] ([location], [bin_no], [part_no]) INCLUDE ([qty]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_lot_bin_exc_idx5] ON [dbo].[cvo_lot_bin_stock_exclusions] ([location], [part_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_lot_bin_stock_exclusions] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_lot_bin_stock_exclusions] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_lot_bin_stock_exclusions] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_lot_bin_stock_exclusions] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_lot_bin_stock_exclusions] TO [public]
GO
