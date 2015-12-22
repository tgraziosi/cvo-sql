SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2008 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2008 Epicor Software Corporation, 2008    
                  All Rights Reserved                    
*/                                                

CREATE PROCEDURE [dbo].[ATTaxProRate_sp] 
AS


DECLARE	@home_precision smallint,
	@oper_precision smallint

SELECT @home_precision = b.curr_precision, @oper_precision =  c.curr_precision
FROM glco a, glcurr_vw b, glcurr_vw c
WHERE a.home_currency = b.currency_code
AND a.oper_currency = c.currency_code

DECLARE @hdrdet_amts TABLE (invoice_no varchar(20), vendor_code varchar(12), 
	hdr_amt float, dtl_amt float, line_qty_amt int, prorrate_case int,
	prorate_flag int)
DECLARE @tableSum TABLE (invoice_no varchar(20), vendor_code varchar(12), sum_dtl float)
DECLARE @FactorDet TABLE (invoice_no varchar(20), vendor_code varchar(12), sequence_id int, prorrate_value float, prorrate_percentage float)
DECLARE @TblProRateBy TABLE (invoice_no varchar(20), vendor_code varchar(12), sequence_id int, prorate_value float)
DECLARE @tblRounding TABLE (invoice_no varchar(20), vendor_code varchar(12), hdr_amt float, sequence_id int, sum_amt_round float)











INSERT @hdrdet_amts (invoice_no, vendor_code, hdr_amt, 
	dtl_amt, line_qty_amt, prorrate_case,
	prorate_flag)
SELECT hdr.invoice_no, hdr.vendor_code, ROUND(hdr.amt_tax, @oper_precision), 
	ROUND(sum(det.amt_tax), @oper_precision), c.tax_per_1line_2qty_3amt, 0,
	hdr.at_tax_calc_flag 
FROM  #atmtchdr hdr, #atmtcdet det, #tbl_vendorconfig c
WHERE	hdr.invoice_no 	= det.invoice_no 
AND	hdr.vendor_code = det.vendor_code
AND	hdr.vendor_code = c.vendor_code
GROUP BY hdr.invoice_no, hdr.vendor_code, hdr.amt_tax, c.tax_per_1line_2qty_3amt,
	hdr.at_tax_calc_flag

