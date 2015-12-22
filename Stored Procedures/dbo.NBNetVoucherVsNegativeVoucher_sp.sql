SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROCEDURE [dbo].[NBNetVoucherVsNegativeVoucher_sp] 	@net_ctrl_num 		varchar(16), 
							@vend_susp_acct 	varchar(32),	
							@process_ctrl_num	varchar(16),
							@debug_level 		smallint
AS


	

















CREATE TABLE  #apinpchg  (
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
	trx_state        	smallint    NULL,
	mark_flag           smallint	 NULL,
	net_original_amt	float,
	org_id		varchar(30) NULL,
	tax_freight_no_recoverable float
	)


	CREATE UNIQUE CLUSTERED INDEX apinpchg_ind_0 ON #apinpchg ( trx_ctrl_num, trx_type )

	




















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
	amt_tax             	float,
	amt_misc            	float,
	amt_extended        	float,
	calc_tax            	float,
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
	trx_state        		smallint NULL,
	mark_flag           	smallint NULL,
	org_id		varchar(30) NULL,
	amt_nonrecoverable_tax	float,
	amt_tax_det		float

	)


	CREATE CLUSTERED INDEX apinpcdt_ind_0	ON #apinpcdt ( trx_ctrl_num, trx_type, sequence_id )

	CREATE TABLE #apinptax	(
	trx_ctrl_num	varchar(16),	trx_type	smallint,	sequence_id	int,
	tax_type_code	varchar(8),	amt_taxable	float,		amt_gross	float,
	amt_tax		float,		amt_final_tax	float	)
	CREATE CLUSTERED INDEX apinptax_ind_0 ON #apinptax ( trx_ctrl_num, trx_type, sequence_id )

	CREATE TABLE #apinpage	(
	trx_ctrl_num	varchar(16),	trx_type	smallint,	sequence_id	int,
	date_applied	int,		date_due	int,		date_aging	int,
	amt_due		float		)
	CREATE UNIQUE CLUSTERED INDEX apinpage_ind_0 ON #apinpage ( trx_ctrl_num, trx_type, date_aging )


	DECLARE	@customer_code		varchar(8),
		@terms_code		varchar(8),
		@posting_code		varchar(8),
		@nat_cur_code		varchar(8),
		@payment_code		varchar(8),
		@company_code		varchar(8),
		@branch_code		varchar(8),
		@fob_code		varchar(8),
		@location_code 		varchar(8),
		@class_code		varchar(8),
		@comment_code		varchar(8),
		@user_trx_type_code	varchar(8),
		@rate_type_home		varchar(8),
		@rate_type_oper		varchar(8),
		@vendor_code 		varchar(12),
		@payment_ctrl_num	varchar(16),
		@trx_ctrl_num		varchar(16),
		@vou_trx_ctrl_num	varchar(16),
		@dm_ctrl_num		varchar(16),
		@vou_ctrl_num		varchar(16),
		@cre_trx_ctrl_num	varchar(16),
		@net_doc_num		varchar(16),
		@cash_acct_code		varchar(32),
		@attention_phone	varchar(30),
		@attention_name		varchar(40),
		@inv_user_trx_type_code varchar(8),
		@vou_amt_committed 	float, 
		@nvou_amt_committed	float,
		@amt_to_be_applied	float,
		@trx_amt_committed	float,
		@amt_applied		float,
		@amt_committed		float,
		@rate_home		float,
		@rate_oper		float,	
		@date_entered		int,
		@sequence_id		int,
		@payment_type		int,
		@company_id		int,
		@num			int,
		@root_org_id		varchar(30)

	


	SELECT @root_org_id = ISNULL((select organization_id from Organization where outline_num = '1'),'')    

	SELECT	@customer_code 	= customer_code,
		@vendor_code 	= vendor_code,
		@nat_cur_code	= currency_code
	FROM 	#nbnethdr_work
	WHERE	net_ctrl_num 	= @net_ctrl_num

	exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.3',0,''

	


	SELECT 	@nvou_amt_committed = ISNULL(SUM(amt_committed),0.0)
	FROM	#nbnetdeb_work
	WHERE	((amt_committed) > (0.0) + 0.0000001)
	AND 	trx_type 	= 4091
	AND	net_ctrl_num 	= @net_ctrl_num

	


	SELECT 	@vou_amt_committed = ISNULL(SUM(amt_committed),0.0)
	FROM	#nbnetcre_work
	WHERE	((amt_committed) > (0.0) + 0.0000001)
	AND 	trx_type 	= 4091
	AND	net_ctrl_num 	= @net_ctrl_num


	


	IF ( @nvou_amt_committed = 0 OR @vou_amt_committed = 0)  
	BEGIN
		exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.3',5,''
		RETURN 0	
	END


	

	

	SELECT 	@user_trx_type_code 	= MIN(user_trx_type_code)
	FROM	apusrtyp
	WHERE	system_trx_type 	=  4092

	


	SELECT	@terms_code		= ISNULL(terms_code,''),
		@posting_code		= ISNULL(posting_code,''),
		@payment_code		= ISNULL(payment_code,''),
		@cash_acct_code		= ISNULL(cash_acct_code,''),
		@branch_code		= ISNULL(branch_code,''),
		@class_code		= ISNULL(vend_class_code,''),
		@comment_code		= ISNULL(comment_code,''), 
		@fob_code		= ISNULL(fob_code,''),
		@location_code 		= ISNULL(location_code,''),
		@attention_name		= ISNULL(attention_name,''),
		@attention_phone	= ISNULL(attention_phone,'')
	FROM 	apvend
	WHERE	vendor_code		= @vendor_code

		

	


	SELECT 	@company_code 	= company_code,
		@company_id	= company_id 
	FROM	glco

	


	EXEC	appdate_sp @date_entered OUTPUT


	



	IF ( @nvou_amt_committed <= @vou_amt_committed )
	BEGIN

		
		


		SELECT	@amt_to_be_applied = @nvou_amt_committed       
		
		SELECT @trx_ctrl_num = ''

		WHILE @amt_to_be_applied > 0
		BEGIN


			SELECT 	@trx_ctrl_num	= MIN(trx_ctrl_num)
			FROM	#nbnetcre_work
			WHERE	net_ctrl_num 	= @net_ctrl_num
			AND	trx_ctrl_num	> @trx_ctrl_num
			AND	trx_type 	= 4091

			SELECT 	@trx_amt_committed = amt_committed
			FROM	#nbnetcre_work
			WHERE	trx_ctrl_num 	= @trx_ctrl_num
			AND	net_ctrl_num	= @net_ctrl_num

			


			SELECT	@rate_type_home	= rate_type_home,
				@rate_type_oper = rate_type_oper,
				@rate_home	= rate_home,
				@rate_oper	= rate_oper
			FROM	apvohdr
			WHERE	trx_ctrl_num	= @trx_ctrl_num

			IF @trx_amt_committed IS NULL
				SELECT @trx_amt_committed = 0
			
			SELECT @sequence_id = 1

			IF @amt_to_be_applied >= @trx_amt_committed
				SELECT @amt_applied = @trx_amt_committed
			ELSE	
				SELECT @amt_applied = @amt_to_be_applied

			


	
			EXEC apnewnum_sp 4092, @company_code, @dm_ctrl_num OUTPUT
			
			


	
			EXEC ARGetNextControl_SP 2130, @net_doc_num OUTPUT, @num OUTPUT


			

				

			INSERT #apinpchg (	
			trx_ctrl_num,	trx_type,	doc_ctrl_num,	apply_to_num,	user_trx_type_code,	batch_code,
			po_ctrl_num,	vend_order_num,	ticket_num,	date_applied,	date_aging,		date_due,
			date_doc,	date_entered,	date_received,	date_required,	date_recurring,		date_discount,
			posting_code,	vendor_code,	pay_to_code,	branch_code,	class_code,		approval_code,
			comment_code,	fob_code,	terms_code,	tax_code,	recurring_code,		location_code,
			payment_code,	times_accrued,	accrual_flag,	drop_ship_flag,	posted_flag,		hold_flag,
			add_cost_flag,	approval_flag,	recurring_flag,	one_time_vend_flag,one_check_flag,	amt_gross,
			amt_discount,	amt_tax,	amt_freight,	amt_misc,	amt_net,		amt_paid,
			amt_due,	amt_restock,	amt_tax_included,frt_calc_tax,	doc_desc,		hold_desc,
			user_id,	next_serial_id,	pay_to_addr1,	pay_to_addr2,	pay_to_addr3,		pay_to_addr4,
			pay_to_addr5,	pay_to_addr6,	attention_name,	attention_phone,intercompany_flag,	company_code,
			cms_flag,	process_group_num,nat_cur_code,	rate_type_home,	rate_type_oper,		rate_home,
			rate_oper,	net_original_amt,org_id)
			VALUES ( 	
			@dm_ctrl_num,	4092,		@net_doc_num,	@trx_ctrl_num,	@user_trx_type_code,	'',
			'',		@trx_ctrl_num, 		'',		@date_entered,	@date_entered,		@date_entered,
		@date_entered,	@date_entered,	@date_entered,	@date_entered,	0,			0,
			@posting_code,	@vendor_code,	'',		@branch_code,	@class_code,		'',
			@comment_code,	@fob_code,	@terms_code,	'NBTAX',	'',			@location_code,
			@payment_code,	0,		0,		0,		-1,			0,
			0.00,		0,		0,		0,		0,			@amt_applied,
	0.00,		0.00,		0.00,		0.00,		@amt_applied,		0.00,
			@amt_applied,	0.00,		0.00,		0.00,		'Netting Transaction',	'',
			USER_ID(),	0,		'',		'',		'',			'',
			'',		'',		@attention_name,@attention_phone,0,			@company_code,
			0,		@process_ctrl_num,@nat_cur_code,@rate_type_home,@rate_type_oper,	@rate_home,
			@rate_oper,	@amt_applied,	@root_org_id	)	

			


			INSERT	#nbtrxrel (	net_ctrl_num, trx_ctrl_num,	trx_type	)
			VALUES (		@net_ctrl_num,@dm_ctrl_num,	4092		)

			exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.3',1,@dm_ctrl_num

			INSERT #apinpcdt	(	
			trx_ctrl_num,	trx_type,	sequence_id,	location_code,		item_code,	bulk_flag,	
			qty_ordered,	qty_received,	qty_returned,	qty_prev_returned,	approval_code,	tax_code,
			return_code,	code_1099,	po_ctrl_num,	unit_code,		unit_price,	amt_discount,		
			amt_freight,	amt_tax,	amt_misc,	amt_extended,		calc_tax,	date_entered,
			gl_exp_acct,	new_gl_exp_acct,rma_num,	line_desc,		serial_id,	company_id,	
			iv_post_flag,	po_orig_flag,	rec_company_code,new_rec_company_code,	reference_code, new_reference_code,
			org_id,		amt_nonrecoverable_tax,		amt_tax_det		)
			VALUES (
			@dm_ctrl_num,	4092,		1,		'',			'',		0,
			0.0,		1.0,		1.0,		0.0,			'',		'NBTAX',
			'',		'',		'',		'',			@amt_applied,	0.00,
			0.00,		0.00,		0.00,		@amt_applied,		0.00,		@date_entered,
			@vend_susp_acct,'',		'',		'Netting Transaction',	0,		@company_id,
			1,		0,		@company_code,'',			'',		'',
			@root_org_id,	0.0,		0.0	)

			INSERT #apinptax(
			trx_ctrl_num,	trx_type,	sequence_id,	tax_type_code,	amt_taxable,	amt_gross,
			amt_tax,	amt_final_tax		)
			VALUES (
			@dm_ctrl_num,	4092,		1,		'NBTAX',	@amt_applied,	@amt_applied,
			0.00,		0.00			)

			IF @@error != 0
			Begin
				exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.3',6,''
				RETURN -1
			End

			UPDATE	#nbnetcre_work			
			SET	amt_committed 	= amt_committed - @amt_applied
			WHERE	trx_ctrl_num 	= @trx_ctrl_num
			AND	net_ctrl_num	= @net_ctrl_num

			SELECT @sequence_id = @sequence_id + 1

			SELECT @amt_to_be_applied =  @amt_to_be_applied - @amt_applied

			IF ((@amt_to_be_applied) < (0.0) - 0.0000001)
				SELECT @amt_to_be_applied = 0.0


		END	


		SELECT 	@vou_trx_ctrl_num = MIN(trx_ctrl_num)	
		FROM	#nbnetdeb_work
		WHERE	net_ctrl_num 	= @net_ctrl_num
		AND	trx_type 	= 4091
		AND	amt_committed	> 0.00

		WHILE 	@vou_trx_ctrl_num IS NOT NULL
		BEGIN

			


			EXEC apnewnum_sp 4091, @company_code, @vou_ctrl_num OUTPUT

			IF @vou_ctrl_num IS NULL
			Begin
				exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.3',7,''
				RETURN 1
			End

			


			EXEC ARGetNextControl_SP 2130, @net_doc_num OUTPUT, @num OUTPUT


			SELECT	@amt_committed = amt_committed
			FROM	#nbnetdeb_work
			WHERE	trx_ctrl_num	= @vou_trx_ctrl_num

			


			SELECT	@rate_type_home	= rate_type_home,
				@rate_type_oper = rate_type_oper,
				@rate_home	= rate_home,
				@rate_oper	= rate_oper
			FROM	apvohdr
			WHERE	trx_ctrl_num	= @vou_trx_ctrl_num

			SELECT 	@inv_user_trx_type_code 	= MAX(user_trx_type_code)
			FROM	apusrtyp
			WHERE	system_trx_type 	=  4091


			

				

			INSERT #apinpchg (	
			trx_ctrl_num,	trx_type,	doc_ctrl_num,	apply_to_num,	user_trx_type_code,	batch_code,
			po_ctrl_num,	vend_order_num,	ticket_num,	date_applied,	date_aging,		date_due,
			date_doc,	date_entered,	date_received,	date_required,	date_recurring,		date_discount,
			posting_code,	vendor_code,	pay_to_code,	branch_code,	class_code,		approval_code,
			comment_code,	fob_code,	terms_code,	tax_code,	recurring_code,		location_code,
			payment_code,	times_accrued,	accrual_flag,	drop_ship_flag,	posted_flag,		hold_flag,
			add_cost_flag,	approval_flag,	recurring_flag,	one_time_vend_flag,one_check_flag,	amt_gross,
			amt_discount,	amt_tax,	amt_freight,	amt_misc,	amt_net,		amt_paid,
			amt_due,	amt_restock,	amt_tax_included,frt_calc_tax,	doc_desc,		hold_desc,
			user_id,	next_serial_id,	pay_to_addr1,	pay_to_addr2,	pay_to_addr3,		pay_to_addr4,
			pay_to_addr5,	pay_to_addr6,	attention_name,	attention_phone,intercompany_flag,	company_code,
			cms_flag,	process_group_num,nat_cur_code,	rate_type_home,	rate_type_oper,		rate_home,
			rate_oper,	net_original_amt, org_id	)
			VALUES 	(
			@vou_ctrl_num,	4091,		@net_doc_num,	@vou_trx_ctrl_num,		@inv_user_trx_type_code,'',  
			'',		@vou_trx_ctrl_num, 		'',		@date_entered,	@date_entered,		@date_entered,	       
		@date_entered,	@date_entered,	@date_entered,	@date_entered,	0,			0,
			@posting_code,	@vendor_code,	'',		@branch_code,	@class_code,		'',
			@comment_code,	@fob_code,	@terms_code,	'NBTAX',	'',			@location_code,
			@payment_code,	0,		0,		0,		-1,			0,
			0,		0,		0,		0,		0,			@amt_committed,
	0.00,		0.00,		0.00,		0.00,		@amt_committed,		0.00,
			@amt_committed,	0.00,		0.00,		0.00,		'Netting Transaction',	'',
			USER_ID(),	0,		'',		'',		'',			'',
			'',		'',		@attention_name,@attention_phone,0,			@company_code,
			0,		@process_ctrl_num,@nat_cur_code,@rate_type_home,@rate_type_oper,	@rate_home,
			@rate_oper,	@amt_committed,	@root_org_id	)	

			


			INSERT	#nbtrxrel (	net_ctrl_num, trx_ctrl_num,	trx_type	)
			VALUES (		@net_ctrl_num,@vou_ctrl_num,	4091		)

			exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.3',2,@vou_ctrl_num

			INSERT #apinpcdt	(	
			trx_ctrl_num,	trx_type,	sequence_id,	location_code,		item_code,	bulk_flag,	
			qty_ordered,	qty_received,	qty_returned,	qty_prev_returned,	approval_code,	tax_code,
			return_code,	code_1099,	po_ctrl_num,	unit_code,		unit_price,	amt_discount,		
			amt_freight,	amt_tax,	amt_misc,	amt_extended,		calc_tax,	date_entered,
			gl_exp_acct,	new_gl_exp_acct,rma_num,	line_desc,		serial_id,	company_id,	
			iv_post_flag,	po_orig_flag,	rec_company_code,new_rec_company_code,	reference_code, new_reference_code,
			org_id,		amt_nonrecoverable_tax, 	amt_tax_det	)
			VALUES (
			@vou_ctrl_num,	4091,		1,		'',			'',		0,		
			1.0,		1.0,		0.0,		0.0,			'',		'NBTAX',	
			'',		'',		'',		'',			@amt_committed,	0.00,
			0.00,		0.00,		0.00,		@amt_committed,		0.00,		@date_entered,
			@vend_susp_acct,'',		'',		'Netting Transaction',	0,		@company_id,
			1,		0,		@company_code,	'',			'',		'',
			@root_org_id,	0.0,		0.0	)
			
			INSERT #apinptax(
			trx_ctrl_num,	trx_type,	sequence_id,	tax_type_code,	amt_taxable,	amt_gross,
			amt_tax,	amt_final_tax		)
			VALUES (
			@vou_ctrl_num,	4091,		1,		'NBTAX',	@amt_committed,	@amt_committed,
			0.00,		0.00			)
			
			INSERT #apinpage (
			trx_ctrl_num,	trx_type,	sequence_id,	date_applied,	date_due,	date_aging,
			amt_due		)
			VALUES	(
			@vou_ctrl_num,	4091,		1,		@date_entered,	@date_entered,	@date_entered,
			@amt_committed	)			

			IF @@error != 0
			Begin
				exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.3',8,@vou_trx_ctrl_num
				RETURN -1
			end


			UPDATE	#nbnetdeb_work
			SET	amt_committed = 0.0
			WHERE	net_ctrl_num 	= @net_ctrl_num
			AND	trx_ctrl_num	= @vou_trx_ctrl_num
	
			SELECT 	@vou_trx_ctrl_num = MIN(trx_ctrl_num)	
			FROM	#nbnetdeb_work
			WHERE	net_ctrl_num 	= @net_ctrl_num
			AND	trx_ctrl_num	> @vou_trx_ctrl_num
			AND	trx_type 	= 4091
			AND	amt_committed	> 0.00
		

		END 	

	
	END
	ELSE
	BEGIN		
	

		


		SELECT	@amt_to_be_applied = @vou_amt_committed        

		SELECT @trx_ctrl_num = ''

		



		WHILE @amt_to_be_applied > 0
		BEGIN 	

			SELECT 	@trx_ctrl_num	= MIN(trx_ctrl_num)
			FROM	#nbnetdeb_work
			WHERE	net_ctrl_num 	= @net_ctrl_num
			AND	trx_ctrl_num	> @trx_ctrl_num
			AND	trx_type 	= 4091

			SELECT 	@trx_amt_committed = amt_committed
			FROM	#nbnetdeb_work
			WHERE	trx_ctrl_num 	= @trx_ctrl_num
			AND	trx_type 	= 4091

			


			SELECT	@rate_type_home	= rate_type_home,
				@rate_type_oper = rate_type_oper,
				@rate_home	= rate_home,
				@rate_oper	= rate_oper
			FROM	apvohdr
			WHERE	trx_ctrl_num	= @trx_ctrl_num

			SELECT 	@inv_user_trx_type_code 	= MAX(user_trx_type_code)
			FROM	apusrtyp
			WHERE	system_trx_type 	=  4091

			IF @trx_amt_committed IS NULL
				SELECT @trx_amt_committed = 0
			
			IF @amt_to_be_applied >= @trx_amt_committed
				SELECT @amt_applied = @trx_amt_committed
			ELSE	
				SELECT @amt_applied = @amt_to_be_applied

			


			EXEC apnewnum_sp 4091, @company_code, @vou_ctrl_num OUTPUT

			IF @vou_ctrl_num IS NULL
			Begin
				exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.3',7,''

				RETURN 1
			End

			


	
			EXEC ARGetNextControl_SP 2130, @net_doc_num OUTPUT, @num OUTPUT

			

				

			INSERT #apinpchg (	
			trx_ctrl_num,	trx_type,	doc_ctrl_num,	apply_to_num,	user_trx_type_code,	batch_code,
			po_ctrl_num,	vend_order_num,	ticket_num,	date_applied,	date_aging,		date_due,
			date_doc,	date_entered,	date_received,	date_required,	date_recurring,		date_discount,
			posting_code,	vendor_code,	pay_to_code,	branch_code,	class_code,		approval_code,
			comment_code,	fob_code,	terms_code,	tax_code,	recurring_code,		location_code,
			payment_code,	times_accrued,	accrual_flag,	drop_ship_flag,	posted_flag,		hold_flag,
			add_cost_flag,	approval_flag,	recurring_flag,	one_time_vend_flag,one_check_flag,	amt_gross,
			amt_discount,	amt_tax,	amt_freight,	amt_misc,	amt_net,		amt_paid,
			amt_due,	amt_restock,	amt_tax_included,frt_calc_tax,	doc_desc,		hold_desc,
			user_id,	next_serial_id,	pay_to_addr1,	pay_to_addr2,	pay_to_addr3,		pay_to_addr4,
			pay_to_addr5,	pay_to_addr6,	attention_name,	attention_phone,intercompany_flag,	company_code,
			cms_flag,	process_group_num,nat_cur_code,	rate_type_home,	rate_type_oper,		rate_home,
			rate_oper,	net_original_amt, org_id	)
			VALUES	(	
			@vou_ctrl_num,	4091,		@net_doc_num,	@trx_ctrl_num,		@inv_user_trx_type_code,'',	
			'',		@trx_ctrl_num, 		'',		@date_entered,	@date_entered,		@date_entered,  
		@date_entered,	@date_entered,	@date_entered,	@date_entered,	0,			0,
			@posting_code,	@vendor_code,	'',		@branch_code,	@class_code,		'',
			@comment_code,	@fob_code,	@terms_code,	'NBTAX',	'',			@location_code,
			@payment_code,	0,		0,		0,		-1,			0,
			0,		0,		0,		0,		0,			@amt_applied,
	0.00,		0.00,		0.00,		0.00,		@amt_applied,		0.00,
			@amt_applied,	0.00,		0.00,		0.00,		'Netting Transaction',	'',
			USER_ID(),	0,		'',		'',		'',			'',
			'',		'',		@attention_name,@attention_phone,0,			@company_code,
			0,		@process_ctrl_num,@nat_cur_code,@rate_type_home,@rate_type_oper,	@rate_home,
			@rate_oper,	@amt_applied,	@root_org_id	)		


			


			INSERT	#nbtrxrel (	net_ctrl_num, trx_ctrl_num,	trx_type	)
			VALUES (		@net_ctrl_num,@vou_ctrl_num,	4091		)

			exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.3',3,@vou_ctrl_num


			INSERT #apinpcdt	(	
			trx_ctrl_num,	trx_type,	sequence_id,	location_code,		item_code,	bulk_flag,	
			qty_ordered,	qty_received,	qty_returned,	qty_prev_returned,	approval_code,	tax_code,
			return_code,	code_1099,	po_ctrl_num,	unit_code,		unit_price,	amt_discount,		
			amt_freight,	amt_tax,	amt_misc,	amt_extended,		calc_tax,	date_entered,
			gl_exp_acct,	new_gl_exp_acct,rma_num,	line_desc,		serial_id,	company_id,	
			iv_post_flag,	po_orig_flag,	rec_company_code,new_rec_company_code,	reference_code, new_reference_code,
			org_id,		amt_nonrecoverable_tax, 	amt_tax_det		)
			VALUES (
			@vou_ctrl_num,	4091,		1,		'',			'',		0,		
			1.0,		1.0,		0.0,		0.0,			'',		'NBTAX',	
			'',		'',		'',		'',			@amt_applied,	0.00,
			0.00,		0.00,		0.00,		@amt_applied,		0.00,		@date_entered,
			@vend_susp_acct,'',		'',		'Netting Transaction',	0,		@company_id,
			1,		0,		@company_code,	'',			'',		'',
			@root_org_id,	0.0,		0.0	)

			
			INSERT #apinptax(
			trx_ctrl_num,	trx_type,	sequence_id,	tax_type_code,	amt_taxable,	amt_gross,
			amt_tax,	amt_final_tax		)
			VALUES (
			@vou_ctrl_num,	4091,		1,		'NBTAX',	@amt_applied,	@amt_applied,
			0.00,		0.00			)
			
			INSERT #apinpage (
			trx_ctrl_num,	trx_type,	sequence_id,	date_applied,	date_due,	date_aging,
			amt_due		)
			VALUES	(
			@vou_ctrl_num,	4091,		1,		@date_entered,	@date_entered,	@date_entered,
			@amt_applied	)			

			IF @@error != 0
			Begin
				exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.3',8,@trx_ctrl_num
				RETURN -1
			end

			UPDATE	#nbnetdeb_work
			SET	amt_committed 	= amt_committed - @amt_applied
			WHERE	trx_ctrl_num 	= @trx_ctrl_num
			AND	net_ctrl_num	= @net_ctrl_num


			


			SELECT @amt_to_be_applied =  @amt_to_be_applied - @amt_applied

			IF ((@amt_to_be_applied) < (0.0) - 0.0000001)
				SELECT @amt_to_be_applied = 0.0
				
			


		END	

		SELECT 	@cre_trx_ctrl_num	= MIN(trx_ctrl_num)
		FROM	#nbnetcre_work
		WHERE	net_ctrl_num 	= @net_ctrl_num
		AND	trx_type 	= 4091

		SELECT @sequence_id = 0

		WHILE @cre_trx_ctrl_num IS NOT NULL
		BEGIN
	
			SELECT @sequence_id = @sequence_id + 1

			SELECT	@amt_committed = amt_committed
			FROM	#nbnetcre_work
			WHERE	net_ctrl_num	= @net_ctrl_num
			AND	trx_ctrl_num	= @cre_trx_ctrl_num
			AND	trx_type	= 4091
			
			


			SELECT	@rate_type_home	= rate_type_home,
				@rate_type_oper = rate_type_oper,
				@rate_home	= rate_home,
				@rate_oper	= rate_oper
			FROM	apvohdr
			WHERE	trx_ctrl_num	= @cre_trx_ctrl_num

			


	
			EXEC apnewnum_sp 4092, @company_code, @dm_ctrl_num OUTPUT

			IF @dm_ctrl_num IS NULL
			Begin
				exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.3',9,''
				RETURN 1
			End

			


	
			EXEC ARGetNextControl_SP 2130, @net_doc_num OUTPUT, @num OUTPUT


			

				

			INSERT #apinpchg (	
			trx_ctrl_num,	trx_type,	doc_ctrl_num,	apply_to_num,	user_trx_type_code,	batch_code,
			po_ctrl_num,	vend_order_num,	ticket_num,	date_applied,	date_aging,		date_due,
			date_doc,	date_entered,	date_received,	date_required,	date_recurring,		date_discount,
			posting_code,	vendor_code,	pay_to_code,	branch_code,	class_code,		approval_code,
			comment_code,	fob_code,	terms_code,	tax_code,	recurring_code,		location_code,
			payment_code,	times_accrued,	accrual_flag,	drop_ship_flag,	posted_flag,		hold_flag,
			add_cost_flag,	approval_flag,	recurring_flag,	one_time_vend_flag,one_check_flag,	amt_gross,
			amt_discount,	amt_tax,	amt_freight,	amt_misc,	amt_net,		amt_paid,
			amt_due,	amt_restock,	amt_tax_included,frt_calc_tax,	doc_desc,		hold_desc,
			user_id,	next_serial_id,	pay_to_addr1,	pay_to_addr2,	pay_to_addr3,		pay_to_addr4,
			pay_to_addr5,	pay_to_addr6,	attention_name,	attention_phone,intercompany_flag,	company_code,
			cms_flag,	process_group_num,nat_cur_code,	rate_type_home,	rate_type_oper,		rate_home,
			rate_oper,	net_original_amt, org_id	)
			VALUES ( 	
			@dm_ctrl_num,	4092,		@net_doc_num,	@cre_trx_ctrl_num,@user_trx_type_code,	'',
			'',		@cre_trx_ctrl_num, 		'',		@date_entered,	@date_entered,		@date_entered,
		@date_entered,	@date_entered,	@date_entered,	@date_entered,	0,			0,
			@posting_code,	@vendor_code,	'',		@branch_code,	@class_code,		'',
			@comment_code,	@fob_code,	@terms_code,	'NBTAX',	'',			@location_code,
			@payment_code,	0,		0,		0,		-1,			0,
			0.00,		0,		0,		0,		0,			@amt_committed,
	0.00,		0.00,		0.00,		0.00,		@amt_committed,		0.00,
			@amt_committed,	0.00,		0.00,		0.00,		'Netting Transaction',	'',
			USER_ID(),	0,		'',		'',		'',			'',
			'',		'',		@attention_name,@attention_phone,0,			@company_code,
			0,		@process_ctrl_num,@nat_cur_code,@rate_type_home,@rate_type_oper,	@rate_home,
			@rate_oper,	@amt_committed, @root_org_id)				


			


			INSERT	#nbtrxrel (	net_ctrl_num, trx_ctrl_num,	trx_type	)
			VALUES (		@net_ctrl_num,@dm_ctrl_num,	4092		)

			exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.3',4,@dm_ctrl_num

			INSERT #apinpcdt	(	
			trx_ctrl_num,	trx_type,	sequence_id,	location_code,		item_code,	bulk_flag,	
			qty_ordered,	qty_received,	qty_returned,	qty_prev_returned,	approval_code,	tax_code,
			return_code,	code_1099,	po_ctrl_num,	unit_code,		unit_price,	amt_discount,		
			amt_freight,	amt_tax,	amt_misc,	amt_extended,		calc_tax,	date_entered,
			gl_exp_acct,	new_gl_exp_acct,rma_num,	line_desc,		serial_id,	company_id,	
			iv_post_flag,	po_orig_flag,	rec_company_code,new_rec_company_code,	reference_code, new_reference_code,
			org_id, 	amt_nonrecoverable_tax, 	amt_tax_det		)
			VALUES (
			@dm_ctrl_num,	4092,		1,		'',			'',		0,
			0.0,		0.0,		1.0,		0.0,			'',		'NBTAX',
			'',		'',		'',		'',			@amt_committed,	0.00,
			0.00,		0.00,		0.00,		@amt_committed,		0.00,		@date_entered,
			@vend_susp_acct,'',		'',		'Netting Transaction',	0,		@company_id,
			1,		0,		@company_code,	'',			'',		'',
			@root_org_id,	0.0,		0.0	)


			INSERT #apinptax(
			trx_ctrl_num,	trx_type,	sequence_id,	tax_type_code,	amt_taxable,	amt_gross,
			amt_tax,	amt_final_tax		)
			VALUES (
			@dm_ctrl_num,	4092,		1,		'NBTAX',	@amt_committed,	@amt_committed,
			0.00,		0.00			)


			UPDATE	#nbnetcre_work
			SET	amt_committed = 0.0
			WHERE	net_ctrl_num 	= @net_ctrl_num
			AND	trx_ctrl_num	= @cre_trx_ctrl_num


			SELECT 	@cre_trx_ctrl_num	= MIN(trx_ctrl_num)
			FROM	#nbnetcre_work
			WHERE	net_ctrl_num 	= @net_ctrl_num
			AND	trx_ctrl_num	> @cre_trx_ctrl_num
			AND	trx_type 	= 4091

			
		END 
	
	END 





