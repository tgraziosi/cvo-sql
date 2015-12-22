SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE PROC [dbo].[APVAInsertTempTable_sp]			@process_ctrl_num   varchar(16),
                                			@batch_ctrl_num		varchar(16),
											@debug_level		smallint = 0
AS

DECLARE
    @result int



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvaitt.cpp" + ", line " + STR( 68, 5 ) + " -- ENTRY: "

    INSERT #apvachg_work(	trx_ctrl_num,	
							trx_type,
							doc_ctrl_num,	
							apply_to_num,
							user_trx_type_code,	
							batch_code,
							po_ctrl_num,
							vend_order_num,
							ticket_num,
							date_applied,
							date_aging,
							date_due,
							date_doc,
							date_entered,
							date_received,
							date_required,
							date_discount,
							posting_code,
							vendor_code,
							pay_to_code,
							branch_code,
							class_code,
							approval_code,
							comment_code,
							fob_code,
							terms_code,
							tax_code,
							recurring_code,	
							payment_code,	
							posted_flag,
							recurring_flag,
							one_time_vend_flag,	
							one_check_flag,	
							amt_gross,
							amt_discount,
							amt_tax,
							amt_freight,
							amt_misc,
							amt_net,
							amt_tax_included,
							frt_calc_tax,
							doc_desc,
							hold_desc,
							user_id,
							next_serial_id,	
							attention_name,	
							attention_phone,	
							intercompany_flag,	
							company_code,	
							cms_flag,
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
							apply_to_num,
							user_trx_type_code,	
							batch_code,
							po_ctrl_num,
							vend_order_num,
							ticket_num,
							date_applied,
							date_aging,
							date_due,
							date_doc,
							date_entered,
							date_received,
							date_required,
							date_discount,
							posting_code,
							vendor_code,
							pay_to_code,
							branch_code,
							class_code,
							approval_code,
							comment_code,
							fob_code,
							terms_code,
							tax_code,
							recurring_code,	
							payment_code,	
							posted_flag,
							recurring_flag,
							one_time_vend_flag,	
							one_check_flag,	
							amt_gross,
							amt_discount,
							amt_tax,
							amt_freight,
							amt_misc,
							amt_net,
							amt_tax_included,
							frt_calc_tax,
							doc_desc,
							hold_desc,
							user_id,
							next_serial_id,	
							attention_name,	
							attention_phone,	
							intercompany_flag,	
							company_code,	
							cms_flag,
							nat_cur_code,
							rate_type_home,
							rate_type_oper,
							rate_home,
							rate_oper,
							org_id,
							0
    FROM    apinpchg
    WHERE   batch_code = @batch_ctrl_num

    IF( @@error != 0 )
        RETURN -1

	
	UPDATE #apvachg_work
	SET org_id = ISNULL((select organization_id from Organization where outline_num = '1'),'') 
	WHERE org_id IS NULL

	    IF( @@error != 0 )
        	RETURN -1
	


	


    INSERT #apvacdt_work(	trx_ctrl_num,	
							trx_type,
							sequence_id,
							location_code,
							item_code,
							bulk_flag,
							qty_ordered,
							qty_received,	
							qty_prev_returned,	
							approval_code,	
							tax_code,
							code_1099,
							po_ctrl_num,
							unit_code,
							unit_price,
							amt_discount,
							amt_freight,
							amt_tax,
							amt_misc,
							amt_extended,
							calc_tax,		
							date_entered,
							gl_exp_acct,
							new_gl_exp_acct,
							rma_num,
							line_desc,
							serial_id,
							company_id,
							iv_post_flag,
							po_orig_flag,	
							rec_company_code,	
							new_rec_company_code,
							reference_code,	
							new_reference_code,	
							org_id,
							db_action,
							amt_nonrecoverable_tax  )			
    SELECT                 	a.trx_ctrl_num,	
							a.trx_type,
							a.sequence_id,
							a.location_code,
							a.item_code,
							a.bulk_flag,
							a.qty_ordered,
							a.qty_received,	
							a.qty_prev_returned,	
							a.approval_code,	
							a.tax_code,
							a.code_1099,
							a.po_ctrl_num,
							a.unit_code,
							a.unit_price,
							a.amt_discount,
							a.amt_freight,
							a.amt_tax,
							a.amt_misc,
							a.amt_extended,
							a.calc_tax,		
							a.date_entered,
							a.gl_exp_acct,
							a.new_gl_exp_acct,
							a.rma_num,
							a.line_desc,
							a.serial_id,
							a.company_id,
							a.iv_post_flag,
							a.po_orig_flag,	
							a.rec_company_code,	
							a.new_rec_company_code,
							a.reference_code,	
							a.new_reference_code,	
							a.org_id,
							0,
							a.amt_nonrecoverable_tax
    FROM    apinpcdt a, #apvachg_work b
    WHERE   a.trx_ctrl_num = b.trx_ctrl_num
      AND   a.trx_type = b.trx_type

    IF( @@error != 0 )
        RETURN -1
 
      
	UPDATE #apvacdt_work
	SET org_id = ISNULL((select organization_id from Organization where outline_num = '1'),'')
	WHERE org_id IS NULL

	    IF( @@error != 0 )
        	RETURN -1
	


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvaitt.cpp" + ", line " + STR( 294, 5 ) + " -- MSG: " + "Load #apvaage_work"
INSERT	#apvaage_work(
	trx_ctrl_num,	
	trx_type,
	sequence_id,	
	date_applied,	
	date_due,
	date_aging,	
	amt_due,	
	db_action)
SELECT	a.trx_ctrl_num,	
		a.trx_type,
		a.sequence_id,	
		a.date_applied,	
		a.date_due,
		a.date_aging,	
		a.amt_due,
		0
FROM	apinpage a, #apvachg_work h
WHERE	a.trx_ctrl_num = h.trx_ctrl_num AND
	a.trx_type = h.trx_type

  
UPDATE pbatch
SET start_number = (SELECT COUNT(*) FROM #apvachg_work),
	start_total = (SELECT ISNULL(SUM(amt_net),0.0) FROM #apvachg_work),
	flag = 1
WHERE batch_ctrl_num = @batch_ctrl_num
AND process_ctrl_num = @process_ctrl_num


	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvaitt.cpp" + ", line " + STR( 325, 5 ) + " -- EXIT: "
    RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APVAInsertTempTable_sp] TO [public]
GO