IF (@@ROWCOUNT>0) 
BEGIN
	
	UPDATE @hdrdet_amts
	SET  prorrate_case = 1 
	WHERE hdr_amt != 0 AND dtl_amt !=0 
	
	
	UPDATE @hdrdet_amts
	SET  prorrate_case = 2 WHERE hdr_amt = 0 AND dtl_amt != 0
	
	
	UPDATE @hdrdet_amts
	SET  prorrate_case = 3 WHERE hdr_amt != 0 AND dtl_amt = 0
	AND prorate_flag = 1
	
	


	UPDATE a SET a.amt_tax = o.dtl_amt
	FROM #atmtchdr a INNER JOIN @hdrdet_amts o ON 
			(o.invoice_no = a.invoice_no AND o.vendor_code = a.vendor_code
			 AND o.prorrate_case = 2)
	
	


	INSERT INTO @TblProRateBy (invoice_no, vendor_code, sequence_id, prorate_value)
	select d.invoice_no, d.vendor_code, d.sequence_id,  
	case tax_per_1line_2qty_3amt when 1 then 1 when 2 then d.qty else d.qty * d.unit_price end prorate_value
	from #atmtcdet d inner join #tbl_vendorconfig c on (d.vendor_code = c.vendor_code)
	
	INSERT @tableSum (invoice_no, vendor_code, sum_dtl)
	SELECT d.invoice_no, d.vendor_code, SUM(prorate_value) 
	FROM  @TblProRateBy d INNER JOIN @hdrdet_amts a 
		ON (d.invoice_no = a.invoice_no AND d.vendor_code = a.vendor_code AND a.prorrate_case = 3)
	GROUP BY d.invoice_no, d.vendor_code
	
	INSERT INTO @FactorDet (invoice_no, vendor_code, sequence_id, prorrate_value, prorrate_percentage)
	SELECT d.invoice_no, d.vendor_code, d.sequence_id, d.prorate_value,  (d.prorate_value / s.sum_dtl)
	FROM  @TblProRateBy d 
	INNER JOIN @tableSum s 
		ON (s.invoice_no = d.invoice_no AND s.vendor_code = d.vendor_code AND s.sum_dtl <> 0) 
	
	


	UPDATE d
	SET d.amt_tax = ROUND(f.prorrate_percentage * t.amt_tax, @oper_precision)
	FROM #atmtcdet d 
		INNER JOIN #atmtchdr t ON (d.invoice_no = t.invoice_no AND d.vendor_code = t.vendor_code )
		INNER JOIN @FactorDet f ON (d.invoice_no = f.invoice_no AND d.vendor_code = f.vendor_code AND d.sequence_id = f.sequence_id)

	


	INSERT INTO @tblRounding (invoice_no, vendor_code, hdr_amt, sequence_id, sum_amt_round)
	SELECT d.invoice_no, d.vendor_code, o.hdr_amt, min(d.sequence_id) sequence_id, SUM(d.amt_tax) sum_amt_round
	FROM #atmtcdet d INNER JOIN @hdrdet_amts o ON 
			(o.invoice_no = d.invoice_no AND o.vendor_code = d.vendor_code AND o.prorrate_case = 3)
	WHERE ROUND(d.amt_tax, @oper_precision) <> 0
	GROUP BY d.invoice_no, d.vendor_code, o.hdr_amt
	HAVING o.hdr_amt != SUM(d.amt_tax)
	


	UPDATE d
	SET d.amt_tax = d.amt_tax + f.hdr_amt - f.sum_amt_round
	FROM #atmtcdet d 
		INNER JOIN @tblRounding f ON (d.invoice_no = f.invoice_no AND d.vendor_code = f.vendor_code AND d.sequence_id = f.sequence_id)
		
END




DELETE FROM @hdrdet_amts
DELETE FROM @tableSum
DELETE FROM @FactorDet
DELETE FROM @TblProRateBy
DELETE FROM @tblRounding

INSERT @hdrdet_amts (invoice_no, vendor_code, hdr_amt, 
	dtl_amt, line_qty_amt, prorrate_case,
	prorate_flag)
SELECT hdr.invoice_no, hdr.vendor_code, ROUND(hdr.amt_freight, @oper_precision), 
	ROUND(sum(det.amt_freight), @oper_precision), c.freight_per_1line_2qty_3amt, 0,
	c.freight_flag
FROM  #atmtchdr hdr, #atmtcdet det, #tbl_vendorconfig c
WHERE	hdr.invoice_no 	= det.invoice_no 
AND	hdr.vendor_code = det.vendor_code
AND	hdr.vendor_code = c.vendor_code
GROUP BY hdr.invoice_no, hdr.vendor_code, hdr.amt_freight, c.freight_per_1line_2qty_3amt,
	c.freight_flag
	
