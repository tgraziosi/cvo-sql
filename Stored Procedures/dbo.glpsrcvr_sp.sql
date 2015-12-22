SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                








































































































































































































































































































  



					  

























































 














































































































































































































































































































                       
































































		
CREATE PROCEDURE	[dbo].[glpsrcvr_sp] 
			@process_ctrl_num	varchar(16),
			@source_batch_code	varchar(16),
			@batch_code		varchar(16),
			@org_company_code	varchar(8),
			@rec_company_code	varchar(8),
			@mode			smallint,
			@debug_level			smallint = 0
AS

BEGIN

	DECLARE		@start_time		datetime,
			@work_time		datetime,
			@post_not_completed	smallint,
			@batch_mode_on		smallint,
			@tran_started		smallint,
			@rows			int,
			@err			int,
			@result			int,
			@state			smallint

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "glpsrcvr.cpp" + ", line " + STR( 103, 5 ) + " -- ENTRY: "
	SELECT	@work_time = getdate(), @start_time = getdate()
	


	IF ( @mode NOT IN (	1,
				2,
				3 ) )
	BEGIN
		RETURN	1066
	END
	





	IF ( @org_company_code != @rec_company_code 
	   AND	@source_batch_code = " " )
		RETURN 1066
	



	IF ( @org_company_code = @rec_company_code
	   AND	@mode = 3 )
	BEGIN
		SELECT	@result = 1066
		GOTO	TRX_ROLLBACK
	END
	
	



































	SELECT	@batch_mode_on = 0,
		@tran_started = 0
	



	IF 	@batch_code = " "
		GOTO 	BATCH_EXISTS
		
	ELSE IF EXISTS(	SELECT	*
			FROM	batchctl
			WHERE	batch_ctrl_num = @batch_code
			AND	process_group_num = @process_ctrl_num )
	BEGIN
		GOTO	BATCH_EXISTS
	END
	
	ELSE
	BEGIN
		RETURN	1021
	END
	
	BATCH_EXISTS:

	


	IF EXISTS(	SELECT	*
			FROM	glco
			WHERE	batch_proc_flag = 1 )
	BEGIN
		SELECT	@batch_mode_on = 1
		



		IF ( @batch_code = " " )
			RETURN	1021
	END
		
	IF EXISTS(	SELECT	*
			FROM	gltrx
			WHERE	batch_code = @batch_code
			AND	process_group_num = @process_ctrl_num
			AND	posted_flag = -1 )
	BEGIN
		GOTO POST_NOT_COMPLETED
	END
	
	ELSE
	BEGIN
		


	   	RETURN 0
	END
	
	POST_NOT_COMPLETED:
	




	IF ( @@trancount = 0 )
	BEGIN
		SELECT	@tran_started = 1
		BEGIN TRAN
	END
	
	IF ( @mode = 1 )
	BEGIN
		


		IF ( @batch_code = " " )
		BEGIN
			SELECT	@result = 1021
			GOTO TRX_ROLLBACK
		END
		
		IF ( @debug_level > 3 )
		BEGIN
			SELECT	"*** glpsrcvr_sp - Inserting I/C details into gltrxdet"
			SELECT	convert( char(20), "journal_ctrl_num")+
				convert( char(15), "sequence_id" )+
				convert( char(15), "company_code" )
			SELECT	convert( char(20), d.journal_ctrl_num)+
				convert( char(15), d.sequence_id )+
				convert( char(15), d.rec_company_code )
			FROM	glictrxd d, gltrx h
			WHERE	h.batch_code = @batch_code
			AND	h.journal_ctrl_num = d.journal_ctrl_num
		END
			
		





		INSERT 	gltrxdet
		       (journal_ctrl_num,	
			sequence_id,	
			account_code,
			posted_flag,		
			date_posted,	
			balance, 
			document_1,		
			description,
			rec_company_code,
			company_id,
			document_2,
			reference_code,
			nat_balance,
			nat_cur_code,
			rate,
			trx_type,
			offset_flag,
			seg1_code,
			seg2_code,
			seg3_code,
			seg4_code,
			seq_ref_id,
			balance_oper,
			rate_oper,
			rate_type_home,
			rate_type_oper)
		SELECT	d.journal_ctrl_num,	
			d.sequence_id,	
			d.account_code,
			d.posted_flag,		
			d.date_posted,	
			d.balance, 
			d.document_1,		
			d.description,
			d.rec_company_code,
			d.company_id,
			d.document_2,
			d.reference_code,
			d.nat_balance,
			d.nat_cur_code,
			d.rate,
			d.trx_type,
			d.offset_flag,
			d.seg1_code,
			d.seg2_code,
			d.seg3_code,
			d.seg4_code,
			d.seq_ref_id,
			d.balance_oper,
			d.rate_oper,
			d.rate_type_home,
			d.rate_type_oper
		FROM	glictrxd d, gltrx h
		WHERE	h.batch_code = @batch_code
		AND	h.journal_ctrl_num = d.journal_ctrl_num

		SELECT	@rows = @@rowcount, @err = @@error
		IF ( @err != 0 )
		BEGIN
			SELECT	@result = 1039
			GOTO	TRX_ROLLBACK
		END

		DELETE	glictrxd
		FROM	glictrxd t, gltrxdet d
		WHERE	d.journal_ctrl_num = t.journal_ctrl_num
		AND	d.sequence_id = t.sequence_id

		IF ( @@error != 0 OR @rows != @@rowcount )
		BEGIN
			SELECT	@result = 1039
			GOTO	TRX_ROLLBACK
		END
	END

	ELSE IF ( @mode = 3 )
	BEGIN
		
		IF ( @debug_level > 3 )
		BEGIN
			SELECT	"*** glpsrcvr_sp - Deleting recipient details from "+@rec_company_code
				+" for batch code: "+@batch_code
			SELECT	convert( char(20), "journal_ctrl_num")+
				convert( char(15), "sequence_id" )+
				convert( char(15), "company_code" )
			SELECT	convert( char(20), d.journal_ctrl_num)+
				convert( char(15), d.sequence_id )+
				convert( char(15), d.rec_company_code )
			FROM	gltrxdet d, gltrx h
			WHERE	h.journal_ctrl_num = d.journal_ctrl_num
			AND	h.batch_code = @batch_code
			AND	h.source_batch_code = @source_batch_code
			AND	h.company_code = @rec_company_code
			AND	h.source_company_code = @org_company_code
			AND	h.process_group_num = @process_ctrl_num
		END
			
		DELETE	gltrxdet
		FROM	gltrxdet d, gltrx h
		WHERE	h.journal_ctrl_num = d.journal_ctrl_num
		AND	h.batch_code = @batch_code
		AND	h.source_batch_code = @source_batch_code
		AND	h.company_code = @rec_company_code
		AND	h.source_company_code = @org_company_code
		AND	h.process_group_num = @process_ctrl_num

		IF ( @@error != 0 )
		BEGIN
			SELECT	@result = 1039
			GOTO	TRX_ROLLBACK
		END
	
		DELETE	gltrx
		WHERE	batch_code = @batch_code
		AND	source_batch_code = @source_batch_code
		AND	company_code = @rec_company_code
		AND	source_company_code = @org_company_code
		AND	process_group_num = @process_ctrl_num

		IF ( @@error != 0 )
		BEGIN
			SELECT	@result = 1039
			GOTO	TRX_ROLLBACK
		END
		
	END
	





	ELSE IF ( @batch_mode_on = 0 )
	BEGIN
		IF ( @debug_level > 3 )
		BEGIN
			SELECT	"*** glpsrcvr_sp - Non Batch: Recovering transactions in "+@rec_company_code
			SELECT	convert( char(20), "journal_ctrl_num")+
				convert( char(15), "company_code" )
			SELECT	convert( char(20), journal_ctrl_num)+
				convert( char(15), company_code )
			FROM	gltrx
			WHERE	batch_code = @batch_code
			AND	company_code = @rec_company_code
			AND	process_group_num = @process_ctrl_num
		END
			
		IF ( @org_company_code = @rec_company_code )
		BEGIN
			
			EXEC 	glpsrcvrib_sp	@process_ctrl_num,@batch_code, @org_company_code
			
			UPDATE	gltrx
			SET	posted_flag = 0,
				batch_code = " ",
				process_group_num = " "
			FROM	gltrx
			WHERE	batch_code = @batch_code
			AND	company_code = @org_company_code
			AND	process_group_num = @process_ctrl_num


			
			IF ( @@error != 0 )
			BEGIN
				SELECT	@result = 1039
				GOTO	TRX_ROLLBACK
			END
		END
	
		ELSE
		BEGIN
						
			UPDATE	gltrx
			SET	posted_flag = 0,
				batch_code = " ",
				process_group_num = " "
			FROM	gltrx
			WHERE	batch_code = @batch_code
			AND	source_batch_code = @source_batch_code
			AND	company_code = @rec_company_code
			AND	source_company_code = @org_company_code
			AND	process_group_num = @process_ctrl_num

			IF ( @@error != 0 )
			BEGIN
				SELECT	@result = 1039
				GOTO	TRX_ROLLBACK
			END
		END
	END
	






	ELSE
	BEGIN
		IF ( @debug_level > 3 )
		BEGIN
			SELECT	"*** glpsrcvr_sp - Batch Mode: Recovering transactions for "+@batch_code
			SELECT	convert( char(20), "journal_ctrl_num")+
				convert( char(15), "company_code" )
			SELECT	convert( char(20), journal_ctrl_num)+
				convert( char(15), company_code )
			FROM	gltrx
			WHERE	batch_code = @batch_code
			AND	process_group_num = @process_ctrl_num
		END
		
		EXEC 	glpsrcvrib_sp	@process_ctrl_num,@batch_code, @org_company_code

		UPDATE	gltrx
		SET	posted_flag = 0,
			process_group_num = " "
		WHERE	batch_code = @batch_code
		AND	process_group_num = @process_ctrl_num

		IF ( @@error != 0 )
		BEGIN
			SELECT	@result = 1039
			GOTO	TRX_ROLLBACK
		END
	END
	




	IF ( @mode IN (	2,
			3 )
	AND 
		@batch_code != " " )
	BEGIN
		IF ( @batch_mode_on = 1 )
			SELECT	@state = 0
		ELSE
			SELECT	@state = 4
			
		EXEC	@result = batupdst_sp	@batch_code, 
						@state
					
		IF ( @result != 0 )
		BEGIN
			GOTO	TRX_ROLLBACK
		END
	END
	
	IF ( @tran_started = 1)
	BEGIN 
		COMMIT TRAN
	END
	
	IF ( @debug_level > 1 ) SELECT "glpsrcvr.cpp" + ", line " + STR( 526, 5 ) + " -- MSG: " + CONVERT(char,@start_time,100) + " "
	


	RETURN 	0
	


	TRX_ROLLBACK:
	
	IF ( @tran_started = 1 )
	BEGIN
		ROLLBACK TRAN
	END

	IF ( @debug_level > 0 ) SELECT "glpsrcvr.cpp" + ", line " + STR( 541, 5 ) + " -- MSG: " + CONVERT(char,@start_time,100) + "Exiting - ERROR"	
	RETURN	@result
END

GO
GRANT EXECUTE ON  [dbo].[glpsrcvr_sp] TO [public]
GO
