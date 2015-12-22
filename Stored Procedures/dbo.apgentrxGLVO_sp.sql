SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2007 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2007 Epicor Software Corporation, 2007    
                  All Rights Reserved                    
*/                                                

CREATE PROCEDURE [dbo].[apgentrxGLVO_sp] 					
       @accrual_number varchar(16),
	   @process_ctrl_num varchar(16),
	    @org_company varchar(8),
		@smuser_id int,
       @debug int	
       	
AS

BEGIN

	DECLARE @count int,
		@indirect_flag int,
		@counttable int,
		@result    int ,
 		@period_end_date int,
		@old_jrnl varchar(30),  
		@jrnl  varchar(30),
		@min_jrnl varchar(30),
		@str_msg_at  VARCHAR(255),
		@company_code	varchar(8),
		@rec_intercomp	varchar(8)
	
	CREATE TABLE #gltrx
	(
		mark_flag			smallint NOT NULL,
		next_seq_id			int NOT NULL,
		trx_state			smallint NOT NULL,
		journal_type          		varchar(8) NOT NULL,
		journal_ctrl_num      		nvarchar(30) NOT NULL, 
		journal_description   		varchar(30) NOT NULL, 
		date_entered          		int NOT NULL,
		date_applied          		int NOT NULL,
		recurring_flag			smallint NOT NULL,
		repeating_flag			smallint NOT NULL,
		reversing_flag			smallint NOT NULL,
		hold_flag             		smallint NOT NULL,
		posted_flag           		smallint NOT NULL,
		date_posted           		int NOT NULL,
		source_batch_code		varchar(16) NOT NULL, 
		process_group_num		varchar(16) NOT NULL,
		batch_code             		varchar(16) NOT NULL, 
		type_flag			smallint NOT NULL,	
								
								
								
								
								
		intercompany_flag		smallint NOT NULL,	
		company_code			varchar(8) NOT NULL, 
		app_id				smallint NOT NULL,	


		home_cur_code		varchar(8) NOT NULL,		
		document_1		varchar(16) NOT NULL,	


		trx_type		smallint NOT NULL,		
		user_id			smallint NOT NULL,
		source_company_code	varchar(8) NOT NULL,
	        oper_cur_code           varchar(8),         
		org_id			varchar(30) NULL,
		interbranch_flag	smallint
	)
	
	CREATE UNIQUE INDEX #gltrx_ind_0
		 ON #gltrx ( journal_ctrl_num )
	
	
	
	CREATE TABLE #gltrxdet
	(
		mark_flag		smallint NOT NULL,
		trx_state		smallint NOT NULL,
	        journal_ctrl_num	varchar(30) NOT NULL,
		sequence_id		int NOT NULL,
		rec_company_code	varchar(8) NOT NULL,	
		company_id		smallint NOT NULL,
	        account_code		varchar(32) NOT NULL,	
		description		varchar(60) NOT NULL,
	        document_1		varchar(16) NOT NULL, 	
	        document_2		varchar(16) NOT NULL, 	
		reference_code		varchar(32) NOT NULL,	
	        balance			float NOT NULL,		
		nat_balance		float NOT NULL,		
		nat_cur_code		varchar(8) NOT NULL,	
		rate			float NOT NULL,		
	        posted_flag             smallint NOT NULL,
	        date_posted		int NOT NULL,
		trx_type		smallint NOT NULL,
		offset_flag		smallint NOT NULL,	





		seg1_code		varchar(32) NOT NULL,
		seg2_code		varchar(32) NOT NULL,
		seg3_code		varchar(32) NOT NULL,
		seg4_code		varchar(32) NOT NULL,
		seq_ref_id		int NOT NULL,		
	        balance_oper            float NULL,
	        rate_oper               float NULL,
	        rate_type_home          varchar(8) NULL,
		rate_type_oper          varchar(8) NULL,
		org_id			varchar(30) NULL
	                                                
	)
	
	CREATE UNIQUE INDEX #gltrxdet_ind_0
		ON #gltrxdet ( journal_ctrl_num, sequence_id )
	
	CREATE INDEX #gltrxdet_ind_1
		ON #gltrxdet ( journal_ctrl_num, account_code )


	
	
	
	CREATE TABLE #apvochg_work
	(
		trx_ctrl_num		varchar(16), 
	    	trx_type		smallint,	
		doc_ctrl_num		varchar(16),
	    	apply_to_num		varchar(16),
		user_trx_type_code	varchar(8),	
		batch_code		varchar(16),
		po_ctrl_num		varchar(16),	
		vend_order_num		varchar(20),
		ticket_num		varchar(20),	
		date_applied		int,
		date_aging		int,	   
		date_due		int,
		date_doc		int,	   
		date_entered		int,
		date_received		int,
		date_required		int,
		date_recurring		int,
		date_discount		int,	
		posting_code		varchar(8),	
	    	vendor_code		varchar(12),	
	    	pay_to_code		varchar(8),	
		branch_code		varchar(8),	
		class_code		varchar(8),	
		approval_code		varchar(8),
		comment_code		varchar(8),
		fob_code		varchar(8),
		terms_code		varchar(8),
		tax_code		varchar(8),
		recurring_code		varchar(8),
		location_code		varchar(8),
		payment_code		varchar(8),
		times_accrued		smallint,  
		accrual_flag		smallint,  
		drop_ship_flag		smallint,  
		posted_flag		smallint,
		add_cost_flag		smallint,  
	    	recurring_flag		smallint,  
		one_time_vend_flag	smallint,  
		one_check_flag		smallint,  
	    	amt_gross		float,
	    	amt_discount		float,
	    	amt_tax			float,
	    	amt_freight		float,
	    	amt_misc		float,
		amt_tax_included	float,
		--frt_calc_tax		float,
	    	glamt_tax		float,
	    	glamt_freight		float,
	    	glamt_misc		float,
	    	glamt_discount		float,
	    	amt_net			float,
		amt_paid		float,
		amt_due			float,
		frt_calc_tax		float,
		doc_desc		varchar(40), 
		hold_desc		varchar(40), 
		user_id			smallint, 
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
		cms_flag		smallint,
		process_group_num 	varchar(16),
		nat_cur_code 		varchar(8),	 
		rate_type_home 		varchar(8),	 
		rate_type_oper		varchar(8),	 
		rate_home 		float,		   
		rate_oper		float,		   
		--iv_ctrl_num		varchar(16),
		net_original_amt	float,
		org_id			varchar(30) NULL,
		tax_freight_no_recoverable	float,
		--db_action			smallint
	)
	
	
	

	INSERT INTO #apvochg_work
	SELECT ah.trx_ctrl_num, ah.trx_type, ah.doc_ctrl_num, ah.apply_to_num, ah.user_trx_type_code, ah.batch_code, ah.po_ctrl_num, ah.vend_order_num, ah.ticket_num, 
	ah.date_applied, ah.date_aging, ah.date_due, ah.date_doc, ah.date_entered, ah.date_received, ah.date_required, ah.date_recurring, ah.date_discount, ah.posting_code, --ah.date_applied
	ah.vendor_code, ah.pay_to_code, ah.branch_code, ah.class_code, ah.approval_code, ah.comment_code, ah.fob_code, ah.terms_code, ah.tax_code, ah.recurring_code, 
	ah.location_code, ah.payment_code, ah.times_accrued, ah.accrual_flag, ah.drop_ship_flag, ah.posted_flag, ah.add_cost_flag, ah.recurring_flag, ah.one_time_vend_flag,
	ah.one_check_flag, ah.amt_gross, ah.amt_discount, ah.amt_tax, ah.amt_freight, ah.amt_misc,amt_tax_included, ah.amt_tax, ah.amt_freight, ah.amt_misc,ah.amt_discount,
	ah.amt_net, ah.amt_paid, ah.amt_due, ah.frt_calc_tax, ah.doc_desc,ah.hold_desc, ah.user_id, ah.next_serial_id, ah.pay_to_addr1, ah.pay_to_addr2, ah.pay_to_addr3,
	ah.pay_to_addr4, ah.pay_to_addr5, ah.pay_to_addr6, ah.attention_name,ah.attention_phone, ah.intercompany_flag, ah.company_code, ah.cms_flag, ah.process_group_num, 
	ah.nat_cur_code, ah.rate_type_home, ah.rate_type_oper, ah.rate_home, ah.rate_oper, ah.net_original_amt, ah.org_id, ah.tax_freight_no_recoverable
	FROM apinpchg ah,accrualsdet t 
	WHERE ah.trx_ctrl_num = t.trx_ctrl_num
        AND t.accrual_number = @accrual_number 
	AND t.to_post_flag=1
	AND t.trans_type =1
	order by ah.org_id



	
	
	CREATE TABLE #apvocdt_work
	(
		trx_ctrl_num		varchar(16),
		trx_type		smallint,
		sequence_id		int,
		location_code		varchar(8),
		item_code		varchar(30),
		bulk_flag		smallint,
		qty_ordered		float,
		qty_received		float,
		approval_code		varchar(8),
		tax_code		varchar(8),
		code_1099		varchar(8),
		po_ctrl_num		varchar(16),
		unit_code		varchar(8),
		unit_price		float,
		amt_discount		float,
		amt_freight 		float,
		amt_tax     		float,
		amt_misc    		float,
		amt_extended		float,
		--amt_orig_extended	float,
		calc_tax		float,
		date_entered		int,
		gl_exp_acct		varchar(32),
		rma_num			varchar(20),
		line_desc		varchar(60),
		serial_id		int,
		company_id		smallint,
		iv_post_flag		smallint,
		po_orig_flag		smallint,
		rec_company_code	varchar(8),
		reference_code		varchar(32),
		org_id		        varchar(30) NULL,
		--db_action		smallint,
		amt_nonrecoverable_tax	float,
		amt_tax_det		float
	)
	
	 INSERT INTO #apvocdt_work
	 SELECT ad.trx_ctrl_num, ad.trx_type, ad.sequence_id, ad.location_code, ad.item_code, ad.bulk_flag, ad.qty_ordered, ad.qty_received,  ad.approval_code, ad.tax_code,
	 ad.code_1099, ad.po_ctrl_num, ad.unit_code, ad.unit_price, ad.amt_discount, ad.amt_freight, ad.amt_tax, ad.amt_misc, ad.amt_extended, ad.calc_tax, ad.date_entered, ad.gl_exp_acct,
	 ad.rma_num, ad.line_desc, ad.serial_id, ad.company_id, ad.iv_post_flag, ad.po_orig_flag, ad.rec_company_code,  ad.reference_code,
	 ad.org_id,  ad.amt_nonrecoverable_tax, ad.amt_tax_det 
	FROM apinpcdt ad,accrualsdet t 
	WHERE ad.trx_ctrl_num = t.trx_ctrl_num 
	AND t.accrual_number = @accrual_number 
	--AND ad.trx_type = t.trx_type 
	AND t.to_post_flag=1
	AND t.trans_type =1

	EXEC @result = APVOUpdateExtendedAmounts_sp  @debug
		
	 UPDATE #apvochg_work 
	 SET #apvochg_work.glamt_discount = dt.sumdisc,
	     #apvochg_work.glamt_freight = dt.sumfrei,
	     #apvochg_work.glamt_tax = dt.sumtax,
	     #apvochg_work.glamt_misc = dt.summisc	
	 FROM #apvochg_work t JOIN 
	 (SELECT  #apvocdt_work.trx_ctrl_num,
                  avg(#apvochg_work.amt_discount) - sum(#apvocdt_work.amt_discount) as sumdisc , 
	       	  avg(#apvochg_work.amt_freight) - sum(#apvocdt_work.amt_freight) as sumfrei,
	          avg(#apvochg_work.amt_tax) - sum(#apvocdt_work.amt_tax) as sumtax, 
	          avg(#apvochg_work.amt_misc) - sum(#apvocdt_work.amt_misc) as summisc
	 FROM #apvocdt_work , #apvochg_work   
	 WHERE #apvocdt_work.trx_ctrl_num = #apvochg_work.trx_ctrl_num     
	 GROUP BY #apvocdt_work.trx_ctrl_num ) dt ON t.trx_ctrl_num = dt.trx_ctrl_num	
	


	
	
	CREATE TABLE #apvotaxdtl_work
	(
		trx_ctrl_num		varchar(16),
		sequence_id		integer,
		trx_type		integer,
		tax_sequence_id		integer,
		detail_sequence_id	integer,
		tax_type_code		varchar(8),
		amt_taxable		float,
		amt_gross		float,
		amt_tax			float,
		amt_final_tax		float,
		recoverable_flag	integer,
		account_code		varchar(32)
		--db_action		smallint
	)
	
	INSERT INTO #apvotaxdtl_work
	SELECT atax.trx_ctrl_num, atax.sequence_id, atax.trx_type, atax.tax_sequence_id, atax.detail_sequence_id, atax.tax_type_code, atax.amt_taxable, 
	atax.amt_gross, atax.amt_tax, atax.amt_final_tax, atax.recoverable_flag, atax.account_code
	FROM apinptaxdtl atax,accrualsdet t 
	WHERE atax.trx_ctrl_num = t.trx_ctrl_num 
	AND t.accrual_number = @accrual_number 
	--AND atax.trx_type = t.trx_type 
	AND t.to_post_flag=1
	AND t.trans_type =1

	
                   


	SELECT @count = COUNT(trx_ctrl_num) FROM #apvochg_work 

	select @period_end_date = period_end_date from accrualshdr where accrual_number = @accrual_number

	CREATE TABLE #trxerror
		(
			journal_ctrl_num  	varchar(30) NOT NULL, 
			sequence_id		int NOT NULL,
			error_code	  	int NOT NULL
		)
		
	



	
	IF ( @count > 0 )
	BEGIN  
		
		--SELECT @org_company=(SELECT company_code FROM glcomp_vw WHERE company_id=(SELECT company_id FROM glco))

		




		EXEC    @result = APVOProcessGLEntries1_sp @process_ctrl_num,@period_end_date,0,@smuser_id,NULL,1,@debug
				
		IF @result =  420
		begin
			return @result
		end         


		
		
		
		
		




		--ciclo por journals
		select @jrnl = ''
		while ( 1 = 1)
		BEGIN
			SELECT  @old_jrnl = @jrnl
		
			SELECT  @min_jrnl = min(journal_ctrl_num)					
			FROM    #gltrx 
			WHERE   journal_ctrl_num > @old_jrnl						
		
			SELECT  @jrnl = journal_ctrl_num
			FROM    #gltrx 
			WHERE   journal_ctrl_num > @old_jrnl
			AND	journal_ctrl_num = @min_jrnl 
		
			
			
			
			IF  @jrnl !> @old_jrnl
				break

			CREATE TABLE	#offset_accts (
					account_code	varchar(32)	NOT NULL,
					org_code	varchar(8)	NOT NULL,
					rec_code	varchar(8)	NOT NULL,
					sequence_id	int 	NOT NULL)

			CREATE TABLE	#offsets (	journal_ctrl_num	varchar(16)	NOT NULL,
					sequence_id		int	NOT NULL,
					company_code		varchar(8)	NOT NULL,
					company_id		smallint	NOT NULL,
					org_ic_acct  		varchar(32)	NOT NULL,
					org_seg1_code		varchar(32)	NOT NULL,
					org_seg2_code		varchar(32)	NOT NULL,
					org_seg3_code		varchar(32)	NOT NULL,
					org_seg4_code		varchar(32)	NOT NULL,
					org_org_id		varchar(30)	NOT NULL,
					rec_ic_acct  		varchar(32)	NOT NULL,
					rec_seg1_code		varchar(32)	NOT NULL,
					rec_seg2_code		varchar(32)	NOT NULL,
					rec_seg3_code		varchar(32)	NOT NULL,
					rec_seg4_code		varchar(32)	NOT NULL, 
					rec_org_id		varchar(32)	NOT NULL )

			
					--ciclo por rec_company_code
					DECLARE rec_intercomp  CURSOR FOR 
					SELECT DISTINCT rec_company_code, company_code
					FROM #gltrxdet, #gltrx
					WHERE #gltrxdet.journal_ctrl_num = #gltrx.journal_ctrl_num

					OPEN rec_intercomp

					FETCH NEXT FROM rec_intercomp 
					INTO @rec_intercomp, @company_code

					WHILE @@FETCH_STATUS = 0
					BEGIN
							
						
							EXEC    @result = gltrxval1_sp   @company_code,
									@rec_intercomp, 
									@jrnl,
									--1,
									@debug
							
							-- Get the next rec_intercomp.
							FETCH NEXT FROM rec_intercomp 
							INTO @rec_intercomp,@company_code
					END 
					CLOSE rec_intercomp
					DEALLOCATE rec_intercomp

			

				drop table #offsets
				drop table #offset_accts
		
		 END        

		
		            
			
		IF @result =  0
		BEGIN
			EXEC gltrxsav_sp @process_ctrl_num,@org_company,0,0,@smuser_id
	
			
			
			SELECT	@indirect_flag = indirect_flag FROM glco
	
			if @indirect_flag=1 
	                BEGIN
				SELECT @counttable = COUNT(Object_Id('tempdb..#gltrxjcn')) 
				if @counttable > 0
				   drop table 	#gltrxjcn
	
				CREATE TABLE #gltrxjcn( journal_ctrl_num varchar(16) ) 
				
				EXEC   glpsindp_sp	@process_ctrl_num, @org_company, 0 
				EXEC  pctrlupd_sp @process_ctrl_num, 3  
				
			END

			UPDATE  accrualshdr
			SET	posted_flag =1
			WHERE   accrual_number = @accrual_number

			EXEC appgetstring_sp 'STR_NO_ERRORS', @str_msg_at  OUT

			UPDATE  accrualsdet
			SET	posted_flag =1,
				 accrualsdet.err_description = @str_msg_at
			WHERE   accrual_number = @accrual_number
			
		END
		ELSE
		BEGIN
		        
			UPDATE  accrualsdet 
		        SET     accrualsdet.err_description = e.e_ldesc,
				accrualsdet.posted_flag =0
			FROM    #trxerror t, glerrdef e
			WHERE	t.error_code = e.e_code
			AND   	accrualsdet.journal_ctrl_num = t.journal_ctrl_num
			AND     accrualsdet.accrual_number = @accrual_number
		END	

		--drop table #trxerror	

		
	END

	drop table #trxerror
	return @result

END
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[apgentrxGLVO_sp] TO [public]
GO
