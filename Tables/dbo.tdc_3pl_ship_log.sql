CREATE TABLE [dbo].[tdc_3pl_ship_log]
(
[tran_date] [datetime] NOT NULL CONSTRAINT [DF__tdc_3pl_s__tran___27AE3C48] DEFAULT (getdate()),
[trans] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[expert] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tran_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tran_ext] [int] NULL,
[cust_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[freight_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[userid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_3pl_ship_log_idx1] ON [dbo].[tdc_3pl_ship_log] ([tran_date], [trans], [expert], [location]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_3pl_ship_log] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_3pl_ship_log] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_3pl_ship_log] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_3pl_ship_log] TO [public]
GO