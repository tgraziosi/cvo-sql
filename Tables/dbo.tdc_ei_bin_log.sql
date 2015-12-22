CREATE TABLE [dbo].[tdc_ei_bin_log]
(
[module] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trans] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tran_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tran_ext] [int] NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[from_bin] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[to_bin] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[begin_tran] [datetime] NULL CONSTRAINT [DF__tdc_ei_bi__begin__2C3DE73B] DEFAULT (getdate()),
[actual_date] [datetime] NOT NULL CONSTRAINT [DF__tdc_ei_bi__actua__2D320B74] DEFAULT (getdate()),
[quantity] [decimal] (20, 8) NULL,
[direction] [int] NULL,
[stationid] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[userid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rowid] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_ei_bin_log_idx01] ON [dbo].[tdc_ei_bin_log] ([module], [trans], [tran_no], [tran_ext], [location], [part_no], [from_bin], [direction], [userid]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_ei_bin_log] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_ei_bin_log] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_ei_bin_log] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_ei_bin_log] TO [public]
GO
