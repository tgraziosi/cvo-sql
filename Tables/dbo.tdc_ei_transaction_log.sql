CREATE TABLE [dbo].[tdc_ei_transaction_log]
(
[begin_tran] [datetime] NULL,
[end_tran] [datetime] NULL CONSTRAINT [DF__tdc_ei_tr__end_t__35C75175] DEFAULT (getdate()),
[module] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trans] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[stationid] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__tdc_ei_tr__stati__36BB75AE] DEFAULT ('N/A'),
[userid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[num_of_trans] [int] NULL,
[price] [decimal] (20, 8) NULL,
[rowid] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_ei_transaction_log_idx02] ON [dbo].[tdc_ei_transaction_log] ([begin_tran]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_ei_transaction_log_idx01] ON [dbo].[tdc_ei_transaction_log] ([module], [trans], [location], [userid]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_ei_transaction_log_idx03] ON [dbo].[tdc_ei_transaction_log] ([rowid]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_ei_transaction_log] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_ei_transaction_log] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_ei_transaction_log] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_ei_transaction_log] TO [public]
GO
