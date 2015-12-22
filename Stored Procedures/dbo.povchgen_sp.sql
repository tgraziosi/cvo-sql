SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE PROC [dbo].[povchgen_sp] @all_match_flag		int,
			@match_num_from 	varchar(16), 
			@match_num_to	        varchar(16), 
			@all_vendor_flag	int,
			@vend_code_from       	varchar(12), 
			@vend_code_to       	varchar(12), 
			@all_invoice_flag	int,
			@invoice_no_from      	varchar(16), 
			@invoice_no_to      	varchar(16), 
			@smuser_id             	int, 
			@posted_trans          	int OUTPUT,
			@process_ctrl_num	varchar(16) OUTPUT

AS
DECLARE @batch_posting		int,
	@user_posting		int,
	@company_id		int,
	@post_lock		int,
	@batch_post_lock	int,
	@today			int,
	@trx_num_loop		varchar(16),
	@result			int,
	@company_code 		varchar(8),
	@tot_qty_received	float,
	@tot_qty_invoiced	float,
	@tax_freight_no_recoverable	float,		
	@no_recoverable_tax	float,			
	@match_ctrl_num		varchar(16),
	@tax_amount		float,
	@trx_ctrl_num		varchar(16),
	@sequence_id		int,
        @tax_connect_flag       int,        
        @tax_authcode_connect   varchar(8),  
        @curr_precision smallint,
	@org_id         varchar(30),
	@vendor_code    varchar(12),
	@vendor_remitto  varchar(8),
        @flag_prorrate_tax   int,
        @prorrate_tax_amount  float,
        @flag_prorrate_discount int,
        @prorrate_disc_amount  float,
        @flag_prorrate_misc     int,
        @prorrate_misc_amount  float,
        @flag_prorrate_freight  int,
        @prorrate_freight_amount  float



















CREATE TABLE  #apinpchg  (
	rec_id			int identity(1,1) ,	
	match_ctrl_num		varchar(16),
	trx_ctrl_num		varchar(16),
	trx_type			smallint,
	doc_ctrl_num		varchar(16),
	apply_to_num		varchar(16),
	user_trx_type_code	varchar(8),
	batch_code			varchar(16),
	po_ctrl_num			varchar(16),
	vend_order_num		varchar(20),
	ticket_num			varchar(20),
	date_applied		int,
	date_aging			int,
	date_due			int,
	date_doc			int,
	date_entered		int,
	date_received		int,
	date_required		int,
	date_recurring		int,
	date_discount		int,
	posting_code		varchar(8),
	vendor_code			varchar(12),
	pay_to_code			varchar(8),
	branch_code			varchar(8),
	class_code			varchar(8),
	approval_code		varchar(8),
	comment_code		varchar(8),
	fob_code			varchar(8),
	terms_code			varchar(8),
	tax_code			varchar(8),
	recurring_code		varchar(8),
	location_code		varchar(8),
	payment_code		varchar(8),
	times_accrued		smallint,
	accrual_flag		smallint,
	drop_ship_flag		smallint,
	posted_flag			smallint,
	hold_flag			smallint,
	add_cost_flag		smallint,
	approval_flag		smallint,
	recurring_flag		smallint,
	one_time_vend_flag	smallint,
	one_check_flag		smallint,
	amt_gross			float,
	amt_discount		float,
	amt_tax				float,
	amt_freight			float,
	amt_misc			float,
	amt_net				float,
	amt_paid			float,
	amt_due				float,
	amt_restock			float,
	amt_tax_included	float,
	frt_calc_tax		float,
	doc_desc			varchar(40),
	hold_desc			varchar(40),
	user_id				smallint,
	next_serial_id		smallint,
	pay_to_addr1		varchar(40),
	pay_to_addr2		varchar(40),
	pay_to_addr3		varchar(40),
	pay_to_addr4		varchar(40),
	pay_to_addr5		varchar(40),
	pay_to_addr6		varchar(40),
	attention_name		varchar(40),
	attention_phone		varchar(30),
	intercompany_flag	smallint,
	company_code		varchar(8),
	cms_flag			smallint,
	process_group_num   varchar(16),
	nat_cur_code 		varchar(8),	 
	rate_type_home 		varchar(8),	 
	rate_type_oper		varchar(8),	 
	rate_home 			float,		   
	rate_oper			float,
	net_original_amt		float,
	org_id			varchar(30),
	tax_freight_no_recoverable	float
	)




