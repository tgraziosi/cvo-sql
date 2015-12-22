CREATE TABLE [dbo].[tdc_department_profile]
(
[department_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[department_description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_department_profile] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_department_profile] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_department_profile] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_department_profile] TO [public]
GO
