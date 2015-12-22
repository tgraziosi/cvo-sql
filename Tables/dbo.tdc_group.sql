CREATE TABLE [dbo].[tdc_group]
(
[group_id] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trans_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (65) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_group] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_group] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_group] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_group] TO [public]
GO