CREATE TABLE #apinpcdt   (
	trx_ctrl_num			varchar(16),
	trx_type            	smallint,
	sequence_id         	int,
	location_code       	varchar(8),
	item_code           	varchar(30),
	bulk_flag           	smallint,
	qty_ordered         	float,
	qty_received        	float,
	qty_returned        	float,
	qty_prev_returned   	float,
	approval_code			varchar(8),
	tax_code            	varchar(8),
	return_code         	varchar(8),
	code_1099           	varchar(8),
	po_ctrl_num         	varchar(16),
	unit_code           	varchar(8),
	unit_price          	float,
	amt_discount        	float,
	amt_freight         	float,
	amt_tax             	dec(20,8),
	amt_misc            	float,
	amt_extended        	dec(20,8),
	calc_tax            	dec(20,8),
	date_entered        	int,
	gl_exp_acct         	varchar(32),
	new_gl_exp_acct     	varchar(32),
	rma_num             	varchar(20),
	line_desc           	varchar(60),
	serial_id           	int,
	company_id          	smallint,
	iv_post_flag        	smallint,
	po_orig_flag        	smallint,
	rec_company_code    	varchar(8),
	new_rec_company_code	varchar(8),
	reference_code			varchar(32),
	new_reference_code		varchar(32),
	org_id                         varchar(30) NULL,
	amt_nonrecoverable_tax   dec(20,8),
	amt_tax_det		dec(20,8)
	)
