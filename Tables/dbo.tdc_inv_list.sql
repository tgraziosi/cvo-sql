CREATE TABLE [dbo].[tdc_inv_list]
(
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[unit_height] [decimal] (20, 8) NULL,
[unit_length] [decimal] (20, 8) NULL,
[unit_width] [decimal] (20, 8) NULL,
[case_qty] [int] NULL,
[pack_qty] [int] NULL,
[pallet_qty] [int] NULL,
[pcsn_flag] [bit] NULL,
[version_capture] [bit] NULL,
[warranty_track] [bit] NULL,
[vendor_sn] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[one_step_recv] [bit] NULL CONSTRAINT [DF__tdc_inv_l__one_s__5357B45C] DEFAULT ((0)),
[wo_batch_track] [bit] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [tdc_inv_list_idx] ON [dbo].[tdc_inv_list] ([location], [part_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_inv_list_idx2] ON [dbo].[tdc_inv_list] ([part_no]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_inv_list] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_inv_list] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_inv_list] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_inv_list] TO [public]
GO
