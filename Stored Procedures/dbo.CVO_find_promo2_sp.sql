SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.1 CT 11/09/2013 - Issue #1354 - add option to only return current promos

-- EXEC CVO_find_promo2_sp '', P, 1

CREATE PROCEDURE [dbo].[CVO_find_promo2_sp]	@search		VARCHAR(20), 
											@sort		VARCHAR(1),
											@current	SMALLINT = 0 -- v1.1

AS
BEGIN
	SELECT @search = @search + '%'

	IF @sort = 'P'
		SELECT	CVO_promotions.promo_id,   
				CVO_promotions.promo_level,   
				CVO_promotions.promo_name,   
				CVO_promotions.promo_start_date,   
				CVO_promotions.promo_end_date  
		FROM	CVO_promotions  
		WHERE	CVO_promotions.promo_id LIKE @search 
				-- START v1.1
				AND ((@current = 0 OR (@current <> 0 AND GETDATE() BETWEEN promo_start_date AND DATEADD(dd,1,promo_end_date))))
				-- END v1.1
		ORDER BY CVO_promotions.promo_id

	IF @sort = 'L'
		SELECT	CVO_promotions.promo_id,   
				CVO_promotions.promo_level,   
				CVO_promotions.promo_name,   
				CVO_promotions.promo_start_date,   
				CVO_promotions.promo_end_date  
		FROM	CVO_promotions  
		WHERE	CVO_promotions.promo_level LIKE @search 
				-- START v1.1
				AND ((@current = 0 OR (@current <> 0 AND GETDATE() BETWEEN promo_start_date AND DATEADD(dd,1,promo_end_date))))
				-- END v1.1
		ORDER BY CVO_promotions.promo_level

	IF @sort = 'N'
		SELECT	CVO_promotions.promo_id,   
				CVO_promotions.promo_level,   
				CVO_promotions.promo_name,   
				CVO_promotions.promo_start_date,   
				CVO_promotions.promo_end_date  
		FROM	CVO_promotions  
		WHERE	CVO_promotions.promo_name LIKE @search 
				-- START v1.1
				AND ((@current = 0 OR (@current <> 0 AND GETDATE() BETWEEN promo_start_date AND DATEADD(dd,1,promo_end_date))))
				-- END v1.1
		ORDER BY CVO_promotions.promo_name

END
GO
GRANT EXECUTE ON  [dbo].[CVO_find_promo2_sp] TO [public]
GO
