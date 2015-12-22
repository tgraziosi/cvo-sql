SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[apvedet2_sp] @error_level smallint, @debug_level smallint = 0
AS

DECLARE @credit_invoice_flag smallint

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvedet2.cpp" + ", line " + STR( 48, 5 ) + " -- ENTRY: "

SELECT @credit_invoice_flag = credit_invoice_flag FROM apco

IF @credit_invoice_flag = 0
BEGIN
IF (SELECT err_type FROM apedterr WHERE err_code = 10960) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvedet2.cpp" + ", line " + STR( 56, 5 ) + " -- MSG: " + "Check if unit_price is negative"
	


      INSERT #ewerror
	  SELECT 4000,
			 10960,
			 "",
			 "",
			 0,
			 unit_price,
			 4,
			 trx_ctrl_num,
			 sequence_id,
			 "",
			 0
	  FROM #apvovcdt 
  	  WHERE ((unit_price) < (0.0) - 0.0000001)
END

END

IF (SELECT err_type FROM apedterr WHERE err_code = 10970) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvedet2.cpp" + ", line " + STR( 80, 5 ) + " -- MSG: " + "Check if unit_price is zero"
	


      INSERT #ewerror
	  SELECT 4000,
			 10970,
			 "",
			 "",
			 0,
			 unit_price,
			 4,
			 trx_ctrl_num,
			 sequence_id,
			 "",
			 0
	  FROM #apvovcdt 
  	  WHERE (ABS((unit_price)-(0.0)) < 0.0000001)
END

IF @credit_invoice_flag = 0
BEGIN
IF (SELECT err_type FROM apedterr WHERE err_code = 10980) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvedet2.cpp" + ", line " + STR( 104, 5 ) + " -- MSG: " + "Check if amt_discount is negative"
	


      INSERT #ewerror
	  SELECT 4000,
			 10980,
			 "",
			 "",
			 0,
			 amt_discount,
			 4,
			 trx_ctrl_num,
			 sequence_id,
			 "",
			 0
	  FROM #apvovcdt 
  	  WHERE ((amt_discount) < (0.0) - 0.0000001)
END

END

IF @credit_invoice_flag = 0
BEGIN
IF (SELECT err_type FROM apedterr WHERE err_code = 10990) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvedet2.cpp" + ", line " + STR( 130, 5 ) + " -- MSG: " + "Check if amt_freight is negative"
	


      INSERT #ewerror
	  SELECT 4000,
			 10990,
			 "",
			 "",
			 0,
			 amt_freight,
			 4,
			 trx_ctrl_num,
			 sequence_id,
			 "",
			 0
	  FROM #apvovcdt 
  	  WHERE ((amt_freight) < (0.0) - 0.0000001)
END

END

IF @credit_invoice_flag = 0
BEGIN
IF (SELECT err_type FROM apedterr WHERE err_code = 11000) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvedet2.cpp" + ", line " + STR( 156, 5 ) + " -- MSG: " + "Check if amt_tax is negative"
	


      INSERT #ewerror
	  SELECT 4000,
			 11000,
			 "",
			 "",
			 0,
			 amt_tax,
			 4,
			 trx_ctrl_num,
			 sequence_id,
			 "",
			 0
	  FROM #apvovcdt 
  	  WHERE ((amt_tax) < (0.0) - 0.0000001)
END

END

IF @credit_invoice_flag = 0
BEGIN
IF (SELECT err_type FROM apedterr WHERE err_code = 11010) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvedet2.cpp" + ", line " + STR( 182, 5 ) + " -- MSG: " + "Check if amt_misc is negative"
	


      INSERT #ewerror
	  SELECT 4000,
			 11010,
			 "",
			 "",
			 0,
			 amt_misc,
			 4,
			 trx_ctrl_num,
			 sequence_id,
			 "",
			 0
	  FROM #apvovcdt 
  	  WHERE ((amt_misc) < (0.0) - 0.0000001)
END

END
			
IF @credit_invoice_flag = 0
BEGIN    
IF (SELECT err_type FROM apedterr WHERE err_code = 11020) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvedet2.cpp" + ", line " + STR( 208, 5 ) + " -- MSG: " + "Check if amt_extended is negative"
	


      INSERT #ewerror
	  SELECT 4000,
			 11020,
			 "",
			 "",
			 0,
			 amt_extended,
			 4,
			 trx_ctrl_num,
			 sequence_id,
			 "",
			 0
	  FROM #apvovcdt 
  	  WHERE ((amt_extended) < (0.0) - 0.0000001)
