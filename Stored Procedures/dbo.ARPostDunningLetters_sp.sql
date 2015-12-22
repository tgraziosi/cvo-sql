SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[ARPostDunningLetters_sp]
AS
DECLARE	@fin_num 	VARCHAR(16),
	@gl_num		VARCHAR(16),
	@next_num	int,
	@result		int,
	@sequence_id	int,
	@today		int,
	@journal_ctrl_num	VARCHAR(16),
	@batch_num		VARCHAR(16),
	@process_ctrl_num 	VARCHAR(16),
	@dunn_ctrl_num		VARCHAR(16),
	@company_code		VARCHAR(8),
	@home_curr		VARCHAR(8),
	@oper_curr		VARCHAR(8),
	@company_id	INT,
	@year		INT,
	@month		INT,
	@day		INT,
	@print_fin_only int,
	@str_msg_ps		VARCHAR(255),
	@str_msg_at		VARCHAR(255)



CREATE TABLE #artrx_work
(
	doc_ctrl_num		varchar(16),
	trx_ctrl_num		varchar(16),
	apply_to_num		varchar(16),
	apply_trx_type	smallint,
	order_ctrl_num	varchar(16),
	doc_desc		varchar(40),
	batch_code		varchar(16),
	trx_type		smallint,
	date_entered		int,
	date_posted		int,
	date_applied		int,
	date_doc		int,
	date_shipped		int,
	date_required		int,
	date_due		int,
	date_aging		int,			
	customer_code		varchar(8),
	ship_to_code		varchar(8),
	salesperson_code	varchar(8),
	territory_code	varchar(8),
	comment_code		varchar(8),
	fob_code		varchar(8),
	freight_code		varchar(8),
	terms_code		varchar(8),
	fin_chg_code		varchar(8),
	price_code		varchar(8),
	dest_zone_code	varchar(8),
	posting_code		varchar(8),
	recurring_flag	smallint,
	recurring_code	varchar(8),
	tax_code		varchar(8),
	payment_code		varchar(8),
	payment_type		smallint,		
	cust_po_num		varchar(20),
	non_ar_flag		smallint,
	gl_acct_code		varchar(32),		
	gl_trx_id		varchar(16),
	prompt1_inp		varchar(30),
	prompt2_inp		varchar(30),
	prompt3_inp		varchar(30),
	prompt4_inp		varchar(30),
	deposit_num		varchar(16),
	amt_gross		float,
	amt_freight		float,
	amt_tax		float,
	amt_tax_included	float,
	amt_discount		float,
	amt_paid_to_date	float,
	amt_net		float,			
	amt_on_acct		float,
	amt_cost		float,
	amt_tot_chg		float,			
	amt_discount_taken	float		NULL,
	amt_write_off_given	float		NULL,
	user_id		smallint,
	void_flag		smallint,
	paid_flag		smallint,		
	date_paid		int,
	posted_flag		smallint,
	commission_flag	smallint,		
	cash_acct_code	varchar(32),
	non_ar_doc_num	varchar(16),
	purge_flag		smallint	NULL,	
	process_group_num varchar(16)	NULL,
	temp_flag		smallint	NULL,
	source_trx_ctrl_num	varchar(16)	NULL,
	source_trx_type	smallint	NULL,
	nat_cur_code		varchar(8),	
	rate_type_home	varchar(8),
	rate_type_oper	varchar(8),
	rate_home		float,
	rate_oper		float,
	reference_code	varchar(32) NULL,
	ddid			varchar(32) NULL,
	db_action		smallint,
	org_id          varchar(30) NULL
)

CREATE INDEX artrx_work_ind_0
	ON #artrx_work( doc_ctrl_num, trx_type, customer_code, payment_type, void_flag )

CREATE INDEX artrx_work_ind_1
	ON #artrx_work( apply_to_num, apply_trx_type, doc_ctrl_num, trx_type, customer_code )

CREATE INDEX #artrx_work_ind_2 
ON #artrx_work ( customer_code, trx_ctrl_num )


