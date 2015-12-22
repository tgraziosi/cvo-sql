SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO






CREATE PROC [dbo].[APPYInsertTempTables_sp]			@process_ctrl_num   varchar(16),
                                			@batch_ctrl_num		varchar(16),
											@debug_level		smallint = 0
	
AS

DECLARE
    @result int             

DECLARE @organization_id VARCHAR(30)
SET @organization_id = ISNULL((select organization_id from Organization where outline_num = '1'),'')


	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appyitt.cpp" + ", line " + STR( 93, 5 ) + " -- ENTRY: "



	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appyitt.cpp" + ", line " + STR( 97, 5 ) + " -- MSG: " + "Insert payment headers into #appypyt_work"
    INSERT #appypyt_work(	trx_ctrl_num,	
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
							user_id,	
							amt_disc_taken,	
							print_batch_num,	
							company_code,	
							nat_cur_code,
							rate_type_home,
							rate_type_oper,
							rate_home,
							rate_oper,
							payee_name,
							settlement_ctrl_num,
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
							user_id,	
							amt_disc_taken,	
							print_batch_num,	
							company_code,	
							nat_cur_code,
							rate_type_home,
							rate_type_oper,
							rate_home,
							rate_oper,
							ISNULL(payee_name,''),
							settlement_ctrl_num,
							ISNULL(org_id,@organization_id),
							0
    FROM    apinppyt
    WHERE   batch_code = @batch_ctrl_num

    IF( @@error != 0 )
        RETURN -1




	UPDATE #appypyt_work
	SET payee_name = b.vendor_name
	FROM #appypyt_work a
		INNER JOIN apvend b ON a.vendor_code = b.vendor_code
	WHERE a.payee_name = ''
	AND a.pay_to_code = ''

    IF( @@error != 0 )
        RETURN -1

	UPDATE #appypyt_work
	SET payee_name = b.pay_to_name
	FROM #appypyt_work a
		INNER JOIN apvnd_vw b ON a.vendor_code = b.vendor_code
	WHERE a.payee_name = ''
	AND a.pay_to_code = b.pay_to_code

    IF( @@error != 0 )
        RETURN -1

	


	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appyitt.cpp" + ", line " + STR( 190, 5 ) + " -- MSG: " + "Insert payment details into #appypdt_work"
	INSERT #appypdt_work(	trx_ctrl_num,	
							trx_type,
							sequence_id,
							apply_to_num,
							apply_trx_type,
							amt_applied,
							amt_disc_taken,
							line_desc,
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
                            a.payment_hold_flag, 
                            a.vendor_code,
							a.vo_amt_applied,
							a.vo_amt_disc_taken,
							a.gain_home,
							a.gain_oper,
							a.nat_cur_code,
							ISNULL(a.org_id,@organization_id),
							0
    FROM    apinppdt a
		INNER JOIN #appypyt_work b ON a.trx_ctrl_num = b.trx_ctrl_num AND a.trx_type = b.trx_type

    IF( @@error != 0 )
        RETURN -1


DECLARE @amt_net FLOAT
DECLARE @count INTEGER

SET @amt_net = (SELECT ISNULL(SUM(amt_payment),0.0) FROM #appypyt_work)
SET @count = (SELECT COUNT(1) FROM #appypyt_work)


UPDATE pbatch
SET start_number = @count,
	start_total = @amt_net,
	flag = 1
WHERE batch_ctrl_num = @batch_ctrl_num
AND process_ctrl_num = @process_ctrl_num


	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appyitt.cpp" + ", line " + STR( 247, 5 ) + " -- EXIT: "
    RETURN 0

GO
GRANT EXECUTE ON  [dbo].[APPYInsertTempTables_sp] TO [public]
GO
