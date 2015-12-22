SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[APVOModifyPersistant_sp]
											@batch_ctrl_num		varchar(16),
											@client_id 			varchar(20),
											@user_id			smallint,  
											@debug_level		smallint = 0
	
AS

DECLARE
	@start_user_id		smallint,
	@errbuf				varchar(100),
	@result				int,
	@next_period        int,
	@date_applied       int,
	@company_code       varchar(8),
	@new_batch_code     varchar(16),
	@current_date       int,
	@home_cur_code 		varchar(8),
	@oper_cur_code 		varchar(8),
	@batch_desc			varchar(30),
	@gst_flag		smallint,
	@org_id			varchar(30) 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvomp.cpp" + ", line " + STR( 89, 5 ) + " -- ENTRY: "




EXEC appdate_sp @current_date OUTPUT		

SELECT @date_applied = date_applied
FROM batchctl a, ewusers_vw b
WHERE a.batch_ctrl_num = @batch_ctrl_num

SELECT @start_user_id = ISNULL(b.user_id,@user_id)
FROM batchctl a, ewusers_vw b
WHERE a.batch_ctrl_num = @batch_ctrl_num
AND	a.start_user = b.user_name


SELECT @company_code = company_code FROM glco




EXEC @result = APVOUPActivity_sp  	@batch_ctrl_num, 
									@client_id,
									@user_id,
	                                @debug_level
IF(@result != 0 )
	RETURN @result





IF EXISTS (SELECT 1 FROM #apvox_work
           WHERE recurring_flag = 1)
BEGIN

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvomp.cpp" + ", line " + STR( 126, 5 ) + " -- MSG: " + "update apcycle date_last_used"

UPDATE apcycle
SET date_last_used = b.date_applied
FROM apcycle a, #apvox_work b
WHERE a.cycle_code = b.recurring_code

IF (@@error != 0)
	RETURN -1

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvomp.cpp" + ", line " + STR( 136, 5 ) + " -- MSG: " + "update apcycle amt_tracked_balance"

UPDATE apcycle
SET amt_tracked_balance = amt_tracked_balance + (SELECT ISNULL(SUM(amt_net),0.0) FROM #apvox_work b
										WHERE b.recurring_code = a.cycle_code)
FROM apcycle a
	INNER JOIN #apvox_work WRK ON a.cycle_code = WRK.recurring_code
WHERE tracked_flag > 0


IF (@@error != 0)
	RETURN -1

END






IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvomp.cpp" + ", line " + STR( 156, 5 ) + " -- MSG: " + "delete records in apinpcdt"
DELETE  apinpcdt
FROM	#apvocdt_work t
	INNER JOIN apinpcdt a ON t.trx_ctrl_num = a.trx_ctrl_num AND t.trx_type = a.trx_type AND t.sequence_id = a.sequence_id
WHERE (t.db_action & 4) = 4


IF (@@error != 0)
	RETURN -1





IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvomp.cpp" + ", line " + STR( 170, 5 ) + " -- MSG: " + "update records in apinpchg"





DELETE  apinpchg_all
FROM	#apvochg_work t
	INNER JOIN apinpchg_all a ON t.trx_ctrl_num = a.trx_ctrl_num AND t.trx_type = a.trx_type
WHERE (t.db_action & 4) = 4



IF (@@error != 0)
	RETURN -1









--REV 3.1
IF EXISTS (SELECT 1 FROM apinpchg_all (nolock)
		   WHERE batch_code = @batch_ctrl_num
		   AND accrual_flag = 1)

BEGIN		   	

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvomp.cpp" + ", line " + STR( 201, 5 ) + " -- MSG: " + "update accrual voucher in input tables"