CREATE TABLE #artrxage_work
(	
	trx_ctrl_num		varchar(16),
	trx_type		smallint,
	ref_id	int,
	doc_ctrl_num		varchar(16),
	order_ctrl_num	varchar(16),
	cust_po_num		varchar(20),
	apply_to_num		varchar(16),
	apply_trx_type	smallint,
	sub_apply_num		varchar(16),
	sub_apply_type	smallint,
	date_doc		int,
	date_due		int,
	date_applied		int,
	date_aging		int,	
	customer_code		varchar(8),
	payer_cust_code	varchar(8),
	salesperson_code	varchar(8),
	territory_code	varchar(8),
	price_code		varchar(8),
	amount			float,
	paid_flag		smallint,
	group_id		int,
	amt_fin_chg		float,
	amt_late_chg		float,
	amt_paid		float,
	db_action		smallint,
	rate_home		float,
	rate_oper		float,
	nat_cur_code		varchar(8),
	true_amount		float,
	date_paid		int,
	journal_ctrl_num	varchar(16),
	account_code		varchar(32),
	org_id              varchar(30)
)

CREATE INDEX artrxage_work_ind_0
	ON #artrxage_work(	customer_code, trx_type, apply_trx_type, apply_to_num, 
	doc_ctrl_num, date_aging )

CREATE INDEX artrxage_work_ind_1
	ON #artrxage_work( doc_ctrl_num, trx_type, date_aging, customer_code )

CREATE INDEX artrxage_work_ind_2
	ON #artrxage_work( doc_ctrl_num, customer_code, ref_id, trx_type )

CREATE INDEX #artrxage_work_ind_3 
	ON #artrxage_work ( customer_code, doc_ctrl_num, trx_type ) 

CREATE INDEX #artrxage_work_ind_4 
	ON #artrxage_work ( apply_to_num, apply_trx_type )









































































  



					  

























































 


















































































































































































































































































































                       









































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
(	mark_flag smallint NOT NULL,  		trx_state smallint NOT NULL,  		journal_ctrl_num varchar(16) NOT NULL, 
	sequence_id int NOT NULL IDENTITY,	rec_company_code varchar(8) NOT NULL,   company_id smallint NOT NULL, 
	account_code varchar(32) NOT NULL,   	description varchar(40) NOT NULL,  	document_1 varchar(16) NOT NULL,  
	document_2 varchar(16) NOT NULL,   	reference_code varchar(32) NOT NULL,   	balance float NOT NULL,  
	nat_balance float NOT NULL,   		nat_cur_code varchar(8) NOT NULL,   	rate float NOT NULL,  
	posted_flag smallint NOT NULL,  	date_posted int NOT NULL,  		trx_type smallint NOT NULL, 
	offset_flag smallint NOT NULL,        	seg1_code varchar(32) NOT NULL,  	seg2_code varchar(32) NOT NULL, 
	seg3_code varchar(32) NOT NULL,  	seg4_code varchar(32) NOT NULL,  	seq_ref_id int NOT NULL,  
	balance_oper float NULL,  		rate_oper float NULL,  			rate_type_home varchar(8) NULL, 
	rate_type_oper varchar(8) NULL,		org_id			varchar(30) NULL 		)
CREATE UNIQUE INDEX #gltrxdet_ind_0  ON #gltrxdet ( journal_ctrl_num, sequence_id ) 
CREATE INDEX #gltrxdet_ind_1  ON #gltrxdet ( journal_ctrl_num, account_code )  



	


	SELECT @year = year(getdate()), @month = month(getdate()), @day = day(getdate())
	
	EXEC appjuldt_sp @year, @month, @day, @today OUTPUT


	SELECT 	@company_code = company_code,
		@home_curr = home_currency,
		@oper_curr = oper_currency,
		@company_id = company_id
	FROM 	glco





DECLARE header_cycle CURSOR FOR 
	SELECT dunn_ctrl_num FROM #ardncshd WHERE print_fin_only = 0

OPEN header_cycle

FETCH NEXT FROM header_cycle into @dunn_ctrl_num

WHILE @@FETCH_STATUS = 0
BEGIN


		UPDATE 	#ardncsdt
		SET	amt_extra 	= amt_extra_projected
		WHERE	dunn_ctrl_num	= @dunn_ctrl_num

		UPDATE 	#ardncshd
		SET	amt_extra 	= amt_extra_projected
		WHERE	dunn_ctrl_num	= @dunn_ctrl_num

		UPDATE 	ardncsdt
		SET	amt_extra 	= amt_extra_projected
		WHERE	dunn_ctrl_num	= @dunn_ctrl_num

		UPDATE 	ardncshd
		SET	amt_extra 	= amt_extra_projected
		WHERE	dunn_ctrl_num	= @dunn_ctrl_num




	FETCH NEXT FROM header_cycle into @dunn_ctrl_num

