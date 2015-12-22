CREATE TABLE [dbo].[tdc_mwo_trades_profile]
(
[tradesperson_id_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tradesperson_first_name] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tradesperson_last_name] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tradesperson_skill_type] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tradesperson_skill_class] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[status] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_mwo_trades_profile] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_mwo_trades_profile] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_mwo_trades_profile] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_mwo_trades_profile] TO [public]
GO
