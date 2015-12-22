SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[apexpdst_sp] 	@print_batch_num int, 
								@cash_acct_code varchar(32),
								@debug_level smallint = 0
	
AS





IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apexpdst.cpp" + ", line " + STR( 117, 5 ) + " -- ENTRY: "




		INSERT #apexpdst (
			vendor_code,
			check_num,
			cash_acct_code,		
			print_batch_num,
			payment_num,
			payment_type, 
			voucher_num,
			sequence_id,
			amt_dist,		
			gl_exp_acct,   	
			posted_flag,	
			printed_flag,
			overflow_flag 	
				 )
		SELECT  	
			a.vendor_code,
			" ",
			@cash_acct_code,
			@print_batch_num,
			a.payment_num,
			1,
			a.voucher_num,
			c.sequence_id,
			a.amt_paid/b.amt_net * c.amt_extended,
			c.gl_exp_acct,
			-1,
			1,
			0
		FROM #apchkstb a, apvohdr b, apvodet c
		WHERE (a.payment_type = 1 or a.payment_type = 6)
		AND a.voucher_num = b.trx_ctrl_num
		AND b.trx_ctrl_num = c.trx_ctrl_num


  






	
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[apexpdst_sp] TO [public]
GO
