CREATE TABLE [dbo].[tdc_mach_wo_util_tx]
(
[machine_code] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[shift_date] [datetime] NOT NULL,
[shift_code] [int] NOT NULL,
[prod_no] [int] NOT NULL,
[prod_ext] [int] NOT NULL CONSTRAINT [DF__tdc_mach___prod___6946F57B] DEFAULT ((0)),
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[line_no] [int] NOT NULL,
[sequence_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tran_type] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tran_date] [datetime] NOT NULL,
[who] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty_good] [decimal] (20, 8) NOT NULL CONSTRAINT [DF__tdc_mach___qty_g__6A3B19B4] DEFAULT ((0)),
[qty_scrap] [decimal] (20, 8) NOT NULL CONSTRAINT [DF__tdc_mach___qty_s__6B2F3DED] DEFAULT ((0)),
[scrap_adj_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[scrap_reason_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[hours_run] [decimal] (20, 8) NULL CONSTRAINT [DF__tdc_mach___hours__6C236226] DEFAULT ((0)),
[hours_down] [decimal] (20, 8) NULL CONSTRAINT [DF__tdc_mach___hours__6D17865F] DEFAULT ((0)),
[downtime_code] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[change_over_count] [int] NULL CONSTRAINT [DF__tdc_mach___chang__6E0BAA98] DEFAULT ((0))
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [mach_wo_util_idx01] ON [dbo].[tdc_mach_wo_util_tx] ([machine_code], [part_type], [shift_date], [shift_code], [location]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [mach_wo_util_idx02] ON [dbo].[tdc_mach_wo_util_tx] ([machine_code], [shift_date], [shift_code], [location]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [mach_wo_util_idx03] ON [dbo].[tdc_mach_wo_util_tx] ([prod_no], [prod_ext], [sequence_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [mach_wo_util_idx04] ON [dbo].[tdc_mach_wo_util_tx] ([prod_no], [prod_ext], [sequence_no], [location]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [mach_wo_util_idx05] ON [dbo].[tdc_mach_wo_util_tx] ([prod_no], [prod_ext], [sequence_no], [shift_date], [shift_code], [location]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_mach_wo_util_tx] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_mach_wo_util_tx] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_mach_wo_util_tx] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_mach_wo_util_tx] TO [public]
GO
