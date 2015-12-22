SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

						


CREATE PROC [dbo].[CMMTInsertPostedRecords_sp]  @journal_ctrl_num  varchar(16),
										@date_applied int,
										@debug_level smallint = 0
AS
			 
	DECLARE	@current_date int

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmtipr.cpp" + ", line " + STR( 49, 5 ) + " -- ENTRY: "
			 							 

EXEC appdate_sp @current_date OUTPUT		

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmtipr.cpp" + ", line " + STR( 54, 5 ) + " -- MSG: " + "Load #cmtrx_work"
		INSERT  #cmtrx_work( 
			trx_ctrl_num, 
			trx_type, 
			batch_code, 
			cash_acct_code,
			reference_code,
			date_applied,
			date_entered,
			gl_trx_id,
			user_id,
			date_posted,
			org_id )
		SELECT	trx_ctrl_num, 
			trx_type, 
			batch_code, 
			cash_acct_code,
			reference_code,
			date_applied, 
			date_entered, 
			@journal_ctrl_num, 
			user_id, 
			@current_date,
			org_id
		FROM	#cmmanhdr_work

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmtipr.cpp" + ", line " + STR( 80, 5 ) + " -- MSG: " + "Load #cmtrxdtl_work"

INSERT #cmtrxdtl_work (	trx_ctrl_num, 
					trx_type, 
					sequence_id,
					doc_ctrl_num, 
					date_document,
					trx_type_cls,
					account_code,
					reference_code,
					amount_natural,
					auto_rec_flag,
					org_id	)
		SELECT  		trx_ctrl_num, 
					trx_type, 
					sequence_id,
					doc_ctrl_num, 
					date_document,
					trx_type_cls,
					account_code,
					reference_code,
					amount_natural,
					auto_rec_flag,   
					org_id
		FROM    		#cmmandtl_work



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmtipr.cpp" + ", line " + STR( 108, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[CMMTInsertPostedRecords_sp] TO [public]
GO