END



CLOSE header_cycle
DEALLOCATE header_cycle





UPDATE artrx
SET amt_tot_chg = amt_tot_chg + amt_extra
FROM #ardncsdt
WHERE #ardncsdt.customer_code = artrx.customer_code
AND      #ardncsdt.invoice_num = artrx.doc_ctrl_num









SELECT dunn_ctrl_num FROM #ardncshd


IF @@ROWCOUNT = 0 
	RETURN 	0








	DECLARE NumberCycle CURSOR FOR
		SELECT sequence_id FROM #ardncsdt, #ardncshd
		WHERE  #ardncshd.dunn_ctrl_num = #ardncsdt.dunn_ctrl_num
				AND #ardncshd.print_fin_only = 0

	OPEN NumberCycle

	FETCH NEXT FROM NumberCycle into @sequence_id

	WHILE @@FETCH_STATUS = 0
	BEGIN

		EXEC @result = ARGetNextControl_SP	2040, @fin_num OUTPUT, @next_num OUTPUT, 0

		EXEC @result = gltrxnew_sp @company_code,
					@journal_ctrl_num OUTPUT


		UPDATE #ardncsdt
		SET 	fin_num 	= @fin_num,
			gl_num		= @journal_ctrl_num
		WHERE sequence_id 	= @sequence_id

		SELECT @fin_num = "", @next_num = 0, @gl_num = ""

		
		FETCH NEXT FROM NumberCycle into @sequence_id


	END
  
	CLOSE NumberCycle
	DEALLOCATE NumberCycle

EXEC appgetstring_sp 'STR_DUNNING_FINANCE_CHARGE', @str_msg_ps  OUT
EXEC appgetstring_sp 'STR_IN_AR', @str_msg_at  OUT

SELECT 	@str_msg_at = @str_msg_ps + ' ' + @str_msg_at
	

	EXEC @result = ARGetNextControl_SP	2100, @batch_num OUTPUT, @next_num OUTPUT, 10
	EXEC @result = pctrladd_sp @process_ctrl_num OUTPUT, @str_msg_at, 1, 2000, @company_code, 2061


	INSERT #artrx_work (
		doc_ctrl_num,
		trx_ctrl_num,
		apply_to_num,
		apply_trx_type,
		order_ctrl_num,
		doc_desc,
		batch_code,
		trx_type,
		date_entered,
		date_posted,
		date_applied,
		date_doc,
		date_shipped,
		date_required,
		date_due,
		date_aging,			
		customer_code,
		ship_to_code,
		salesperson_code,
		territory_code,
		comment_code,
		fob_code,
		freight_code,
		terms_code,
		fin_chg_code,
		price_code,
		dest_zone_code,
		posting_code,
		recurring_flag,
		recurring_code,
		tax_code,
		payment_code,
		payment_type,
		cust_po_num,
		non_ar_flag,
		gl_acct_code,
		gl_trx_id,
		prompt1_inp,
		prompt2_inp,
		prompt3_inp,
		prompt4_inp,
		deposit_num,
		amt_gross,
		amt_freight,
		amt_tax,
		amt_tax_included,
		amt_discount,
		amt_paid_to_date,
		amt_net,
		amt_on_acct,
		amt_cost,
		amt_tot_chg,
		amt_discount_taken,
		amt_write_off_given,
		user_id,
		void_flag,
		paid_flag,
		date_paid,
		posted_flag,
		commission_flag,
		cash_acct_code,
		non_ar_doc_num,
		purge_flag,
		process_group_num,
		temp_flag,
		source_trx_ctrl_num,
		source_trx_type,
		nat_cur_code,
		rate_type_home,
		rate_type_oper,
		rate_home,
		rate_oper,
		reference_code,
		ddid,
		db_action
	)
	SELECT  a.fin_num,	
		a.fin_num,	
		a.invoice_num,	
		2031, 		
		" ",		
		@str_msg_ps,	
		" ",		
		2061,		
		@today,		
		@today,		
		@today,				
		@today,				
		0, 		
		0, 				
		b.date_due,	
		b.date_aging,	
		b.customer_code,	
		b.ship_to_code,		
		b.salesperson_code,	
		b.territory_code,	
		"",		
		"",				
		"",		
		"",				
		b.fin_chg_code,		
		b.price_code,			
		"",		
		b.posting_code,	
		0,		
		"",		
		"",				
		"",						
		0,		 
		"",		
		0,		
		"",		
		a.gl_num,	
		"",		
		"",				
		"",				
		"",				
		"",				
		a.amt_extra,				
		0.0,		
		0.0,		
		0.0,		
		0.0,		
		0.0,		
		a.amt_extra,					
		0.0,		
		0.0,		
		a.amt_extra,				
		0.0,		
		0.0,		
		b.user_id,	
		0,				
		0,		
		0,		
		1,		
		0,		
		"",		
		"",		
		0,		
		@process_ctrl_num,	
		0,		
		NULL,		
		NULL,		
		b.nat_cur_code, 
		b.rate_type_home,	
		b.rate_type_oper,	 
		b.rate_home,		
		b.rate_oper,		
		NULL,				
		NULL,				
		1				
	FROM #ardncsdt a, artrx b, #ardncshd c
	WHERE a.invoice_num = b.doc_ctrl_num
 	AND c.dunn_ctrl_num = a.dunn_ctrl_num
	AND c.print_fin_only = 0
	AND   b.trx_type = 2031

