SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE PROC [dbo].[APVAUpdateExtendedAmounts_sp] 		@debug_level smallint = 0

AS
DECLARE
 @result 	int


	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvauea.sp" + ", line " + STR( 50, 5 ) + " -- ENTRY: "
	

	UPDATE	#apvacdt_work
	SET		amt_extended = a.amt_extended - a.calc_tax
	FROM 	#apvacdt_work a, #apvachg_work b, aptax c
	WHERE 	a.trx_ctrl_num = b.trx_ctrl_num
	AND 	a.tax_code = c.tax_code
	AND 	c.tax_included_flag = 1

	IF( @@error != 0 )
		RETURN -1
	

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvauea.sp" + ", line " + STR( 64, 5 ) + " -- EXIT: "
	RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APVAUpdateExtendedAmounts_sp] TO [public]
GO
