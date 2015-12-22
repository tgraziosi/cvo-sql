SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO








 

create procedure [dbo].[adm_upd_SO_dtl_validate] 










as


-- if insert and so does not have lines.
	INSERT INTO #ewerror
	(module_id, err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 3700, tempd.SONumber, tempd.SONumber, tempd.LineNumber
	FROM #TEMPSOD tempd
	LEFT JOIN #TEMPSO temp ON tempd.SONumber = temp.SONumber
	WHERE temp.SONumber IS NULL 

-- if update and so_no is not found.
	INSERT INTO #ewerror
	(module_id, err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 3800, tempd.SONumber, tempd.SONumber, tempd.LineNumber
	FROM #TEMPSOD tempd
	INNER JOIN #TEMPSO temp ON tempd.SONumber = temp.SONumber
	LEFT JOIN ord_list pur ON tempd.SONumber = pur.order_no
	WHERE pur.order_no IS NULL


	INSERT INTO #ewerror
	(module_id, err_code, info, source, sequence_id)	
	SELECT DISTINCT 19000, 3900, tempd.SONumber, tempd.Type, tempd.LineNumber
	FROM #TEMPSOD tempd
	WHERE tempd.Type NOT IN ('P','M','X', 'V', 'C', 'E', 'J') AND tempd.Type IS NOT NULL


	INSERT INTO #ewerror
	(module_id, err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 4000, tempd.SONumber, tempd.PartNo, tempd.LineNumber
	FROM #TEMPSOD tempd
	INNER JOIN #TEMPSO temp ON tempd.SONumber = tempd.SONumber
	INNER JOIN orders pur (NOLOCK) ON tempd.SONumber = pur.order_no
	LEFT JOIN inv_master inv (NOLOCK)ON tempd.PartNo = inv.part_no
	WHERE inv.part_no IS NULL AND tempd.PartNo IS NOT NULL
	AND tempd.Type ='P'



--update
	INSERT INTO #ewerror
	(module_id, err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 4100, tempd.SONumber, tempd.UnitOfMeasure, tempd.LineNumber
	FROM #TEMPSOD tempd
	LEFT JOIN uom_table uom (NOLOCK) ON (tempd.PartNo = uom.item OR uom.item = 'STD') 
	INNER JOIN #TEMPSO temp ON tempd.SONumber = temp.SONumber
	WHERE uom.item IS NULL AND tempd.UnitOfMeasure IS NOT NULL
	UNION ALL
	SELECT DISTINCT 19000, 4100, tempd.SONumber, tempd.UnitOfMeasure, tempd.LineNumber
	FROM #TEMPSOD tempd
	LEFT JOIN uom_list uom (NOLOCK) ON  tempd.UnitOfMeasure = uom.uom
	INNER JOIN #TEMPSO temp ON tempd.SONumber = temp.SONumber
	WHERE uom.uom IS NULL AND tempd.UnitOfMeasure IS NOT NULL


--update 
	INSERT INTO #ewerror
	(module_id, err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 4200, tempd.SONumber, tempd.Quantity, tempd.LineNumber
	FROM #TEMPSOD tempd
	INNER JOIN #TEMPSO temp ON tempd.SONumber = temp.SONumber
	WHERE tempd.Quantity < 1 AND tempd.Quantity IS NOT NULL


-- update
	INSERT INTO #ewerror
	(module_id, err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 4300, tempd.SONumber, tempd.Loc, tempd.LineNumber
	FROM #TEMPSOD tempd
	INNER JOIN #TEMPSO temp ON tempd.SONumber = temp.SONumber
	LEFT JOIN locations l (NOLOCK) ON tempd.Loc = l.location 
	WHERE l.location IS NULL AND tempd.Loc IS NOT NULL


-- update 
	INSERT INTO #ewerror
	(module_id, err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 4400, tempd.SONumber, tempd.Account, tempd.LineNumber
	FROM #TEMPSOD tempd
	INNER JOIN #TEMPSO temp ON tempd.SONumber = temp.SONumber 
	LEFT JOIN adm_glchart inv (NOLOCK) ON tempd.Account = inv.account_code
	WHERE inv.account_code IS NULL AND tempd.Account IS NOT NULL


	INSERT INTO #ewerror
	(module_id, err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 4500, tempd.SONumber, tempd.ItemDescription, tempd.LineNumber
	FROM #TEMPSOD tempd
	INNER JOIN #TEMPSO temp ON tempd.SONumber = temp.SONumber
	WHERE tempd.ItemDescription = '' AND tempd.ItemDescription IS NOT NULL


	INSERT INTO #ewerror
	(module_id, err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 6700, temp.SONumber, temp.SONumber, 0
	FROM #TEMPSO temp
	INNER JOIN #TEMPSOD tempd ON temp.SONumber = tempd.SONumber
	INNER JOIN orders pur (NOLOCK) ON temp.SONumber = pur.order_no
	INNER JOIN ord_list pl (NOLOCK) ON temp.SONumber = pl.order_no
	WHERE ISNULL(temp.Blanket, pur.blanket ) = 'Y'
	GROUP BY temp.SONumber, ISNULL(temp.BlanketAmount, pur.blanket_amt)
	HAVING ISNULL(temp.BlanketAmount, pur.blanket_amt) < sum((ISNULL(tempd.Quantity, pl.ordered) * ISNULL(tempd.Price, pl.price) ))











/**/                                              
GO
GRANT EXECUTE ON  [dbo].[adm_upd_SO_dtl_validate] TO [public]
GO
