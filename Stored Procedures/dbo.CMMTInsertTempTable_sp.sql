SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROC [dbo].[CMMTInsertTempTable_sp]			@process_ctrl_num   varchar(16),
                                			@batch_ctrl_num		varchar(16),
											@debug_level		smallint = 0
   
AS

DECLARE
    @result int



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'cmmtitt.cpp' + ', line ' + STR( 53, 5 ) + ' -- ENTRY: '

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'cmmtitt.cpp' + ', line ' + STR( 55, 5 ) + ' -- MSG: ' + 'Load #cmmanhdr_work'
INSERT	#cmmanhdr_work 
	(
	 trx_ctrl_num,
	 trx_type,
	 description,
	 batch_code,
	 cash_acct_code,
	 reference_code,
	 date_applied,
	 date_entered,
	 user_id,
	 total,
	 currency_code,
	 rate_type_home,
	 rate_type_oper,
	 rate_home,
	 rate_oper,
	 org_id	 
	)

SELECT  	 trx_ctrl_num,
			 trx_type,
			 description,
			 batch_code,
			 cash_acct_code,
	                 reference_code,
			 date_applied,
			 date_entered,
			 user_id,
			 total,
			 currency_code,
			 rate_type_home,
			 rate_type_oper,
			 rate_home,
			 rate_oper,
			 org_id
FROM	cmmanhdr
WHERE	batch_code = @batch_ctrl_num 
AND 	posted_flag = -1

IF( @@error != 0 )
        RETURN -1
        
	UPDATE #cmmanhdr_work 
	SET org_id = ISNULL((select organization_id from Organization where outline_num = '1'),'') 
	WHERE org_id IS NULL

	    IF( @@error != 0 )
        	RETURN -1
	



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'cmmtitt.cpp' + ', line ' + STR( 109, 5 ) + ' -- MSG: ' + 'Load #cmmandtl_work'
INSERT #cmmandtl_work 
   (
	 trx_ctrl_num,
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
	)
SELECT	 a.trx_ctrl_num,
		 a.trx_type,
		 a.sequence_id,
		 a.doc_ctrl_num,
		 a.date_document,
		 a.trx_type_cls,
		 a.account_code,
	         a.reference_code,
		 a.amount_natural,
		 a.auto_rec_flag,
		 a.org_id
FROM cmmandtl a, #cmmanhdr_work b
WHERE a.trx_ctrl_num = b.trx_ctrl_num

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'cmmtitt.cpp' + ', line ' + STR( 138, 5 ) + ' -- EXIT: '
    RETURN 0


 
	UPDATE #cmmandtl_work 
	SET org_id = ISNULL((select organization_id from Organization where outline_num = '1'),'') 
	WHERE org_id IS NULL

	    IF( @@error != 0 )
        	RETURN -1
 
GO
GRANT EXECUTE ON  [dbo].[CMMTInsertTempTable_sp] TO [public]
GO
