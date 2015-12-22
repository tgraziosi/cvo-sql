CREATE TABLE [dbo].[tdc_3pl_labor_avail_transactions]
(
[category] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tran_id] [int] NOT NULL,
[transaction] [varchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[expert] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_filter_reqd] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__tdc_3pl_l__part___1683B046] DEFAULT ('Y')
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [tdc_3pl_labor_avail_transactions_idx1] ON [dbo].[tdc_3pl_labor_avail_transactions] ([category], [tran_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_3pl_labor_avail_transactions_idx3] ON [dbo].[tdc_3pl_labor_avail_transactions] ([expert]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_3pl_labor_avail_transactions_idx4] ON [dbo].[tdc_3pl_labor_avail_transactions] ([part_filter_reqd]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_3pl_labor_avail_transactions_idx2] ON [dbo].[tdc_3pl_labor_avail_transactions] ([transaction]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_3pl_labor_avail_transactions] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_3pl_labor_avail_transactions] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_3pl_labor_avail_transactions] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_3pl_labor_avail_transactions] TO [public]
GO
