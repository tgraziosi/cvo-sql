SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


	



CREATE PROCEDURE [dbo].[apdedet2_sp] @error_level smallint, @debug_level smallint = 0
AS

DECLARE @precision int

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apdedet2.cpp' + ', line ' + STR( 37, 5 ) + ' -- ENTRY: '







IF (SELECT err_type FROM apedterr WHERE err_code = 20960) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apdedet2.cpp' + ', line ' + STR( 47, 5 ) + ' -- MSG: ' + 'Check if unit_price is negative'
	


      INSERT #ewerror
	  SELECT 4000,
			 20960,
			 '',
			 '',
			 0,
			 unit_price,
			 4,
			 trx_ctrl_num,
			 sequence_id,
			 '',
			 0
	  FROM #apdmvcdt 
  	  WHERE ((unit_price) < (0.0) - 0.0000001)
END


IF (SELECT err_type FROM apedterr WHERE err_code = 20970) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apdedet2.cpp' + ', line ' + STR( 70, 5 ) + ' -- MSG: ' + 'Check if unit_price is zero'
	


      INSERT #ewerror
	  SELECT 4000,
			 20970,
			 '',
			 '',
			 0,
			 unit_price,
			 4,
			 trx_ctrl_num,
			 sequence_id,
			 '',
			 0
	  FROM #apdmvcdt 
  	  WHERE (ABS((unit_price)-(0.0)) < 0.0000001)
END

IF (SELECT err_type FROM apedterr WHERE err_code = 20980) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apdedet2.cpp' + ', line ' + STR( 92, 5 ) + ' -- MSG: ' + 'Check if amt_discount is negative'
	


      INSERT #ewerror
	  SELECT 4000,
			 20980,
			 '',
			 '',
			 0,
			 amt_discount,
			 4,
			 trx_ctrl_num,
			 sequence_id,
			 '',
			 0
	  FROM #apdmvcdt 
  	  WHERE ((amt_discount) < (0.0) - 0.0000001)
END


IF (SELECT err_type FROM apedterr WHERE err_code = 20990) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apdedet2.cpp' + ', line ' + STR( 115, 5 ) + ' -- MSG: ' + 'Check if amt_freight is negative'
	


      INSERT #ewerror
	  SELECT 4000,
			 20990,
			 '',
			 '',
			 0,
			 amt_freight,
			 4,
			 trx_ctrl_num,
			 sequence_id,
			 '',
			 0
	  FROM #apdmvcdt 
  	  WHERE ((amt_freight) < (0.0) - 0.0000001)
END


IF (SELECT err_type FROM apedterr WHERE err_code = 21000) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apdedet2.cpp' + ', line ' + STR( 138, 5 ) + ' -- MSG: ' + 'Check if amt_tax is negative'
	


      INSERT #ewerror
	  SELECT 4000,
			 21000,
			 '',
			 '',
			 0,
			 amt_tax,
			 4,
			 trx_ctrl_num,
			 sequence_id,
			 '',
			 0
	  FROM #apdmvcdt 
  	  WHERE ((amt_tax) < (0.0) - 0.0000001)
END


IF (SELECT err_type FROM apedterr WHERE err_code = 21010) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apdedet2.cpp' + ', line ' + STR( 161, 5 ) + ' -- MSG: ' + 'Check if amt_misc is negative'
	


      INSERT #ewerror
	  SELECT 4000,
			 21010,
			 '',
			 '',
			 0,
			 amt_misc,
			 4,
			 trx_ctrl_num,
			 sequence_id,
			 '',
			 0
	  FROM #apdmvcdt 
  	  WHERE ((amt_misc) < (0.0) - 0.0000001)
END

			    
IF (SELECT err_type FROM apedterr WHERE err_code = 21020) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apdedet2.cpp' + ', line ' + STR( 184, 5 ) + ' -- MSG: ' + 'Check if amt_extended is negative'
	


      INSERT #ewerror
	  SELECT 4000,
			 21020,
			 '',
			 '',
			 0,
			 amt_extended,
			 4,
			 trx_ctrl_num,
			 sequence_id,
			 '',
			 0
	  FROM #apdmvcdt 
  	  WHERE ((amt_extended) < (0.0) - 0.0000001)
END


IF (SELECT err_type FROM apedterr WHERE err_code = 21030) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apdedet2.cpp' + ', line ' + STR( 207, 5 ) + ' -- MSG: ' + 'check if amt_extended = unit_price * qty_returned'
	


	
      INSERT #ewerror
	  SELECT 4000,
			 21030,
			 '',
			 '',
			 0,
			 amt_extended,
			 4,
			 d.trx_ctrl_num,
			 sequence_id,
			 '',
			 0
 	  FROM #apdmvcdt d, glcurr_vw a, #apdmvchg h
   	  WHERE d.trx_ctrl_num = h.trx_ctrl_num and a.currency_code = h.nat_cur_code
          and 
(ABS(((SIGN(amt_extended) * ROUND(ABS(amt_extended) + 0.0000001, a.curr_precision)))-((SIGN(unit_price * qty_returned) * ROUND(ABS(unit_price * qty_returned) + 0.0000001, a.curr_precision)))) > 0.0000001)
END

