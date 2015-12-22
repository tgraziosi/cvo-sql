SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO





























  



					  

























































 









































































































































































































































































































































































































































































































































































































































































































































































































































































CREATE PROC [dbo].[arinvcr_sp]	@batch_ctrl_num	varchar( 16 ),
				@process_ctrl_num	varchar( 16 ),
				@trx_type 		smallint,	
				@trx_ctrl_num 	varchar( 16 ),	
				@rec_code_code 	varchar( 8 ),	
				@debug_level		smallint = 0,
				@perf_level		smallint = 0

AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									






IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arinvcr.cpp", 73, "Entering arinvcr_sp", @PERF_time_last OUTPUT




DECLARE	
	@result		smallint,
	@cr_tcn 		varchar( 16 ),	
	@bal_fwd_flag 	smallint, 
	@last_check 		varchar( 16 ),	
	@doc_ctrl_num 	varchar( 16 ),
	@date_aging 		int,	
	@cash_acct 		varchar( 32 ),
	@amt_pymt 		float,  	
	@apply_to_num 	varchar( 16 ),
	@apply_trx_type 	smallint,	
	@amt_disc 		float,	
	@amt_onacct 		float,
	@open_bala 		float,	
	@amt_applied 		float,	
	@trx_desc 		varchar( 60),
	@last_customer	varchar( 8 ),
	@payer_customer_code varchar( 8 ),
	@date_entered		int,
	@date_doc		int,
	@user_id		smallint,
	@date_applied		int,
	@customer_code	varchar( 8 ),
	@payment_code		varchar( 8 ),
	@prompt1_inp		varchar( 30),
	@prompt2_inp		varchar( 30),
	@prompt3_inp		varchar( 30),
	@prompt4_inp		varchar( 30),
	@min_doc_ctrl_num	varchar( 16 ), 
	@nat_cur_code		varchar(8),
	@rate_type_home	varchar(8),		
	@rate_type_oper	varchar(8),	
	@rate_home		float,
	@rate_oper		float,
	@org_id		varchar(30)


BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinvcr.cpp" + ", line " + STR( 116, 5 ) + " -- ENTRY: "

	


	SELECT	@doc_ctrl_num = NULL,
		@payer_customer_code = ' ',
		@last_customer = ' '


	



	SELECT	@apply_to_num = apply_to_num,
		@apply_trx_type = apply_trx_type,
		@date_aging = date_aging,
		@date_entered = date_entered,
		@date_applied = date_applied,		
		@user_id = user_id,
		@org_id	 = org_id
	FROM	#arinpchg_work
	WHERE	trx_ctrl_num = @trx_ctrl_num
	AND	trx_type = @trx_type
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinvcr.cpp" + ", line " + STR( 142, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	








	SELECT	@open_bala = amt_tot_chg - amt_paid_to_date
	FROM	#artrx_work
	WHERE	doc_ctrl_num = @apply_to_num
  	AND	trx_type = @apply_trx_type	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinvcr.cpp" + ", line " + STR( 161, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	







	WHILE ( 1 = 1 )
	BEGIN
		SELECT  @last_customer = @payer_customer_code
       	SELECT  @payer_customer_code = NULL
        
	 	SELECT  @payer_customer_code = MIN(customer_code)
	       FROM    #arinptmp_work
	       WHERE   trx_ctrl_num = @trx_ctrl_num
	       AND     customer_code > @last_customer
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinvcr.cpp" + ", line " + STR( 184, 5 ) + " -- EXIT: "
			RETURN 34563
		END

        	IF( @payer_customer_code IS NULL )
			BREAK

        	


        	SELECT  @doc_ctrl_num = ' '
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinvcr.cpp" + ", line " + STR( 195, 5 ) + " -- MSG: " + "Procesing payments for payer customer " + @payer_customer_code
		
        	


        	WHILE ( 1 = 1 )
        	BEGIN
	       	SELECT	@last_check = @doc_ctrl_num
	        	SELECT	@doc_ctrl_num = NULL

			SELECT @min_doc_ctrl_num = MIN(doc_ctrl_num)
			FROM	#arinptmp_work
        		WHERE	trx_ctrl_num = @trx_ctrl_num
			AND	doc_ctrl_num > @last_check 
			AND	customer_code = @payer_customer_code
			AND	amt_payment > 0.0
			IF	( @@error != 0 )
			BEGIN
				IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinvcr.cpp" + ", line " + STR( 213, 5 ) + " -- EXIT: "
				RETURN 34563
			END
			
			SELECT	@doc_ctrl_num = doc_ctrl_num,
        			@trx_desc = trx_desc,
        			@amt_disc = amt_disc_taken,
        			@amt_pymt = amt_payment,
        			@cash_acct = cash_acct_code
	        	FROM	#arinptmp_work
        		WHERE	trx_ctrl_num = @trx_ctrl_num
			AND	doc_ctrl_num = @min_doc_ctrl_num 
			AND	customer_code = @payer_customer_code 
			IF( @@error != 0 )
			BEGIN
				IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinvcr.cpp" + ", line " + STR( 228, 5 ) + " -- EXIT: "
				RETURN 34563
			END

	        	


        		IF ( @doc_ctrl_num IS NULL )
	        		BREAK

			IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinvcr.cpp" + ", line " + STR( 238, 5 ) + " -- MSG: " + "Creating payment for document number " + @doc_ctrl_num
						
        		



        		
        		IF ( ((@open_bala) > (0.0) + 0.0000001) )
	        	BEGIN
        			SELECT	@open_bala = @open_bala - @amt_pymt - @amt_disc 

	        		
        			IF ((@open_bala) < (0.0) - 0.0000001)
	        		BEGIN
		        		SELECT	@amt_onacct = - @open_bala
			        	SELECT	@open_bala = 0.0,
						@amt_applied = @amt_pymt - @amt_onacct
        			END
	        		ELSE
		        		SELECT	@amt_onacct = 0.0,
						@amt_applied = @amt_pymt
        		END
	        	ELSE
		       	SELECT	@amt_onacct = @amt_pymt,
					@amt_applied = 0

        		



        		SELECT	@bal_fwd_flag = NULL

	        	SELECT	@bal_fwd_flag = bal_fwd_flag
        		FROM	arcust
	        	WHERE	customer_code = @rec_code_code
			IF( @@error != 0 )
			BEGIN
				IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinvcr.cpp" + ", line " + STR( 275, 5 ) + " -- EXIT: "
				RETURN 34563
			END


			SELECT	@trx_desc = trx_desc,
				@date_doc = date_doc,
				@customer_code = customer_code,
				@payment_code = payment_code,
	        		@prompt1_inp = prompt1_inp, 
		        	@prompt2_inp = prompt2_inp,
        			@prompt3_inp = prompt3_inp,
	        		@prompt4_inp = prompt4_inp
        		FROM	#arinptmp_work
	        	WHERE	trx_ctrl_num = @trx_ctrl_num
        	  	AND	doc_ctrl_num = @doc_ctrl_num
			AND	customer_code = @payer_customer_code   
			IF( @@error != 0 )
			BEGIN
				IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinvcr.cpp" + ", line " + STR( 294, 5 ) + " -- EXIT: "
				RETURN 34563
			END

			




			SELECT	@nat_cur_code = nat_cur_code,
				@rate_type_home = rate_type_home,
				@rate_type_oper = rate_type_oper,
				@rate_home = rate_home,
				@rate_oper = rate_oper
			FROM	#arinpchg_work
			WHERE	trx_ctrl_num = @trx_ctrl_num
			AND	trx_type = @trx_type
			


			SELECT	@cr_tcn = ' '
			EXEC @result = arpycrh_sp	2000,
							2,
							@cr_tcn OUTPUT,	
							@doc_ctrl_num,	
							@trx_desc,		
							' ',			
							2111,	
							0,			
							" ",			
							" ",			
							@date_entered,	
							@date_applied,	
							@date_doc,		
							@customer_code,	
							@payment_code,	
							1,			
							@amt_pymt,		
							@amt_onacct,		
							@prompt1_inp,		
							@prompt2_inp,		
							@prompt3_inp,		
							@prompt4_inp,		
							" ",			
							@bal_fwd_flag,	
							0,			
							-1, 			
							0,			
							0,			
							0,			
							@user_id,		
							0,			
							0,			
							0,			
							@cash_acct,		
							0,			
							@process_ctrl_num,	
							@trx_ctrl_num,	
							2031,	
							@nat_cur_code,		
							@rate_type_home,			
							@rate_type_oper,		
							@rate_home,		
							@rate_oper,		
							NULL,			
							@org_id			

			IF( @result != 0 OR @@error != 0 )
			BEGIN
				IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinvcr.cpp" + ", line " + STR( 363, 5 ) + " -- EXIT: "
				RETURN 34563
			END
			


			UPDATE CVO_Control..ccacryptaccts
				SET trx_ctrl_num = @cr_tcn,
				    trx_type = 2111
			FROM    CVO_Control..ccacryptaccts
				WHERE    trx_ctrl_num = @trx_ctrl_num
					AND  ( trx_type = 2031 OR trx_type = 2021 )
			


			UPDATE icv_ccinfo
				SET trx_ctrl_num = @cr_tcn,
				    trx_type = 2111
			FROM    icv_ccinfo
				WHERE    trx_ctrl_num = @trx_ctrl_num
					AND  ( trx_type = 2031 OR trx_type = 2021 )
	        	




        		
			IF (((@amt_disc) > (0.0) + 0.0000001)) OR (((@amt_applied) > (0.0) + 0.0000001))
			BEGIN
				EXEC @result = arpycrd_sp	2000,
								2,
								@cr_tcn,		
								@doc_ctrl_num,	
								1,			
								2111,	
								@apply_to_num,	
								@apply_trx_type,	
								@rec_code_code,		
								@date_aging,		
								@amt_applied,		
								@amt_disc,		
								0,			
								0,			
								0,			
								@trx_desc,		
								" ",			
								0,			
								0,			
								0,			
								" ",			
								" ",			
								0,			
								0,			
								0.0,			
								0.0,			
								@amt_applied,		
								@amt_disc,		
								0.0,					
								@nat_cur_code,			
								@org_id			

				IF( @result != 0 OR @@error != 0 )
				BEGIN
					IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinvcr.cpp" + ", line " + STR( 426, 5 ) + " -- EXIT: "
					RETURN 34563
				END
			END
        	END     
	END     

	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arinvcr.cpp", 433, "Leaving arinvcr_sp", @PERF_time_last OUTPUT
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinvcr.cpp" + ", line " + STR( 434, 5 ) + " -- EXIT: "
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[arinvcr_sp] TO [public]
GO
