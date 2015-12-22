CREATE TABLE [dbo].[tdc_wow_vendor]
(
[userid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[all_vendors] [int] NULL CONSTRAINT [DF__tdc_wow_v__all_v__1B9D6B1E] DEFAULT ((0)),
[vendor] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_wow_vendor_idx1] ON [dbo].[tdc_wow_vendor] ([userid], [vendor]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_wow_vendor] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_wow_vendor] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_wow_vendor] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_wow_vendor] TO [public]
GO
