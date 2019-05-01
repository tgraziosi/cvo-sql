CREATE TABLE [dbo].[CVO_bogo_apply]
(
[spid] [int] NOT NULL,
[line_no] [int] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ordered] [decimal] (20, 8) NOT NULL,
[brand] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[gender] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[attribute] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[is_free] [smallint] NOT NULL,
[free_qty] [decimal] (20, 8) NOT NULL,
[split] [smallint] NOT NULL,
[price] [decimal] (20, 8) NOT NULL,
[discount] [decimal] (20, 8) NOT NULL,
[error_desc] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[adt_brand] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[adt_gender] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[adt_attribute] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CVO_bogo_apply_ind01] ON [dbo].[CVO_bogo_apply] ([spid], [line_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CVO_bogo_apply_ind02] ON [dbo].[CVO_bogo_apply] ([spid], [part_no]) ON [PRIMARY]
GO
GRANT DELETE ON  [dbo].[CVO_bogo_apply] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_bogo_apply] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_bogo_apply] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_bogo_apply] TO [public]
GO