SELECT  @next_period = 0
SELECT  @next_period = MIN( period_start_date )
FROM    glprd
WHERE   period_start_date > @date_applied



		UPDATE apinpchg
		SET rate_home = b.rate
		FROM apinpchg a
			INNER JOIN #rates b ON a.nat_cur_code = b.from_currency AND a.rate_type_home = b.rate_type
		WHERE b.to_currency = @home_cur_code
		

		UPDATE apinpchg
		SET rate_oper = b.rate
		FROM apinpchg a
			INNER JOIN #rates b ON a.nat_cur_code = b.from_currency AND a.rate_type_oper = b.rate_type
		WHERE b.to_currency = @oper_cur_code
		

   IF (SELECT batch_proc_flag FROM apco) = 1
       BEGIN


				SELECT @new_batch_code = NULL


				IF (SELECT batch_desc_flag from apco (NOLOCK)) = 1
				BEGIN
					SELECT @batch_desc = batch_description FROM batchctl (NOLOCK) WHERE batch_ctrl_num = @batch_ctrl_num

				END
				ELSE
				BEGIN
					SELECT @batch_desc = "Created from " + @batch_ctrl_num

				END


--				SELECT org_id INTO #new_batches FROM apinpchg  
-- REV 3.1 											
				SELECT org_id INTO #new_batches FROM apinpchg_all (nolock)
				WHERE batch_code = @batch_ctrl_num
					AND accrual_flag = 1
			
				WHILE (1=1) 				
				BEGIN

					SELECT @org_id = MIN(org_id)	
						FROM #new_batches

					IF ( @org_id IS NULL )		
						break
					
	
					EXEC @result = apnxtbat_sp	4000,  @batch_ctrl_num ,	4010,		
									@start_user_id,	@next_period,	@company_code,
									@new_batch_code OUTPUT, @batch_desc, @org_id
					IF (@result != 0)
						RETURN @result                            
				
--					UPDATE apinpchg
--  REV 3.1
					UPDATE apinpchg_all
					SET batch_code = @new_batch_code,
				   		posted_flag = 0,
						process_group_num = "",
						date_applied = @next_period,
						hold_flag = 1,
						times_accrued = times_accrued + 1
					WHERE batch_code = @batch_ctrl_num
					AND accrual_flag = 1
					AND org_id = @org_id	
	
					IF (@@error != 0)
						RETURN -1
		
					


-- REV 3.1
				 	DECLARE @count_trx_ctrl_num int
					DECLARE @sum_amt_net int											
				
					SELECT @count_trx_ctrl_num = count(trx_ctrl_num), @sum_amt_net = sum(amt_net)
					FROM apinpchg_all (nolock) WHERE batch_code = @new_batch_code


					UPDATE	batchctl
					SET	actual_number = @count_trx_ctrl_num,
						actual_total = @sum_amt_net,
						number_held = @count_trx_ctrl_num,
						hold_flag = 1
					WHERE	batch_ctrl_num = @new_batch_code

--REV 3.1











				 
				 	IF (@@error != 0)
							RETURN -1

					DELETE #new_batches 	
					WHERE org_id = @org_id	

					SELECT @new_batch_code = NULL
				END

		 		DROP TABLE #new_batches	
	 END
	ELSE
		UPDATE apinpchg_all
		SET batch_code = "",
		    posted_flag = 0,
			process_group_num = "",
			date_applied = @next_period,
			hold_flag = 1,
			times_accrued = times_accrued + 1
		WHERE batch_code = @batch_ctrl_num
		AND accrual_flag = 1













		IF (@@error != 0)
				RETURN -1

END







IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvomp.cpp" + ", line " + STR( 357, 5 ) + " -- MSG: " + "delete apinptax"
DELETE  apinptax
FROM	#apvotax_work t
	INNER JOIN apinptax a ON a.trx_ctrl_num = t.trx_ctrl_num AND a.trx_type = t.trx_type AND a.sequence_id = t.sequence_id
WHERE (t.db_action & 4) = 4


IF (@@error != 0)
	RETURN -1




IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvomp.cpp" + ", line " + STR( 370, 5 ) + " -- MSG: " + "delete apinptaxdtl"
DELETE  apinptaxdtl
FROM	#apvotaxdtl_work t
	INNER JOIN apinptaxdtl a ON a.trx_ctrl_num = t.trx_ctrl_num AND a.trx_type = t.trx_type AND a.sequence_id = t.sequence_id
WHERE (t.db_action & 4) = 4