CREATE TABLE  #epmchhdr_range
(
	match_ctrl_num              varchar(16) NOT NULL,
	vendor_code                 varchar(12) NOT NULL,
	vendor_remit_to             char(8) NULL,
	amt_discount                float NULL DEFAULT 0.0,
	amt_tax                     float NULL DEFAULT 0.0,
	amt_freight                 float NULL DEFAULT 0.0, 
	amt_misc                    float NULL DEFAULT 0.0,
        org_id			    varchar(30) NULL,
        process_ctrl_num	    varchar(16)
	
)






	
	SELECT @posted_trans = 0

	SELECT 	@company_code = company_code
	from glco 


	EXEC @result = pctrladd_sp @process_ctrl_num OUTPUT,  
	'Match Posting Process', @smuser_id, 4000, @company_code, 4065  
	
	
	
	SELECT @batch_posting = batch_proc_flag,
		@user_posting = batch_usr_flag,
		@company_id = company_id
	FROM apco

	IF @batch_posting = 1
	BEGIN
		SELECT @batch_post_lock = MIN(posted_flag) - 1
		FROM batchctl
		WHERE posted_flag <= 0		

		UPDATE batchctl SET posted_flag = @batch_post_lock
		WHERE posted_flag = 0
		AND hold_flag = 0
		AND number_held = 0
		AND completed_date > 0
		AND selected_user_id = @smuser_id
		AND batch_type = 4065
		AND selected_flag = 1

		IF @@rowcount = 0  
		BEGIN 


			DROP TABLE #apinpchg
			DROP TABLE #apinpcdt
			SELECT @posted_trans = -10
			SELECT @posted_trans, @process_ctrl_num
			RETURN 
		END 

		SELECT @post_lock = MIN(match_posted_flag) - 1
		FROM epmchhdr
		WHERE match_posted_flag <= 0		

		UPDATE epmchhdr
			SET match_posted_flag = @post_lock
		FROM epmchhdr a, batchctl b
		WHERE  a.batch_code = b.batch_ctrl_num
		AND	b.posted_flag = @batch_post_lock

		IF @@rowcount = 0
		BEGIN 

			DROP TABLE #apinpchg
			DROP TABLE #apinpcdt
			SELECT @posted_trans = -10
			SELECT @posted_trans, @process_ctrl_num
			RETURN 
		END 


	END	
	ELSE
	BEGIN
		SELECT @post_lock = MIN(match_posted_flag) - 1
		FROM epmchhdr
		WHERE match_posted_flag <= 0		


		UPDATE epmchhdr
			SET match_posted_flag = @post_lock
		WHERE ( ((@all_match_flag = 1) OR 
			 (match_ctrl_num >= @match_num_from AND match_ctrl_num <= @match_num_to )) AND
			((@all_vendor_flag = 1) OR
			 (vendor_code >= @vend_code_from AND vendor_code <= @vend_code_to)) AND
			((@all_invoice_flag = 1) OR
			 (vendor_invoice_no >= @invoice_no_from AND vendor_invoice_no <= @invoice_no_to))) 
		AND 	match_posted_flag = 0
		AND	( ( tolerance_hold_flag = 0 ) OR tolerance_approval_flag = 1  ) 
		AND	( validated_flag = 1 )

		IF @@rowcount = 0
		BEGIN 

			DROP TABLE #apinpchg
			DROP TABLE #apinpcdt
			SELECT @posted_trans = -10
			SELECT @posted_trans, @process_ctrl_num
			RETURN 
		END 
		

	END	

	EXEC appdate_sp @today OUTPUT	

	
	EXECUTE @result = appoxhdr_sp	@company_id,
					@post_lock,
					@today,
					@smuser_id


	IF @result <> 0  
	BEGIN 
		EXECUTE @result = APPOUnlockTransactions_SP @batch_posting, @post_lock, @batch_post_lock 
		DROP TABLE #apinpchg
		DROP TABLE #apinpcdt
		SELECT @posted_trans = -20
		RETURN 
	END 

	
	EXECUTE @result = appoxhd1_sp @process_ctrl_num

	IF @result > 0  
	BEGIN 
		EXECUTE @result = APPOUnlockTransactions_SP @batch_posting, @post_lock, @batch_post_lock 
		DROP TABLE #apinpchg
		DROP TABLE #apinpcdt
		SELECT @posted_trans = 0 
		RETURN 
	END 

	 
	EXECUTE @result = appoxdet_sp								

	IF @result > 0  
	BEGIN 
		EXECUTE @result = APPOUnlockTransactions_SP @batch_posting, @post_lock, @batch_post_lock 
		DROP TABLE #apinpchg
		DROP TABLE #apinpcdt
		SELECT @posted_trans = -30
		RETURN 
	END 




		
	IF @batch_posting = 1
	BEGIN
		EXEC @result = appobatch_sp

		IF @result > 0  
		BEGIN 

			EXECUTE @result = APPOUnlockTransactions_SP @batch_posting, @post_lock, @batch_post_lock 
			DROP TABLE #apinpchg
			DROP TABLE #apinpcdt
			SELECT @posted_trans = -40
			SELECT @posted_trans, @process_ctrl_num
			RETURN 
		END 
	END

		
	EXEC @result = apposum_sp


	IF @result > 0  
	BEGIN 

		EXECUTE @result = APPOUnlockTransactions_SP @batch_posting, @post_lock, @batch_post_lock 
		DROP TABLE #apinpchg
		DROP TABLE #apinpcdt
		SELECT @posted_trans = -50
		SELECT @posted_trans, @process_ctrl_num
		RETURN 
	END 
	
	
	
	
	DELETE #epmchhdr_range
		
	INSERT  #epmchhdr_range (
		    match_ctrl_num ,             
		    vendor_code  ,               
		    vendor_remit_to,  
		    amt_discount,
		    amt_tax,
		    amt_freight,
		    amt_misc,
		    org_id,
		    process_ctrl_num)
		    
	SELECT 	    a.match_ctrl_num , 
		    a.vendor_code,
		    a.pay_to_code,
		   mt.amt_discount,
		   mt.amt_tax,
		   mt.amt_freight,
		   mt.amt_misc,
		   a.org_id,
		   @process_ctrl_num
		FROM 	#apinpchg a, epmchhdr mt
		WHERE   a.match_ctrl_num = mt.match_ctrl_num
	        ORDER BY a.match_ctrl_num
	        
	IF OBJECT_ID('tempdb..#epmchdtl_val') IS NOT NULL 
	   DROP TABLE #epmchdtl_val
	
	SELECT  dtl.* INTO #epmchdtl_val
	     FROM epmchdtl dtl , #epmchhdr_range mt
	     WHERE dtl.match_ctrl_num = mt.match_ctrl_num
	        
	EXEC @result = povchval_sp @process_ctrl_num
	
	IF OBJECT_ID('tempdb..#epmchdtl_val') IS NOT NULL 
	   DROP TABLE #epmchdtl_val
	
	IF @result > 0  
	BEGIN 
		EXECUTE @result = APPOUnlockTransactions_SP @batch_posting, @post_lock, @batch_post_lock 
		DROP TABLE #apinpchg
		DROP TABLE #apinpcdt
		SELECT @posted_trans = -55
		SELECT @posted_trans, @process_ctrl_num
		RETURN 
	END 
	
	
	
	

	BEGIN TRANSACTION POST_MATCH	
          

	DECLARE	taxconnect_update_header SCROLL CURSOR FOR
		SELECT 	trx_ctrl_num, match_ctrl_num , vendor_code, pay_to_code, org_id
		FROM 	#apinpchg
		ORDER BY trx_ctrl_num
	
	OPEN	taxconnect_update_header 
	
	FETCH	taxconnect_update_header
	INTO	@trx_ctrl_num, @match_ctrl_num, @vendor_code , @vendor_remitto, @org_id
	
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
	
                SELECT  @tax_authcode_connect = '' , @tax_connect_flag = 0
                
                SET ROWCOUNT 1
                
                SELECT DISTINCT  @tax_authcode_connect = type.tax_auth_code , 
                                 @tax_connect_flag = type.tax_connect_flag
			FROM	mtinptaxdtl dt (nolock), aptxtype type (nolock)
			WHERE	dt.match_ctrl_num 	= @match_ctrl_num
		          AND	dt.tax_type_code	= type.tax_type_code
		          AND	type.tax_connect_flag 	= 1

                SET ROWCOUNT 0
                
                
                IF(@tax_connect_flag > 0 )
                BEGIN
                
                        IF OBJECT_ID('tempdb..#mtinptax') IS NOT NULL 
	                      DROP TABLE #mtinptax
	                
                        select * into #mtinptax from mtinptax where match_ctrl_num = @match_ctrl_num
                        

                        IF OBJECT_ID('tempdb..#mtinptaxdtl') IS NOT NULL 
	                      DROP TABLE #mtinptaxdtl
                        
                        select * into #mtinptaxdtl from mtinptaxdtl where match_ctrl_num = @match_ctrl_num
	
	                IF OBJECT_ID('tempdb..#epmchdtl') IS NOT NULL 
	                     DROP TABLE #epmchdtl
	                
                        select * into #epmchdtl from epmchdtl where match_ctrl_num = @match_ctrl_num
	                
	                  
                        EXECUTE  @result = mttaxvogen_sp	@match_ctrl_num , 
						                @trx_ctrl_num   ,
						                @org_id         ,
						                @vendor_code    ,
						                @vendor_remitto ,
				                                0
		        IF   (@result != 0 )
		        BEGIN
				EXECUTE @result = APPOUnlockTransactions_SP @batch_posting, @post_lock, @batch_post_lock 
				IF OBJECT_ID('tempdb..#mtinptax') IS NOT NULL 
				      DROP TABLE #mtinptax
					IF OBJECT_ID('tempdb..#mtinptaxdtl') IS NOT NULL 
					      DROP TABLE #mtinptaxdtl
					IF OBJECT_ID('tempdb..#epmchdtl') IS NOT NULL 
					      DROP TABLE #epmchdtl

				DROP TABLE #apinpchg
				DROP TABLE #apinpcdt
				SELECT @posted_trans = -60
				SELECT @posted_trans, @process_ctrl_num
				CLOSE taxconnect_update_header
	                        DEALLOCATE taxconnect_update_header
				RETURN 
                        END
				                                
				                                
			DELETE #mtinptaxdtl where match_ctrl_num = @match_ctrl_num and sequence_id = -1	                                
			
			DELETE mtinptax where match_ctrl_num = @match_ctrl_num
			
			INSERT INTO mtinptax ( timestamp, match_ctrl_num, trx_type,
                                	sequence_id, tax_type_code, 
                                	amt_taxable, amt_gross, amt_tax, amt_final_tax )
		        SELECT NULL,  match_ctrl_num, trx_type,
                                	sequence_id, tax_type_code, 
                                	amt_taxable, amt_gross, amt_tax, amt_final_tax 
			FROM #mtinptax
			
			DELETE mtinptaxdtl where match_ctrl_num = @match_ctrl_num
			
			INSERT INTO mtinptaxdtl (
			        match_ctrl_num, sequence_id, trx_type, tax_sequence_id,	
				detail_sequence_id,tax_type_code,amt_taxable,
				amt_gross,amt_tax,amt_final_tax,
				recoverable_flag, account_code )
                         SELECT match_ctrl_num, sequence_id, trx_type, tax_sequence_id,	
				detail_sequence_id,tax_type_code,amt_taxable,
				amt_gross,amt_tax,amt_final_tax,
				recoverable_flag, account_code
                        FROM #mtinptaxdtl
			
				                                
                        UPDATE epm
			    SET	epm.amt_tax = ISNULL( (SIGN(TXL.amt_tax) * ROUND(ABS(TXL.amt_tax) + 0.0000001, @curr_precision)),0.0) ,
				epm.calc_tax = ISNULL( (SIGN(TXL.calc_tax) * ROUND(ABS(TXL.calc_tax) + 0.0000001, @curr_precision)) , 0.0)
			    FROM epmchdtl epm,  #epmchdtl TXL	
			 WHERE   epm.match_ctrl_num = TXL.match_ctrl_num
			     AND TXL.sequence_id  =  epm.sequence_id	
		             AND TXL.match_ctrl_num = @match_ctrl_num 


                END	
	
	
		FETCH	taxconnect_update_header
		INTO	@trx_ctrl_num, @match_ctrl_num, @vendor_code , @vendor_remitto, @org_id		
	END
		
	CLOSE taxconnect_update_header
	DEALLOCATE taxconnect_update_header




        



		
	INSERT INTO apinptax (
		trx_ctrl_num,
		trx_type,
		sequence_id,
		tax_type_code,
		amt_taxable,
		amt_gross,
		amt_tax,
		amt_final_tax
	)
	SELECT a.trx_ctrl_num,
		4091,
		b.sequence_id,		
		b.tax_type_code,		
		round(b.amt_taxable, isnull(g.curr_precision,1.0)),		
		round(b.amt_gross, isnull(g.curr_precision,1.0)),		
		round(b.amt_tax, isnull(g.curr_precision,1.0)),		
		round(b.amt_final_tax, isnull(g.curr_precision,1.0))		
	FROM #apinpchg a LEFT OUTER JOIN glcurr_vw g (nolock) ON (a.nat_cur_code = g.currency_code), mtinptax b 
	WHERE a.match_ctrl_num = b.match_ctrl_num

	IF( @@error != 0 )
	BEGIN 
		ROLLBACK TRANSACTION POST_MATCH 
		EXECUTE @result = APPOUnlockTransactions_SP @batch_posting, @post_lock, @batch_post_lock 
		DROP TABLE #apinpchg
		DROP TABLE #apinpcdt
		SELECT @posted_trans = -60
		SELECT @posted_trans, @process_ctrl_num
		RETURN 
	END 
	

	


		
	INSERT INTO apinptaxdtl (
		trx_ctrl_num, 	trx_type,	sequence_id,	tax_sequence_id,	detail_sequence_id,
		tax_type_code,	amt_taxable,		amt_gross,	amt_tax,		amt_final_tax,
		recoverable_flag,	account_code	
	)
	SELECT 	a.trx_ctrl_num,
		4091,
		b.sequence_id,		
		b.tax_sequence_id,		
		b.detail_sequence_id,		
		b.tax_type_code,
		round(b.amt_taxable, isnull(g.curr_precision,1.0)),
		round(b.amt_gross, isnull(g.curr_precision,1.0)),		
		round(b.amt_tax, isnull(g.curr_precision,1.0)),		
		round(b.amt_final_tax, isnull(g.curr_precision,1.0)),
		b.recoverable_flag,
		b.account_code
	FROM #apinpchg a LEFT OUTER JOIN glcurr_vw g (nolock) ON (a.nat_cur_code = g.currency_code), mtinptaxdtl b
	WHERE a.match_ctrl_num = b.match_ctrl_num

	IF( @@error != 0 )
	BEGIN 
		ROLLBACK TRANSACTION POST_MATCH 
		EXECUTE @result = APPOUnlockTransactions_SP @batch_posting, @post_lock, @batch_post_lock 
		DROP TABLE #apinpchg
		DROP TABLE #apinpcdt
		SELECT @posted_trans = -60
		SELECT @posted_trans, @process_ctrl_num
		RETURN 
	END 
	


	
	CREATE TABLE #tempPass1 (match_ctrl_num varchar(16), pass_amount dec(20,8))

	INSERT INTO #tempPass1
	SELECT 	dt.match_ctrl_num, ISNULL(SUM(dt.amt_final_tax),0) tax_freight_no_recoverable
	FROM	mtinptaxdtl dt, aptxtype type, #apinpchg t
	WHERE	dt.tax_type_code	= type.tax_type_code	
	AND	t.match_ctrl_num = dt.match_ctrl_num
		AND	type.tax_based_type 	= 2
		AND	type.recoverable_flag 	= 0
	GROUP BY dt.match_ctrl_num

	UPDATE 	h
	SET 	h.tax_freight_no_recoverable = #tempPass1.pass_amount
	FROM 	#apinpchg h, #tempPass1 
	WHERE 	h.match_ctrl_num = #tempPass1.match_ctrl_num	

	DELETE FROM #tempPass1
	
	INSERT INTO #tempPass1
