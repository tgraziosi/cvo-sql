CREATE TABLE [dbo].[tdc_wow_bin_group]
(
[userid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[all_bin_groups] [int] NULL CONSTRAINT [DF__tdc_wow_b__all_b__1D85B390] DEFAULT ((0)),
[group_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group_code_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_wow_bin_group_idx1] ON [dbo].[tdc_wow_bin_group] ([userid], [group_code], [group_code_id]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_wow_bin_group] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_wow_bin_group] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_wow_bin_group] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_wow_bin_group] TO [public]
GO
