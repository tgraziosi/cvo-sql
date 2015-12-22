CREATE TABLE [dbo].[tdc_stage_carton]
(
[carton_no] [int] NOT NULL,
[stage_no] [char] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tdc_ship_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[adm_ship_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tdc_ship_date] [datetime] NULL,
[adm_ship_date] [datetime] NULL,
[stage_error] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[master_pack] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_stage_carton] ADD CONSTRAINT [pk_tdc_stage_carton_1] PRIMARY KEY CLUSTERED  ([carton_no], [stage_no]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_stage_carton] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_stage_carton] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_stage_carton] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_stage_carton] TO [public]
GO