IF (@@error != 0)
	RETURN -1




IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvomp.cpp" + ", line " + STR( 382, 5 ) + " -- MSG: " + "delete apinptmp"
DELETE  apinptmp
FROM	#apvotmp_work t
	INNER JOIN apinptmp a ON t.trx_ctrl_num = a.trx_ctrl_num
WHERE (t.db_action & 4) = 4

IF (@@error != 0)
	RETURN -1




IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvomp.cpp" + ", line " + STR( 394, 5 ) + " -- MSG: " + "delete apinpage"
DELETE  apinpage
FROM	#apvoage_work t
	INNER JOIN apinpage a ON t.trx_ctrl_num = a.trx_ctrl_num AND t.trx_type = a.trx_type AND t.sequence_id = a.sequence_id
WHERE (t.db_action & 4) = 4

IF (@@error != 0)
	RETURN -1

SELECT @gst_flag = gst_flag FROM glco

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvomp.cpp" + ", line " + STR( 405, 5 ) + " -- MSG: " + "insert apmaster"

IF (@gst_flag <> 1)
BEGIN
	INSERT  apmaster (
		vendor_code,       pay_to_code,         address_name,
		short_name,        addr1,               addr2,
		addr3,             addr4,               addr5,
		addr6,             addr_sort1,          addr_sort2,
		addr_sort3,        address_type,        status_type,
		attention_name,    attention_phone,     contact_name,
		contact_phone,     tlx_twx,             phone_1,
		phone_2,           tax_code,            terms_code,
		fob_code,          posting_code,        location_code,
		orig_zone_code,    customer_code,       affiliated_vend_code,
		alt_vendor_code,   comment_code,        vend_class_code,
		branch_code,       pay_to_hist_flag,    item_hist_flag,
		credit_limit_flag, credit_limit,        aging_limit_flag,
		aging_limit,       restock_chg_flag,    restock_chg,
		prc_flag,          vend_acct,           tax_id_num,
		flag_1099,         exp_acct_code,       amt_max_check,
		lead_time,         note,	      	doc_ctrl_num,
		one_check_flag,    dup_voucher_flag,    dup_amt_flag,
		code_1099,         user_trx_type_code,  payment_code,
		limit_by_home,	   rate_type_home,	rate_type_oper,
		nat_cur_code,	   one_cur_vendor,	cash_acct_code,
		city,		   state,		postal_code,
		country,	   url,			freight_code 
		)
	SELECT	vendor_code,       pay_to_code,			addr1,
			" ",               addr1,		        addr2,
			addr3,      	   addr4,       		addr5,
			addr6,      	   " ",                 " ",
			" ",               2,                   5,
			attention_name,    attention_phone,     " ",
			" ",               " ",                 " ",
			" ",               " ",                 " ",
			" ",               " ",                 " ",
			" ",               NULL,                NULL,
			NULL,              NULL,                NULL,
			NULL,              0,                   0,
			NULL,              NULL,                NULL,
			NULL,              NULL,                NULL,
			NULL,              NULL,                NULL,
			1,                 NULL,                NULL,
			NULL,              " ",                 NULL,
			NULL,              NULL,                NULL,
			"",                NULL,                NULL,
			NULL,			   rate_type_home,		rate_type_oper,
			nat_cur_code,	   NULL,				NULL,
			"",				   "",					"",
			"",				   "",					""
	FROM    #apvomast_work
	WHERE	(db_action & 2) = 2
END

