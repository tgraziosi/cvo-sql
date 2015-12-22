SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE PROC [dbo].[APDMInsertTempTable_sp]			@process_ctrl_num   varchar(16),
                                			@batch_ctrl_num		varchar(16),
											@debug_level		smallint = 0
                                  
AS

DECLARE
    @result int

DECLARE @organization_id VARCHAR(30)
SET @organization_id = ISNULL((select organization_id from Organization where outline_num = '1'),'')


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmitt.cpp" + ", line " + STR( 102, 5 ) + " -- ENTRY: "

    INSERT #apdmchg_work(	trx_ctrl_num,	
							trx_type,
							doc_ctrl_num,	
							apply_to_num,
							user_trx_type_code,	
							batch_code,
							po_ctrl_num,
							vend_order_num,
							ticket_num,
							date_applied,
							date_doc,
							date_entered,
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
							location_code,	
							posted_flag,
							amt_gross,
							amt_discount,
							amt_tax,
							amt_freight,
							amt_misc,
							amt_tax_included,
							frt_calc_tax,
							glamt_tax,
							glamt_freight,
							glamt_misc,
							glamt_discount,
							amt_net,
							amt_restock,
							doc_desc,
							hold_desc,
							user_id,
							next_serial_id,	
							attention_name,	
							attention_phone,	
							intercompany_flag,	
							company_code,	
							cms_flag,
							iv_ctrl_num,
							nat_cur_code,	 
							rate_type_home,	 
							rate_type_oper,	 
							rate_home,		   
							rate_oper,	
							org_id,
							tax_freight_no_recoverable,	   
							db_action	)	   
    SELECT              	trx_ctrl_num,
							trx_type,
							doc_ctrl_num,
							apply_to_num,
							user_trx_type_code ,
							batch_code,
							po_ctrl_num,
							vend_order_num,
							ticket_num,
							date_applied,
							date_doc,
							date_entered,
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
							location_code,
							posted_flag,
							amt_gross,
							amt_discount,
							amt_tax,
							amt_freight,
							amt_misc,
						   	amt_tax_included,
							frt_calc_tax,
							amt_tax,
							amt_freight,
							amt_misc,
							amt_discount,
							amt_net,
							amt_restock,
							doc_desc,
							hold_desc,
							user_id,
							next_serial_id,
							attention_name,
							attention_phone,
							intercompany_flag,
							company_code,
							cms_flag,
							"",
							nat_cur_code,	 
							rate_type_home,	 
							rate_type_oper,	 
							rate_home,		   
							rate_oper,	
							ISNULL(org_id,@organization_id),
							tax_freight_no_recoverable,
							0
    FROM    apinpchg
    WHERE   batch_code = @batch_ctrl_num

    IF( @@error != 0 )
        RETURN -1




	


    INSERT #apdmcdt_work(	trx_ctrl_num,	
							trx_type,
							sequence_id,
							location_code,
							item_code,
							bulk_flag,
							qty_ordered,
							qty_returned,	
							qty_prev_returned,	
							approval_code,	
							tax_code,
							return_code,
							unit_code,
							unit_price,
							amt_discount,
							amt_freight,
							amt_tax,
							amt_misc,
							amt_extended,
							amt_orig_extended,
							calc_tax,		
							date_entered,
							gl_exp_acct,
							rma_num,
							line_desc,
							serial_id,
							company_id,
							iv_post_flag,
							po_orig_flag,	
							rec_company_code,	
							reference_code,
							org_id,	   	
							db_action,
							amt_nonrecoverable_tax,
							amt_tax_det  )			
    SELECT                 	a.trx_ctrl_num,	
							a.trx_type,
							a.sequence_id,
							a.location_code,
							a.item_code,
							a.bulk_flag,
							a.qty_ordered,
							a.qty_returned,	
							a.qty_prev_returned,	
							a.approval_code,	
							a.tax_code,
							a.return_code,
							a.unit_code,
							a.unit_price,
							a.amt_discount,
							a.amt_freight,
							a.amt_tax,
							a.amt_misc,
							a.amt_extended,
							a.amt_extended,
							a.calc_tax,
							a.date_entered,
							a.gl_exp_acct,
							a.rma_num,
							a.line_desc,
							a.serial_id,
							a.company_id,
							a.iv_post_flag,
							a.po_orig_flag,	
							a.rec_company_code,	
							a.reference_code,	
							ISNULL(a.org_id,@organization_id),	   
							0,
							a.amt_nonrecoverable_tax,
							a.amt_tax_det
    FROM    apinpcdt a
		INNER JOIN #apdmchg_work b ON a.trx_ctrl_num = b.trx_ctrl_num AND   a.trx_type = b.trx_type

    IF( @@error != 0 )
        RETURN -1

       

	INSERT #apdmtaxdtl_work (
				trx_ctrl_num,
				sequence_id,
				trx_type,
				tax_sequence_id,
				detail_sequence_id,
				tax_type_code,
				amt_taxable,
				amt_gross,
				amt_tax,
				amt_final_tax,
				recoverable_flag,
				account_code,
				db_action 
			)
	SELECT			a.trx_ctrl_num,
				a.sequence_id,
				a.trx_type,
				a.tax_sequence_id,
				a.detail_sequence_id,
				a.tax_type_code,
				a.amt_taxable,
				a.amt_gross,
				a.amt_tax,
				a.amt_final_tax,
				a.recoverable_flag,
				a.account_code,
				0
    	FROM    apinptaxdtl a
			INNER JOIN #apdmchg_work b ON a.trx_ctrl_num = b.trx_ctrl_num AND   a.trx_type = b.trx_type


DECLARE @amt_net FLOAT
DECLARE @count INTEGER

SET @amt_net = (SELECT ISNULL(SUM(amt_net),0.0) FROM #apdmchg_work)
SET @count = (SELECT COUNT(1) FROM #apdmchg_work)

UPDATE pbatch
SET start_number = @count,
	start_total = @amt_net,
	flag = 1
WHERE batch_ctrl_num = @batch_ctrl_num
AND process_ctrl_num = @process_ctrl_num


	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmitt.cpp" + ", line " + STR( 350, 5 ) + " -- EXIT: "
    RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APDMInsertTempTable_sp] TO [public]
GO
