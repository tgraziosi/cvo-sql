CREATE TABLE [dbo].[tdc_ei_performance_log]
(
[start_tran] [datetime] NULL CONSTRAINT [DF__tdc_ei_pe__start__2F1A53E6] DEFAULT (getdate()),
[actual_date] [datetime] NULL CONSTRAINT [DF__tdc_ei_pe__actua__300E781F] DEFAULT (getdate()),
[stationid] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[userid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tran_type] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__tdc_ei_pe__tran___31029C58] DEFAULT ('N/A'),
[trans] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cust_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__tdc_ei_pe__cust___31F6C091] DEFAULT ('N/A'),
[carton_no] [int] NULL,
[tran_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tran_ext] [int] NULL CONSTRAINT [DF__tdc_ei_pe__tran___32EAE4CA] DEFAULT ((0)),
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[quantity] [decimal] (20, 8) NULL CONSTRAINT [DF__tdc_ei_pe__quant__33DF0903] DEFAULT ((0)),
[rowid] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_ei_performance_log_idx01] ON [dbo].[tdc_ei_performance_log] ([actual_date]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_ei_performance_log_idx02] ON [dbo].[tdc_ei_performance_log] ([trans], [carton_no], [stationid], [userid], [tran_no], [tran_ext], [rowid]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_ei_performance_log] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_ei_performance_log] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_ei_performance_log] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_ei_performance_log] TO [public]
GO