ELSE
BEGIN






	INSERT  apmaster (
		vendor_code,       pay_to_code,         address_name,
		short_name,        addr1,               addr2,
		addr3,             addr4,               addr5,
		addr6,             addr_sort1,          addr_sort2,
		addr_sort3,        address_type,        status_type,
		attention_name,    attention_phone,     contact_name,
		contact_phone,     tlx_twx,             phone_1,
		phone_2,           tax_code,            terms_code,
		fob_code,          posting_code,        location_code,
		orig_zone_code,    customer_code,       affiliated_vend_code,
		alt_vendor_code,   comment_code,        vend_class_code,
		branch_code,       pay_to_hist_flag,    item_hist_flag,
		credit_limit_flag, credit_limit,        aging_limit_flag,
		aging_limit,       restock_chg_flag,    restock_chg,
		prc_flag,          vend_acct,           tax_id_num,
		flag_1099,         exp_acct_code,       amt_max_check,
		lead_time,         note,	      	doc_ctrl_num,
		one_check_flag,    dup_voucher_flag,    dup_amt_flag,
		code_1099,         user_trx_type_code,  payment_code,
		limit_by_home,	   rate_type_home,	rate_type_oper,
		nat_cur_code,	   one_cur_vendor,	cash_acct_code,
		city,		   state,		postal_code,
		country,	   url,			freight_code 
		)
	SELECT	vendor_code,       pay_to_code,			addr1,
			" ",               addr1,		        addr2,
			addr3,      	   addr4,       		addr5,
			" ",      	   " ",                 " ",
			" ",               2,                   5,
			attention_name,    attention_phone,     " ",
			" ",               " ",                 " ",
			" ",               " ",                 " ",
			" ",               " ",                 " ",
			" ",               NULL,                NULL,
			NULL,              NULL,                NULL,
			NULL,              0,                   0,
			NULL,              NULL,                NULL,
			NULL,              NULL,                NULL,
			NULL,              NULL,                addr6,
			1,                 NULL,                NULL,
			NULL,              " ",                 NULL,
			NULL,              NULL,                NULL,
			"",                NULL,                NULL,
			NULL,		   rate_type_home,	rate_type_oper,
			nat_cur_code,	   NULL,				NULL,
			"",				   "",					"",
			"",				   "",					""
	FROM    #apvomast_work
	WHERE	(db_action & 2) = 2

END

IF (@@error != 0)
	RETURN -1







EXEC @result = APVOUPSummary_sp  	@batch_ctrl_num, 
								@client_id,
								@user_id,
                                @debug_level
IF(@result != 0 )
		RETURN @result











IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvomp.cpp" + ", line " + STR( 548, 5 ) + " -- MSG: " + "insert apvohdr"
INSERT  apvohdr(
	trx_ctrl_num,		doc_ctrl_num,			apply_to_num,
	user_trx_type_code,	batch_code,			po_ctrl_num,
	vend_order_num,		ticket_num,			date_posted,
	date_applied,		date_aging,			date_due,
	date_doc,		date_entered,			date_received,
	date_required,		date_paid,			date_discount,
	posting_code,		vendor_code,			pay_to_code,
	branch_code,		class_code,			approval_code,
	comment_code,		fob_code,			terms_code,
	tax_code,		recurring_code,			payment_code,
	state_flag,		paid_flag,			recurring_flag,
	one_time_vend_flag,	one_check_flag,			accrual_flag,
	times_accrued,		amt_gross,			amt_discount,
	amt_freight,		amt_tax,			amt_misc,
	amt_net,		amt_paid_to_date,		amt_tax_included,
	frt_calc_tax,		doc_desc,			user_id,
	journal_ctrl_num,	payment_hold_flag,		intercompany_flag,
	process_ctrl_num,	currency_code,			rate_type_home,
	rate_type_oper,		rate_home,			rate_oper,
	net_original_amt,	org_id,				tax_freight_no_recoverable
)
SELECT	trx_ctrl_num,       	doc_ctrl_num,			apply_to_num,
        user_trx_type_code,	@batch_ctrl_num,		po_ctrl_num,
        vend_order_num,     	ticket_num,		    	@current_date,
	date_applied,       	date_aging,			date_due,
	date_doc,		date_entered,			date_received,
	date_required,		0,				date_discount,
	posting_code,		vendor_code,			pay_to_code,
	branch_code,		class_code,			approval_code,
	comment_code,		fob_code,			terms_code,
	tax_code,		recurring_code,     		payment_code,
	1,		CASE WHEN amt_net < 0.00  THEN 0
				ELSE
			        CONVERT(SMALLINT,SIGN(-amt_net))+ 1
				END,    		
								recurring_flag,
	one_time_vend_flag, 	one_check_flag,	    		accrual_flag,
	times_accrued,		amt_gross,          		amt_discount,
	amt_freight,        	amt_tax,            		amt_misc,
	amt_net,            	0.0,		        	amt_tax_included,		
	frt_calc_tax,		doc_desc,           		user_id,
	gl_trx_id,		0,           			intercompany_flag, 		
	"",			nat_cur_code,			rate_type_home,			
	rate_type_oper,	 	rate_home,			rate_oper,
	net_original_amt,	org_id,				tax_freight_no_recoverable
