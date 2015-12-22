CREATE TABLE [dbo].[tdc_machine_downtime_code]
(
[downtime_code] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[downtime_code_desc] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[downtime_code_type] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_machine_downtime_code_dx0] ON [dbo].[tdc_machine_downtime_code] ([downtime_code]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_machine_downtime_code] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_machine_downtime_code] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_machine_downtime_code] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_machine_downtime_code] TO [public]
GO