IF @@error != 0 
	RETURN  @@error


	
	INSERT #artrxage_work
	(	
		trx_ctrl_num,
		trx_type,
		ref_id,
		doc_ctrl_num,
		order_ctrl_num,
		cust_po_num,
		apply_to_num,
		apply_trx_type,
		sub_apply_num,
		sub_apply_type,
		date_doc,
		date_due,
		date_applied,
		date_aging,
		customer_code,
		payer_cust_code,
		salesperson_code,
		territory_code,
		price_code,
		amount,
		paid_flag,
		group_id,
		amt_fin_chg,
		amt_late_chg,
		amt_paid,
		db_action,
		rate_home,
		rate_oper,
		nat_cur_code,
		true_amount,
		date_paid,
		journal_ctrl_num,
		account_code,
		org_id
	)
	SELECT
		a.fin_num,		
		2061,			
		1,			
		a.fin_num,		
		'',			
		'',			
		a.invoice_num,		
		2031,			
		a.invoice_num,		
		2031,			
		@today,			
		b.date_due,		
		@today,			
		b.date_aging,		
		b.customer_code,		
		b.payer_cust_code,	
		b.salesperson_code,	
		b.territory_code,		
		b.price_code,		
		a.amt_extra,					
		0,			
		0,			
		0.0,			
		0.0,			
		0.0,			
		1,			
		b.rate_home,		
		b.rate_oper,		
		b.nat_cur_code,		
		a.amt_extra,				
		0,			
		a.gl_num,		
		b.account_code,		
		b.org_id		 
	FROM #ardncsdt a, artrxage b, #ardncshd c
	WHERE a.invoice_num = b.doc_ctrl_num
 	AND c.dunn_ctrl_num = a.dunn_ctrl_num
	AND c.print_fin_only = 0
	AND   b.trx_type = 2031

