SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARCACreateCashReceipt_SP]	@batch_ctrl_num	varchar(16),
						@debug_level		smallint,
						@perf_level		smallint

AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									






											  
DECLARE
	@result		int,
	@trx_ctrl_num 	varchar(16),
	@cr_trx_ctrl_num 	varchar(16),
	@last_trx_ctrl_num 	varchar(16),
	@doc_ctrl_num 	varchar(16),
	@trx_desc 		varchar(40),
	@gl_acct_code		varchar(32),
	@date_entered		int,
	@date_applied		int,
	@date_doc		int,
    	@customer_code	varchar(8),
	@payment_code		varchar(8),
	@amt_payment		float,
	@bal_fwd_flag		smallint,
	@user_id		smallint,
	@cash_acct_code	varchar(32),
 	@process_group_num	varchar(16),
 	@min_trx_ctrl_num	varchar(16),
	@nat_cur_code		varchar(8),
	@rate_type_home	varchar(8),		
	@rate_type_oper	varchar(8),	
	@rate_home		float,
	@rate_oper		float,
	@non_ar_flag		smallint,
	@non_ar_doc_num	varchar(16),
	@amt_on_acct		float,
	@reference_code	varchar(32),
	@org_id			varchar(30)


IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arcaccr.cpp", 74, "Entering ARCACreateCashReceipt_SP", @PERF_time_last OUTPUT

