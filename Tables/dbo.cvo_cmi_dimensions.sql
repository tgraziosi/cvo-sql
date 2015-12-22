CREATE TABLE [dbo].[cvo_cmi_dimensions]
(
[id] [smallint] NOT NULL IDENTITY(1, 1),
[model_id] [smallint] NULL,
[variant_id] [smallint] NULL,
[brand] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[isActive] [smallint] NULL,
[eye_size] [float] NULL,
[a_size] [float] NULL,
[b_size] [float] NULL,
[ed_size] [float] NULL,
[bridge_size] [float] NULL,
[temple_size] [float] NULL,
[overall_temple_length] [float] NULL,
[frame_cost] [float] NULL,
[front_cost] [float] NULL,
[temple_cost] [float] NULL,
[fit] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ws_ship1_qty] [int] NULL,
[ws_ship2_qty] [int] NULL,
[ws_ship3_qty] [int] NULL,
[ws_sale_sets] [int] NULL,
[ws_lead_demand_qty] [int] NULL,
[lens_color] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ws_vexpo_sets] [int] NULL,
[dimImported] [smallint] NULL CONSTRAINT [DF__cvo_cmi_d__dimIm__788A67F6] DEFAULT ((0)),
[dimImportDate] [datetime] NULL,
[dimImportBy] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ws_size_pattern] [smallint] NULL CONSTRAINT [DF__cvo_cmi_d__ws_si__54F974FB] DEFAULT ((0)),
[dim_unit] [char] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_cmi_d__dim_u__4E6FA059] DEFAULT ('mm'),
[dim_release_date] [datetime] NULL,
[dim_power] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_cmi_d__dim_p__5E54FB1A] DEFAULT ((0)),
[circum_size] [float] NULL,
[dim_eye_shape] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dim_asterisk] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_cmi_dimensions] ADD CONSTRAINT [PK__cvo_cmi_dimensio__1BC65536] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