INSERT	apinpchg (			
			trx_ctrl_num,	trx_type,	doc_ctrl_num,	apply_to_num,	user_trx_type_code,	batch_code,
			po_ctrl_num,	vend_order_num,	ticket_num,	date_applied,	date_aging,		date_due,
			date_doc,	date_entered,	date_received,	date_required,	date_recurring,		date_discount,
			posting_code,	vendor_code,	pay_to_code,	branch_code,	class_code,		approval_code,
			comment_code,	fob_code,	terms_code,	tax_code,	recurring_code,		location_code,
			payment_code,	times_accrued,	accrual_flag,	drop_ship_flag,	posted_flag,		hold_flag,
			add_cost_flag,	approval_flag,	recurring_flag,	one_time_vend_flag,one_check_flag,	amt_gross,
			amt_discount,	amt_tax,	amt_freight,	amt_misc,	amt_net,		amt_paid,
			amt_due,	amt_restock,	amt_tax_included,frt_calc_tax,	doc_desc,		hold_desc,
			user_id,	next_serial_id,	pay_to_addr1,	pay_to_addr2,	pay_to_addr3,		pay_to_addr4,
			pay_to_addr5,	pay_to_addr6,	attention_name,	attention_phone,intercompany_flag,	company_code,
			cms_flag,	process_group_num,nat_cur_code,	rate_type_home,	rate_type_oper,		rate_home,
			rate_oper,	net_original_amt, org_id	)
