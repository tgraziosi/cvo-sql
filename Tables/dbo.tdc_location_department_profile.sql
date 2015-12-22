CREATE TABLE [dbo].[tdc_location_department_profile]
(
[location_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[department_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_location_department_profile] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_location_department_profile] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_location_department_profile] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_location_department_profile] TO [public]
GO
