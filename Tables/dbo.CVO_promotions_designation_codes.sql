CREATE TABLE [dbo].[CVO_promotions_designation_codes]
(
[promo_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[promo_level] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[line_no] [int] NOT NULL,
[designation_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CVO_promotions_designation_codes_inx01] ON [dbo].[CVO_promotions_designation_codes] ([promo_id], [promo_level], [line_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[CVO_promotions_designation_codes] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_promotions_designation_codes] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_promotions_designation_codes] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_promotions_designation_codes] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_promotions_designation_codes] TO [public]
GO
