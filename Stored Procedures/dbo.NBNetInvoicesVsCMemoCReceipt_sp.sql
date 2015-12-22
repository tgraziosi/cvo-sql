SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO




CREATE PROCEDURE [dbo].[NBNetInvoicesVsCMemoCReceipt_sp] 	@net_ctrl_num varchar(16), @process_ctrl_num varchar(16),	
							@debug_level smallint
AS

	CREATE TABLE #gain_loss	(
	settlement_ctrl_num	varchar(16) NULL,	trx_ctrl_num	    varchar(16)	NULL,	sequence_id         int         NULL,   
	artrx_doc_ctrl_num	varchar(16) NULL,	cross_rate          float       NULL,	adj_home            float       NULL,
	adj_oper            	float       NULL,	rate_home_cur       float       NULL,	rate_oper_cur       float       NULL,
	rate_home_org       	float       NULL,	rate_oper_org       float       NULL    )
	CREATE INDEX argain_loss_ind_0	ON #gain_loss (settlement_ctrl_num,trx_ctrl_num,sequence_id)

	
CREATE TABLE #arinppyt4750
(
       timestamp            timestamp,
       trx_ctrl_num         varchar(16),
  doc_ctrl_num         varchar(16),
  trx_desc             varchar(40),
  batch_code           varchar(16),
       trx_type             smallint,
  non_ar_flag   smallint,
  non_ar_doc_num       varchar(16),
  gl_acct_code         varchar(32), 
  date_entered         int,
  date_applied         int,
  date_doc             int,
       customer_code        varchar(8),
  payment_code         varchar(8),
  payment_type         smallint, 
             
             
             
       amt_payment          float,
  amt_on_acct          float,
  prompt1_inp          varchar(30),
  prompt2_inp          varchar(30),
  prompt3_inp          varchar(30),
  prompt4_inp          varchar(30),
  deposit_num          varchar(16),
  bal_fwd_flag         smallint, 
             
  printed_flag         smallint,
  posted_flag          smallint,
  hold_flag            smallint,
  wr_off_flag          smallint, 
             
             
  on_acct_flag         smallint, 
             
             
  user_id              smallint, 
  max_wr_off           float,   
  days_past_due        int,   
  void_type            smallint,  
             
             
             
  cash_acct_code       varchar(32),
       origin_module_flag   smallint NULL, 


  process_group_num    varchar(16) NULL,
  source_trx_ctrl_num varchar(16) NULL,
  source_trx_type      smallint NULL,
  nat_cur_code         varchar(8),  
  rate_type_home       varchar(8),
  rate_type_oper       varchar(8),
  rate_home            float,
  rate_oper            float,        
  amt_discount    float NULL,   
  reference_code  varchar(32) NULL  ,
  settlement_ctrl_num varchar(16) NULL, 
  doc_amount	  float NULL,
  org_id          varchar(30)
)


	CREATE INDEX arinppyt_ind_0   		ON #arinppyt4750 (customer_code,trx_ctrl_num,trx_type)
	CREATE UNIQUE INDEX arinppyt_ind_1   	ON #arinppyt4750 (trx_ctrl_num,trx_type)

	