END

END

IF (SELECT err_type FROM apedterr WHERE err_code = 11030) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvedet2.cpp" + ", line " + STR( 232, 5 ) + " -- MSG: " + "check if amt_extended = unit_price * qty_received"
	


      INSERT #ewerror
	  SELECT 4000,
			 11030,
			 "",
			 "",
			 0,
			 a.amt_extended,
			 4,
			 a.trx_ctrl_num,
			 a.sequence_id,
			 "",
			 0
	  FROM #apvovcdt a, #apvovchg b, glcurr_vw c
  	  WHERE a.trx_ctrl_num = b.trx_ctrl_num
  	  AND b.nat_cur_code = c.currency_code
  	  AND 
(ABS(((SIGN(a.amt_extended) * ROUND(ABS(a.amt_extended) + 0.0000001, c.curr_precision)))-((SIGN(a.unit_price * a.qty_received) * ROUND(ABS(a.unit_price * a.qty_received) + 0.0000001, c.curr_precision)))) > 0.0000001)
END


IF (SELECT err_type FROM apedterr WHERE err_code = 10830) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvedet2.cpp" + ", line " + STR( 258, 5 ) + " -- MSG: " + "Check if no line items exist"
	


      INSERT #ewerror
	  SELECT 4000,
			 10830,
			 "",
			 "",
			 0,
			 0.0,
			 0,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg 
  	  WHERE (ABS((amt_gross)-(0.0)) > 0.0000001)
	  AND trx_ctrl_num NOT IN (SELECT trx_ctrl_num FROM #apvovcdt)
END


IF (SELECT err_type FROM apedterr WHERE err_code = 10831) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvedet2.cpp" + ", line " + STR( 282, 5 ) + " -- MSG: " + "Check if no line items exist"
	


      INSERT #ewerror
	  SELECT 4000,
			 10831,
			 "",
			 "",
			 0,
			 0.0,
			 0,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg 
  	  WHERE (ABS((amt_gross)-(0.0)) < 0.0000001)
	  AND trx_ctrl_num NOT IN (SELECT trx_ctrl_num FROM #apvovcdt)
END


IF (SELECT err_type FROM apedterr WHERE err_code = 11480) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvedet2.cpp" + ", line " + STR( 306, 5 ) + " -- MSG: " + "Check if the detail tax doesn't exceeds the range limit."
	


	
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
		#apvovchg h 
		INNER JOIN #apvovcdt d
		ON d.trx_ctrl_num = h.trx_ctrl_num AND d.trx_type = h.trx_type
		INNER JOIN #apvovtaxdtl t 
		ON t.trx_ctrl_num = d.trx_ctrl_num AND t.trx_type = d.trx_type
			AND d.sequence_id = t.detail_sequence_id

	  INSERT #ewerror
	  SELECT DISTINCT 4000,
			 11480,
			 ""  ,
			 "",
			 0,
			 c.amt_final_tax_converted,
			 4,
			 d.trx_ctrl_num,
			 d.sequence_id,
			 "",
			 0
	  FROM #apvovcdt d, #rates_converted c
	  WHERE d.trx_ctrl_num = c.trx_ctrl_num
		AND (	( (c.amt_final_tax_converted < c.amt_tax_converted) AND
					(	(@amount_under <> 0 AND (c.amt_final_tax_converted - c.amt_tax_converted) < (-@amount_under - 0.0000001))
						OR
						(@percent_under <> 0 AND c.amt_tax_converted <> 0 AND (ABS((c.amt_final_tax_converted - c.amt_tax_converted)/c.amt_tax_converted) > (@percent_under/100.0)))
					)
				)
			OR  ( (c.amt_final_tax_converted > c.amt_tax_converted) AND
					(	(@amount_over <> 0 AND (c.amt_final_tax_converted - c.amt_tax_converted) > (@amount_over + 0.0000001))
						OR
						(@percent_over <> 0 AND c.amt_tax_converted <> 0 AND (ABS((c.amt_final_tax_converted - c.amt_tax_converted)/c.amt_tax_converted) > (@percent_over/100.0)))
					)
				)
		   )
	DROP TABLE #rates_converted
	END
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
	 FROM   #apvovcdt b, #apvovchg c, glcomp_vw d
	 WHERE b.trx_ctrl_num = c.trx_ctrl_num
	 AND b.rec_company_code = d.company_code





IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvedet2.cpp" + ", line " + STR( 385, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[apvedet2_sp] TO [public]
GO