IF @@error != 0 
	RETURN @@error


	INSERT #gltrx
	(		
		mark_flag,
		next_seq_id,
		trx_state,
		journal_type,
		journal_ctrl_num,
		journal_description,
		date_entered,
		date_applied,
		recurring_flag,
		repeating_flag,
		reversing_flag,
		hold_flag,
		posted_flag,
		date_posted,
		source_batch_code,
		process_group_num,
		batch_code,
		type_flag,
		intercompany_flag,
		company_code,
		app_id,
		home_cur_code,
		document_1,
		trx_type,
		user_id,
		source_company_code,
        	oper_cur_code
	)
	SELECT  0,			
		1,			
		2, 			
		"AR",			
		a.gl_trx_id,		
		@str_msg_ps,		
		@today,			
		@today,			
		0,			
		0,			
		0,			
		0,			
		0,			
		0,			
		@batch_num,		
		@process_ctrl_num,	
		"",			
		0,			
		0,			
		@company_code,		
		2000,			
		@home_curr,		
		" ",			
		2061,			
		a.user_id,		
		@company_code,		
		@oper_curr		
	FROM #artrx_work a

	INSERT #gltrxdet
	(
		mark_flag,
		trx_state,
        	journal_ctrl_num,

		rec_company_code,
		company_id,
        	account_code,
		description,
        	document_1,
        	document_2,
		reference_code,
        	balance,
		nat_balance,
		nat_cur_code,
		rate,
        	posted_flag,
        	date_posted,
		trx_type,
		offset_flag,
		seg1_code,
		seg2_code,
		seg3_code,
		seg4_code,
		seq_ref_id,
        	balance_oper,
        	rate_oper,
        	rate_type_home,
		rate_type_oper
	)
	SELECT 0,	
		2, 	
		b.gl_trx_id,						

		@company_code,	
		@company_id,	
		dbo.IBAcctMask_fn(c.ar_acct_code,b.org_id),	
		@str_msg_ps,	
		a.customer_code, 
		a.fin_num,		
		"",		
		nat_balance	= case 
					when b.rate_home > 0 then b.amt_tot_chg * b.rate_home
					else b.amt_tot_chg /(1/ABS(b.rate_home))
				end,
		b.amt_tot_chg,	
		b.nat_cur_code,		
		b.rate_home,		
		0,		
		0,		
		2061,		
		0,		
		d.seg1_code,			
		d.seg2_code,	
		d.seg3_code,	
		d.seg4_code,	
		0,		
		balance_oper =  case 
					when b.rate_oper > 0 then b.amt_tot_chg * b.rate_oper
					else b.amt_tot_chg /(1/ABS(b.rate_oper))
				end,
		b.rate_oper,	
		b.rate_type_home,	
		b.rate_type_oper	
	FROM  #ardncsdt a, #artrx_work b, araccts c, glchart d, #ardncshd e
	WHERE a.fin_num = b.trx_ctrl_num
	AND   b.posting_code = c.posting_code
	AND   c.ar_acct_code = d.account_code
 	AND e.dunn_ctrl_num = a.dunn_ctrl_num
	AND e.print_fin_only = 0


	INSERT #gltrxdet
	(
		mark_flag,
		trx_state,
        	journal_ctrl_num,

		rec_company_code,
		company_id,
        	account_code,
		description,
        	document_1,
        	document_2,
		reference_code,
        	balance,
		nat_balance,
		nat_cur_code,
		rate,
        	posted_flag,
        	date_posted,
		trx_type,
		offset_flag,
		seg1_code,
		seg2_code,
		seg3_code,
		seg4_code,
		seq_ref_id,
        	balance_oper,
        	rate_oper,
        	rate_type_home,
		rate_type_oper
	)
	SELECT 	0,	
		2, 	
		b.gl_trx_id,						
		
		@company_code,	
		@company_id,	
		dbo.IBAcctMask_fn(c.fin_chg_acct_code,b.org_id),	
		@str_msg_ps,	
		a.customer_code, 
		a.fin_num,		
		"",		
		nat_balance	= case 
					when b.rate_home > 0 then -1 * (b.amt_tot_chg * b.rate_home)
					else -1 * (b.amt_tot_chg /(1/ABS(b.rate_home)))
				end,
		-1 * b.amt_tot_chg,	
		b.nat_cur_code,		
		b.rate_home,		
		0,		
		0,		
		2061,		
		0,		
		d.seg1_code,			
		d.seg2_code,	
		d.seg3_code,	
		d.seg4_code,	
		0,		
		balance_oper =  case 
					when b.rate_oper > 0 then -1 * (b.amt_tot_chg * b.rate_oper)
					else -1 * (b.amt_tot_chg /(1/ABS(b.rate_oper)))
				end,
		b.rate_oper,	
		b.rate_type_home,	
		b.rate_type_oper	
	FROM  #ardncsdt a, #artrx_work b, araccts c, glchart d, #ardncshd e
	WHERE a.fin_num = b.trx_ctrl_num
	AND   b.posting_code = c.posting_code
	AND   c.fin_chg_acct_code = d.account_code
 	AND e.dunn_ctrl_num = a.dunn_ctrl_num
	AND e.print_fin_only = 0
		
	EXEC @result = artrx_sp @batch_num, 10, 10
	IF @result != 0
		RETURN @result

 
	EXEC @result = artrxage_sp @batch_num, 10, 10
	IF @result != 0
		RETURN @result

	
	EXEC @result = gltrxsav_sp   @process_ctrl_num, @company_code, 10
	IF @result != 0
		RETURN @result


DROP TABLE #artrx_work
DROP TABLE #artrxage_work
DROP TABLE #gltrx
DROP TABLE #gltrxdet

RETURN 
GO
GRANT EXECUTE ON  [dbo].[ARPostDunningLetters_sp] TO [public]
GO
