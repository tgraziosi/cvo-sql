CREATE TABLE [dbo].[cvo_cmi_models]
(
[id] [smallint] NOT NULL IDENTITY(1, 1),
[brand] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[model_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RES_type] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[release_date] [datetime] NULL,
[front_price] [float] NULL,
[temple_price] [float] NULL,
[wholesale_price] [float] NULL,
[retail_price] [float] NULL,
[eye_shape] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fit] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[demographic] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[target_age] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[case_part] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[frame_category] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[front_material] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[temple_material] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[nose_pads] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[hinge_type] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[component_1] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[component_2] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[component_3] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[spare_temple_length] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[suns_only] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[notes] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[frame_cost] [float] NULL,
[front_cost] [float] NULL,
[temple_cost] [float] NULL,
[cable_price] [float] NULL,
[added_date] [datetime] NULL,
[progressive_type] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lens_base] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[temple_tip_material] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[nose_pad_partno] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[single_cable_cost] [float] NULL,
[country_origin] [char] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[modelImported] [smallint] NULL CONSTRAINT [DF__cvo_cmi_m__model__76A21F84] DEFAULT ((0)),
[modelImportDate] [datetime] NULL,
[modelImportBy] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[short_model] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[initial_ship_date] [datetime] NULL,
[catalog_ship_date] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[special_program] [varchar] (24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[supplier] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pattern_text] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[hinge_part_no] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[comp1_supplier] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[comp2_supplier] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[comp3_supplier] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[spare_cable_temple] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cost_currency] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[clips_available] [smallint] NULL CONSTRAINT [DF__cvo_cmi_m__clips__55ED9934] DEFAULT ((0)),
[model_lead_time] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[moq_model_color] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[stop_hinge] [tinyint] NULL CONSTRAINT [DF__cvo_cmi_m__stop___56E1BD6D] DEFAULT ('0'),
[alternative_styles] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[substitution_styles] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[product_description] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[hinge_smooth_supplier] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[hinge_smooth_movement] [smallint] NULL CONSTRAINT [DF__cvo_cmi_m__hinge__7CBE18E9] DEFAULT ('0'),
[material_composition] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[print_flag] [varchar] (24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[isEP] [tinyint] NULL CONSTRAINT [DF__cvo_cmi_mo__isEP__19617DA6] DEFAULT ((0)),
[frame_only] [tinyint] NULL CONSTRAINT [DF__cvo_cmi_m__frame__49D20CDC] DEFAULT ((0)),
[lens_cost] [float] NULL,
[lens_vendor] [varchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[frame_price] [float] NULL,
[frame_only_cost] [float] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_cmi_models] ADD CONSTRAINT [PK__cvo_cmi_models__6D0B664D] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