IF (SELECT err_type FROM apedterr WHERE err_code = 21480) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apdedet2.cpp' + ', line ' + STR( 232, 5 ) + ' -- MSG: ' + 'Check if the detail tax doesnot exceeds the range limit.'
	


	
	IF EXISTS (SELECT 1 FROM apco WHERE expense_tax_override_flag = 1 )
	BEGIN

	  DECLARE @amount_under float, @amount_over float, @percent_under float, @percent_over float
	
	  SELECT @amount_under = amount_under, @amount_over = amount_over,
			 @percent_under = percent_under, @percent_over = percent_over
 	  FROM   apco      

	
	  SELECT 
		 d.trx_ctrl_num,
		 amt_tax_converted = CASE WHEN h.rate_home < 0.0 THEN t.amt_tax / ABS(h.rate_home) ELSE  t.amt_tax * ABS(h.rate_home) END,
		 amt_final_tax_converted = CASE WHEN h.rate_home < 0.0 THEN t.amt_final_tax / ABS(h.rate_home) ELSE  t.amt_final_tax * ABS(h.rate_home) END
	  INTO	#rates_converted
	  FROM 	 
		#apdmvchg h 
		INNER JOIN #apdmvcdt d
		ON d.trx_ctrl_num = h.trx_ctrl_num AND d.trx_type = h.trx_type
		INNER JOIN #apdmvtaxdtl t 
		ON t.trx_ctrl_num = d.trx_ctrl_num AND t.trx_type = d.trx_type 
		   AND d.sequence_id = t.detail_sequence_id

	  INSERT #ewerror
	  SELECT 4000,
			 21480,
			 '',
			 '',
			 0,
			 0.0,
			 0,
			 d.trx_ctrl_num,
			 0,
			 '',
			 0
	  FROM #apdmvcdt d, #rates_converted c
	  WHERE d.trx_ctrl_num = c.trx_ctrl_num
	  	AND ( ( (c.amt_final_tax_converted < c.amt_tax_converted) AND
	  		( (@amount_under <> 0 AND (c.amt_final_tax_converted - c.amt_tax_converted) < (-@amount_under - 0.0000001))
	  		   OR
	  		  (@percent_under <> 0 AND c.amt_tax_converted <> 0 AND 
	  		  (ABS((c.amt_final_tax_converted - c.amt_tax_converted)/c.amt_tax_converted) > (@percent_under/100.0)))
	  		) )
	  	OR  ( (c.amt_final_tax_converted > c.amt_tax_converted) AND
	  	    ((@amount_over <> 0 AND (c.amt_final_tax_converted - c.amt_tax_converted) > (@amount_over + 0.0000001))
	  	 	   OR
	  	     (@percent_over <> 0 AND c.amt_tax_converted <> 0 AND 
	  	          (ABS((c.amt_final_tax_converted - c.amt_tax_converted)/c.amt_tax_converted) > (@percent_over/100.0)))
	  		) )
		   )
	  
	  
	DROP TABLE #rates_converted
	END
END


IF (SELECT err_type FROM apedterr WHERE err_code = 20830) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apdedet2.cpp' + ', line ' + STR( 284, 5 ) + ' -- MSG: ' + 'Check if no line items exist'
	


      INSERT #ewerror
	  SELECT 4000,
			 20830,
			 '',
			 '',
			 0,
			 0.0,
			 0,
			 trx_ctrl_num,
			 0,
			 '',
			 0
	  FROM #apdmvchg 
  	  WHERE (ABS((amt_gross)-(0.0)) > 0.0000001)
	  AND trx_ctrl_num NOT IN (SELECT trx_ctrl_num FROM #apdmvcdt)
END


IF (SELECT err_type FROM apedterr WHERE err_code = 20831) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apdedet2.cpp' + ', line ' + STR( 308, 5 ) + ' -- MSG: ' + 'Check if no line items exist'
	


      INSERT #ewerror
	  SELECT 4000,
			 20831,
			 '',
			 '',
			 0,
			 0.0,
			 0,
			 trx_ctrl_num,
			 0,
			 '',
			 0
	  FROM #apdmvchg 
  	  WHERE (ABS((amt_gross)-(0.0)) < 0.0000001)
	  AND trx_ctrl_num NOT IN (SELECT trx_ctrl_num FROM #apdmvcdt)
END



	 



	 INSERT #apveacct
	 SELECT d.db_name,
	 		b.trx_ctrl_num,
			b.sequence_id,
			1,
			b.gl_exp_acct,
			c.date_applied,
			b.reference_code,
			0,
			b.org_id
	 FROM   #apdmvcdt b, #apdmvchg c, glcomp_vw d
	 WHERE b.trx_ctrl_num = c.trx_ctrl_num
	 AND b.rec_company_code = d.company_code





IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apdedet2.cpp' + ', line ' + STR( 353, 5 ) + ' -- EXIT: '
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[apdedet2_sp] TO [public]
GO
