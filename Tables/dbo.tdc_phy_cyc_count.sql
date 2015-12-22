CREATE TABLE [dbo].[tdc_phy_cyc_count]
(
[team_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[userid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cyc_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[child_serial_no] [int] NULL,
[adm_actual_qty] [decimal] (20, 8) NULL,
[tdc_actual_qty] [decimal] (20, 8) NULL,
[count_qty] [decimal] (20, 8) NULL,
[count_date] [datetime] NULL,
[cycle_date] [datetime] NULL CONSTRAINT [DF__tdc_phy_c__cycle__265003BB] DEFAULT (getdate()),
[post_qty] [decimal] (20, 8) NULL,
[post_pcs_qty] [decimal] (20, 8) NULL,
[post_ver] [int] NULL,
[post_pcs_ver] [tinyint] NULL,
[range_type] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[range_start] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[range_end] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_phy_cyc_count_idx3] ON [dbo].[tdc_phy_cyc_count] ([location], [part_no], [child_serial_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_phy_cyc_count_idx1] ON [dbo].[tdc_phy_cyc_count] ([location], [part_no], [lot_ser], [bin_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_phy_cyc_count_idx2] ON [dbo].[tdc_phy_cyc_count] ([post_ver], [adm_actual_qty]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_phy_cyc_count_idx4] ON [dbo].[tdc_phy_cyc_count] ([team_id], [userid], [location], [part_no], [lot_ser], [bin_no]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_phy_cyc_count] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_phy_cyc_count] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_phy_cyc_count] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_phy_cyc_count] TO [public]
GO
