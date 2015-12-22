CREATE TABLE [dbo].[CVO_promotions_gender]
(
[promo_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[promo_level] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[line_no] [int] NOT NULL,
[line_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[gender] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CVO_promotions_gender_inx01] ON [dbo].[CVO_promotions_gender] ([promo_id], [promo_level], [line_no], [line_type]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[CVO_promotions_gender] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_promotions_gender] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_promotions_gender] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_promotions_gender] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_promotions_gender] TO [public]
GO
