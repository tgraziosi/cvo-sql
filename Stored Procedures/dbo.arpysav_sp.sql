SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE  PROCEDURE [dbo].[arpysav_sp]	@company_code	varchar(8), 
					@proc_user_id	smallint,
					@debug_level smallint = 0
AS
DECLARE 
	@tran_started		smallint,
	@batch_module_id    	smallint, 
	@batch_date_applied 	int,            
	@batch_source       	varchar(16),
	@batch_trx_type   	smallint,
	@trx_type         	smallint,
	@home_company     	varchar(8),
	@result           	smallint,
	@new_batch_code    	varchar(16),
	@org_id			varchar(30)  

BEGIN

	SELECT  @tran_started = 0

	SELECT	@home_company = company_code 
	FROM	glco
	



	IF EXISTS(	SELECT  *
			FROM    arco
			WHERE   batch_proc_flag = 1 )
	BEGIN
		INSERT #arpybat
		SELECT  DISTINCT	date_applied, 
					process_group_num,
					trx_type,
					org_id	
		FROM    #arinppyt
		IF( @@error != 0 )
			RETURN 34563
		IF( @debug_level >= 2 )
		BEGIN
			SELECT	"Records in #arpybat that need batches created"
			SELECT	"date_applied:process_group_num:trx_type"
			SELECT	STR(date_applied, 7) + ":" +
				process_group_num + ":" +
				STR(trx_type, 6) 
			FROM	#arpybat
		END

		



		WHILE(1=1)
		BEGIN
			SELECT  @batch_date_applied = NULL
			SELECT  @batch_date_applied = MIN( date_applied )
			FROM    #arpybat
			IF( @@error != 0 )
			BEGIN
				IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arpysav.cpp" + ", line " + STR( 96, 5 ) + " -- EXIT: "
				RETURN 34563
			END
						
			IF ( @batch_date_applied IS NULL )
			BEGIN
				IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "arpysav.cpp" + ", line " + STR( 102, 5 ) + " -- MSG: " + "Leaving batch creation loop"
				break
			END
			
			SELECT  @batch_source = MIN( process_group_num)
			FROM   #arpybat
			WHERE  date_applied  = @batch_date_applied
			IF( @@error != 0 )
			BEGIN
				IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arpysav.cpp" + ", line " + STR( 111, 5 ) + " -- EXIT: "
				RETURN 34563
			END

			SELECT  @trx_type = MIN( trx_type ),
				@org_id = MIN (org_id)
			FROM   #arpybat
			WHERE  date_applied = @batch_date_applied
			AND    process_group_num = @batch_source
			IF( @@error != 0 )
			BEGIN
				IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arpysav.cpp" + ", line " + STR( 122, 5 ) + " -- EXIT: "
				RETURN 34563
			END
			

IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "arpysav.cpp" + ", line " + STR( 127, 5 ) + " -- MSG: " + "Creating batch for " + STR(@batch_date_applied, 7) + " " + "process_group_num: " + @batch_source + " " + "trx_type: " + STR(@trx_type, 6)

			IF @trx_type = 2111
			       SELECT @batch_trx_type = 2050
		    	ELSE IF @trx_type = 2112
				   SELECT @batch_trx_type = 2060
		    	ELSE IF @trx_type = 2113
				   SELECT @batch_trx_type = 2060
		    	ELSE IF @trx_type = 2121
				   SELECT @batch_trx_type = 2060
		    	ELSE IF @trx_type = 2151
				   SELECT @batch_trx_type = 2070

			EXEC    @result = arnxtbat_sp	@batch_module_id,
								@batch_source,
								@batch_trx_type,
								@proc_user_id,
								@batch_date_applied,
								@home_company,
								@new_batch_code OUTPUT,
								0,
								@org_id 
			IF ( @result != 0 )
			BEGIN
				IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arpysav.cpp" + ", line " + STR( 151, 5 ) + " -- EXIT: "
				RETURN  @result
			END

			IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "arpysav.cpp" + ", line " + STR( 155, 5 ) + " -- MSG: " + "Batch number retrieved = " + @new_batch_code + "and batch_trx_type = " + STR(@batch_trx_type, 6)

			UPDATE  #arinppyt
			SET     batch_code = @new_batch_code
			WHERE   date_applied = @batch_date_applied
			AND     trx_type = @trx_type
			AND 	org_id = @org_id  
			IF( @@error != 0 )
			BEGIN
				IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arpysav.cpp" + ", line " + STR( 164, 5 ) + " -- EXIT: "
				RETURN 34563
			END
			
			DELETE  #arpybat
			WHERE   date_applied = @batch_date_applied
			AND trx_type = @trx_type
			AND 	org_id = @org_id  
			IF( @@error != 0 )
			BEGIN
				IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arpysav.cpp" + ", line " + STR( 174, 5 ) + " -- EXIT: "
				RETURN 34563
			END
		END
	END
	ELSE
	BEGIN
		





		UPDATE  #arinppyt
		SET     batch_code = ' '
		IF ( @@error != 0 )
		BEGIN
			RETURN  34563
		END
	END
	




	IF ( @@trancount = 0 )
	BEGIN
		BEGIN TRANSACTION
		SELECT  @tran_started = 1
	END
	
	INSERT  arinppyt 
	(      
    		trx_ctrl_num,		doc_ctrl_num,
		trx_desc,		batch_code,	    	trx_type,
		non_ar_flag,		non_ar_doc_num,	gl_acct_code,
		date_entered,		date_applied,		date_doc,
	    	customer_code,	payment_code,		payment_type,
	    	amt_payment,		amt_on_acct,		prompt1_inp,
		prompt2_inp,		prompt3_inp,		prompt4_inp,
		deposit_num,		bal_fwd_flag,		printed_flag,
		posted_flag,		hold_flag,		wr_off_flag,
		on_acct_flag,		user_id,		max_wr_off,
		days_past_due,	void_type,		cash_acct_code,
	    	origin_module_flag,	process_group_num,	source_trx_ctrl_num,
		source_trx_type,	nat_cur_code,		rate_type_home,
		rate_type_oper,	rate_home,		rate_oper,
		reference_code,		org_id
	)
	SELECT          
		trx_ctrl_num,		doc_ctrl_num,
		trx_desc,		batch_code,	    	trx_type,
		non_ar_flag,		non_ar_doc_num,	gl_acct_code,
		date_entered,		date_applied,		date_doc,
	    	customer_code,	payment_code,		payment_type,
	    	amt_payment,		amt_on_acct,		prompt1_inp,
		prompt2_inp,		prompt3_inp,		prompt4_inp,
		deposit_num,		bal_fwd_flag,		printed_flag,
		posted_flag,		hold_flag,		wr_off_flag,
		on_acct_flag,		user_id,		max_wr_off,
		days_past_due,	void_type,		cash_acct_code,
	    	origin_module_flag,	process_group_num,	source_trx_ctrl_num,
		source_trx_type,	nat_cur_code,		rate_type_home,
		rate_type_oper,	rate_home,		rate_oper,
		reference_code,		org_id
	FROM    #arinppyt
	IF( @@error != 0 )
	BEGIN
		IF( @tran_started = 1 )
			ROLLBACK TRAN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arpysav.cpp" + ", line " + STR( 244, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	



	INSERT arinppdt  
		(trx_ctrl_num, 		doc_ctrl_num,  			sequence_id, 		trx_type, 
		apply_to_num,  		apply_trx_type, 		customer_code, 		date_aging,  
		amt_applied, 		amt_disc_taken, 		wr_off_flag,  		amt_max_wr_off, 
		void_flag, 			line_desc,  			sub_apply_num, 		sub_apply_type, 
		amt_tot_chg,  		amt_paid_to_date, 		terms_code, 		posting_code,  
		date_doc, 			amt_inv, 				gain_home,  		gain_oper, 
		inv_amt_applied, 	inv_amt_disc_taken,  	inv_amt_max_wr_off, inv_cur_code, 
		writeoff_code,		org_id  )  

SELECT  a.trx_ctrl_num, 	a.doc_ctrl_num,  		a.sequence_id, 			a.trx_type, 
		a.apply_to_num,  	a.apply_trx_type, 		a.customer_code, 		a.date_aging,  
		a.amt_applied, 		a.amt_disc_taken, 		a.wr_off_flag,  		a.amt_max_wr_off, 
		a.void_flag, 		a.line_desc,  			a.sub_apply_num, 		a.sub_apply_type, 
		a.amt_tot_chg,  	a.amt_paid_to_date, 	a.terms_code, 			a.posting_code,  
		a.date_doc, 		a.amt_inv, 				a.gain_home,  			a.gain_oper, 
		a.inv_amt_applied, 	a.inv_amt_disc_taken,  	a.inv_amt_max_wr_off, 	a.inv_cur_code, 
		c.writeoff_code,	a.org_id  
FROM 	#arinppdt a,  #arinppyt b, arcust c
where	a.trx_ctrl_num = b.trx_ctrl_num
and	b.customer_code = c.customer_code



	IF( @@error != 0 )
	BEGIN
		IF( @tran_started = 1 )
			ROLLBACK TRAN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arpysav.cpp" + ", line " + STR( 280, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	






	EXEC    @result = arpyusv_sp
	IF ( @result != 0 )
	BEGIN
		IF( @tran_started = 1 )
			ROLLBACK TRAN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arpysav.cpp" + ", line " + STR( 296, 5 ) + " -- EXIT: "
		RETURN  @result
	END
			
	DELETE #arinppyt
	IF( @@error != 0 )
 	BEGIN
 		IF( @tran_started = 1 )
 			ROLLBACK TRAN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arpysav.cpp" + ", line " + STR( 305, 5 ) + " -- EXIT: "
 		RETURN 34563
 	END

	DELETE #arinppdt
	IF( @@error != 0 )
 	BEGIN
 		IF( @tran_started = 1 )
 			ROLLBACK TRAN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arpysav.cpp" + ", line " + STR( 314, 5 ) + " -- EXIT: "
 		RETURN 34563
 	END

	DELETE #arpybat
	IF( @@error != 0 )
 	BEGIN
 		IF( @tran_started = 1 )
 			ROLLBACK TRAN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arpysav.cpp" + ", line " + STR( 323, 5 ) + " -- EXIT: "
 		RETURN 34563
 	END

	IF ( @tran_started = 1 )
	BEGIN
		COMMIT TRANSACTION
		SELECT  @tran_started = 0
	END
	




END
GO
GRANT EXECUTE ON  [dbo].[arpysav_sp] TO [public]
GO