--	SELECT dt.match_ctrl_num, SUM((SIGN(ISNULL(amt_final_tax,0.0)) * ROUND(ABS(ISNULL(amt_final_tax,0.0)) + 0.0000001, g.curr_precision)) ) no_recoverable_tax
        SELECT dt.match_ctrl_num, SUM((ROUND(ISNULL(amt_final_tax,0.0), g.curr_precision))) no_recoverable_tax
	FROM mtinptaxdtl dt, #apinpchg t LEFT OUTER JOIN glcurr_vw g  ON (t.nat_cur_code = g.currency_code)
	WHERE  t.match_ctrl_num = dt.match_ctrl_num
	AND ISNULL(recoverable_flag,0) = 0
	GROUP BY dt.match_ctrl_num

	UPDATE 	h
        SET
--	SET 	amt_gross = round(amt_gross, isnull(g.curr_precision,1.0)) + round(#tempPass1.pass_amount, isnull(g.curr_precision,1.0)),
--		amt_tax = round(amt_tax, isnull(g.curr_precision,1.0)) - round(#tempPass1.pass_amount, isnull(g.curr_precision,1.0))		
--        SET 
               amt_gross = ISNULL( (SIGN(amt_gross) * ROUND(ABS(amt_gross) + 0.0000001, g.curr_precision)),0.0) 
                          --ISNULL(amt_gross,0.0)
                        + ISNULL( #tempPass1.pass_amount,0.0) ,
                amt_tax = ISNULL( amt_tax ,0.0) - ISNULL( #tempPass1.pass_amount, 0.0 )
	FROM 	#apinpchg h LEFT OUTER JOIN glcurr_vw g (nolock) ON (h.nat_cur_code = g.currency_code),
                #tempPass1 
	WHERE 	h.match_ctrl_num = #tempPass1.match_ctrl_num	
	
	IF OBJECT_ID('tempdb..#epmchdtl') IS NOT NULL 
	BEGIN
		UPDATE 	h
		SET      h.tax_code = dt.tax_code 
		FROM #apinpchg h, #epmchdtl dt, aptax tx (nolock)
		WHERE 	h.match_ctrl_num 	= dt.match_ctrl_num AND 
			dt.tax_code	= tx.tax_code AND
			tx.tax_connect_flag 	= 1
	END




   

	DROP TABLE #tempPass1
	
	CREATE TABLE #tempPass2 (trx_ctrl_num varchar(16), sequence_id int, 
		sum_nonrecoverable_tax dec(20,8), sum_tax_det dec(20,8))

	INSERT INTO #tempPass2
	SELECT 	dt.trx_ctrl_num, dt.detail_sequence_id, 
		SUM(CASE WHEN dt.recoverable_flag = 0 THEN dt.amt_final_tax ELSE 0 END) sum_nonrecoverable_tax,
		SUM(CASE WHEN dt.recoverable_flag = 1 THEN dt.amt_final_tax ELSE 0 END) sum_tax_det
	FROM	apinptaxdtl dt, #apinpcdt t
	WHERE	dt.trx_ctrl_num = t.trx_ctrl_num
	AND	dt.detail_sequence_id = t.sequence_id
	GROUP BY dt.trx_ctrl_num, dt.detail_sequence_id

	UPDATE 	d
	SET 	d.amt_tax_det  = ISNULL((SIGN(x.sum_tax_det) * ROUND(ABS(x.sum_tax_det) + 0.0000001, isnull(g.curr_precision,1.0))), 0.0), 
		d.amt_nonrecoverable_tax = ISNULL((SIGN(x.sum_nonrecoverable_tax) * ROUND(ABS(x.sum_nonrecoverable_tax) + 0.0000001, isnull(g.curr_precision,1.0))), 0.0)
	FROM 	#apinpchg h LEFT OUTER JOIN glcurr_vw g (nolock) ON (h.nat_cur_code = g.currency_code),
                #apinpcdt d , #tempPass2 x
		WHERE 	h.trx_ctrl_num = d.trx_ctrl_num
                AND     d.trx_ctrl_num 	= x.trx_ctrl_num
		AND	d.sequence_id 	= x.sequence_id	

	DROP TABLE #tempPass2
	


    UPDATE
         a
         SET a.amt_discount = ISNULL((SIGN(b.amt_discount) * ROUND(ABS(b.amt_discount) + 0.0000001, isnull(g.curr_precision,1.0))), 0.0),
             a.amt_freight  = ISNULL((SIGN(b.amt_freight) * ROUND(ABS(b.amt_freight) + 0.0000001, isnull(g.curr_precision,1.0))), 0.0), 
             a.amt_misc     = ISNULL((SIGN(b.amt_misc) * ROUND(ABS(b.amt_misc) + 0.0000001, isnull(g.curr_precision,1.0))), 0.0)
    FROM #apinpchg h LEFT OUTER JOIN glcurr_vw g (nolock) ON (h.nat_cur_code = g.currency_code),
         #apinpcdt a, #epmchhdr_range ran, epmchdtl b 
     WHERE  h.trx_ctrl_num = a.trx_ctrl_num
	AND h.match_ctrl_num = ran.match_ctrl_num
	AND h.match_ctrl_num = b.match_ctrl_num
	AND a.sequence_id = b.sequence_id



	INSERT  INTO apinpage  ( 
	 sequence_id, 
	 trx_ctrl_num,  
	 trx_type, 
	 date_applied, 
	 date_due,  
	 date_aging, 
	 amt_due
	 )
	SELECT 1, 
	 h.trx_ctrl_num,  
	 h.trx_type, 
	 h.date_applied, 
	 h.date_due,  
	 h.date_aging, 
	 round(h.amt_due , isnull(g.curr_precision,1.0))	
	 FROM #apinpchg h LEFT OUTER JOIN glcurr_vw g (nolock) ON (h.nat_cur_code = g.currency_code)
	
	IF( @@error != 0 )
	BEGIN 
		ROLLBACK TRANSACTION POST_MATCH 
		EXECUTE @result = APPOUnlockTransactions_SP @batch_posting, @post_lock, @batch_post_lock 
		DROP TABLE #apinpchg
		DROP TABLE #apinpcdt
		SELECT @posted_trans = -60
		SELECT @posted_trans, @process_ctrl_num
		RETURN 
	END 

	
	EXEC @result = appoCreate_Vouchers_sp

	IF @result > 0  
	BEGIN 
		ROLLBACK TRANSACTION POST_MATCH 
		EXECUTE @result = APPOUnlockTransactions_SP @batch_posting, @post_lock, @batch_post_lock 
		DROP TABLE #apinpchg
		DROP TABLE #apinpcdt
		SELECT @posted_trans = -70
		SELECT @posted_trans, @process_ctrl_num
		RETURN 
	END 
		
	
	

	EXEC @result = bows_ap_create_project_details_SP

	IF @result > 0  
	BEGIN 
		ROLLBACK TRANSACTION POST_MATCH 
		EXECUTE @result = APPOUnlockTransactions_SP @batch_posting, @post_lock, @batch_post_lock 
		DROP TABLE #apinpchg
		DROP TABLE #apinpcdt
		SELECT @posted_trans = -70
		SELECT @posted_trans, @process_ctrl_num
		RETURN 
	END 
	

	
	SELECT @trx_num_loop = MIN(trx_ctrl_num)
	FROM #apinpchg
	
	WHILE @trx_num_loop IS NOT NULL
	BEGIN
		EXEC apaprmk_sp 4091, 
				@trx_num_loop, 
				@today

		SELECT @trx_num_loop = MIN(trx_ctrl_num)
		FROM #apinpchg
		WHERE trx_ctrl_num > @trx_num_loop
	END

	IF @batch_posting = 1
		UPDATE batchctl 
			SET posted_flag = 1
		WHERE posted_flag = @batch_post_lock

	

	

	CREATE TABLE #pivot
	(
	 sum_qty_invoiced float,
	 receipt_dtl_key        varchar(50),
	receipt_sequence_id	int	NULL		
	)
	

	INSERT INTO #pivot
	(
	sum_qty_invoiced,
	receipt_dtl_key,
	receipt_sequence_id				
	)
	SELECT SUM(epmchdtl.qty_invoiced) invoiced,
		  epmchdtl.receipt_dtl_key,
		  epmchdtl.receipt_sequence_id
		  FROM epmchdtl, epmchdtl x2, epmchhdr h1
		  WHERE EXISTS (SELECT 1 FROM #apinpchg WHERE x2.match_ctrl_num = #apinpchg.match_ctrl_num)
				AND x2.receipt_dtl_key  = epmchdtl.receipt_dtl_key
				AND 
				((h1.match_ctrl_num = epmchdtl.match_ctrl_num) AND
				 (h1.match_posted_flag = 1 OR h1.match_ctrl_num = x2.match_ctrl_num ))
	GROUP BY epmchdtl.receipt_dtl_key, epmchdtl.receipt_sequence_id



	CREATE TABLE #temp
	(
	 --amt_invoiced 		float,
         amt_invoiced 		dec(20,8),
	 receipt_dtl_key        varchar(50)	
	)

	INSERT INTO #temp
	(
		amt_invoiced,
		receipt_dtl_key			
	)
	select sum(epmchdtl.invoice_unit_price * epmchdtl.qty_invoiced) as amt_invoiced,
			epmchdtl.receipt_dtl_key
	from #pivot, epmchdtl where epmchdtl.receipt_dtl_key = #pivot.receipt_dtl_key
	group by epmchdtl.receipt_dtl_key

	UPDATE epinvdtl 		
	set   epinvdtl.qty_invoiced = #pivot.sum_qty_invoiced,
		 epinvdtl.amt_invoiced = #temp.amt_invoiced
	FROM epinvdtl, #pivot, #temp
	WHERE epinvdtl.receipt_detail_key = #pivot.receipt_dtl_key
	AND	epinvdtl.sequence_id = #pivot.receipt_sequence_id 
	AND  epinvdtl.receipt_detail_key = #temp.receipt_dtl_key

        UPDATE dtl
	set dtl.invoiced_full_flag = 1
	  , dtl.amt_invoiced = CAST(round((ABS(dtl.amt_invoiced)+ 0.0000001), isnull(g.curr_precision,1.0)) as dec(20,8)) 
	FROM epinvdtl dtl, epinvhdr hdr
             LEFT OUTER JOIN glcurr_vw g  ON (hdr.nat_cur_code = g.currency_code), 
             #pivot piv
	WHERE dtl.receipt_ctrl_num = hdr.receipt_ctrl_num
        AND  dtl.receipt_detail_key = piv.receipt_dtl_key
	AND   ((dtl.qty_received - piv.sum_qty_invoiced)<= 0.000001)
	AND dtl.sequence_id = piv.receipt_sequence_id 		

	UPDATE epinvhdr
	set invoiced_full_flag = 1
	FROM epinvdtl dtl, epinvhdr hdr
	WHERE hdr.receipt_ctrl_num = dtl.receipt_ctrl_num
	AND   hdr.receipt_ctrl_num NOT IN (select distinct receipt_ctrl_num FROM epinvdtl
					WHERE invoiced_full_flag = 0)

	DROP TABLE #pivot
	DROP TABLE #temp
	
	UPDATE epmchhdr
	SET match_posted_flag = 1
	FROM epmchhdr
	WHERE match_posted_flag = @post_lock

	EXEC @result = pctrlupd_sp @process_ctrl_num, 3
	
	
	INSERT epmchpsthdr
	SELECT @process_ctrl_num,
		ISNULL(a.batch_code, ' '),
		a.match_ctrl_num,
		a.trx_ctrl_num,
		a.vendor_code,
		a.doc_ctrl_num,
		a.amt_due,
		b.symbol
	FROM #apinpchg a, glcurr_vw b
	WHERE a.nat_cur_code = b.currency_code
	
	IF @posted_trans = 0
		SELECT @posted_trans = COUNT(match_ctrl_num)
		FROM #apinpchg
	COMMIT TRANSACTION POST_MATCH 

	
	SELECT @posted_trans, @process_ctrl_num

	DROP TABLE #apinpchg
	DROP TABLE #apinpcdt
	DROP TABLE #epmchhdr_range
RETURN
GO
GRANT EXECUTE ON  [dbo].[povchgen_sp] TO [public]
GO
