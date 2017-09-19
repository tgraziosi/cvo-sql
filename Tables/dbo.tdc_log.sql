CREATE TABLE [dbo].[tdc_log]
(
[tran_date] [datetime] NOT NULL,
[UserID] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trans_source] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[module] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trans] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tran_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tran_ext] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[quantity] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[data] [varchar] (7500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_log_idx3] ON [dbo].[tdc_log] ([bin_no], [location]) WITH (ALLOW_PAGE_LOCKS=OFF) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_log_idx4] ON [dbo].[tdc_log] ([tran_date]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_log_idx1] ON [dbo].[tdc_log] ([tran_date], [location], [part_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_log_idx5_tag] ON [dbo].[tdc_log] ([tran_date], [trans]) INCLUDE ([bin_no], [data], [location], [lot_ser], [module], [part_no], [quantity], [tran_ext], [tran_no], [trans_source], [UserID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_log_idx2] ON [dbo].[tdc_log] ([tran_no], [tran_ext]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_log_idx7_carts] ON [dbo].[tdc_log] ([trans], [tran_date], [UserID]) INCLUDE ([tran_ext], [tran_no]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_log] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_log] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_log] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_log] TO [public]
GO
