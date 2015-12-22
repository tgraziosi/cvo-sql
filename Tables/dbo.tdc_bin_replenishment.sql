CREATE TABLE [dbo].[tdc_bin_replenishment]
(
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[replenish_min_lvl] [decimal] (20, 0) NOT NULL,
[replenish_max_lvl] [decimal] (20, 0) NOT NULL,
[replenish_qty] [decimal] (20, 0) NOT NULL,
[last_modified_date] [datetime] NOT NULL,
[modified_by] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[auto_replen] [int] NULL CONSTRAINT [DF__tdc_bin_r__auto___60E6B9A4] DEFAULT ((0))
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_bin_replenishment] ADD CONSTRAINT [PK_tdc_bin_replenishment_1__17] PRIMARY KEY CLUSTERED  ([location], [bin_no], [part_no]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_bin_replenishment] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_bin_replenishment] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_bin_replenishment] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_bin_replenishment] TO [public]
GO
