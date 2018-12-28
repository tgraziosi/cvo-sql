CREATE TABLE [dbo].[cvo_evite_program_filters]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[invite_key] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[filter_brands] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[filter_res_type] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[filter_demographic] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[filter_fit] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[filter_color_family] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[filter_eye_shape] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[filter_frame_type] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[filter_show_min_qty] [int] NULL,
[filter_order_min_qty] [int] NULL,
[filter_display_price] [tinyint] NULL CONSTRAINT [DF__cvo_evite__filte__349C8835] DEFAULT ((0)),
[filter_discount_type] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[filter_discount_offered] [int] NULL,
[email_content] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cc_evite] [tinyint] NULL CONSTRAINT [DF__cvo_evite__cc_ev__12126607] DEFAULT ((0)),
[isLive] [tinyint] NULL CONSTRAINT [DF__cvo_evite__isLiv__15E2F6EB] DEFAULT ((1)),
[filter_show_inv_avail] [tinyint] NULL CONSTRAINT [DF__cvo_evite__filte__52EC052B] DEFAULT ((0))
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_evite_program_filters] ADD CONSTRAINT [PK__cvo_evite_progra__33A863FC] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
