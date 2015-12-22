CREATE TABLE [dbo].[tdc_wo_pick]
(
[prod_no] [int] NOT NULL,
[prod_ext] [int] NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seq_no] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[line_no] [int] NOT NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dest_bin] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pick_qty] [decimal] (20, 8) NOT NULL,
[used_qty] [decimal] (20, 8) NOT NULL CONSTRAINT [DF__tdc_wo_pi__used___28034203] DEFAULT ((0.0)),
[tran_date] [datetime] NULL CONSTRAINT [DF__tdc_wo_pi__tran___28F7663C] DEFAULT (getdate())
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[tdc_upd_tdcwopick_trg] ON [dbo].[tdc_wo_pick] 
FOR UPDATE AS

DELETE FROM tdc_wo_pick WHERE pick_qty <= 0 AND used_qty <= 0

GO
CREATE NONCLUSTERED INDEX [tdc_wo_pick_ind2] ON [dbo].[tdc_wo_pick] ([prod_no], [prod_ext], [location], [line_no], [part_no], [lot_ser], [dest_bin]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_wo_pick_ind1] ON [dbo].[tdc_wo_pick] ([prod_no], [prod_ext], [location], [part_no], [lot_ser], [dest_bin]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_wo_pick] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_wo_pick] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_wo_pick] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_wo_pick] TO [public]
GO
