SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.1 CT 07/08/2012 - Added logic to calculate correct discount for buying group promo discounts
-- v1.2 CB 24/09/2012 - Revert back to v1.0 as the list price is now correct for buying groups

CREATE VIEW [dbo].[CVO_disc_percent] 
AS

SELECT 
	c.order_no,    
	c.order_ext,   
	c.line_no,
	-- START v1.1
	-- Start v1.2
/*
	CASE 
		WHEN (c.orig_list_price = c.list_price) 
		THEN (CASE
				WHEN list_price = 0  THEN 0  
				 ELSE ROUND(((c.list_price - d.price)/c.list_price),2)
			  END)
		ELSE (CASE 
				WHEN c.orig_list_price = 0 THEN 0  
				ELSE ROUND(((c.orig_list_price - c.list_price)/c.orig_list_price),2)
			  END) 
	 END AS disc_perc
*/ 
	case
	when list_price = 0  then 0
		else
			ROUND(((c.list_price - d.price)/c.list_price),2)
		end
	 
	as disc_perc
	-- v1.2 End
	-- END v1.1
FROM 
	dbo.cvo_ord_list c(NOLOCK) 
JOIN 
	dbo.ord_list d (NOLOCK) 
ON  
	d.order_no = c.order_no 
	AND d.order_ext = c.order_ext 
	AND d.line_no = c.line_no




GO
GRANT REFERENCES ON  [dbo].[CVO_disc_percent] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_disc_percent] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_disc_percent] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_disc_percent] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_disc_percent] TO [public]
GO
