CREATE TABLE [dbo].[tdc_location_profile]
(
[lock_to_location] [int] NOT NULL,
[location_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location_description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_location_profile] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_location_profile] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_location_profile] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_location_profile] TO [public]
GO
