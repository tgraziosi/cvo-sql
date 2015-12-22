SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE PROC [dbo].[APDMUpdateExtendedAmounts_sp] 		@debug_level smallint = 0

AS
DECLARE
 @result 	int


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apdmuea.sp" + ", line " + STR( 50, 5 ) + " -- ENTRY: "
	


UPDATE #apdmchg_work
SET db_action = c.dm_type
FROM #apdmchg_work, apusrtyp b, apdmtype c
WHERE #apdmchg_work.user_trx_type_code = b. user_trx_type_code
AND b.dm_type = c.dm_type
AND b.dm_type > 1

IF @@rowcount > 0
BEGIN

	UPDATE #apdmchg_work
	SET amt_gross = 0.0,
		amt_discount = 0.0,
		amt_misc = 0.0,
		amt_tax = amt_tax * ABS(SIGN(db_action - 3)),
		amt_freight = amt_freight * ABS(SIGN(db_action - 2)),
		amt_net = amt_tax * ABS(SIGN(db_action - 3)) + amt_freight * ABS(SIGN(db_action - 2)),
		amt_tax_included = amt_tax_included * ABS(SIGN(db_action - 3)),
		frt_calc_tax = frt_calc_tax * ABS(SIGN(db_action - 2)),
	 glamt_tax = glamt_tax * ABS(SIGN(db_action - 3)),
	 glamt_freight = glamt_freight * ABS(SIGN(db_action - 2)),
	 glamt_misc= 0.0,
		glamt_discount = 0.0
	FROM #apdmchg_work
	WHERE db_action > 1

	UPDATE #apdmcdt_work
	SET amt_extended = #apdmcdt_work.calc_tax * ABS(SIGN(b.db_action - 3)) * c.tax_included_flag,
		amt_discount = 0.0,
		amt_misc = 0.0,
		amt_tax = #apdmcdt_work.amt_tax * ABS(SIGN(b.db_action - 3)),
		amt_freight = #apdmcdt_work.amt_freight * ABS(SIGN(b.db_action - 2)),
		amt_orig_extended = #apdmcdt_work.calc_tax * ABS(SIGN(b.db_action - 3)) * c.tax_included_flag,
		calc_tax = #apdmcdt_work.calc_tax * ABS(SIGN(b.db_action - 3))
	FROM #apdmcdt_work, #apdmchg_work b, aptax c
	WHERE #apdmcdt_work.trx_ctrl_num = b.trx_ctrl_num
	AND #apdmcdt_work.tax_code = c.tax_code
	AND b.db_action > 1


	UPDATE #apdmchg_work
	SET db_action = 0
	WHERE db_action != 0

END

		
UPDATE	#apdmcdt_work
SET		amt_extended = #apdmcdt_work.amt_extended - #apdmcdt_work.calc_tax
FROM 	#apdmcdt_work, #apdmchg_work b, aptax c
WHERE 	#apdmcdt_work.trx_ctrl_num = b.trx_ctrl_num
AND 	#apdmcdt_work.tax_code = c.tax_code
AND 	c.tax_included_flag = 1


IF( @@error != 0 )
	RETURN -1
	

UPDATE #apdmchg_work
SET glamt_misc = glamt_misc - (SELECT ISNULL(SUM(amt_misc),0.0) FROM #apdmcdt_work b
								 WHERE b.trx_ctrl_num = #apdmchg_work.trx_ctrl_num)
FROM #apdmchg_work
WHERE ((glamt_misc) > (0.0) + 0.0000001)

UPDATE #apdmchg_work
SET glamt_discount = glamt_discount - (SELECT ISNULL(SUM(amt_discount),0.0) FROM #apdmcdt_work b
										 WHERE b.trx_ctrl_num = #apdmchg_work.trx_ctrl_num)
FROM #apdmchg_work	
WHERE ((glamt_discount) > (0.0) + 0.0000001)


UPDATE #apdmchg_work
SET glamt_tax = glamt_tax - (SELECT ISNULL(SUM(amt_tax),0.0) FROM #apdmcdt_work b
								 WHERE b.trx_ctrl_num = #apdmchg_work.trx_ctrl_num)
FROM #apdmchg_work	
WHERE ((glamt_tax) > (0.0) + 0.0000001)
								 

UPDATE #apdmchg_work
SET glamt_freight = glamt_freight - (SELECT ISNULL(SUM(amt_freight),0.0) FROM #apdmcdt_work b
										 WHERE b.trx_ctrl_num = #apdmchg_work.trx_ctrl_num)
FROM #apdmchg_work
WHERE ((glamt_freight) > (0.0) + 0.0000001)

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apdmuea.sp" + ", line " + STR( 141, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APDMUpdateExtendedAmounts_sp] TO [public]
GO
