CREATE TABLE [dbo].[tdc_wow_part_location]
(
[userid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[all_partlocations] [int] NULL CONSTRAINT [DF__tdc_wow_p__all_p__15E491C8] DEFAULT ((0)),
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_wow_part_location_idx1] ON [dbo].[tdc_wow_part_location] ([userid], [part_no], [location]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_wow_part_location] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_wow_part_location] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_wow_part_location] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_wow_part_location] TO [public]
GO
