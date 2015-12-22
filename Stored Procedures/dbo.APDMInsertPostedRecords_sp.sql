SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO





CREATE PROC [dbo].[APDMInsertPostedRecords_sp]  @journal_ctrl_num  varchar(16),
										@date_applied int,
										@debug_level smallint = 0
AS
			 
	DECLARE	@current_date int,
			@dm_count int,
			@next_num int,
			@last_num int,
			@doc_ctrl_num varchar(16),
			@mask varchar(16),
			@disb_num varchar(16),
			@flag smallint

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmipr.cpp" + ", line " + STR( 61, 5 ) + " -- ENTRY: "
			 							 

	EXEC appdate_sp @current_date OUTPUT		



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmipr.cpp" + ", line " + STR( 68, 5 ) + " -- MSG: " + "Insert Debit memo header records"
INSERT  #apdmx_work (
	trx_ctrl_num,           trx_type,               doc_ctrl_num,   
	apply_to_num,           user_trx_type_code,     batch_code,
	po_ctrl_num,            vend_order_num,         date_applied,
	date_doc,               date_entered,           posting_code,
	vendor_code,            pay_to_code,			branch_code,
	class_code,             approval_code,			comment_code,
	fob_code,               terms_code,				tax_code,
	amt_gross,              amt_discount,			amt_freight,
	amt_tax,                amt_misc,				amt_net,
	amt_restock,            amt_tax_included,		frt_calc_tax,
	doc_desc,				user_id,				gl_trx_id,				
	payment_type,			ticket_num,
	amt_on_acct,            intercompany_flag,		company_code,
	cms_flag,				nat_cur_code,			rate_type_home,
	rate_type_oper,			rate_home,				rate_oper,
	org_id,	   		tax_freight_no_recoverable,	db_action)
SELECT
	trx_ctrl_num,           trx_type,               doc_ctrl_num,
	apply_to_num,           user_trx_type_code,     batch_code,
	po_ctrl_num,            vend_order_num,			date_applied,
	date_doc,               date_entered,			posting_code,
	vendor_code,            pay_to_code,			branch_code,
	class_code,             approval_code,			comment_code,
	fob_code,               terms_code,				tax_code,
	amt_gross,              amt_discount,			amt_freight,
	amt_tax,                amt_misc,				amt_net,
	amt_restock,            amt_tax_included,		frt_calc_tax,
	doc_desc,				user_id,				@journal_ctrl_num,		
	0,						ticket_num,
	0,                      intercompany_flag,		company_code,			
	cms_flag,				nat_cur_code,			rate_type_home,			
	rate_type_oper,				rate_home,				rate_oper,		
	org_id,	   		tax_freight_no_recoverable,	2
FROM    #apdmchg_work
  

IF (@@error != 0)
	RETURN -1

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmipr.cpp" + ", line " + STR( 109, 5 ) + " -- MSG: " + "Insert Debit memo tax records"
INSERT  #apdmxtax_work(
	trx_ctrl_num,   trx_type,       tax_type_code,
	date_applied,   amt_gross,      amt_taxable,
	amt_tax,		db_action )
SELECT  a.trx_ctrl_num,   a.trx_type,       a.tax_type_code,
	b.date_applied, a.amt_gross,     a.amt_taxable,    
	a.amt_final_tax,	2
FROM    apinptax a, #apdmchg_work b
WHERE a.trx_ctrl_num = b.trx_ctrl_num
AND a.trx_type = b.trx_type
 

IF (@@ERROR != 0)
	RETURN -1


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmipr.cpp" + ", line " + STR( 126, 5 ) + " -- MSG: " + "Insert voucher tax details records"
INSERT 	#apdmxtaxdtl_work(
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
	db_action)
SELECT	t.trx_ctrl_num,
	t.sequence_id,
	t.trx_type,
	t.tax_sequence_id,
	t.detail_sequence_id,
	t.tax_type_code,
	t.amt_taxable,
	t.amt_gross,
	t.amt_tax,
	t.amt_final_tax,
	t.recoverable_flag,
	t.account_code,
	2
FROM	#apdmtaxdtl_work t, #apdmchg_work h
WHERE	t.trx_ctrl_num = h.trx_ctrl_num AND
		t.trx_type = h.trx_type

IF (@@error != 0)
	RETURN -1


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmipr.cpp" + ", line " + STR( 162, 5 ) + " -- MSG: " + "Insert Debit memo detail records"
INSERT  #apdmxcdt_work(
	trx_ctrl_num,   	trx_type,       sequence_id,
	location_code,  	item_code,      bulk_flag,
	qty_ordered,    	qty_returned,	tax_code,
	return_code,    	unit_code,      unit_price,
	amt_discount,		amt_freight,    amt_tax,
	amt_misc,			date_entered,   gl_exp_acct,
	rma_num,        	line_desc,      serial_id,
	company_id,			approval_code,	amt_extended,
   	calc_tax,			rec_company_code,	reference_code, 
   	po_orig_flag, 		qty_prev_returned,	org_id,	   	db_action,
	amt_nonrecoverable_tax,	amt_tax_det )
SELECT
	trx_ctrl_num,   	trx_type,       sequence_id,
	location_code,  	item_code,      bulk_flag,
	qty_ordered,    	qty_returned,	tax_code,
	return_code,    	unit_code,      unit_price,
	amt_discount,		amt_freight,    amt_tax,
	amt_misc,			date_entered,   gl_exp_acct,    
	rma_num,        	line_desc,      serial_id,
	company_id,			approval_code,	amt_orig_extended,
	calc_tax,			rec_company_code,	reference_code, 
	po_orig_flag,   	qty_prev_returned,	org_id,	   	2,
	amt_nonrecoverable_tax,	amt_tax_det