BEGIN

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcaccr.cpp" + ", line " + STR( 78, 5 ) + " -- ENTRY: "


	



	CREATE TABLE #arcacr
	(	
		trx_ctrl_num		varchar(16),
		gl_acct_code		varchar(32),
	    	customer_code		varchar(8),
		bal_fwd_flag		smallint,
		cash_acct_code	varchar(32)
	)

	






	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcaccr.cpp" + ", line " + STR( 101, 5 ) + " -- MSG: " + "Inserting Cash Receipt"
	INSERT  #arcacr
	(
		trx_ctrl_num,
		gl_acct_code,
	    	customer_code,
		bal_fwd_flag,
		cash_acct_code
	)       
	SELECT
		pyt.trx_ctrl_num,
		pyt.gl_acct_code,
	    	trn.customer_code,
		mast.bal_fwd_flag,
		trn.cash_acct_code
	FROM	#arinppyt_work pyt, arcust mast, arcrtran trn
	WHERE	pyt.customer_code = mast.customer_code
	AND	pyt.trx_ctrl_num = trn.trx_ctrl_num
	AND	pyt.batch_code = @batch_ctrl_num
	AND	pyt.void_type = 4
	AND	pyt.trx_type = 2113

	IF( @debug_level >= 2 )
	BEGIN
		SELECT "Cash Receipt Transfer records to be posted.."
		SELECT	" trx_ctrl_num = " + trx_ctrl_num +
			" bal_fwd_flag = " + STR(bal_fwd_flag,2) + 
			" customer_code = " + customer_code +
			" cash_acct_code = " + cash_acct_code +
			" gl_acct_code = " + gl_acct_code
		FROM #arcacr
	END
	
	


	SELECT	@last_trx_ctrl_num = ' ',
		@trx_ctrl_num = NULL

	WHILE(1=1)
	BEGIN
		

  
        
        	SELECT	@min_trx_ctrl_num = MIN(cr.trx_ctrl_num)
        	FROM 	#arcacr cr, #arinppyt_work pyt
		WHERE	cr.trx_ctrl_num > @last_trx_ctrl_num
		AND   	cr.trx_ctrl_num = pyt.trx_ctrl_num

		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcaccr.cpp" + ", line " + STR( 153, 5 ) + " -- EXIT: "
			RETURN 34563
		END
		
		SELECT	@trx_ctrl_num = cr.trx_ctrl_num,
			@doc_ctrl_num = pyt.doc_ctrl_num,
			@trx_desc = pyt.trx_desc,
			@gl_acct_code = cr.gl_acct_code,
			@date_entered = pyt.date_entered,
			@date_applied = pyt.date_applied,
			@date_doc = pyt.date_doc,
		    	@customer_code = cr.customer_code,
			@payment_code = pyt.payment_code,
			@amt_payment = pyt.amt_payment,
			@bal_fwd_flag = cr.bal_fwd_flag,
			@user_id = pyt.user_id,
			@cash_acct_code = cr.cash_acct_code,
		 	@process_group_num = pyt.process_group_num,
			@nat_cur_code = pyt.nat_cur_code,
			@rate_type_home = pyt.rate_type_home,
			@rate_type_oper = pyt.rate_type_oper,
			@rate_home = pyt.rate_home,
			@rate_oper = pyt.rate_oper,
			@non_ar_flag = pyt.non_ar_flag,
			@non_ar_doc_num = pyt.non_ar_doc_num,
			@reference_code = pyt.reference_code,
			@org_id = pyt.org_id
		FROM 	#arcacr cr, #arinppyt_work pyt
		WHERE	cr.trx_ctrl_num = pyt.trx_ctrl_num
		AND	cr.trx_ctrl_num = @min_trx_ctrl_num
	
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcaccr.cpp" + ", line " + STR( 186, 5 ) + " -- EXIT: "
			RETURN 34563
		END

		IF( @trx_ctrl_num IS NULL )
			BREAK

		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcaccr.cpp" + ", line " + STR( 193, 5 ) + " -- MSG: " + "Creating cash receipt for " + @trx_ctrl_num
		
		IF (@non_ar_flag = 0)
			SELECT @amt_on_acct = @amt_payment
		ELSE
			SELECT @amt_on_acct = 0.0
		
		


		SELECT @cr_trx_ctrl_num = @trx_ctrl_num

		EXEC @result = arpycrh_sp	2000,	
						2,
						@cr_trx_ctrl_num OUTPUT,	
						@doc_ctrl_num,		
						@trx_desc,			
						' ',				
						2111,		
						@non_ar_flag,	  		
						@non_ar_doc_num,		
						@gl_acct_code,		
						@date_entered,		
						@date_applied,		
						@date_doc,			
						@customer_code,		
						@payment_code,		
						1,				
						@amt_payment,			
						@amt_on_acct,			
						" ",				
						" ",				
						" ",				
						" ",				
						" ",				
						@bal_fwd_flag,		
						0,				
						-1,				
						0,				
						0,				
						1,				
						@user_id,			
						0.0,				
						0,				
						0,				
						@cash_acct_code,		
						0,				
						@process_group_num,		
						@trx_ctrl_num,		
						2113,		
						@nat_cur_code,		
						@rate_type_home,						
						@rate_type_oper,			
						@rate_home,			
						@rate_oper,			
						@reference_code,		
						@org_id				
		IF( @result != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcaccr.cpp" + ", line " + STR( 252, 5 ) + " -- EXIT: "
			RETURN 34563
		END

		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcaccr.cpp" + ", line " + STR( 256, 5 ) + " -- MSG: " + "Cash Receipt Created = " + @cr_trx_ctrl_num

		



		INSERT arnonardet (	trx_ctrl_num,		trx_type,		sequence_id,		line_desc,		
					tax_code,		gl_acct_code,		unit_price,		extended_price,		
					reference_code,		amt_tax,		qty_shipped,		org_id 
						)
		SELECT 			@cr_trx_ctrl_num, 	2111,		det.sequence_id,	det.line_desc,		
					det.tax_code,		det.gl_acct_code,	det.unit_price,		det.extended_price,	
					det.reference_code,	det.amt_tax,		det.qty_shipped,	det.org_id
		FROM	#arinppyt_work pyt, 	#arnonardet_work det
		WHERE	pyt.trx_ctrl_num	= det.trx_ctrl_num
		AND	pyt.trx_type		= det.trx_type
		AND	pyt.trx_ctrl_num	= @min_trx_ctrl_num
			

		INSERT arinptax	(	trx_ctrl_num,		trx_type,		sequence_id,		tax_type_code,
					amt_taxable,		amt_gross,		amt_tax,		amt_final_tax 
					)
		SELECT 			@cr_trx_ctrl_num,	2111,		tax.sequence_id,	tax.tax_type_code,
					tax.amt_taxable,	tax.amt_gross,		tax.amt_tax,		tax.amt_final_tax
		FROM	#arinppyt_work pyt, 	#arinptax_work tax
		WHERE	pyt.trx_ctrl_num	= tax.trx_ctrl_num
		AND	pyt.trx_type		= tax.trx_type 
		AND	pyt.trx_ctrl_num	= @min_trx_ctrl_num	

		


		


		SELECT	@last_trx_ctrl_num = @trx_ctrl_num,
			@trx_ctrl_num = NULL

	END	

	IF( @debug_level >= 2 )
	BEGIN
		SELECT "dumping #arinppyt after being loaded with transfers. "
		SELECT	"trx_ctrl_num = " + trx_ctrl_num +
			" trx_state = " + STR(trx_state,2) + 
			" customer_code = " + customer_code +
			" amt_payment = " + STR(amt_payment,10,2) +
			" reference_code =" + reference_code
		FROM	#arinppyt
	END
	
	DROP TABLE #arcacr
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcaccr.cpp" + ", line " + STR( 308, 5 ) + " -- EXIT: "
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arcaccr.cpp", 309, "Returning from ARCACreateCashReceipt_SP", @PERF_time_last OUTPUT
    	RETURN 0 




END

GO
GRANT EXECUTE ON  [dbo].[ARCACreateCashReceipt_SP] TO [public]
GO
