CREATE TABLE [dbo].[tdc_mwo_labor_tx]
(
[mwo_number] [int] NOT NULL,
[mwo_type] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[mwo_priority] [int] NOT NULL,
[mwo_status] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tradesperson_id_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tradesperson_skill_type] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tradesperson_skill_class] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tradesperson_hours] [decimal] (5, 2) NOT NULL,
[entered_by] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_mwo_labor_tx] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_mwo_labor_tx] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_mwo_labor_tx] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_mwo_labor_tx] TO [public]
GO
