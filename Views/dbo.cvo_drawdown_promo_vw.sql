SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Name:			cvo_drawdown_promo_vw.sql
Type:			View
Called From:	Enterprise
Description:	List valid drawndown promos
Developer:		Chris Tyler
Date:			1st November 2013

Revision History
v1.1 CT	17/01/2014 - Issue #864 - Change dividing character between id and level from '-' to '_'
*/

CREATE VIEW [dbo].[cvo_drawdown_promo_vw]
AS


SELECT 
	promo_id,
	promo_level,
	-- START v1.1
	promo_id + '_' + promo_level as full_promo,
	--promo_id + '-' + promo_level as full_promo,
	-- END v1.1
	promo_id + ' - ' + promo_level as full_promo_desc
FROM 
	dbo.CVO_promotions
WHERE
	ISNULL(void,'N') = 'N' 
	AND drawdown_promo = 1

GO
GRANT SELECT ON  [dbo].[cvo_drawdown_promo_vw] TO [public]
GO