CREATE TABLE #arinppdt4750
(
	timestamp            timestamp,
	trx_ctrl_num         varchar(16),
	doc_ctrl_num         varchar(16),
	sequence_id          int,
	trx_type             smallint,
	apply_to_num         varchar(16),
	apply_trx_type       smallint,
	customer_code        varchar(8),
	date_aging           int,
	amt_applied          float,
	amt_disc_taken       float,
	wr_off_flag          smallint,
	amt_max_wr_off       float,
	void_flag            smallint,
	line_desc            varchar(40),
	sub_apply_num        varchar(16),
	sub_apply_type       smallint,
	amt_tot_chg          float,	      
	amt_paid_to_date     float,       
	terms_code           varchar(8),  
	posting_code         varchar(8),  
	date_doc             int,	      
	amt_inv              float,       
	gain_home            float,       
	gain_oper            float,
	inv_amt_applied      float,
	inv_amt_disc_taken   float,
	inv_amt_max_wr_off   float,        
	inv_cur_code		varchar(8),	
	writeoff_code	     varchar(8)	NULL DEFAULT "",	
	writeoff_amount	     float,		
	cross_rate	     float,		
	org_id		     varchar(30)
)


	CREATE UNIQUE CLUSTERED INDEX arinppdt_ind_0   ON #arinppdt4750 (trx_ctrl_num,trx_type,sequence_id)
	CREATE INDEX arinppdt_ind_1	ON #arinppdt4750 (apply_to_num,trx_type)


	CREATE TABLE #arinpstlhdr	(
	settlement_ctrl_num 	varchar(16) NOT NULL,	description	 varchar(40),		hold_flag 		smallint,
	posted_flag 		smallint,		date_entered	 int NOT NULL,		date_applied		int NOT NULL, 
	user_id 		smallint,		process_group_num varchar(16) NULL,	doc_count_expected	int,
	doc_count_entered 	int,			doc_sum_expected  float,		doc_sum_entered 	float,
	cr_total_home 		float,			cr_total_oper 	 float,			oa_cr_total_home 	float,
	oa_cr_total_oper 	float,			cm_total_home 	 float,			cm_total_oper 		float,
	inv_total_home		float,			inv_total_oper	 float,			disc_total_home 	float,
	disc_total_oper 	float,			wroff_total_home float,			wroff_total_oper	float,
	onacct_total_home 	float,			onacct_total_oper float,		gain_total_home 	float,
	gain_total_oper 	float,			loss_total_home  float,			loss_total_oper 	float,
	amt_on_acct	 	float,			inv_amt_nat	float,			amt_doc_nat		float,
	amt_dist_nat		float,			customer_code	varchar(8),		nat_cur_code		varchar(8),
	rate_type_home		varchar(8),		rate_home	float,			rate_type_oper		varchar(8),
	rate_oper		float, 			Settle_flag 	int,			org_id			varchar(30)NULL	)
	CREATE UNIQUE INDEX arsinpstlhdr_ind_0 ON #arinpstlhdr ( settlement_ctrl_num )


	DECLARE	@customer_code		varchar(8),
		@terms_code		varchar(8),
		@posting_code		varchar(8),
		@nat_cur_code		varchar(8),
		@rate_type_home		varchar(8),
		@rate_type_oper		varchar(8),
		@payment_code		varchar(8),
		@vendor_code 		varchar(12),
		@settlement_ctrl_num	varchar(16),
		@payment_ctrl_num	varchar(16),
		@trx_ctrl_num		varchar(16),
		@doc_ctrl_num		varchar(16),   
		@cre_trx_ctrl_num	varchar(16),
		@cre_doc_ctrl_num	varchar(16),	 
		@deb_trx_ctrl_num	varchar(16),
		@deb_doc_ctrl_num	varchar(16),	  
		@net_doc_num		varchar(16),
		@cash_acct_code		varchar(32),
		@payment_type	int,		
		@inv_amt_committed 	float, 
		@cr_amt_committed	float,
		@cm_amt_committed	float,
		@amt_to_be_applied	float,
		@trx_amt_committed	float,
		@amt_applied		float,
		@amt_committed		float,
		@rate_home		float,
		@rate_oper		float,
		@date_entered		int,
		@sequence_id		int,
		@num			int,
		@result			int,
		@rows			int,
		@ar_rate_type_home	varchar(8),
		@ar_rate_type_oper	varchar(8),
		@ap_rate_type_home	varchar(8),
		@ap_rate_type_oper	varchar(8),
		@ap_rate_home		float,
		@ap_rate_oper		float,
		@ar_rate_home		float,
		@ar_rate_oper		float,
		@printed_flag		int,
		@root_org_id		varchar(30),
		@trx_type		smallint

	


	SELECT @root_org_id = ISNULL((select organization_id from Organization where outline_num = '1'),'')    
		
		
	exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.1',0,''

	SELECT	@customer_code 	= customer_code,
		@vendor_code 	= vendor_code,
		@nat_cur_code	= currency_code
	FROM 	#nbnethdr_work
	WHERE	net_ctrl_num 	= @net_ctrl_num

									
	SELECT 	@inv_amt_committed = ISNULL(SUM(amt_committed),0.0)
	FROM	#nbnetdeb_work
	WHERE	((amt_committed) > (0.0) + 0.0000001)
	AND 	trx_type	IN (2021, 2031)
	AND	net_ctrl_num 	= @net_ctrl_num

	SELECT 	@cr_amt_committed = ISNULL(SUM(amt_committed),0.0)
	FROM	#nbnetcre_work
	WHERE	((amt_committed) > (0.0) + 0.0000001)
	AND 	trx_type 	= 2111
	AND	net_ctrl_num 	= @net_ctrl_num

	SELECT 	@cm_amt_committed = ISNULL(SUM(amt_committed),0.0)
	FROM	#nbnetcre_work
	WHERE	((amt_committed) > (0.0) + 0.0000001)
	AND 	trx_type 	= 2032
	AND	net_ctrl_num 	= @net_ctrl_num


	


	IF ((@cr_amt_committed + @cm_amt_committed) = 0 or @inv_amt_committed = 0)  
	Begin
		exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.1',2,''
		RETURN 0
		
	End

	


	SELECT	@terms_code	= ISNULL(terms_code,''),
		@posting_code	= ISNULL(posting_code,''),
		@payment_code	= ISNULL(b.payment_code,''),
		@cash_acct_code	= ISNULL(asset_acct_code,'')	
	FROM 	arcust a,  arpymeth b
	WHERE	customer_code	= @customer_code
	AND	a.payment_code	= b.payment_code
		
	


	EXEC ARGetNextControl_SP 2015, @settlement_ctrl_num OUTPUT, @num OUTPUT

	IF @settlement_ctrl_num IS NULL
	Begin
		exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.1',3,''
		RETURN 1
	End

	


	EXEC         appdate_sp @date_entered OUTPUT


	


	
	INSERT #arinpstlhdr
	(settlement_ctrl_num,	description,		hold_flag,		posted_flag,		date_entered,		
	date_applied,		user_id,		process_group_num,	doc_count_expected, 	doc_count_entered,	
	doc_sum_expected,	doc_sum_entered,	cr_total_home,		cr_total_oper,		oa_cr_total_home,	
	oa_cr_total_oper,	cm_total_home,		cm_total_oper,		inv_total_home,		inv_total_oper,		
	disc_total_home,	disc_total_oper,	wroff_total_home,	wroff_total_oper,	onacct_total_home,	
	onacct_total_oper,	gain_total_home,	gain_total_oper,	loss_total_home,	loss_total_oper,
	amt_on_acct,		inv_amt_nat,		amt_doc_nat,		amt_dist_nat,		customer_code,
	nat_cur_code,		rate_type_home,		rate_home,		rate_type_oper,		rate_oper,
	Settle_flag,		org_id)
	values (
	@settlement_ctrl_num,	'Netting Settlement ' + @net_ctrl_num,	
							0,			-1,			@date_entered,
	@date_entered,		USER_ID(),		@process_ctrl_num,	0,			0,			
	0,			0,			0,			0,			0,
	0,		0,			0,			0,			0,
	0,			0,			0,			0,			0,
	0,			0,			0,			0,			0,
	0,			0,			0,			0,			@customer_code,
	@nat_cur_code,		'',			0,			'',			0,
	0,			@root_org_id)

	IF @@error != 0
	Begin
		exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.1',4,''
		RETURN 	1
	end

	



	IF ( (@cr_amt_committed + @cm_amt_committed) <= @inv_amt_committed )
	BEGIN

		


		SELECT	@amt_to_be_applied = @cr_amt_committed + @cm_amt_committed

		SELECT @trx_ctrl_num = ''
		SELECT @doc_ctrl_num = ''
		SELECT @sequence_id = 0   
		WHILE @amt_to_be_applied > 0
		BEGIN

			SELECT 	@trx_ctrl_num	= MIN(trx_ctrl_num)
			FROM	#nbnetdeb_work
			WHERE	net_ctrl_num 	= @net_ctrl_num
			AND	trx_ctrl_num	> @trx_ctrl_num
			AND	trx_type 	IN (2021, 2031)

			SELECT 	@trx_amt_committed = amt_committed, @doc_ctrl_num = doc_ctrl_num,  
				@trx_type = trx_type
			FROM	#nbnetdeb_work
			WHERE	trx_ctrl_num 	= @trx_ctrl_num
			AND	net_ctrl_num	= @net_ctrl_num

			IF @trx_amt_committed IS NULL
				SELECT @trx_amt_committed = 0
			
			SELECT @sequence_id = @sequence_id + 1  

			IF @amt_to_be_applied >= @trx_amt_committed
				SELECT @amt_applied = @trx_amt_committed
			ELSE	
				SELECT @amt_applied = @amt_to_be_applied
				
			
			
			INSERT #arinppdt4750	(
			trx_ctrl_num,		doc_ctrl_num,		sequence_id,	trx_type,	apply_to_num,		
			apply_trx_type,		customer_code,		date_aging,	amt_applied,	amt_disc_taken,	
			wr_off_flag,		amt_max_wr_off,		void_flag,	line_desc,	sub_apply_num,	
			sub_apply_type,		amt_tot_chg,		amt_paid_to_date,terms_code,	posting_code,	
			date_doc,		amt_inv,		gain_home,	gain_oper,	inv_amt_applied,
			inv_amt_disc_taken,	inv_amt_max_wr_off,	inv_cur_code,	writeoff_code,	writeoff_amount,	
			cross_rate,		org_id 	)
			VALUES 	( 
			@settlement_ctrl_num,		@payment_ctrl_num,	@sequence_id,	2111,		@doc_ctrl_num,   
			@trx_type,		@customer_code,		@date_entered,	@amt_applied,	0,
			0,			0.0,			0,		@net_ctrl_num,	'',
			0,			@amt_applied,		@amt_applied,	@terms_code,	@posting_code,
			@date_entered,		@amt_applied,		0,		0,		@amt_applied,
			0.0,			0.0,			@nat_cur_code,	'',		0.0,
			1,			@root_org_id
			)
								
			
			
			UPDATE	#nbnetdeb_work
			SET	amt_committed 	= amt_committed - @amt_applied
			WHERE	trx_ctrl_num 	= @trx_ctrl_num
			AND	net_ctrl_num	= @net_ctrl_num
			

			SELECT @sequence_id = @sequence_id + 1

			SELECT @amt_to_be_applied =  @amt_to_be_applied - @amt_applied

			IF ((@amt_to_be_applied) < (0.0) - 0.0000001)
				SELECT @amt_to_be_applied = 0.0



		END	

		SELECT @cre_doc_ctrl_num = ''
		SELECT @cre_trx_ctrl_num= ''

		SELECT 	@cre_trx_ctrl_num = MIN(trx_ctrl_num)
		FROM	#nbnetcre_work
		WHERE	net_ctrl_num 	= @net_ctrl_num
		AND	trx_type 	IN (2111,2032)

		WHILE 	@cre_trx_ctrl_num IS NOT NULL
		BEGIN

			

	

			EXEC ARGetNextControl_SP 2011, @payment_ctrl_num OUTPUT, @num OUTPUT
	
			SELECT	@amt_committed 	= amt_committed, @cre_doc_ctrl_num = doc_ctrl_num   
			FROM	#nbnetcre_work
			WHERE	trx_ctrl_num	= @cre_trx_ctrl_num

			


	
			EXEC ARGetNextControl_SP 2130, @net_doc_num OUTPUT, @num OUTPUT

			


			SELECT 	@rate_type_home	= rate_type_home,
				@rate_type_oper	= rate_type_oper,
				@rate_home	= rate_home,
				@rate_oper	= rate_oper,
				@payment_code	= ISNULL(payment_code,''), 
				@cash_acct_code	= ISNULL(cash_acct_code,'')	
			FROM	artrx
			WHERE	trx_ctrl_num	= @cre_trx_ctrl_num
			AND	trx_type	IN (2111,2032)

			IF ((select trx_type from #nbnetcre_work where trx_ctrl_num	= @cre_trx_ctrl_num) = 2032)				
				select @payment_type = 4, @printed_flag = 0
			ELSE		
				select @payment_type = 2, @printed_flag = 1

			INSERT #arinppyt4750	(
			trx_ctrl_num,		doc_ctrl_num,		trx_desc,		batch_code,	trx_type,	
			non_ar_flag,		non_ar_doc_num,		gl_acct_code,		date_entered,	date_applied,	
			date_doc,		customer_code,		payment_code,		payment_type,	amt_payment,		
			amt_on_acct,		prompt1_inp,		prompt2_inp,		prompt3_inp,	prompt4_inp,	
			deposit_num,		bal_fwd_flag,		printed_flag,		posted_flag,	hold_flag,	
			wr_off_flag,		on_acct_flag,		user_id,		max_wr_off,	days_past_due,	
			void_type,		cash_acct_code,		origin_module_flag,	process_group_num, source_trx_ctrl_num,
			source_trx_type,	nat_cur_code,		rate_type_home,		rate_type_oper,	rate_home,
			rate_oper,		amt_discount,		reference_code,		settlement_ctrl_num,
			doc_amount,		org_id			)
			VALUES (
			@payment_ctrl_num,	@cre_doc_ctrl_num,		'Netting Transacction',	'',		2111,    
			0, 	'',			'',			@date_entered,	@date_entered,
			@date_entered,		@customer_code,		@payment_code,		@payment_type,		@amt_committed,
			0,			'',			'',			'',		'',
			'',			0,			1,			-1,		0,
			0,			0,			USER_ID(),		0.0,		0,
			0,			@cash_acct_code,	NULL,			@process_ctrl_num,NULL,
			NULL,			@nat_cur_code,		@rate_type_home,	@rate_type_oper,@rate_home,
			@rate_oper,		0.0,			'',			@settlement_ctrl_num,		
			@amt_committed,		@root_org_id			)
			

			INSERT	#nbtrxrel (	net_ctrl_num, trx_ctrl_num,		trx_type	)
			VALUES (		@net_ctrl_num,@payment_ctrl_num,	2111		)

			exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.1',1,@payment_ctrl_num

			UPDATE	#nbnetcre_work
			SET	amt_committed = 0.0
			WHERE	net_ctrl_num 	= @net_ctrl_num
			AND	trx_ctrl_num	= @cre_trx_ctrl_num

	
			SELECT 	@cre_trx_ctrl_num = MIN(trx_ctrl_num)	
			FROM	#nbnetcre_work
			WHERE	net_ctrl_num 	= @net_ctrl_num
			AND	trx_ctrl_num	> @cre_trx_ctrl_num
			AND	trx_type 	IN (2111,2032)
		

		END 	

	
	END
	ELSE
	BEGIN		
	

		


		SELECT	@amt_to_be_applied = @inv_amt_committed

		SELECT @doc_ctrl_num = ''		
		SELECT @trx_ctrl_num = ''

		



		WHILE @amt_to_be_applied > 0
		BEGIN 	


			SELECT 	@trx_ctrl_num	= MIN(trx_ctrl_num)
			FROM	#nbnetcre_work
			WHERE	net_ctrl_num 	= @net_ctrl_num
			AND	trx_ctrl_num	> @trx_ctrl_num
			AND	trx_type 	IN (2111,2032)

			SELECT 	@trx_amt_committed = amt_committed, @doc_ctrl_num = doc_ctrl_num		
			FROM	#nbnetcre_work
			WHERE	trx_ctrl_num 	= @trx_ctrl_num
			AND	trx_type 	IN (2111,2032)

			


			SELECT 	@rate_type_home	= rate_type_home,
				@rate_type_oper	= rate_type_oper,
				@rate_home	= rate_home,
				@rate_oper	= rate_oper,
				@payment_code	= ISNULL(payment_code,''),	
				@cash_acct_code	= ISNULL(cash_acct_code,'')	
			FROM	artrx
			WHERE	trx_ctrl_num	= @trx_ctrl_num
			AND	trx_type	IN (2111,2032)


			IF @trx_amt_committed IS NULL
				SELECT @trx_amt_committed = 0
			
			IF @amt_to_be_applied >= @trx_amt_committed
				SELECT @amt_applied = @trx_amt_committed
			ELSE	
				SELECT @amt_applied = @amt_to_be_applied

			IF ((select trx_type from #nbnetcre_work where trx_ctrl_num	= @trx_ctrl_num) = 2032)				
				select @payment_type = 4 , @printed_flag = 0
			ELSE		
				select @payment_type = 2, @printed_flag = 1
			


			EXEC ARGetNextControl_SP 2011, @payment_ctrl_num OUTPUT, @num OUTPUT
			
			


	
			EXEC ARGetNextControl_SP 2130, @net_doc_num OUTPUT, @num OUTPUT
	


			INSERT #arinppyt4750	(
			trx_ctrl_num,		doc_ctrl_num,		trx_desc,		batch_code,	trx_type,	
			non_ar_flag,		non_ar_doc_num,		gl_acct_code,		date_entered,	date_applied,	
			date_doc,		customer_code,		payment_code,		payment_type,	amt_payment,		
			amt_on_acct,		prompt1_inp,		prompt2_inp,		prompt3_inp,	prompt4_inp,	
			deposit_num,		bal_fwd_flag,		printed_flag,		posted_flag,	hold_flag,	
			wr_off_flag,		on_acct_flag,		user_id,		max_wr_off,	days_past_due,	
			void_type,		cash_acct_code,		origin_module_flag,	process_group_num, source_trx_ctrl_num,
			source_trx_type,	nat_cur_code,		rate_type_home,		rate_type_oper,	rate_home,
			rate_oper,		amt_discount,		reference_code,		settlement_ctrl_num,
			doc_amount,		org_id			)
			VALUES (
			@payment_ctrl_num,	@doc_ctrl_num,		'Netting Transacction',	'',		2111,		
			0, 	'',			'',			@date_entered,	@date_entered,
			@date_entered,		@customer_code,		@payment_code,		@payment_type,		@amt_applied,
			0,			'',			'',			'',		'',
			'',			0,			1,			-1,		0,
			0,			0,			USER_ID(),		0.0,		0,
			0,			@cash_acct_code,	NULL,			@process_ctrl_num,NULL,
			NULL,			@nat_cur_code,		@rate_type_home,	@rate_type_oper,@rate_home,
			@rate_oper,		0.0,			'',			@settlement_ctrl_num,
			@amt_applied,		@root_org_id			)


			INSERT	#nbtrxrel 	(	net_ctrl_num, trx_ctrl_num,		trx_type	)
			VALUES 			(	@net_ctrl_num,@payment_ctrl_num,	2111		)

			
			exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.1',1,@payment_ctrl_num


			UPDATE	#nbnetcre_work
			SET	amt_committed 	= amt_committed - @amt_applied
			WHERE	trx_ctrl_num 	= @trx_ctrl_num
			AND	net_ctrl_num	= @net_ctrl_num


			


			SELECT @amt_to_be_applied =  @amt_to_be_applied - @amt_applied

			IF ((@amt_to_be_applied) < (0.0) - 0.0000001)
				SELECT @amt_to_be_applied = 0.0
		

		END	

		SELECT @deb_doc_ctrl_num = ''				
		SELECT @deb_trx_ctrl_num = ''

		SELECT 	@deb_trx_ctrl_num = MIN(trx_ctrl_num)
		FROM	#nbnetdeb_work
		WHERE	net_ctrl_num 	= @net_ctrl_num
		AND	trx_type 	IN (2021, 2031)


		SELECT @sequence_id = 0

		WHILE @deb_trx_ctrl_num IS NOT NULL
		BEGIN
	
			SELECT @sequence_id = @sequence_id + 1

			SELECT	@amt_committed = amt_committed, @deb_doc_ctrl_num = doc_ctrl_num, 
				@trx_type = trx_type
			FROM	#nbnetdeb_work
			WHERE	net_ctrl_num	= @net_ctrl_num
			AND	trx_ctrl_num	= @deb_trx_ctrl_num
			AND	trx_type	IN (2021, 2031)
			

			INSERT #arinppdt4750	(
			trx_ctrl_num,		doc_ctrl_num,		sequence_id,	trx_type,	apply_to_num,		
			apply_trx_type,		customer_code,		date_aging,	amt_applied,	amt_disc_taken,	
			wr_off_flag,		amt_max_wr_off,		void_flag,	line_desc,	sub_apply_num,	
			sub_apply_type,		amt_tot_chg,		amt_paid_to_date,terms_code,	posting_code,	
			date_doc,		amt_inv,		gain_home,	gain_oper,	inv_amt_applied,
			inv_amt_disc_taken,	inv_amt_max_wr_off,	inv_cur_code,	writeoff_code,	writeoff_amount,	
			cross_rate, 		org_id)
			VALUES 	( 
			@settlement_ctrl_num,	@deb_trx_ctrl_num,	@sequence_id,	2111,		@deb_doc_ctrl_num,		
			@trx_type,		@customer_code,		@date_entered,	@amt_committed,	0,
			0,			0.0,			0,		@net_ctrl_num,	'',
			0,			@amt_committed,		@amt_committed,	@terms_code,	@posting_code,
			@date_entered,		@amt_committed,		0,		0,		@amt_committed,
			0.0,			0.0,			@nat_cur_code,	'',		0.0,
			1,			@root_org_id
			)

			
			UPDATE	#nbnetcre_work
			SET	amt_committed = 0.0
			WHERE	net_ctrl_num 	= @net_ctrl_num
			AND	trx_ctrl_num	= @deb_trx_ctrl_num


			SELECT 	@deb_trx_ctrl_num	= MIN(trx_ctrl_num)
			FROM	#nbnetdeb_work
			WHERE	net_ctrl_num 	= @net_ctrl_num
			AND	trx_ctrl_num	> @deb_trx_ctrl_num
			AND	trx_type 	IN (2021, 2031)

		END 	
	
	END 	


		DECLARE arsett_cur CURSOR FOR SELECT settlement_ctrl_num FROM #arinpstlhdr 
	OPEN arsett_cur

	FETCH NEXT FROM arsett_cur INTO @settlement_ctrl_num

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT 	@amt_committed 	= SUM(amt_payment), @rows= COUNT(trx_ctrl_num)
		FROM	#arinppyt4750
		where settlement_ctrl_num	= @settlement_ctrl_num

		IF @amt_committed IS NULL
			SELECT  @amt_committed = 0

		set rowcount  1

		SELECT	@ar_rate_type_home	= rate_type_home,                
				@ar_rate_type_oper = rate_type_oper,
				@ar_rate_home	= rate_home,
				@ar_rate_oper	= rate_oper
		FROM	#arinppyt4750 
		WHERE	settlement_ctrl_num	= @settlement_ctrl_num		
	
		set rowcount  0
	
		UPDATE	#arinpstlhdr
		SET	doc_count_entered 	= @rows,	
			doc_sum_entered		= @amt_committed,
			inv_total_home		= @amt_committed,
			inv_total_oper		= @amt_committed,
			cr_total_home  		= @amt_committed                 ,
			cr_total_oper                 = @amt_committed,
			inv_amt_nat                   = @amt_committed,
			amt_doc_nat		= @amt_committed,
			rate_type_home	= @ar_rate_type_home ,
			rate_home    		= @ar_rate_home,
                                    rate_type_oper		= @ar_rate_type_oper,
			rate_oper		=@ar_rate_oper,
			Settle_flag 		= 1
		WHERE	process_group_num 	= @process_ctrl_num
		AND	settlement_ctrl_num	= @settlement_ctrl_num
		


		EXEC @result = arstlprt_sp 	@settlement_ctrl_num

		IF @result != 0
		Begin
			exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.1',5,''
			RETURN	@result
		End


		FETCH NEXT FROM arsett_cur INTO @settlement_ctrl_num
	END
  
	CLOSE arsett_cur
	DEALLOCATE arsett_cur


INSERT arinppyt(
	trx_ctrl_num, 	doc_ctrl_num, 	trx_desc,	batch_code, 	trx_type, 	non_ar_flag, 	non_ar_doc_num, 
	gl_acct_code, 	date_entered, 	date_applied, 	date_doc, 	customer_code, 	payment_code, 	payment_type,  
	amt_payment, 	amt_on_acct, 	prompt1_inp, 	prompt2_inp, 	prompt3_inp, 	prompt4_inp, 	deposit_num, 
	bal_fwd_flag,  	printed_flag, 	posted_flag, 	hold_flag, 	wr_off_flag,  	on_acct_flag,  	user_id,  
	max_wr_off,    	days_past_due,	void_type, 	cash_acct_code, origin_module_flag,process_group_num, source_trx_ctrl_num, 
	source_trx_type,nat_cur_code,	rate_type_home, rate_type_oper, rate_home, 	rate_oper, 	amt_discount, 
	reference_code,   settlement_ctrl_num, doc_amount, org_id  	)
SELECT 	trx_ctrl_num, 	doc_ctrl_num, 	trx_desc, 	batch_code, 	trx_type, 	non_ar_flag, 	non_ar_doc_num, 
	gl_acct_code, 	date_entered, 	date_applied, 	date_doc, 	customer_code, 	payment_code, 	payment_type,  
	amt_payment, 	amt_on_acct, 	prompt1_inp, 	prompt2_inp, 	prompt3_inp, 	prompt4_inp, 	deposit_num, 
	bal_fwd_flag,  	printed_flag, 	posted_flag, 	hold_flag, 	wr_off_flag,  	on_acct_flag,  	user_id,  
	max_wr_off,    	days_past_due,  void_type, 	cash_acct_code, origin_module_flag,process_group_num, source_trx_ctrl_num, 
	source_trx_type,nat_cur_code,   rate_type_home, rate_type_oper, rate_home, 	rate_oper, 	amt_discount, 
	reference_code,	settlement_ctrl_num  , amt_payment, org_id
FROM	#arinppyt4750

IF @@error != 0
Begin
	exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.1',6,''
	RETURN	-1
End

INSERT arinppdt	(	
	trx_ctrl_num,	doc_ctrl_num,	sequence_id,	trx_type,	apply_to_num,	apply_trx_type,	customer_code,	
	date_aging,	amt_applied,	amt_disc_taken,	wr_off_flag,	amt_max_wr_off,	void_flag,	line_desc,	
	sub_apply_num,	sub_apply_type,	amt_tot_chg,	amt_paid_to_date,terms_code,	posting_code,	date_doc,	
	amt_inv,	gain_home,	gain_oper,	inv_amt_applied, inv_amt_disc_taken,inv_amt_max_wr_off,	inv_cur_code,	
	writeoff_code,	writeoff_amount, cross_rate,	org_id		)
SELECT 	trx_ctrl_num,	doc_ctrl_num,	sequence_id,	trx_type,	apply_to_num,	apply_trx_type,	customer_code,	
	date_aging,	amt_applied,	amt_disc_taken,	wr_off_flag,	amt_max_wr_off,	void_flag,	line_desc,	
	sub_apply_num,	sub_apply_type,	amt_tot_chg,	amt_paid_to_date,terms_code,	posting_code,	date_doc,	
	amt_inv,	gain_home,	gain_oper,	inv_amt_applied,inv_amt_disc_taken,inv_amt_max_wr_off,	inv_cur_code,	
	writeoff_code,	writeoff_amount, cross_rate,	org_id		
FROM	#arinppdt4750

IF @@error != 0
Begin
	exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.1',7,''
	RETURN	-1
End

INSERT arinpstlhdr( 
	settlement_ctrl_num, 	description,  	hold_flag,		posted_flag,		date_entered,	
	date_applied, 		user_id,	process_group_num, 	doc_count_expected,	doc_count_entered,   
	doc_sum_expected,   	doc_sum_entered,cr_total_home,   	cr_total_oper,   	oa_cr_total_home,
	oa_cr_total_oper,   	cm_total_home,	cm_total_oper,		inv_total_home,   	inv_total_oper,   
	disc_total_home,	disc_total_oper,wroff_total_home,   	wroff_total_oper,	onacct_total_home,   
	onacct_total_oper,   	gain_total_home,gain_total_oper,   	loss_total_home,   	loss_total_oper,
	amt_on_acct,		inv_amt_nat,	amt_doc_nat,		amt_dist_nat,		customer_code,
	nat_cur_code,		rate_type_home,	rate_home,		rate_type_oper,		rate_oper, 
	settle_flag,		org_id		)
SELECT 	settlement_ctrl_num, 	description,  	hold_flag,		posted_flag,		date_entered,	
	date_applied, 		user_id,	process_group_num, 	doc_count_expected,	doc_count_entered,   
	doc_sum_expected,   	doc_sum_entered,cr_total_home,   	cr_total_oper,   	oa_cr_total_home,
	oa_cr_total_oper,   	cm_total_home,	cm_total_oper,		inv_total_home,   	inv_total_oper,   
	disc_total_home,	disc_total_oper,wroff_total_home,   	wroff_total_oper,	onacct_total_home,   
	onacct_total_oper,   	gain_total_home,gain_total_oper,   	loss_total_home,   	loss_total_oper,
	amt_on_acct,		inv_amt_nat,	amt_doc_nat,		amt_dist_nat,		customer_code,
	nat_cur_code,		rate_type_home,	rate_home,		rate_type_oper,		rate_oper,
	Settle_flag,		org_id	   
FROM	#arinpstlhdr


IF @@error != 0
Begin
	exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.1',8,''
	RETURN	-1
End

DROP TABLE #arinppyt4750
DROP TABLE #arinppdt4750
DROP TABLE #arinpstlhdr
DROP TABLE #gain_loss

exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.1',-1,''
RETURN   0  


GO
GRANT EXECUTE ON  [dbo].[NBNetInvoicesVsCMemoCReceipt_sp] TO [public]
GO
