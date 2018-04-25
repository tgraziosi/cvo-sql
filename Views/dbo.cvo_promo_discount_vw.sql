SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[cvo_promo_discount_vw]
AS
	SELECT	a.promo_id, a.promo_level, MAX(CASE WHEN (ISNULL(b.list,'N') = 'Y' OR ISNULL(b.price_override,'N') = 'Y') THEN 1 ELSE 0 END) list
	FROM	cvo_promotions a (NOLOCK)
	LEFT JOIN CVO_line_discounts b (NOLOCK)
	ON		a.promo_id = b.promo_id
	AND		a.promo_level = b.promo_level
	GROUP BY a.promo_id, a.promo_level
GO
GRANT SELECT ON  [dbo].[cvo_promo_discount_vw] TO [public]
GO
