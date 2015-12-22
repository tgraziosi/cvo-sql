CREATE TABLE [dbo].[tdc_bin_part_qty]
(
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qty] [decimal] (20, 8) NOT NULL CONSTRAINT [DF__tdc_bin_par__qty__5B2DE04E] DEFAULT ((0)),
[primary] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__tdc_bin_p__prima__5C220487] DEFAULT ('N'),
[seq_no] [int] NOT NULL CONSTRAINT [DF__tdc_bin_p__seq_n__5D1628C0] DEFAULT ((2))
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_bin_part_qty] ADD CONSTRAINT [pk_loc_bin_part] PRIMARY KEY NONCLUSTERED  ([location], [part_no], [bin_no]) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [RCM_tdc_bin_part_qty] ON [dbo].[tdc_bin_part_qty] ([part_no], [location], [seq_no], [bin_no]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_bin_part_qty] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_bin_part_qty] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_bin_part_qty] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_bin_part_qty] TO [public]
GO
