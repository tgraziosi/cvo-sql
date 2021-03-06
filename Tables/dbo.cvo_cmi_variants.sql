CREATE TABLE [dbo].[cvo_cmi_variants]
(
[id] [smallint] NOT NULL IDENTITY(1, 1),
[brand] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[model_id] [smallint] NULL,
[variant_name] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[color_family] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[color] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[temple_img] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[front_img] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[added_date] [datetime] NULL,
[asterisk_1] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[asterisk_2] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[isPolarizedAvailable] [smallint] NULL CONSTRAINT [DF__cvo_cmi_v__isPol__08B380C2] DEFAULT ('0'),
[isActive] [smallint] NULL CONSTRAINT [DF__cvo_cmi_v__isAct__6FE7D2F8] DEFAULT ('1'),
[lead_time] [int] NULL,
[product_description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[supplier_color_description] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[temple_color_description] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ws_material_moq] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ws_material_yield] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ws_alternative_styles] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ws_substitution_styles] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ws_lens_color_code] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[material_lead_time] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[asterisk_3] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[highres_front_img] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[highres_temple_img] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[highres_34_img] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[varImported] [smallint] NULL CONSTRAINT [DF__cvo_cmi_v__varIm__779643BD] DEFAULT ((0)),
[varImportDate] [datetime] NULL,
[varImportBy] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[variant_release_date] [datetime] NULL,
[nose_pad_color] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lens_color] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[nose_pads] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[isDefaultImage] [tinyint] NULL CONSTRAINT [DF__cvo_cmi_v__isDef__5D60D6E1] DEFAULT ((0)),
[var_asterisk_1] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[var_asterisk_2] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_cmi_variants] ADD CONSTRAINT [PK__cvo_cmi_variants__6EF3AEBF] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
