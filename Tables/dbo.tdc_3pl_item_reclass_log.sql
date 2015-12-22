CREATE TABLE [dbo].[tdc_3pl_item_reclass_log]
(
[tran_date] [datetime] NOT NULL CONSTRAINT [DF__tdc_3pl_i__tran___13A7439B] DEFAULT (getdate()),
[trans] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[expert] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[orig_part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[reclass_part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qty] [decimal] (20, 8) NOT NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bin_group] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[uom] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[userid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[adj_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[issue_no] [int] NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_3pl_item_reclass_log_idx1] ON [dbo].[tdc_3pl_item_reclass_log] ([tran_date], [trans], [expert], [location], [orig_part_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_3pl_item_reclass_log_idx2] ON [dbo].[tdc_3pl_item_reclass_log] ([tran_date], [trans], [expert], [location], [reclass_part_no]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_3pl_item_reclass_log] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_3pl_item_reclass_log] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_3pl_item_reclass_log] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_3pl_item_reclass_log] TO [public]
GO
