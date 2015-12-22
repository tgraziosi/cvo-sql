CREATE TABLE [dbo].[tdc_wow_category]
(
[userid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[all_categories] [int] NULL CONSTRAINT [DF__tdc_wow_c__all_c__17CCDA3A] DEFAULT ((0)),
[category] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_wow_category_idx1] ON [dbo].[tdc_wow_category] ([userid], [category]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_wow_category] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_wow_category] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_wow_category] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_wow_category] TO [public]
GO
