SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[cvo_style_status_changes_vw]
AS 
-- find any entries with the first active entry
SELECT new.*, 'new' src FROM 
(SELECT c.collection, c.style, c.color_desc, c.pom_date, c.tl, c.style_pom_status,'' AS [TB NOTES], '' AS [TG NOTES], 
c.qty_avl, c.in_stock, c.e12_wu, c.po_on_order, c.active, c.eff_date, c.obs_date, ROWNUM FROM  
(SELECT ROW_NUMBER() OVER(PARTITION BY collection, style, color_desc ORDER BY collection, style, color_desc, eff_date DESC) AS rownum,
 * FROM cvo_pom_tl_status
) AS c 
WHERE rownum =1
AND pom_date >= DATEADD(yy, -2, DATEADD(yy, DATEDIFF(yy,0, GETDATE()), 0))
AND c.obs_date >= DATEADD(mm, -2, DATEADD(mm, DATEDIFF(mm,0, GETDATE()), 0))
) AS new

WHERE NOT EXISTS 
(SELECT 1 FROM
(SELECT c.collection, c.style, c.color_desc, c.pom_date, c.tl, c.style_pom_status,'' AS [TB NOTES], '' AS [TG NOTES], 
c.qty_avl, c.in_stock, c.e12_wu, c.po_on_order, c.active, c.eff_date, c.obs_date, ROWNUM FROM  
(SELECT ROW_NUMBER() OVER(PARTITION BY collection, style, color_desc ORDER BY collection, style, color_desc, eff_date DESC) AS rownum,
 * FROM cvo_pom_tl_status
) AS c 
WHERE rownum > 1
AND pom_date >= DATEADD(yy, -2, DATEADD(yy, DATEDIFF(yy,0, GETDATE()), 0))
) AS previous
WHERE new.collection = previous.collection AND new.style = previous.style
	AND new.color_desc = previous.color_desc
	AND new.style_pom_status = previous.style_pom_status
)

UNION ALL

-- get the active piece of the changed tl status on the style
SELECT active.*, 'active' src FROM 
(SELECT c.collection, c.style, c.color_desc, c.pom_date, c.tl, c.style_pom_status,'' AS [TB NOTES], '' AS [TG NOTES],
c.qty_avl, c.in_stock, c.e12_wu, c.po_on_order,  c.active, c.eff_date, c.obs_date, ROWNUM FROM  
(SELECT ROW_NUMBER() OVER(PARTITION BY collection, style, color_desc ORDER BY collection, style, color_desc, eff_date DESC) AS rownum,
 * FROM cvo_pom_tl_status
) AS c 
WHERE rownum =1
AND pom_date >= DATEADD(yy, -2, DATEADD(yy, DATEDIFF(yy,0, GETDATE()), 0))
) AS active
INNER JOIN 
(SELECT c.collection, c.style, c.color_desc, c.pom_date, c.tl, c.style_pom_status,
ROWNUM FROM  
(SELECT ROW_NUMBER() OVER(PARTITION BY collection, style, color_desc ORDER BY collection, style, color_desc, eff_date DESC) AS rownum,
 * FROM cvo_pom_tl_status
) AS c 
WHERE rownum = 2
AND pom_date >= DATEADD(yy, -2, DATEADD(yy, DATEDIFF(yy,0, GETDATE()), 0))
) AS previous 
ON previous.collection = active.collection AND previous.style = active.style
	AND previous.color_desc = active.color_desc 
	-- and previous.pom_date = active.pom_date
	AND previous.tl <> active.tl

UNION ALL

-- get the last months piece of the changed tl status on the style
SELECT previous.* , 'previous' src FROM 
(SELECT c.collection, c.style, c.color_desc, c.pom_date, c.tl, c.style_pom_status,'' AS [TB NOTES], '' AS [TG NOTES],
c.qty_avl, c.in_stock, c.e12_wu, c.po_on_order, c.active, c.eff_date, c.obs_date, ROWNUM FROM  
(SELECT ROW_NUMBER() OVER(PARTITION BY collection, style, color_desc ORDER BY collection, style, color_desc, eff_date DESC) AS rownum,
 * FROM cvo_pom_tl_status
) AS c 
WHERE rownum =2
AND pom_date >= DATEADD(yy, -2, DATEADD(yy, DATEDIFF(yy,0, GETDATE()), 0))
) AS previous
INNER JOIN  
(SELECT c.collection, c.style, c.color_desc, c.pom_date, c.tl, c.style_pom_status, ROWNUM FROM  
(SELECT ROW_NUMBER() OVER(PARTITION BY collection, style, color_desc ORDER BY collection, style, color_desc, eff_date DESC) AS rownum,
 * FROM cvo_pom_tl_status
) AS c 
WHERE rownum =1
AND pom_date >= DATEADD(yy, -2, DATEADD(yy, DATEDIFF(yy,0, GETDATE()), 0))
) AS active 
ON previous.collection = active.collection AND previous.style = active.style
	AND previous.color_desc = active.color_desc 
	-- and previous.pom_date = active.pom_date
	AND previous.tl <> active.tl

-- order by collection, style, color_desc, eff_date
	 




GO
GRANT REFERENCES ON  [dbo].[cvo_style_status_changes_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_style_status_changes_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_style_status_changes_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_style_status_changes_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_style_status_changes_vw] TO [public]
GO
