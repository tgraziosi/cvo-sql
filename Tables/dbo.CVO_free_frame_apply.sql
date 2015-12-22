CREATE TABLE [dbo].[CVO_free_frame_apply]
(
[SPID] [int] NOT NULL,
[line_no] [int] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ordered] [decimal] (20, 8) NOT NULL,
[brand] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[category] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[style] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[gender] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[attribute] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[is_free] [smallint] NOT NULL,
[free_qty] [decimal] (20, 8) NOT NULL,
[split] [smallint] NOT NULL,
[price] [decimal] (20, 8) NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CVO_free_frame_apply_inx01] ON [dbo].[CVO_free_frame_apply] ([SPID], [line_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CVO_free_frame_apply_inx02] ON [dbo].[CVO_free_frame_apply] ([SPID], [part_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[CVO_free_frame_apply] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_free_frame_apply] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_free_frame_apply] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_free_frame_apply] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_free_frame_apply] TO [public]
GO
