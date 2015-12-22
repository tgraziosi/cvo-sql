CREATE TABLE [dbo].[tdc_wow_location]
(
[userid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[all_locations] [int] NULL CONSTRAINT [DF__tdc_wow_l__all_l__13FC4956] DEFAULT ((0)),
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_wow_location_idx1] ON [dbo].[tdc_wow_location] ([userid], [location]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_wow_location] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_wow_location] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_wow_location] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_wow_location] TO [public]
GO
