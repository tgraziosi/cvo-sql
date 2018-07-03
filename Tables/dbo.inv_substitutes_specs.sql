CREATE TABLE [dbo].[inv_substitutes_specs]
(
[priority] [int] NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IMG_part_no] [varchar] (304) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[s_part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[s_IMG_part_no] [varchar] (304) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Collection] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[model] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PrimaryDemographic] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RES_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[frame_material] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[eye_shape] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ColorGroupCode] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[eye_size] [decimal] (20, 8) NULL,
[release_date] [datetime] NULL,
[pom_date] [datetime] NULL,
[s_collection] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[s_model] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[s_primarydemographic] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[s_res_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[s_frame_material] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[s_eye_shape] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[s_colorgroupcode] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[s_eye_size] [decimal] (20, 8) NULL,
[s_release_date] [datetime] NULL,
[s_pom_date] [datetime] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_part] ON [dbo].[inv_substitutes_specs] ([part_no]) INCLUDE ([s_part_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_s_part] ON [dbo].[inv_substitutes_specs] ([s_part_no]) INCLUDE ([part_no]) ON [PRIMARY]
GO
GRANT DELETE ON  [dbo].[inv_substitutes_specs] TO [public]
GO
GRANT INSERT ON  [dbo].[inv_substitutes_specs] TO [public]
GO
GRANT REFERENCES ON  [dbo].[inv_substitutes_specs] TO [public]
GO
GRANT SELECT ON  [dbo].[inv_substitutes_specs] TO [public]
GO
GRANT UPDATE ON  [dbo].[inv_substitutes_specs] TO [public]
GO
