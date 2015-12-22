CREATE TABLE [dbo].[tdc_bin_inventory]
(
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[company_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[warehouse_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[lot_no] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[batch_no] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty_available] [decimal] (20, 8) NOT NULL,
[qty_reserved] [decimal] (20, 8) NOT NULL,
[first_in_date] [datetime] NOT NULL,
[last_in_tx_date] [datetime] NULL,
[last_in_tx_qty] [decimal] (20, 8) NULL,
[last_in_tx_code] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[last_in_tx_no] [int] NULL,
[last_in_tx_ext] [int] NULL,
[last_in_tx_by] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[last_out_tx_date] [datetime] NULL,
[last_out_tx_qty] [decimal] (20, 8) NULL,
[last_out_tx_code] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[last_out_tx_no] [int] NULL,
[last_out_tx_ext] [int] NULL,
[last_out_tx_by] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_bin_inventory] ADD CONSTRAINT [PK_tdc_bin_inventory_1__17] PRIMARY KEY CLUSTERED  ([bin_no], [company_no], [location], [warehouse_no], [part_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_bin_inventory_idx01] ON [dbo].[tdc_bin_inventory] ([bin_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_bin_inventory_idx02] ON [dbo].[tdc_bin_inventory] ([part_no]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_bin_inventory] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_bin_inventory] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_bin_inventory] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_bin_inventory] TO [public]
GO
