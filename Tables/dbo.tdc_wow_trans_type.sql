CREATE TABLE [dbo].[tdc_wow_trans_type]
(
[userid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[all_trans_type] [int] NULL CONSTRAINT [DF__tdc_wow_t__all_t__233E8CE6] DEFAULT ((0)),
[trans_type] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_wow_trans_type_idx1] ON [dbo].[tdc_wow_trans_type] ([userid], [trans_type]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_wow_trans_type] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_wow_trans_type] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_wow_trans_type] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_wow_trans_type] TO [public]
GO
