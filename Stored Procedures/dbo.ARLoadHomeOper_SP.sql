SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARLoadHomeOper_SP]	@debug_level smallint = 0,
 	@perf_level smallint = 0 
AS
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arlho.sp" + ", line " + STR( 39, 5 ) + " -- ENTRY: "


	
	DELETE	#argldist
	FROM	glcurr_vw n, glcurr_vw o, glcurr_vw h, glco
	WHERE	SIGN(ROUND(ISNULL(nat_balance, 0), n.curr_precision)) = 0
	AND	SIGN(ROUND(ISNULL(oper_balance, 0), o.curr_precision)) = 0
	AND	SIGN(ROUND(ISNULL(home_balance, 0), h.curr_precision)) = 0
	AND	#argldist.nat_cur_code = n.currency_code
	AND	glco.oper_currency = o.currency_code
	AND	glco.home_currency = h.currency_code


	
	UPDATE	#argldist
	SET	journal_type = glappid.journal_type
	FROM	glappid
	WHERE	app_id = 2000
	
	UPDATE	#argldist
	SET	reference_code = " "
	WHERE	reference_code IS NULL

	UPDATE	#argldist
	SET	rec_company_code = company_code,
		home_cur_code = home_currency,
		oper_cur_code = oper_currency
	FROM	glco

	

	UPDATE	#argldist
	SET	home_balance = (SIGN(nat_balance * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS(nat_balance * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, h.curr_precision)),
		oper_balance = (SIGN(nat_balance * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) * ROUND(ABS(nat_balance * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) + 0.0000001, o.curr_precision))
	FROM	glcurr_vw h, glcurr_vw o
	WHERE	h.currency_code = home_cur_code
	 AND	o.currency_code = oper_cur_code
	 AND	SIGN(nat_balance) != 0

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arlho.sp" + ", line " + STR( 88, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	IF( @debug_level >= 2 )
	BEGIN
		SELECT	"Rows in #argldist after rounding and 0 deletion"
		SELECT	"date_applied journal_type rec_company_code account code description document_1 document_2"
		SELECT	STR(date_applied, 7) + ":" +
				journal_type + ":" +
				rec_company_code + ":" +
				account_code + ":" +
				description + ":" +
				document_1 + ":" +
				document_2
		FROM	#argldist
				
		SELECT	"document_2 nat_balance nat_cur_code home_balance home_cur oper_bal oper_cur rate_h rate_o trx_type seq_ref_id"
		SELECT	document_2 + ":" +
				STR(nat_balance, 10, 4) + ":" +
				nat_cur_code + ":" +
				STR(home_balance, 10, 4) + ":" +
				home_cur_code + ":" +
				STR(oper_balance, 10, 4) + ":" +
				oper_cur_code + ":" +
				STR(rate_home, 10, 6) + ":" +
				STR(rate_oper, 10, 6) + ":" +
				STR(trx_type, 5 ) + ":" +
				STR(seq_ref_id, 6)
		FROM	#argldist
	END

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arlho.sp" + ", line " + STR( 120, 5 ) + " -- EXIT: "

	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[ARLoadHomeOper_SP] TO [public]
GO
