SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[APVOUpdateExtendedAmounts_sp] 		@debug_level smallint = 0

AS
DECLARE
    @result 	int


	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvouea.sp" + ", line " + STR( 53, 5 ) + " -- ENTRY: "


	UPDATE	#apvocdt_work
	SET		amt_extended = #apvocdt_work.amt_extended - #apvocdt_work.calc_tax
	FROM 	#apvocdt_work, #apvochg_work b, aptax c
	WHERE 	#apvocdt_work.trx_ctrl_num = b.trx_ctrl_num
	AND 	#apvocdt_work.tax_code = c.tax_code
	AND 	c.tax_included_flag = 1

	IF( @@error != 0 )
		RETURN -1
	

	




	UPDATE #apvochg_work
	SET glamt_misc = glamt_misc - (SELECT ISNULL(SUM(amt_misc),0.0) FROM #apvocdt_work b
									  WHERE b.trx_ctrl_num = #apvochg_work.trx_ctrl_num)
	FROM #apvochg_work	
	WHERE ((glamt_misc) > (0.0) + 0.0000001)

	IF( @@error != 0 )
		RETURN -1

	UPDATE #apvochg_work
	SET glamt_discount = glamt_discount - (SELECT ISNULL(SUM(amt_discount),0.0) FROM #apvocdt_work b
									  WHERE b.trx_ctrl_num = #apvochg_work.trx_ctrl_num)
	FROM #apvochg_work 
	WHERE (ABS((glamt_discount)-(0.0)) > 0.0000001)
	



	IF( @@error != 0 )
		RETURN -1


	UPDATE #apvochg_work
	SET glamt_tax = glamt_tax - (SELECT ISNULL(SUM(amt_tax),0.0) FROM #apvocdt_work b
									  WHERE b.trx_ctrl_num = #apvochg_work.trx_ctrl_num)
	FROM #apvochg_work	
	WHERE ((glamt_tax) > (0.0) + 0.0000001)

	IF( @@error != 0 )
		RETURN -1
								  

	UPDATE #apvochg_work
	SET glamt_freight = glamt_freight - (SELECT ISNULL(SUM(amt_freight),0.0) FROM #apvocdt_work b
									  WHERE b.trx_ctrl_num = #apvochg_work.trx_ctrl_num)
	FROM #apvochg_work	
	WHERE ((glamt_freight) > (0.0) + 0.0000001)

	IF( @@error != 0 )
		RETURN -1

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvouea.sp" + ", line " + STR( 113, 5 ) + " -- EXIT: "
	RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APVOUpdateExtendedAmounts_sp] TO [public]
GO