IF (@@ROWCOUNT>0) 
BEGIN
	
	UPDATE @hdrdet_amts
	SET  prorrate_case = 1 
	WHERE hdr_amt != 0 AND dtl_amt !=0 
	
	
	UPDATE @hdrdet_amts
	SET  prorrate_case = 2 WHERE hdr_amt = 0 AND dtl_amt != 0
	
	
	UPDATE @hdrdet_amts
	SET  prorrate_case = 3 WHERE hdr_amt != 0 AND dtl_amt = 0
	AND prorate_flag = 1
	
	


	UPDATE a SET a.amt_freight = o.dtl_amt
	FROM #atmtchdr a INNER JOIN @hdrdet_amts o ON 
			(o.invoice_no = a.invoice_no AND o.vendor_code = a.vendor_code
			 AND o.prorrate_case = 2)	

	


	INSERT INTO @TblProRateBy (invoice_no, vendor_code, sequence_id, prorate_value)
	select d.invoice_no, d.vendor_code, d.sequence_id,  
	case freight_per_1line_2qty_3amt when 1 then 1 when 2 then d.qty else d.qty * d.unit_price end prorate_value
	from #atmtcdet d inner join #tbl_vendorconfig c on (d.vendor_code = c.vendor_code)

	INSERT @tableSum (invoice_no, vendor_code, sum_dtl)
	SELECT d.invoice_no, d.vendor_code, SUM(prorate_value) 
	FROM  @TblProRateBy d INNER JOIN @hdrdet_amts a 
		ON (d.invoice_no = a.invoice_no AND d.vendor_code = a.vendor_code AND a.prorrate_case = 3)
	GROUP BY d.invoice_no, d.vendor_code

	INSERT INTO @FactorDet (invoice_no, vendor_code, sequence_id, prorrate_value, prorrate_percentage)
	SELECT d.invoice_no, d.vendor_code, d.sequence_id, d.prorate_value,  (d.prorate_value / s.sum_dtl)
	FROM  @TblProRateBy d 
	INNER JOIN @tableSum s 
		ON (s.invoice_no = d.invoice_no AND s.vendor_code = d.vendor_code AND s.sum_dtl <> 0) 
	
	


	UPDATE d
	SET d.amt_freight = ROUND(f.prorrate_percentage * t.amt_freight, @oper_precision)
	FROM #atmtcdet d 
		INNER JOIN #atmtchdr t ON (d.invoice_no = t.invoice_no AND d.vendor_code = t.vendor_code )
		INNER JOIN @FactorDet f ON (d.invoice_no = f.invoice_no AND d.vendor_code = f.vendor_code AND d.sequence_id = f.sequence_id)

	


	INSERT INTO @tblRounding (invoice_no, vendor_code, hdr_amt, sequence_id, sum_amt_round)
	SELECT d.invoice_no, d.vendor_code, o.hdr_amt, min(d.sequence_id) sequence_id, SUM(d.amt_freight) sum_amt_round
	FROM #atmtcdet d INNER JOIN @hdrdet_amts o ON 
			(o.invoice_no = d.invoice_no AND o.vendor_code = d.vendor_code AND o.prorrate_case = 3)
	WHERE ROUND(d.amt_freight, @oper_precision) <> 0
	GROUP BY d.invoice_no, d.vendor_code, o.hdr_amt
	HAVING o.hdr_amt != SUM(d.amt_freight)
	


	UPDATE d
	SET d.amt_freight = d.amt_freight + f.hdr_amt - f.sum_amt_round
	FROM #atmtcdet d 
		INNER JOIN @tblRounding f ON (d.invoice_no = f.invoice_no AND d.vendor_code = f.vendor_code AND d.sequence_id = f.sequence_id)
	
	
END		




DELETE FROM @hdrdet_amts
DELETE FROM @tableSum
DELETE FROM @FactorDet
DELETE FROM @TblProRateBy
DELETE FROM @tblRounding

INSERT @hdrdet_amts (invoice_no, vendor_code, hdr_amt, 
	dtl_amt, line_qty_amt, prorrate_case,
	prorate_flag)
SELECT hdr.invoice_no, hdr.vendor_code, ROUND(hdr.amt_discount, @oper_precision), 
	ROUND(sum(det.amt_discount), @oper_precision), c.disc_per_1line_2qty_3amt, 0,
	c.disc_flag
FROM  #atmtchdr hdr, #atmtcdet det, #tbl_vendorconfig c
WHERE	hdr.invoice_no 	= det.invoice_no 
AND	hdr.vendor_code = det.vendor_code
AND	hdr.vendor_code = c.vendor_code
GROUP BY hdr.invoice_no, hdr.vendor_code, hdr.amt_discount, c.disc_per_1line_2qty_3amt,
	c.disc_flag
	
