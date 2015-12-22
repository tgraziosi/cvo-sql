CREATE TABLE [dbo].[CVO_drawdown_promo_qualified_lines]
(
[rec_id] [int] NOT NULL IDENTITY(1, 1),
[SPID] [int] NOT NULL,
[promo_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[promo_level] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[line_no] [int] NOT NULL,
[brand] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[category] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[gender_check] [smallint] NOT NULL,
[attribute] [smallint] NOT NULL,
[brand_exclude] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[category_exclude] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CVO_drawdown_promo_qualified_lines_inx02] ON [dbo].[CVO_drawdown_promo_qualified_lines] ([SPID], [promo_id], [promo_level]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CVO_drawdown_promo_qualified_lines_inx01] ON [dbo].[CVO_drawdown_promo_qualified_lines] ([SPID], [rec_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[CVO_drawdown_promo_qualified_lines] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_drawdown_promo_qualified_lines] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_drawdown_promo_qualified_lines] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_drawdown_promo_qualified_lines] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_drawdown_promo_qualified_lines] TO [public]
GO
