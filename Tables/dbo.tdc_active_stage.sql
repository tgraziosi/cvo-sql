CREATE TABLE [dbo].[tdc_active_stage]
(
[stage_no] [char] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_active_stage] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_active_stage] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_active_stage] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_active_stage] TO [public]
GO