IF (@@ROWCOUNT>0) 
BEGIN
	
	UPDATE @hdrdet_amts
	SET  prorrate_case = 1 
	WHERE hdr_amt != 0 AND dtl_amt !=0 
	
	
	UPDATE @hdrdet_amts
	SET  prorrate_case = 2 WHERE hdr_amt = 0 AND dtl_amt != 0
	
	
	UPDATE @hdrdet_amts
	SET  prorrate_case = 3 WHERE hdr_amt != 0 AND dtl_amt = 0
	AND prorate_flag = 1
	
	


	UPDATE a SET a.amt_discount = o.dtl_amt
	FROM #atmtchdr a INNER JOIN @hdrdet_amts o ON 
			(o.invoice_no = a.invoice_no AND o.vendor_code = a.vendor_code
			 AND o.prorrate_case = 2)	

	


	INSERT INTO @TblProRateBy (invoice_no, vendor_code, sequence_id, prorate_value)
	select d.invoice_no, d.vendor_code, d.sequence_id,  
	case disc_per_1line_2qty_3amt when 1 then 1 when 2 then d.qty else d.qty * d.unit_price end prorate_value
	from #atmtcdet d inner join #tbl_vendorconfig c on (d.vendor_code = c.vendor_code)

	INSERT @tableSum (invoice_no, vendor_code, sum_dtl)
	SELECT d.invoice_no, d.vendor_code, SUM(prorate_value) 
	FROM  @TblProRateBy d INNER JOIN @hdrdet_amts a 
		ON (d.invoice_no = a.invoice_no AND d.vendor_code = a.vendor_code AND a.prorrate_case = 3)
	GROUP BY d.invoice_no, d.vendor_code

	INSERT INTO @FactorDet (invoice_no, vendor_code, sequence_id, prorrate_value, prorrate_percentage)
	SELECT d.invoice_no, d.vendor_code, d.sequence_id, d.prorate_value,  (d.prorate_value / s.sum_dtl)
	FROM  @TblProRateBy d 
	INNER JOIN @tableSum s 
		ON (s.invoice_no = d.invoice_no AND s.vendor_code = d.vendor_code AND s.sum_dtl <> 0) 
	
	


	UPDATE d
	SET d.amt_discount = ROUND(f.prorrate_percentage * t.amt_discount, @oper_precision)
	FROM #atmtcdet d 
		INNER JOIN #atmtchdr t ON (d.invoice_no = t.invoice_no AND d.vendor_code = t.vendor_code )
		INNER JOIN @FactorDet f ON (d.invoice_no = f.invoice_no AND d.vendor_code = f.vendor_code AND d.sequence_id = f.sequence_id)

	


	INSERT INTO @tblRounding (invoice_no, vendor_code, hdr_amt, sequence_id, sum_amt_round)
	SELECT d.invoice_no, d.vendor_code, o.hdr_amt, min(d.sequence_id) sequence_id, SUM(d.amt_discount) sum_amt_round
	FROM #atmtcdet d INNER JOIN @hdrdet_amts o ON 
			(o.invoice_no = d.invoice_no AND o.vendor_code = d.vendor_code AND o.prorrate_case = 3)
	WHERE ROUND(d.amt_discount, @oper_precision) <> 0
	GROUP BY d.invoice_no, d.vendor_code, o.hdr_amt
	HAVING o.hdr_amt != SUM(d.amt_discount)
	


	UPDATE d
	SET d.amt_discount = d.amt_discount + f.hdr_amt - f.sum_amt_round
	FROM #atmtcdet d 
		INNER JOIN @tblRounding f ON (d.invoice_no = f.invoice_no AND d.vendor_code = f.vendor_code AND d.sequence_id = f.sequence_id)
	
	
END		




DELETE FROM @hdrdet_amts
DELETE FROM @tableSum
DELETE FROM @FactorDet
DELETE FROM @TblProRateBy
DELETE FROM @tblRounding

INSERT @hdrdet_amts (invoice_no, vendor_code, hdr_amt, 
	dtl_amt, line_qty_amt, prorrate_case,
	prorate_flag)
SELECT hdr.invoice_no, hdr.vendor_code, ROUND(hdr.amt_misc, @oper_precision), 
	ROUND(sum(det.amt_misc), @oper_precision), c.misc_per_1line_2qty_3amt, 0,
	c.misc_flag
