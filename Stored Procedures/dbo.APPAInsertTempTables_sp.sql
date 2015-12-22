SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO






CREATE PROC [dbo].[APPAInsertTempTables_sp]			@process_ctrl_num   varchar(16),
                                			@batch_ctrl_num		varchar(16),
											@debug_level		smallint = 0
	
AS


BEGIN

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appaitt.cpp' + ', line ' + STR( 67, 5 ) + ' -- ENTRY: '



	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appaitt.cpp' + ', line ' + STR( 71, 5 ) + ' -- MSG: ' + 'Insert payment headers'
    INSERT #appapyt_work(	trx_ctrl_num,	
							trx_type,	
							doc_ctrl_num,	
							trx_desc,	
							batch_code,	
							cash_acct_code,	
							date_entered,	
							date_applied,	
							date_doc,	
							vendor_code,	
							pay_to_code,	
							approval_code,	
							payment_code,	
							payment_type,	
							amt_payment,	
							amt_on_acct,	
							posted_flag,	
							printed_flag,	
							hold_flag,	
							approval_flag,	
							gen_id,	
							user_id,	
							void_type,	
							amt_disc_taken,	
							print_batch_num,	
							company_code,	
							nat_cur_code,
							rate_type_home,
							rate_type_oper,
							rate_home,
							rate_oper,
							org_id,
							db_action	)	
    SELECT              	trx_ctrl_num,	
							trx_type,	
							doc_ctrl_num,	
							trx_desc,	
							batch_code,	
							cash_acct_code,	
							date_entered,	
							date_applied,	
							date_doc,	
							vendor_code,	
							pay_to_code,	
							approval_code,	
							payment_code,	
							payment_type,	
							amt_payment,	
							amt_on_acct,	
							posted_flag,	
							printed_flag,	
							hold_flag,	
							approval_flag,	
							gen_id,	
							user_id,	
							void_type,	
							amt_disc_taken,	
							print_batch_num,	
							company_code,	
							nat_cur_code,
							rate_type_home,
							rate_type_oper,
							rate_home,
							rate_oper,
							org_id,
							0
    FROM    apinppyt
    WHERE   batch_code = @batch_ctrl_num

    IF( @@error != 0 )
        RETURN -1

       
	UPDATE #appapyt_work
	SET org_id = ISNULL((select organization_id from Organization where outline_num = '1'),'')
	WHERE org_id IS NULL

	    IF( @@error != 0 )
        	RETURN -1
	



	


	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appaitt.cpp' + ', line ' + STR( 158, 5 ) + ' -- MSG: ' + 'Insert payment details'
	INSERT #appapdt_work(	trx_ctrl_num,	
							trx_type,
							sequence_id,
							apply_to_num,
							apply_trx_type,
							amt_applied,
							amt_disc_taken,
							line_desc,
							void_flag,
							payment_hold_flag,
							vendor_code,
							vo_amt_applied,
							vo_amt_disc_taken,
							gain_home,
							gain_oper,
							nat_cur_code,
							org_id,
							db_action  )			
    SELECT                 	a.trx_ctrl_num,    
                            a.trx_type,    
                            a.sequence_id,
                            a.apply_to_num,    
                            a.apply_trx_type,
                            a.amt_applied,
                            a.amt_disc_taken,
                            a.line_desc,
                            a.void_flag,
                            a.payment_hold_flag, 
                            a.vendor_code,
							a.vo_amt_applied,
							a.vo_amt_disc_taken,
							a.gain_home,
							a.gain_oper,
							a.nat_cur_code,
							a.org_id,		
							0
    FROM    apinppdt a, #appapyt_work b
    WHERE   a.trx_ctrl_num = b.trx_ctrl_num
      AND   a.trx_type = b.trx_type
    IF( @@error != 0 )
        RETURN -1
       
	UPDATE #appapdt_work
	SET org_id = ISNULL((select organization_id from Organization where outline_num = '1'),'')
	WHERE org_id IS NULL

	    IF( @@error != 0 )
        	RETURN -1
	


UPDATE pbatch
SET start_number = (SELECT COUNT(*) FROM #appapyt_work),
	start_total = (SELECT ISNULL(SUM(amt_payment),0.0) FROM #appapyt_work),
	flag = 1
WHERE batch_ctrl_num = @batch_ctrl_num
AND process_ctrl_num = @process_ctrl_num


	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appaitt.cpp' + ', line ' + STR( 218, 5 ) + ' -- EXIT: '
    RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[APPAInsertTempTables_sp] TO [public]
GO
