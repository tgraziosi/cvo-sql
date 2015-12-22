SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[CVO_find_promo_sp]    Script Date: 08/18/2010  *****
SED009 -- AutoAllocation   
Object:      Procedure  CVO_find_promo_sp
Source file: CVO_find_promo_sp.sql
Author:		 Jesus Velazquez
Created:	 08/18/2010
Function:    
Modified:    
Calls:    
Called by:   
Copyright:   Epicor Software 2010.  All rights reserved. 
v1.1 CB 12/09/2010 - Add ISNULL to void field
v1.2 CT 29/10/2012 - Don't return subscription promos
v1.3 CT 30/10/2013 - Issue #1405 - Don't return promos which haven't started yet
v1.4 CT 05/11/2013 - Issue #864 - Don't return drawdown promos
*/
CREATE PROCEDURE [dbo].[CVO_find_promo_sp] @search VARCHAR(20), @sort VARCHAR(1), @today DATETIME AS
BEGIN
	SELECT @search = @search + '%'

	IF @sort = 'P'
		SELECT	CVO_promotions.promo_id,   
				CVO_promotions.promo_level,   
				CVO_promotions.promo_name,   
				CVO_promotions.promo_start_date,   
				CVO_promotions.promo_end_date  
		FROM	CVO_promotions  
		WHERE	CVO_promotions.promo_id LIKE @search AND
				CVO_promotions.promo_end_date >= @today AND
				CVO_promotions.promo_start_date <= @today AND -- v1.3
				ISNULL(CVO_promotions.void,'N') = 'N' -- v1.1
				AND ISNULL(CVO_promotions.subscription,0) = 0 -- v1.2
				AND ISNULL(CVO_promotions.drawdown_promo,0) = 0 -- v1.4
		ORDER BY CVO_promotions.promo_id

	IF @sort = 'L'
		SELECT	CVO_promotions.promo_id,   
				CVO_promotions.promo_level,   
				CVO_promotions.promo_name,   
				CVO_promotions.promo_start_date,   
				CVO_promotions.promo_end_date  
		FROM	CVO_promotions  
		WHERE	CVO_promotions.promo_level LIKE @search AND
				CVO_promotions.promo_end_date >= @today AND
				CVO_promotions.promo_start_date <= @today AND -- v1.3
				ISNULL(CVO_promotions.void,'N') = 'N' -- v1.1
				AND ISNULL(CVO_promotions.subscription,0) = 0 -- v1.2
				AND ISNULL(CVO_promotions.drawdown_promo,0) = 0 -- v1.4
		ORDER BY CVO_promotions.promo_level

	IF @sort = 'N'
		SELECT	CVO_promotions.promo_id,   
				CVO_promotions.promo_level,   
				CVO_promotions.promo_name,   
				CVO_promotions.promo_start_date,   
				CVO_promotions.promo_end_date  
		FROM	CVO_promotions  
		WHERE	CVO_promotions.promo_name LIKE @search AND
				CVO_promotions.promo_end_date >= @today AND
				CVO_promotions.promo_start_date <= @today AND -- v1.3
				ISNULL(CVO_promotions.void,'N') = 'N' -- v1.1
				AND ISNULL(CVO_promotions.subscription,0) = 0 -- v1.2
				AND ISNULL(CVO_promotions.drawdown_promo,0) = 0 -- v1.4
		ORDER BY CVO_promotions.promo_name
	
END

-- Permissions
GO
GRANT EXECUTE ON  [dbo].[CVO_find_promo_sp] TO [public]
GO