FROM  #atmtchdr hdr, #atmtcdet det, #tbl_vendorconfig c
WHERE	hdr.invoice_no 	= det.invoice_no 
AND	hdr.vendor_code = det.vendor_code
AND	hdr.vendor_code = c.vendor_code
GROUP BY hdr.invoice_no, hdr.vendor_code, hdr.amt_misc, c.misc_per_1line_2qty_3amt,
	c.misc_flag
	
IF (@@ROWCOUNT>0) 
BEGIN
	
	UPDATE @hdrdet_amts
	SET  prorrate_case = 1 
	WHERE hdr_amt != 0 AND dtl_amt !=0 
	
	
	UPDATE @hdrdet_amts
	SET  prorrate_case = 2 WHERE hdr_amt = 0 AND dtl_amt != 0
	
	
	UPDATE @hdrdet_amts
	SET  prorrate_case = 3 WHERE hdr_amt != 0 AND dtl_amt = 0
	AND prorate_flag = 1
	
	


	UPDATE a SET a.amt_misc = o.dtl_amt
	FROM #atmtchdr a INNER JOIN @hdrdet_amts o ON 
			(o.invoice_no = a.invoice_no AND o.vendor_code = a.vendor_code
			 AND o.prorrate_case = 2)	

	


	INSERT INTO @TblProRateBy (invoice_no, vendor_code, sequence_id, prorate_value)
	select d.invoice_no, d.vendor_code, d.sequence_id,  
	case misc_per_1line_2qty_3amt when 1 then 1 when 2 then d.qty else d.qty * d.unit_price end prorate_value
	from #atmtcdet d inner join #tbl_vendorconfig c on (d.vendor_code = c.vendor_code)

	INSERT @tableSum (invoice_no, vendor_code, sum_dtl)
	SELECT d.invoice_no, d.vendor_code, SUM(prorate_value) 
	FROM  @TblProRateBy d INNER JOIN @hdrdet_amts a 
		ON (d.invoice_no = a.invoice_no AND d.vendor_code = a.vendor_code AND a.prorrate_case = 3)
	GROUP BY d.invoice_no, d.vendor_code

	INSERT INTO @FactorDet (invoice_no, vendor_code, sequence_id, prorrate_value, prorrate_percentage)
	SELECT d.invoice_no, d.vendor_code, d.sequence_id, d.prorate_value,  (d.prorate_value / s.sum_dtl)
	FROM  @TblProRateBy d 
	INNER JOIN @tableSum s 
		ON (s.invoice_no = d.invoice_no AND s.vendor_code = d.vendor_code AND s.sum_dtl <> 0) 
	
	


	UPDATE d
	SET d.amt_misc = ROUND(f.prorrate_percentage * t.amt_misc, @oper_precision)
	FROM #atmtcdet d 
		INNER JOIN #atmtchdr t ON (d.invoice_no = t.invoice_no AND d.vendor_code = t.vendor_code )
		INNER JOIN @FactorDet f ON (d.invoice_no = f.invoice_no AND d.vendor_code = f.vendor_code AND d.sequence_id = f.sequence_id)

	


	INSERT INTO @tblRounding (invoice_no, vendor_code, hdr_amt, sequence_id, sum_amt_round)
	SELECT d.invoice_no, d.vendor_code, o.hdr_amt, min(d.sequence_id) sequence_id, SUM(d.amt_misc) sum_amt_round
	FROM #atmtcdet d INNER JOIN @hdrdet_amts o ON 
			(o.invoice_no = d.invoice_no AND o.vendor_code = d.vendor_code AND o.prorrate_case = 3)
	WHERE ROUND(d.amt_misc, @oper_precision) <> 0
	GROUP BY d.invoice_no, d.vendor_code, o.hdr_amt
	HAVING o.hdr_amt != SUM(d.amt_misc)
	


	UPDATE d
	SET d.amt_misc = d.amt_misc + f.hdr_amt - f.sum_amt_round
	FROM #atmtcdet d 
		INNER JOIN @tblRounding f ON (d.invoice_no = f.invoice_no AND d.vendor_code = f.vendor_code AND d.sequence_id = f.sequence_id)
	
END		
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[ATTaxProRate_sp] TO [public]
GO
