CREATE TABLE [dbo].[tdc_machine_profile]
(
[machine_code] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[lock_to_resource] [int] NOT NULL,
[machine_description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_machine_profile] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_machine_profile] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_machine_profile] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_machine_profile] TO [public]
GO
