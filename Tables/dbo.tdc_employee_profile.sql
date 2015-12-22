CREATE TABLE [dbo].[tdc_employee_profile]
(
[lock_to_employee] [int] NOT NULL,
[employee_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[employee_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_employee_profile] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_employee_profile] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_employee_profile] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_employee_profile] TO [public]
GO
