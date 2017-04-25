CREATE TABLE [dbo].[CVO_free_frame_qualified]
(
[rec_id] [int] NOT NULL IDENTITY(1, 1),
[SPID] [int] NOT NULL,
[line_no] [int] NOT NULL,
[ff_min_qty] [int] NOT NULL,
[ff_min_frame] [smallint] NOT NULL,
[ff_min_sun] [smallint] NOT NULL,
[ff_max_free_qty] [int] NOT NULL,
[ff_max_free_frame] [smallint] NOT NULL,
[ff_max_free_sun] [smallint] NOT NULL,
[brand] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[category] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[gender_check] [smallint] NULL,
[attribute] [smallint] NULL,
[brand_exclude] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[category_exclude] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[promo_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[promo_level] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[min_qty] [int] NULL,
[max_qty] [int] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CVO_free_frame_qualified_inx01] ON [dbo].[CVO_free_frame_qualified] ([SPID], [rec_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[CVO_free_frame_qualified] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_free_frame_qualified] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_free_frame_qualified] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_free_frame_qualified] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_free_frame_qualified] TO [public]
GO