FROM    #apvox_work
WHERE	(db_action & 2) = 2





UPDATE apvohdr 
SET amt_net = b.amt_net + a.amt_net 
FROM #apvox_work a
	INNER JOIN apvohdr b ON a.apply_to_num = b.trx_ctrl_num
	LEFT JOIN #apvox_work WRK ON b.trx_ctrl_num = WRK.trx_ctrl_num 
WHERE ((a.amt_net) > (0.0) + 0.0000001) 
	AND WRK.trx_ctrl_num IS NULL


UPDATE apvohdr 
SET amt_paid_to_date = b.amt_paid_to_date + ABS(a.amt_net)
FROM #apvox_work a
	INNER JOIN apvohdr b ON a.apply_to_num = b.trx_ctrl_num
	LEFT JOIN #apvox_work WRK ON b.trx_ctrl_num = WRK.trx_ctrl_num 
WHERE ((a.amt_net) < (0.0) - 0.0000001)
	AND WRK.trx_ctrl_num IS NULL


UPDATE apvohdr
SET amt_paid_to_date = b.amt_paid_to_date + ABS(a.amt_net)
FROM #apvox_work a
	INNER JOIN apvohdr b on a.trx_ctrl_num = b.trx_ctrl_num
WHERE b.apply_to_num <> b.trx_ctrl_num
AND   ((a.amt_net) > (0.0) + 0.0000001)

UPDATE apvohdr
SET amt_paid_to_date = b.amt_paid_to_date + a.amt_net 
FROM #apvox_work a
	INNER JOIN apvohdr b ON a.trx_ctrl_num = b.trx_ctrl_num
WHERE b.apply_to_num <> b.trx_ctrl_num
AND   ((a.amt_net) < (0.0) - 0.0000001)


UPDATE apvohdr 
SET date_paid = @current_date ,paid_flag = 1 
FROM #apvox_work a
	INNER JOIN apvohdr b ON a.trx_ctrl_num  = b.trx_ctrl_num 
WHERE b.trx_ctrl_num <> b.apply_to_num


UPDATE apvohdr 
SET paid_flag = 1, date_paid = @current_date 
FROM #apvox_work a
	INNER JOIN apvohdr b ON a.apply_to_num = b.trx_ctrl_num
	LEFT JOIN #apvox_work WRK ON b.trx_ctrl_num = WRK.trx_ctrl_num 
WHERE (ABS((b.amt_net - b.amt_paid_to_date)-(0.0)) < 0.0000001)
AND WRK.trx_ctrl_num  IS NULL


IF (@@error != 0)
	RETURN -1




IF EXISTS (SELECT am_flag FROM apco WHERE am_flag = 1)
   BEGIN

		INSERT amapnew (trx_ctrl_num)
		SELECT trx_ctrl_num
		FROM #apvox_work

    	IF (@@error != 0)
	    	RETURN -1
   END






IF EXISTS (SELECT installed 
		  FROM CVO_Control..sminst a, glcomp_vw b 
		  WHERE a.app_id = 18000 
		  AND installed = 1
		  AND a.company_id = b.company_id
		  AND b.company_code = @company_code
		   )
   BEGIN

		INSERT lc_apvoucher (voucher_no)
		SELECT DISTINCT a.trx_ctrl_num
		FROM #apvox_work a
			INNER JOIN #apvoxcdt_work b ON a.trx_ctrl_num = b.trx_ctrl_num 
			INNER JOIN lc_glaccounts c ON c.account_code = b.gl_exp_acct
		WHERE b.rec_company_code = @company_code

    	IF (@@error != 0)
	    	RETURN -1
   END





IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvomp.cpp" + ", line " + STR( 697, 5 ) + " -- MSG: " + "insert aptrxage"
INSERT  aptrxage (
	trx_ctrl_num,   	trx_type,       	doc_ctrl_num,
	ref_id,         	apply_to_num,   	apply_trx_type,
	date_doc,       	date_applied,   	date_due,
	date_aging,     	vendor_code,    	pay_to_code,
	class_code,     	branch_code,    	amount,
	paid_flag,      	cash_acct_code, 	amt_paid_to_date,
	date_paid,		nat_cur_code,		rate_home,
	rate_oper,		journal_ctrl_num,	account_code,	
	org_id)

SELECT	trx_ctrl_num,   	trx_type,		doc_ctrl_num,
	ref_id,         	apply_to_num,   	apply_trx_type,
	date_doc,       	date_applied,   	date_due,
	date_aging,     	vendor_code,    	pay_to_code,
	class_code,     	branch_code,    	amount,
	CASE WHEN amount < 0.00  THEN 0
	ELSE
        CONVERT(SMALLINT,SIGN(-amount))+ 1
	END,    		
				"", 	  		0.0,
	date_applied,		nat_cur_code,		rate_home,
	rate_oper,		journal_ctrl_num, 	account_code,
	org_id
FROM    #apvoxage_work
WHERE	(db_action & 2) = 2

IF (@@error != 0)
	RETURN -1




IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvomp.cpp" + ", line " + STR( 731, 5 ) + " -- MSG: " + "insert apvodet"
INSERT  apvodet (
	trx_ctrl_num,	sequence_id,	location_code,
	item_code,	qty_ordered,	qty_received,
	qty_returned,	code_1099,	tax_code,
	unit_code,	unit_price,	amt_discount,
	amt_freight,	amt_tax,	amt_misc,
	amt_extended,	calc_tax,	gl_exp_acct,
	line_desc,	serial_id,	rec_company_code,
	reference_code,	po_orig_flag,	po_ctrl_num,	
	org_id,		amt_nonrecoverable_tax,
	amt_tax_det  )
SELECT	
	trx_ctrl_num,   sequence_id,	location_code,
	item_code,      qty_ordered,    qty_received,
	0.0,		code_1099,	tax_code,
	unit_code,      unit_price,     amt_discount,
	amt_freight,    amt_tax,        amt_misc,
	amt_extended,	calc_tax,	gl_exp_acct,   
	line_desc,      serial_id,	rec_company_code,
	reference_code, po_orig_flag,	po_ctrl_num,
	org_id,		amt_nonrecoverable_tax,
	amt_tax_det
FROM    #apvoxcdt_work
WHERE	(db_action & 2) = 2

IF (@@error != 0)
	RETURN -1








IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvomp.cpp" + ", line " + STR( 767, 5 ) + " -- MSG: " + "insert aptrxtax"
INSERT aptrxtax (
	   trx_ctrl_num	 ,	
	   trx_type		 ,	
	   tax_type_code ,		
	   date_applied	 ,	
	   amt_gross	 ,		
	   amt_taxable	 ,		
	   amt_tax	     )		
SELECT 
	   trx_ctrl_num	 ,
	   trx_type		 ,
	   tax_type_code ,
	   date_applied	 ,
	   amt_gross	 ,
	   amt_taxable	 ,
	   amt_tax	     
FROM   #apvoxtax_work
WHERE  (db_action & 2) = 2

IF (@@error != 0)
	RETURN -1




IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvomp.cpp" + ", line " + STR( 793, 5 ) + " -- MSG: " + "Insert aptrxtaxdtl"
INSERT 	aptrxtaxdtl(
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
	account_code)
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
	t.account_code
FROM	#apvoxtaxdtl_work t
WHERE  (t.db_action & 2) = 2
 
IF (@@ERROR != 0)
	RETURN -1

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvomp.cpp" + ", line " + STR( 825, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APVOModifyPersistant_sp] TO [public]
GO
