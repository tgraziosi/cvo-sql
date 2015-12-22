CREATE TABLE [dbo].[tdc_slot_bin_moves]
(
[sel_flg] [smallint] NULL,
[tran_id] [int] NOT NULL,
[seq_no] [int] NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[from_bin] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[to_bin] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty] [decimal] (20, 8) NULL,
[msg] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_slot_bin_moves_idx1] ON [dbo].[tdc_slot_bin_moves] ([tran_id]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_slot_bin_moves] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_slot_bin_moves] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_slot_bin_moves] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_slot_bin_moves] TO [public]
GO
