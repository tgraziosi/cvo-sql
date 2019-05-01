CREATE TABLE [dbo].[CVO_pop_gifts]
(
[promo_ID] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[promo_level] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[line_no] [int] NOT NULL,
[part] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty] [int] NULL,
[freq] [int] NULL,
[optional] [int] NULL CONSTRAINT [DF__CVO_pop_g__optio__3DA6CF82] DEFAULT ((0))
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [idx_CVO_pop_gifts] ON [dbo].[CVO_pop_gifts] ([promo_ID], [line_no], [promo_level]) ON [PRIMARY]
GO
GRANT DELETE ON  [dbo].[CVO_pop_gifts] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_pop_gifts] TO [public]
GO
GRANT REFERENCES ON  [dbo].[CVO_pop_gifts] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_pop_gifts] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_pop_gifts] TO [public]
GO
