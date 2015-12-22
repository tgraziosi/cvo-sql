SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                








 

create procedure [dbo].[adm_upd_SO_validate]





as



/***	INSERT INTO #ewerror
	(module_id,err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 1000, temp.SONumber, temp.SoldTo, 0 
	FROM #TEMPSO temp 
	LEFT JOIN adm_cust adm ON temp.SoldTo = adm.customer_code 
	WHERE adm.customer_code IS NULL AND temp.SoldTo IS NOT NULL
****/

	INSERT INTO #ewerror
	(module_id,err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 1000, temp.SONumber, temp.SoldTo, 0 
	FROM #TEMPSO temp
	INNER JOIN orders b ON temp.SONumber = order_no AND temp.SoldTo <> b.cust_code
	WHERE  temp.SoldTo IS NOT NULL

	INSERT INTO #ewerror
	(module_id, err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 1100, temp.SONumber, temp.ShipTo, 0
	FROM #TEMPSO temp
	INNER JOIN orders ord ON temp.SONumber = ord.order_no
	LEFT JOIN adm_shipto l ON temp.ShipTo = l.ship_to_code AND ord.cust_code = l.customer_code
	WHERE l.ship_to_code IS NULL AND temp.ShipTo IS NOT NULL


	INSERT INTO #ewerror
	(module_id, err_code, info, source, sequence_id)
	SELECT DISTINCT 19000,1200, temp.SONumber, temp.Carrier, 0
	FROM #TEMPSO temp
	LEFT JOIN arshipv ar ON temp.Carrier = ar.ship_via_code
	WHERE ar.ship_via_code IS NULL AND temp.Carrier IS NOT NULL


	INSERT INTO #ewerror
	(module_id, err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 1300, temp.SONumber, temp.Fob, 0
	FROM #TEMPSO temp
	LEFT JOIN arfob adm ON temp.Fob = adm.fob_code
	WHERE adm.fob_code IS NULL AND temp.Fob IS NOT NULL


	INSERT INTO #ewerror
	(module_id, err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 1500, temp.SONumber, temp.Terms, 0
	FROM #TEMPSO temp
	LEFT JOIN arterms adm ON temp.Terms = adm.terms_code
	WHERE adm.terms_code IS NULL AND temp.Terms IS NOT NULL


	INSERT INTO #ewerror
	(module_id, err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 1400, temp.SONumber, temp.Tax, 0
	FROM #TEMPSO temp
	LEFT JOIN adm_artax_vw adm ON temp.Tax = adm.tax_code 
	WHERE adm.tax_code IS NULL AND temp.Tax IS NOT NULL	


	INSERT INTO #ewerror
	(module_id, err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 1600, temp.SONumber, temp.PostingCode, 0
	FROM #TEMPSO temp
	LEFT JOIN araccts adm ON temp.PostingCode = adm.posting_code 
	WHERE adm.posting_code IS NULL AND temp.PostingCode IS NOT NULL


	INSERT INTO #ewerror
	(module_id, err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 2200, temp.SONumber, temp.SONumber, 0
	FROM #TEMPSO temp
	LEFT JOIN orders pur ON temp.SONumber = pur.order_no
	WHERE pur.order_no IS NULL 



	INSERT INTO #ewerror
	(module_id, err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 2300, temp.SONumber, temp.OrdCountry, 0
	FROM #TEMPSO temp
	LEFT JOIN gl_country glcon ON temp.OrdCountry = glcon.country_code
	WHERE glcon.country_code IS NULL AND temp.OrdCountry IS NOT NULL 	


	INSERT INTO #ewerror
	(module_id, err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 2400, temp.SONumber, temp.Currency, 0
	FROM #TEMPSO temp
	LEFT JOIN glcurr_vw vw ON temp.Currency = vw.currency_code
	WHERE vw.currency_code IS NULL AND temp.Currency IS NOT NULL


	INSERT INTO #ewerror
	(module_id, err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 2500, temp.SONumber, temp.SalesPerson, 0
	FROM #TEMPSO temp
	LEFT JOIN arsalesp b ON temp.SalesPerson = b.salesperson_code
	WHERE  b.salesperson_code IS NULL AND temp.SalesPerson <> '' AND temp.SalesPerson IS NOT NULL	


	INSERT INTO #ewerror
	(module_id, err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 1700, temp.SONumber, temp.UserStatus, 0
	FROM #TEMPSO temp
	LEFT JOIN so_usrstat b ON temp.UserStatus = b.user_stat_code --AND b.status_code = 'A'	
	WHERE  b.user_stat_code IS NULL AND temp.UserStatus <> '' AND temp.UserStatus IS NOT NULL





	INSERT INTO #ewerror
	(module_id, err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 2700, temp.SONumber, temp.Blanket, 0
	FROM #TEMPSO temp
	WHERE temp.Blanket NOT IN ('Y', 'N')
	AND temp.Blanket IS NOT NULL


	INSERT INTO #ewerror
	(module_id, err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 2800, temp.SONumber, temp.SONumber, 0
	FROM #TEMPSO temp
	INNER JOIN orders pur (nolock) ON temp.SONumber = pur.order_no 
	WHERE ISNULL(temp.Blanket, pur.blanket) = 'Y' AND ISNULL(temp.BlanketFrom, pur.from_date) IS NULL


	INSERT INTO #ewerror
	(module_id, err_code, info, source, sequence_id)	
	SELECT DISTINCT 19000, 2900, temp.SONumber, temp.SONumber, 0
	FROM #TEMPSO temp
	INNER JOIN orders pur (nolock) ON temp.SONumber = pur.order_no 
	WHERE ISNULL(temp.Blanket, pur.blanket) = 'Y' AND ISNULL(temp.BlanketTo, pur.to_date) IS NULL


	INSERT INTO #ewerror
	(module_id, err_code, info, source, sequence_id)	
	SELECT DISTINCT 19000, 1800, temp.SONumber, temp.BlanketAmount, 0
	FROM #TEMPSO temp
	INNER JOIN orders pur (nolock) ON temp.SONumber = pur.order_no 
	WHERE pur.blanket = 'Y' AND ISNULL(temp.BlanketAmount, pur.blanket_amt) IS NULL


/***	INSERT INTO #ewerror
	(module_id, err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 3000, temp.SONumber, temp.Location, 0
	FROM #TEMPSO temp
	LEFT JOIN locations b ON temp.Location = b.location
	WHERE  b.location IS NULL AND temp.Location IS NOT NULL	
***/
	INSERT INTO #ewerror
	(module_id, err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 3000, temp.SONumber, temp.Location, 0
	FROM #TEMPSO temp
	INNER JOIN orders b ON temp.SONumber = order_no AND temp.Location <> b.location
	WHERE  temp.Location IS NOT NULL

	INSERT INTO #ewerror
	(module_id, err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 3100, temp.SONumber, temp.BackOrder, 0
	FROM #TEMPSO temp
	WHERE temp.BackOrder NOT IN ('0', '1', '2') AND temp.BackOrder IS NOT NULL


	INSERT INTO #ewerror
	(module_id, err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 3200, temp.SONumber, temp.Category, 0
	FROM #TEMPSO temp
	LEFT JOIN so_usrcateg b ON temp.Category = b.category_code
	WHERE  b.category_code IS NULL AND temp.Category IS NOT NULL AND temp.Category <> ''


	INSERT INTO #ewerror
	(module_id, err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 3300, temp.SONumber, temp.SOPriority, 0
	FROM #TEMPSO temp
	WHERE temp.SOPriority NOT IN ('1','2','3','4','5','6','7','8','9','')
	AND temp.SOPriority IS NOT NULL


	INSERT INTO #ewerror
	(module_id, err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 3400, temp.SONumber, temp.Fowarder, 0
	FROM #TEMPSO temp
	LEFT JOIN arfwdr vw ON temp.Fowarder = vw.kys
	WHERE vw.kys IS NULL AND temp.Fowarder IS NOT NULL AND temp.Fowarder <> ''	


	INSERT INTO #ewerror
	(module_id, err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 3500, temp.SONumber, temp.FreightTo, 0
	FROM #TEMPSO temp
	LEFT JOIN arfrt_to vw ON temp.FreightTo = vw.kys
	WHERE vw.kys IS NULL AND temp.FreightTo IS NOT NULL AND temp.FreightTo <> ''	


	INSERT INTO #ewerror
	(module_id, err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 3600, temp.SONumber, temp.FreightType, 0
	FROM #TEMPSO temp
	LEFT JOIN freight_type vw ON temp.FreightType = vw.kys
	WHERE vw.kys IS NULL AND temp.FreightType IS NOT NULL AND temp.FreightType <> ''


	INSERT INTO #ewerror
	(module_id, err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 4600, temp.SONumber, temp.Hold, 0
	FROM #TEMPSO temp
	LEFT JOIN adm_oehold adm ON temp.Hold = adm.hold_code
	WHERE adm.hold_code IS NULL AND temp.Source IN (1,0)
	AND temp.Hold IS NOT NULL AND temp.Hold <> ''

	INSERT INTO #ewerror
	(module_id, err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 4600, temp.SONumber, temp.Hold, 0
	FROM #TEMPSO temp
	where temp.Source > 1


	INSERT INTO #ewerror
	(module_id, err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 5100, temp.SONumber, temp.Phone, 0
	FROM #TEMPSO temp
	WHERE ISNUMERIC(temp.Phone) = 0 
	AND temp.Phone IS NOT NULL 






	INSERT INTO #ewerror
	(module_id, err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 5200, temp.order_no, temp.payment_code, 0
	FROM #TEMPSOPAY temp
	INNER JOIN orders ord ON temp.order_no = ord.order_no
	INNER JOIN #TEMPSO temph ON temp.order_no = temph.SONumber
	LEFT JOIN arpymeth ar ON temp.payment_code = ar.payment_code
	WHERE ar.payment_code IS NULL AND temp.payment_code IS NOT NULL
	AND ISNULL(temph.Consolidate, ord.consolidate_flag) = 0


	INSERT INTO #ewerror
	(module_id, err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 6400, temp.order_no, temph.Consolidate, 0
	FROM #TEMPSOPAY temp
	INNER JOIN orders ord ON temp.order_no = ord.order_no
	INNER JOIN #TEMPSO temph ON temp.order_no = temph.SONumber
	AND ISNULL(temph.Consolidate, ord.consolidate_flag) = 1


	INSERT INTO #ewerror
	(module_id, err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 5300, temp.order_no, temp.amt_payment, 0
	FROM #TEMPSOPAY temp
	INNER JOIN orders ord ON temp.order_no = ord.order_no
	INNER JOIN #TEMPSO temph ON temp.order_no = temph.SONumber
	WHERE ISNULL(temp.amt_payment, 0) < 0 AND ISNULL(temph.Consolidate, ord.consolidate_flag) = 0 


	INSERT INTO #ewerror
	(module_id, err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 5400, temp.order_no, temp.amt_disc_taken, 0
	FROM #TEMPSOPAY temp
	INNER JOIN orders ord ON temp.order_no = ord.order_no
	INNER JOIN #TEMPSO temph ON temp.order_no = temph.SONumber
	WHERE ISNULL(temp.amt_disc_taken, 0) < 0 AND ISNULL(temph.Consolidate, ord.consolidate_flag) = 0 


	INSERT INTO #ewerror
	(module_id, err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 5500, temp.order_no, temp.salesperson, 0
	FROM #TEMPSOCO temp
	INNER JOIN #TEMPSO temph ON temp.order_no = temph.SONumber
	LEFT JOIN arsalesp ar ON temp.salesperson = ar.salesperson_code
	WHERE ar.salesperson_code IS NULL AND temp.salesperson IS NOT NULL


	INSERT INTO #ewerror
	(module_id, err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 5600, temp.order_no, temp.sales_comm, 0
	FROM #TEMPSOCO temp
	INNER JOIN #TEMPSO temph ON temp.order_no = temph.SONumber
	WHERE ISNULL(temp.sales_comm, 0) < 0   



	INSERT INTO #ewerror
	(module_id, err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 5800, temp.order_no, 0, 0
	FROM #TEMPSOPAY temp
	LEFT JOIN #TEMPSO temph ON temp.order_no = temph.SONumber
	WHERE temph.SONumber IS NULL and temp.order_no IS NOT NULL


	INSERT INTO #ewerror
	(module_id, err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 5900, temp.order_no, 0, 0
	FROM #TEMPSOCO temp
	LEFT JOIN #TEMPSO temph ON temp.order_no = temph.SONumber
	WHERE temph.SONumber IS NULL and temp.order_no IS NOT NULL


	INSERT INTO #ewerror
	(module_id, err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 6500, temp.order_no, 0, 0
	FROM #TEMPSOCO temp
	WHERE temp.display_line IS NULL



	INSERT INTO #ewerror
	(module_id, err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 6000, temp.order_no, temp.prompt2_inp, 0
	FROM #TEMPSOPAY temp
	INNER JOIN #TEMPSO  temph ON temp.order_no = temph.SONumber
	INNER JOIN icv_cctype icv (NOLOCK) ON temp.payment_code = icv.payment_code
	WHERE len(temp.prompt2_inp) <> icv.creditcard_length		
	

	INSERT INTO #ewerror
	(module_id, err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 6100, temp.order_no, temp.prompt2_inp, 0
	FROM #TEMPSOPAY temp
	INNER JOIN #TEMPSO  temph ON temp.order_no = temph.SONumber
	INNER JOIN icv_cctype icv (NOLOCK) ON temp.payment_code = icv.payment_code
	WHERE cast(temp.prompt2_inp as varchar(16)) NOT like cast(icv.creditcard_prefix as varchar(16) )+ '%'

	
	

	INSERT INTO #ewerror
	(module_id, err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 8000, tempre.order_no, tempre.order_no, 0
	FROM #TEMPSORE tempre 
	LEFT JOIN #TEMPSO temp ON tempre.order_no = temp.SONumber
	LEFT JOIN orders ord ON tempre.order_no = ord.order_no
	WHERE temp.SONumber IS NULL AND ord.order_no IS NULL


	INSERT INTO #ewerror
	(module_id,err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 7600, temp.order_no, temp.ext, 0 	
	FROM #TEMPSORE temp 
	INNER JOIN #TEMPSORE temp2 ON temp.key_table <> temp2.key_table 
	AND temp.order_no = temp2.order_no and temp.ext = temp2.ext
	

	INSERT INTO #ewerror
	(module_id,err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 7700, temp.order_no, temp.ord_detail_line, 0 	
	FROM #TEMPSORE temp 
	LEFT JOIN #TEMPSOD tempd ON temp.order_no = tempd.SONumber AND temp.ord_detail_line = tempd.LineNumber
	LEFT JOIN ord_list ord ON temp.order_no = ord.order_no AND temp.ord_detail_line = ord.line_no
	WHERE tempd.SONumber IS NULL AND ord.order_no IS NULL


	INSERT INTO #ewerror
	(module_id,err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 7800, temp.order_no, temp.sch_ship_date, 0 	
	FROM #TEMPSORE temp 
	INNER JOIN #TEMPSORE temp2 ON temp.order_no = temp2.order_no 
	AND temp.sch_ship_date = temp2.sch_ship_date 
	AND temp.key_table <> temp2.key_table 


	INSERT INTO #ewerror
	(module_id,err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 7900, temp.order_no, temp.ordered, 0 	
	FROM #TEMPSORE temp 
	WHERE temp.ordered < 0

	
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[adm_upd_SO_validate] TO [public]
GO
