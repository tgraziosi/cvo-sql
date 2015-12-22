SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[apchklns_sp]	@voucher_classification smallint,
							  	@voucher_comment		smallint,
							  	@voucher_memo			smallint,
							  	@expense_dist			smallint,
								@history_flag			smallint,	 
								@debug_level			smallint = 0

AS
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apchklns.cpp" + ", line " + STR( 56, 5 ) + " -- ENTRY: "


	IF (@voucher_classification = 1 OR
		@voucher_comment = 1 OR
		@voucher_memo = 1)
	BEGIN
			UPDATE #apchkstb
			SET lines = lines + (voucher_classification * SIGN(ISNULL(DATALENGTH(RTRIM(voucher_classify)),0))) +
								(voucher_comment * SIGN(ISNULL(DATALENGTH(RTRIM(comment_line)),0))) +
								(voucher_memo * SIGN(ISNULL(DATALENGTH(RTRIM(voucher_internal_memo)),0)))
			WHERE payment_type = 1 or payment_type = 6 

			IF (@@error != 0)
				   RETURN -1

	END
	
	IF (@expense_dist = 1)
	BEGIN
	   UPDATE #apchkstb
	   SET	lines = lines +  (SELECT ISNULL(COUNT(Distinct gl_exp_acct) ,0) FROM #apexpdst
							  WHERE #apexpdst.voucher_num = #apchkstb.voucher_num)
	   FROM #apchkstb	
	   WHERE payment_type = 1 or payment_type = 6
	
	   IF (@@error != 0)
	   		   RETURN -1
	END	

	



	IF (@history_flag = 1)
	BEGIN
	   UPDATE #apchkstb
	   SET	lines = lines +  (SELECT ISNULL(COUNT(*) ,0) FROM #apvohist
							  WHERE #apvohist.trx_link = #apchkstb.payment_num
							  AND #apvohist.voucher_num = #apchkstb.voucher_num)
	   FROM #apchkstb	
	   WHERE payment_type = 1 or payment_type = 6	
	
	   IF (@@error != 0)
	   		   RETURN -1
	END	


	














	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apchklns.cpp" + ", line " + STR( 119, 5 ) + " -- EXIT: "

	RETURN 0
	
GO
GRANT EXECUTE ON  [dbo].[apchklns_sp] TO [public]
GO