SELECT			trx_ctrl_num,	trx_type,	doc_ctrl_num,	apply_to_num,	user_trx_type_code,	batch_code,
			po_ctrl_num,	vend_order_num,	ticket_num,	date_applied,	date_aging,		date_due,
			date_doc,	date_entered,	date_received,	date_required,	date_recurring,		date_discount,
			posting_code,	vendor_code,	pay_to_code,	branch_code,	class_code,		approval_code,
			comment_code,	fob_code,	terms_code,	tax_code,	recurring_code,		location_code,
			payment_code,	times_accrued,	accrual_flag,	drop_ship_flag,	posted_flag,		hold_flag,
			add_cost_flag,	approval_flag,	recurring_flag,	one_time_vend_flag,one_check_flag,	amt_gross,
			amt_discount,	amt_tax,	amt_freight,	amt_misc,	amt_net,		amt_paid,
			amt_due,	amt_restock,	amt_tax_included,frt_calc_tax,	doc_desc,		hold_desc,
			user_id,	next_serial_id,	pay_to_addr1,	pay_to_addr2,	pay_to_addr3,		pay_to_addr4,
			pay_to_addr5,	pay_to_addr6,	attention_name,	attention_phone,intercompany_flag,	company_code,
			cms_flag,	process_group_num,nat_cur_code,	rate_type_home,	rate_type_oper,		rate_home,
			rate_oper,	net_original_amt, org_id				