FROM    #apdmcdt_work
  
IF (@@error != 0)
	RETURN -1






IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmipr.cpp" + ", line " + STR( 197, 5 ) + " -- MSG: " + "Insert Debit memo on-acct records"
INSERT	#apdmx_work (
	trx_ctrl_num,		trx_type,			doc_ctrl_num,	
	apply_to_num,		user_trx_type_code,	batch_code,
	po_ctrl_num,		vend_order_num,		date_applied,		
	date_doc,			date_entered,		posting_code,
	vendor_code,		pay_to_code,		branch_code,
	class_code,			approval_code,		comment_code,
	fob_code,			terms_code,			tax_code,
	amt_gross,			amt_discount,		amt_freight,
	amt_tax,			amt_misc,			amt_net,
	amt_restock,		amt_tax_included,	frt_calc_tax,
	doc_desc,			user_id,			gl_trx_id,			
	payment_type,    	ticket_num,			amt_on_acct,		
	intercompany_flag,	company_code,		cms_flag,			
	nat_cur_code,		rate_type_home,		rate_type_oper,		
	rate_home,			rate_oper,			org_id,	   	db_action)
SELECT
	"",					4111,				trx_ctrl_num,	
	apply_to_num,		" ",				batch_code,
	" ",				" ",				date_applied,
	date_doc,			date_entered,		posting_code,
	vendor_code,		pay_to_code,		branch_code,
	class_code,			approval_code,		" ",
	" ",				" ",				" ",
	amt_net,			0.0,				0.0,
	0.0,				0.0,				amt_net,
	0.0,				amt_tax_included,	frt_calc_tax,
	doc_desc,			user_id,			@journal_ctrl_num,	
	3,					" ",				amt_net,			
	intercompany_flag,	company_code,		cms_flag,		   	
	nat_cur_code,		rate_type_home,		rate_type_oper,		
	rate_home,			rate_oper,			org_id,	   	2
FROM	#apdmchg_work
  
IF @@error != 0
	RETURN -1

INSERT	#apdmxage_work(
	trx_ctrl_num,		trx_type,		doc_ctrl_num,
	ref_id,				apply_to_num,	apply_trx_type,
	date_doc,			date_applied,	date_due,
	date_aging,			vendor_code,	pay_to_code,
	class_code,			branch_code,	amount,
	paid_flag,			cash_acct_code,	amt_paid_to_date,
	nat_cur_code,		rate_home,		rate_oper,
	journal_ctrl_num,	account_code,	org_id,	   	db_action )
SELECT
	"", 				4161,					a.trx_ctrl_num,
	0,					"",						0,		
	a.date_doc,			a.date_applied,			0,
	0,					a.vendor_code,			a.pay_to_code,
	a.class_code,		a.branch_code,			-a.amt_net,
	0,					" ",					0,
	a.nat_cur_code,		a.rate_home,			a.rate_oper,
	@journal_ctrl_num,	dbo.IBAcctMask_fn(b.dm_on_acct_code,org_id),	org_id,	   	2
FROM	#apdmchg_work a, apaccts b
WHERE a.posting_code = b.posting_code

  
IF(@@error != 0)
	RETURN -1


IF EXISTS (SELECT * FROM #apdmx_work WHERE trx_ctrl_num = "")
   BEGIN
	  SELECT @dm_count = count(trx_ctrl_num) FROM #apdmx_work
						WHERE trx_ctrl_num = ""

	  BEGIN TRAN
		  UPDATE apnumber
		  SET next_cash_disb_num = next_cash_disb_num + @dm_count


		  SELECT @next_num = next_cash_disb_num - @dm_count,
		         @mask = cash_disb_num_mask
		  FROM apnumber

	  COMMIT TRAN

	  SELECT @last_num = @next_num + @dm_count	  
	  WHILE (@next_num < @last_num)
	  	  BEGIN
				  EXEC fmtctlnm_sp @next_num, @mask, @disb_num OUTPUT, @flag OUTPUT

				  SET ROWCOUNT 1

				  SELECT @doc_ctrl_num = doc_ctrl_num
				  FROM #apdmx_work
				  WHERE trx_ctrl_num = ""

				  SET ROWCOUNT 0
				  
				  UPDATE #apdmx_work
				  SET trx_ctrl_num = @disb_num
				  WHERE trx_ctrl_num = ""
				  AND doc_ctrl_num = @doc_ctrl_num
				  					
				  SELECT @next_num = @next_num + 1	

		  END
   END

UPDATE #apdmxage_work
SET trx_ctrl_num = b.trx_ctrl_num,
	apply_to_num = b.trx_ctrl_num
FROM #apdmxage_work, #apdmx_work b
WHERE #apdmxage_work.doc_ctrl_num = b.doc_ctrl_num
AND b.trx_type = 4111

IF(@@error != 0)
	RETURN -1


UPDATE #apdmxcdv_work
SET qty_returned = #apdmxcdv_work.qty_returned + b.qty_returned,
    db_action = 1
FROM #apdmxcdv_work, #apdmcdt_work b, #apdmchg_work c
WHERE #apdmxcdv_work.trx_ctrl_num = c.apply_to_num
AND b.trx_ctrl_num = c.trx_ctrl_num
AND #apdmxcdv_work.sequence_id = b.sequence_id


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmipr.cpp" + ", line " + STR( 320, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APDMInsertPostedRecords_sp] TO [public]
GO