FROM	#apinpchg

INSERT	apinpcdt (	trx_ctrl_num,	trx_type,	sequence_id,	location_code,		item_code,	bulk_flag,	
			qty_ordered,	qty_received,	qty_returned,	qty_prev_returned,	approval_code,	tax_code,
			return_code,	code_1099,	po_ctrl_num,	unit_code,		unit_price,	amt_discount,		
			amt_freight,	amt_tax,	amt_misc,	amt_extended,		calc_tax,	date_entered,
			gl_exp_acct,	new_gl_exp_acct,rma_num,	line_desc,		serial_id,	company_id,	
			iv_post_flag,	po_orig_flag,	rec_company_code,new_rec_company_code,	reference_code, new_reference_code,
			org_id, 	amt_nonrecoverable_tax, 	amt_tax_det
		)
SELECT			trx_ctrl_num,	trx_type,	sequence_id,	location_code,		item_code,	bulk_flag,	
			qty_ordered,	qty_received,	qty_returned,	qty_prev_returned,	approval_code,	tax_code,
			return_code,	code_1099,	po_ctrl_num,	unit_code,		unit_price,	amt_discount,		
			amt_freight,	amt_tax,	amt_misc,	amt_extended,		calc_tax,	date_entered,
			gl_exp_acct,	new_gl_exp_acct,rma_num,	line_desc,		serial_id,	company_id,	
			iv_post_flag,	po_orig_flag,	rec_company_code,new_rec_company_code,	reference_code, new_reference_code,
			org_id, 	amt_nonrecoverable_tax, 	amt_tax_det
FROM	#apinpcdt


INSERT	apinptax (	trx_ctrl_num,	trx_type,	sequence_id,	tax_type_code,	amt_taxable,	amt_gross,
			amt_tax,	amt_final_tax		)
SELECT			trx_ctrl_num,	trx_type,	sequence_id,	tax_type_code,	amt_taxable,	amt_gross,
			amt_tax,	amt_final_tax		
FROM	#apinptax


INSERT	apinpage (	trx_ctrl_num,	trx_type,	sequence_id,	date_applied,	date_due,	date_aging,
			amt_due					
)
SELECT			trx_ctrl_num,	trx_type,	sequence_id,	date_applied,	date_due,	date_aging,
			amt_due
FROM	#apinpage


DROP TABLE #apinpchg
DROP TABLE #apinpcdt
DROP TABLE #apinptax
DROP TABLE #apinpage

exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.3',-1,''

RETURN    0  


GO
GRANT EXECUTE ON  [dbo].[NBNetVoucherVsNegativeVoucher_sp] TO [public]
GO
