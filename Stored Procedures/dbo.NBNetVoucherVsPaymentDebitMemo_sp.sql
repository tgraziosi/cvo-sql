SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROCEDURE [dbo].[NBNetVoucherVsPaymentDebitMemo_sp] 	@net_ctrl_num 		varchar(16), 
							@process_ctrl_num 	varchar(16),	
							@debug_level 		smallint
AS


	CREATE TABLE #gain_loss	(
	settlement_ctrl_num	varchar(16) NULL,	trx_ctrl_num	    varchar(16)	NULL,	sequence_id         int         NULL,   
	artrx_doc_ctrl_num	varchar(16) NULL,	cross_rate          float       NULL,	adj_home            float       NULL,
	adj_oper            	float       NULL,	rate_home_cur       float       NULL,	rate_oper_cur       float       NULL,
	rate_home_org       	float       NULL,	rate_oper_org       float       NULL    )
	CREATE INDEX argain_loss_ind_0	ON #gain_loss (settlement_ctrl_num,trx_ctrl_num,sequence_id)

	

CREATE TABLE #apinppyt3450
(
	timestamp timestamp,
	trx_ctrl_num varchar(16),
	trx_type smallint,	
						
	doc_ctrl_num varchar(16), 
	trx_desc varchar(40),
	batch_code varchar(16),
	cash_acct_code varchar(32),
	date_entered int,
	date_applied int,
	date_doc int,
	vendor_code varchar(12),
	pay_to_code varchar(8),
	approval_code varchar(8),
	payment_code varchar(8),
	payment_type smallint, 
					 
					 
	amt_payment float, 
	amt_on_acct float,
	posted_flag smallint,
	printed_flag smallint, 
					 
					 
	hold_flag smallint,
	approval_flag smallint,
	gen_id int, 
	user_id smallint, 
	void_type smallint, 
					 
					 
	amt_disc_taken float,
	print_batch_num int, 
	company_code varchar(8), 
	process_group_num varchar(16) NULL,
	nat_cur_code			varchar(8) NULL,
	rate_type_home			varchar(8) NULL,
	rate_type_oper			varchar(8) NULL,
	rate_home				float NULL,
	rate_oper				float NULL,
	payee_name				varchar(40) NULL,
	settlement_ctrl_num	varchar(16) NULL,
	doc_amount				float	,
	org_id				varchar(30) NULL
)


	
CREATE TABLE #apinppdt3450
(
	timestamp			timestamp,
	trx_ctrl_num		varchar(16),
	trx_type			smallint,
	sequence_id			int,		
	apply_to_num		varchar(16),	
	apply_trx_type		smallint,	
	amt_applied			float,		
	amt_disc_taken		float,		
	line_desc			varchar(40),
	void_flag			smallint,
	payment_hold_flag	smallint,
	vendor_code			varchar(12),
	vo_amt_applied		float NULL,
	vo_amt_disc_taken	float NULL,
	gain_home			float NULL,
	gain_oper			float NULL,
	nat_cur_code		varchar(8) NULL,
	cross_rate			float NULL,
	org_id				varchar(30) NULL
)


	CREATE TABLE #apinpstl	(
	settlement_ctrl_num 	varchar (16) NOT NULL,		vendor_code 		varchar (12) NOT NULL ,
	pay_to_code 		varchar (8) NOT NULL ,		hold_flag 		smallint NOT NULL ,	
	date_entered 		int NOT NULL,			date_applied 		int NOT NULL ,
	user_id 		smallint NOT NULL,		batch_code 		varchar (16) NOT NULL ,
	process_group_num 	varchar (16) NOT NULL ,		state_flag 		smallint NOT NULL ,		
	disc_total_home 	float NOT NULL ,		disc_total_oper 	float NOT NULL ,
	debit_memo_total_home 	float NOT NULL ,		debit_memo_total_oper 	float NOT NULL ,
	on_acct_pay_total_home 	float NOT NULL ,		on_acct_pay_total_oper 	float NOT NULL ,
	payments_total_home 	float NOT NULL ,		payments_total_oper 	float NOT NULL ,
	put_on_acct_total_home 	float NOT NULL ,		put_on_acct_total_oper 	float NOT NULL ,
	gain_total_home 	float NOT NULL ,		gain_total_oper 	float NOT NULL ,
	loss_total_home 	float NOT NULL ,		loss_total_oper 	float NOT NULL,
	description		varchar(40),			nat_cur_code 		varchar(12),
	doc_count_expected      int,				doc_count_entered       int,
	doc_sum_expected        float,				doc_sum_entered         float,
	vo_total_home    	float,				vo_total_oper    	float,
	rate_type_home    	varchar(8),			rate_home         	float,
	rate_type_oper    	varchar(8),			rate_oper         	float,
	vo_amt_nat	    	float,				amt_doc_nat	    	float,
	amt_dist_nat	    	float,				amt_on_acct	    	float,
	org_id			varchar(30) NULL	
	)

	CREATE CLUSTERED INDEX apinpstl_01 ON #apinpstl (vendor_code,settlement_ctrl_num)
	
	DECLARE	@customer_code		varchar(8),
		@posting_code		varchar(8),
		@nat_cur_code		varchar(8),
		@rate_type_home		varchar(8),
		@rate_type_oper		varchar(8),
		@payment_code		varchar(8),
		@company_code		varchar(8),
		@vendor_code 		varchar(12),		
		@settlement_ctrl_num	varchar(16),
		@payment_ctrl_num	varchar(16),
		@trx_ctrl_num		varchar(16),
		@doc_ctrl_num           varchar(16),
		@cre_trx_ctrl_num	varchar(16),
		@cre_doc_ctrl_num	varchar(16),
		@deb_trx_ctrl_num	varchar(16),
		@deb_doc_ctrl_num	varchar(16),
		@net_doc_num		varchar(16),
		@cash_acct_code		varchar(32),
		@payment_type	int,		
		@vou_amt_committed 	float, 
		@dm_amt_committed	float,
		@pay_amt_committed	float,
		@amt_to_be_applied	float,
		@trx_amt_committed	float,
		@amt_applied		float,
		@amt_committed		float,
		@rate_home		float,
		@rate_oper		float,
		@date_entered		int,
		@sequence_id		int,
		@result			int,
		@num			int,
		@counter		int,
		@trx_type		smallint,
		@root_org_id		varchar(30)
		
	


	SELECT @root_org_id = ISNULL((select organization_id from Organization where outline_num = '1'),'')    

	exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.2',0,''

	SELECT	@customer_code 	= customer_code,
		@vendor_code 	= vendor_code,
		@nat_cur_code	= currency_code
	FROM 	#nbnethdr_work
	WHERE	net_ctrl_num 	= @net_ctrl_num

	
	SELECT 	@pay_amt_committed = ISNULL(SUM(amt_committed),0.0)
	FROM	#nbnetdeb_work
	WHERE	((amt_committed) > (0.0) + 0.0000001)
	AND 	trx_type	= 4111
	AND	net_ctrl_num 	= @net_ctrl_num
	
	SELECT 	@dm_amt_committed = ISNULL(SUM(amt_committed),0.0)
	FROM	#nbnetdeb_work
	WHERE	((amt_committed) > (0.0) + 0.0000001)
	AND 	trx_type 	= 4092
	AND	net_ctrl_num 	= @net_ctrl_num
	
	SELECT 	@vou_amt_committed = ISNULL(SUM(amt_committed),0.0)
	FROM	#nbnetcre_work
	WHERE	((amt_committed) > (0.0) + 0.0000001)
	AND 	trx_type 	= 4091
	AND	net_ctrl_num 	= @net_ctrl_num
	

	


	IF ((@dm_amt_committed + @pay_amt_committed) = 0 or @vou_amt_committed = 0)
	BEGIN
		exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.2',2,''
		RETURN 0
	END

	


	SELECT	@payment_code	= ISNULL(payment_code,''),
		@cash_acct_code	= ISNULL(cash_acct_code,'')
	FROM 	apvend
	WHERE	vendor_code	= @vendor_code
		
	


	SELECT 	@company_code = company_code
	FROM	glco

	


	EXEC apnewnum_sp 4116, @company_code, @settlement_ctrl_num OUTPUT

	IF @settlement_ctrl_num IS NULL
	BEGIN
		exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.2',3,''
		RETURN 1
	End

	


	EXEC         appdate_sp @date_entered OUTPUT


	


	INSERT #apinpstl	(
	settlement_ctrl_num,	vendor_code,		pay_to_code,		hold_flag,	
	date_entered,		date_applied,		user_id,		batch_code,
	process_group_num,	state_flag,		disc_total_home,	disc_total_oper,
	debit_memo_total_home,	debit_memo_total_oper,	on_acct_pay_total_home,	on_acct_pay_total_oper,
	payments_total_home,	payments_total_oper,	put_on_acct_total_home,	put_on_acct_total_oper,
	gain_total_home,	gain_total_oper,	loss_total_home,	loss_total_oper,	
	description,		nat_cur_code,		doc_count_expected,	doc_count_entered,	
	doc_sum_expected,	doc_sum_entered,	vo_total_home,		vo_total_oper,
	rate_type_home,		rate_home,		rate_type_oper,		rate_oper,
	vo_amt_nat,		amt_doc_nat,		amt_dist_nat,		amt_on_acct,
	org_id			)
	values (
	@settlement_ctrl_num,	@vendor_code,		'',			0,
	@date_entered,		@date_entered,		USER_ID(),		'',
	@process_ctrl_num,	-1,			0,			0,			
	0.0,			0.0,			0.0,			0.0,
	0.0,			0.0,			0.0,			0.0,
	0.0,			0.0,			0.0,			0.0,
	'Netting Transaction',	@nat_cur_code,		0,			0,		
	0,			0,			0.00,			0.00,
	'',			0.00,			'',			0.00,
	0.00,			0.00,			0.00,			0.00,
	@root_org_id		)
	
	IF @@error != 0
	BEGIN
		exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.2',4,''
		RETURN 	-1
	END

	



	IF ( (@dm_amt_committed + @pay_amt_committed) <= @vou_amt_committed )
	BEGIN

		
		


		SELECT	@amt_to_be_applied = @dm_amt_committed + @pay_amt_committed
		

		SELECT @trx_ctrl_num = ''


		WHILE @amt_to_be_applied > 0
		BEGIN


			SELECT 	@trx_ctrl_num	= MIN(trx_ctrl_num)
			FROM	#nbnetcre_work
			WHERE	net_ctrl_num 	= @net_ctrl_num
			AND	trx_ctrl_num	> @trx_ctrl_num
			AND	amt_committed	> 0.00
			AND	trx_type 	= 4091

			SELECT 	@trx_amt_committed = amt_committed, @doc_ctrl_num = doc_ctrl_num
			FROM	#nbnetcre_work
			WHERE	trx_ctrl_num 	= @trx_ctrl_num
			AND	net_ctrl_num	= @net_ctrl_num


			IF @trx_amt_committed IS NULL
				SELECT @trx_amt_committed = 0
			
			SELECT @sequence_id = 1

			IF @amt_to_be_applied >= @trx_amt_committed
				SELECT @amt_applied = @trx_amt_committed
			ELSE	
				SELECT @amt_applied = @amt_to_be_applied
				

			INSERT #apinppdt3450	(
			trx_ctrl_num,	trx_type,	sequence_id,	apply_to_num,	apply_trx_type,	
			amt_applied,    amt_disc_taken,	line_desc,	void_flag,	payment_hold_flag,	
			vendor_code,	vo_amt_applied,	vo_amt_disc_taken,gain_home,	gain_oper,	
			nat_cur_code,	cross_rate,	org_id		)
			VALUES 	( 
			@settlement_ctrl_num,	4111,		@sequence_id,	@trx_ctrl_num,	4091,
			@amt_applied,	0.0,		'Netting Transaction',0,	0,
			@vendor_code,	@amt_applied,	0.0,		0.0,		0.0,
			@nat_cur_code,	1,		@root_org_id	)
			

			IF @@error != 0
			Begin
				exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.2',5,'@trx_ctrl_num'
				RETURN 1
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


		SELECT 	@deb_trx_ctrl_num = MIN(trx_ctrl_num)	
		FROM	#nbnetdeb_work
		WHERE	net_ctrl_num 	= @net_ctrl_num
		AND	trx_type 	IN (4092,4111)
		AND	amt_committed	> 0.00

		WHILE 	@deb_trx_ctrl_num IS NOT NULL
		BEGIN

			


			EXEC apnewnum_sp 4111, @company_code, @payment_ctrl_num OUTPUT
			
			


			EXEC ARGetNextControl_SP 2130, @net_doc_num OUTPUT, @num OUTPUT



			IF @payment_ctrl_num IS NULL
			Begin
				exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.2',6,''
				RETURN 1
			end

			SELECT	@amt_committed 	= amt_committed, @doc_ctrl_num = doc_ctrl_num,
				@trx_type 	= trx_type
			FROM	#nbnetdeb_work
			WHERE	trx_ctrl_num	= @deb_trx_ctrl_num
			AND	net_ctrl_num	= @net_ctrl_num

			


			IF	@trx_type	= 4092
			BEGIN

				SELECT	@rate_type_home	= rate_type_home,
					@rate_type_oper	= rate_type_oper,
					@rate_home	= rate_home,			
					@rate_oper	= rate_oper,
					@payment_code	= 'DBMEMO',
					@payment_type = 3,
					@cash_acct_code	= ''			
				FROM	apdmhdr
				WHERE	trx_ctrl_num	= @doc_ctrl_num
			
			END


			


			IF	@trx_type	= 4111
			BEGIN

				SELECT	@rate_type_home	= rate_type_home,
					@rate_type_oper	= rate_type_oper,
					@rate_home	= rate_home,
					@rate_oper	= rate_oper,                   
					@payment_code	= ISNULL(payment_code,''),		
					@payment_type = 2,
					@cash_acct_code	= ISNULL(cash_acct_code,'')
				FROM	appyhdr
				WHERE	trx_ctrl_num	= @deb_trx_ctrl_num
		
			END

			INSERT #apinppyt3450	(
			trx_ctrl_num, 	trx_type,	doc_ctrl_num,	trx_desc,	batch_code,	cash_acct_code,
			date_entered,	date_applied,	date_doc,	vendor_code,	pay_to_code,	approval_code,
			payment_code,	payment_type,	amt_payment,	amt_on_acct,	posted_flag,	printed_flag,
			hold_flag,	approval_flag,	gen_id,		user_id,	void_type, 	amt_disc_taken,
			print_batch_num,company_code,	process_group_num,nat_cur_code,	rate_type_home,	rate_type_oper,
			rate_home,	rate_oper,	payee_name,	settlement_ctrl_num,		doc_amount,
			org_id		)	
			VALUES (
			@payment_ctrl_num,4111,		@doc_ctrl_num,'Netting Transacction ' + @net_ctrl_num,
											'',		@cash_acct_code,
			@date_entered,	@date_entered,	@date_entered,	@vendor_code,	'',		0, 
			@payment_code,	@payment_type, 		@amt_committed,	0.0,		-1,		1,
			0,		0,		0,		USER_ID(),	0,		0.0,
			0,		@company_code,	@process_ctrl_num,@nat_cur_code,@rate_type_home,@rate_type_oper,
			@rate_home,	@rate_oper,	NULL,		@settlement_ctrl_num,		 @amt_committed,
			@root_org_id)


			


			INSERT	#nbtrxrel (	net_ctrl_num, trx_ctrl_num,		trx_type	)
			VALUES (		@net_ctrl_num,@payment_ctrl_num,	4111		)

			exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.2',1,@payment_ctrl_num

			UPDATE	#nbnetdeb_work
			SET	amt_committed = 0.0
			WHERE	net_ctrl_num 	= @net_ctrl_num
			AND	trx_ctrl_num	= @deb_trx_ctrl_num
	
			SELECT 	@deb_trx_ctrl_num = MIN(trx_ctrl_num)	
			FROM	#nbnetdeb_work
			WHERE	net_ctrl_num 	= @net_ctrl_num
			AND	trx_ctrl_num	> @deb_trx_ctrl_num
			AND	trx_type 	IN (4111,4092)
		

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
			AND	amt_committed	> 0.00
			AND	trx_type 	IN (4111,4092)

			SELECT 	@trx_amt_committed = amt_committed, @doc_ctrl_num = doc_ctrl_num,
				@trx_type	= trx_type
			FROM	#nbnetdeb_work
			WHERE	trx_ctrl_num 	= @trx_ctrl_num
			AND	trx_type 	IN (4111,4092)

			IF @trx_amt_committed IS NULL
				SELECT @trx_amt_committed = 0
			
			IF @amt_to_be_applied >= @trx_amt_committed
				SELECT @amt_applied = @trx_amt_committed
			ELSE	
				SELECT @amt_applied = @amt_to_be_applied


			


			IF	@trx_type	= 4092
			BEGIN

				SELECT	@rate_type_home	= rate_type_home,
					@rate_type_oper	= rate_type_oper,
					@rate_home	= rate_home,
					@rate_oper	= rate_oper,
					@payment_code	= 'DBMEMO',
					@payment_type = 3,
					@cash_acct_code	= ''					
				FROM	apdmhdr
				WHERE	trx_ctrl_num	= @doc_ctrl_num
			
			END

			


			IF	@trx_type	= 4111
			BEGIN

				SELECT	@rate_type_home	= rate_type_home,
					@rate_type_oper	= rate_type_oper,
					@rate_home	= rate_home,
					@rate_oper	= rate_oper,
					@payment_code	= ISNULL(payment_code,''),  
					@payment_type = 2,
					@cash_acct_code	= ISNULL(cash_acct_code,'')
				FROM	appyhdr
				WHERE	trx_ctrl_num	= @trx_ctrl_num
		
			END

			


			EXEC apnewnum_sp 4111, @company_code, @payment_ctrl_num OUTPUT

			


	
			EXEC ARGetNextControl_SP 2130, @net_doc_num OUTPUT, @num OUTPUT


			IF @payment_ctrl_num IS NULL
			Begin
				exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.2',6,''
				RETURN 1
			end

			INSERT #apinppyt3450	(
			trx_ctrl_num, 	trx_type,	doc_ctrl_num,	trx_desc,	batch_code,	cash_acct_code,
			date_entered,	date_applied,	date_doc,	vendor_code,	pay_to_code,	approval_code,
			payment_code,	payment_type,	amt_payment,	amt_on_acct,	posted_flag,	printed_flag,
			hold_flag,	approval_flag,	gen_id,		user_id,	void_type, 	amt_disc_taken,
			print_batch_num,company_code,	process_group_num,nat_cur_code,	rate_type_home,	rate_type_oper,
			rate_home,	rate_oper,	payee_name,	settlement_ctrl_num,		doc_amount,
			org_id		)		
			VALUES (
			@payment_ctrl_num,4111,		@doc_ctrl_num,	'Netting Transacction ' + @net_ctrl_num,
											'',		@cash_acct_code,
			@date_entered,	@date_entered,	@date_entered,	@vendor_code,	'',		0, 
			@payment_code,	@payment_type, 		@amt_applied,	0.0,		-1,		1,
			0,		0,		0,		USER_ID(),	0,		0.0,
			0,		@company_code,	@process_ctrl_num,@nat_cur_code,@rate_type_home,@rate_type_oper,
			@rate_home,	@rate_oper,	NULL,		@settlement_ctrl_num,		@amt_applied,
			@root_org_id	)


			INSERT	#nbtrxrel (	net_ctrl_num, trx_ctrl_num,trx_type)
			VALUES (		@net_ctrl_num,@payment_ctrl_num,4111	)

			exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.2',1,@payment_ctrl_num
			
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


			INSERT #apinppdt3450	(
			trx_ctrl_num,		trx_type,	sequence_id,		apply_to_num,		apply_trx_type,	
			amt_applied,    	amt_disc_taken,	line_desc,		void_flag,		payment_hold_flag,	
			vendor_code,		vo_amt_applied,	vo_amt_disc_taken,	gain_home,		gain_oper,	
			nat_cur_code,		cross_rate,	org_id		)
			VALUES 	( 
			@settlement_ctrl_num,	4111,		@sequence_id,		@cre_trx_ctrl_num,	4091,
			@amt_committed,		0.0,		'Netting Transaction',	0,			0,
			@vendor_code,		@amt_committed,	0.0,			0.0,			0.0,
			@nat_cur_code,		1,		@root_org_id		)


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

	SELECT 	@counter = count(settlement_ctrl_num)
	FROM	#apinpstl

	UPDATE	#apinpstl
	SET	payments_total_home	= @vou_amt_committed,
		payments_total_oper	= @vou_amt_committed,
		doc_count_entered	= @counter
	WHERE	process_group_num 	= @process_ctrl_num
	AND	settlement_ctrl_num	= @settlement_ctrl_num



	DECLARE apsett_cur CURSOR FOR SELECT settlement_ctrl_num FROM #apinpstl
	OPEN apsett_cur

	FETCH NEXT FROM apsett_cur INTO @settlement_ctrl_num

	WHILE @@FETCH_STATUS = 0
	BEGIN

		



		EXEC @result = apstlprt_sp @settlement_ctrl_num
	
		IF @result !=  0
		Begin
			exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.2',7,''
			RETURN	@result
		End
	
		FETCH NEXT FROM apsett_cur INTO @settlement_ctrl_num
	END
  
	CLOSE apsett_cur
	DEALLOCATE apsett_cur



INSERT	apinpstl (
	settlement_ctrl_num,	vendor_code,		pay_to_code,		hold_flag,	
	date_entered,		date_applied,		user_id,		batch_code,
	process_group_num,	state_flag,		disc_total_home,	disc_total_oper,
	debit_memo_total_home,	debit_memo_total_oper,	on_acct_pay_total_home,	on_acct_pay_total_oper,
	payments_total_home,	payments_total_oper,	put_on_acct_total_home,	put_on_acct_total_oper,
	gain_total_home,	gain_total_oper,	loss_total_home,	loss_total_oper,	
	description,		nat_cur_code,		doc_count_expected,	doc_count_entered,
	doc_sum_expected,	doc_sum_entered,	vo_total_home,		vo_total_oper,
	rate_type_home,		rate_home,		rate_type_oper,		rate_oper,
	vo_amt_nat,		amt_doc_nat,		amt_dist_nat,		amt_on_acct,
	org_id			)
SELECT	settlement_ctrl_num,	vendor_code,		pay_to_code,		hold_flag,	
	date_entered,		date_applied,		user_id,		batch_code,
	process_group_num,	state_flag,		disc_total_home,	disc_total_oper,
	debit_memo_total_home,	debit_memo_total_oper,	on_acct_pay_total_home,	on_acct_pay_total_oper,
	payments_total_home,	payments_total_oper,	put_on_acct_total_home,	put_on_acct_total_oper,
	gain_total_home,	gain_total_oper,	loss_total_home,	loss_total_oper,
	description,		nat_cur_code,		doc_count_expected,	doc_count_entered,
	doc_sum_expected,	doc_sum_entered,	vo_total_home,		vo_total_oper,
	rate_type_home,		rate_home,		rate_type_oper,		rate_oper,
	vo_amt_nat,		amt_doc_nat,		amt_dist_nat,		amt_on_acct,
	org_id		
FROM	#apinpstl

INSERT	apinppyt (			
	trx_ctrl_num, 	trx_type,	doc_ctrl_num,	trx_desc,	batch_code,	cash_acct_code,
	date_entered,	date_applied,	date_doc,	vendor_code,	pay_to_code,	approval_code,
	payment_code,	payment_type,	amt_payment,	amt_on_acct,	posted_flag,	printed_flag,
	hold_flag,	approval_flag,	gen_id,		user_id,	void_type, 	amt_disc_taken,
	print_batch_num,company_code,	process_group_num,nat_cur_code,	rate_type_home,	rate_type_oper,
	rate_home,	rate_oper,	payee_name,	settlement_ctrl_num, org_id	)
SELECT	trx_ctrl_num, 	trx_type,	doc_ctrl_num,	trx_desc,	batch_code,	cash_acct_code,
	date_entered,	date_applied,	date_doc,	vendor_code,	pay_to_code,	approval_code,
	payment_code,	payment_type,	amt_payment,	amt_on_acct,	posted_flag,	printed_flag,
	hold_flag,	approval_flag,	gen_id,		user_id,	void_type, 	amt_disc_taken,
	print_batch_num,company_code,	process_group_num,nat_cur_code,	rate_type_home,	rate_type_oper,
	rate_home,	rate_oper,	payee_name,	settlement_ctrl_num, org_id	
FROM	#apinppyt3450

INSERT	apinppdt (			
	trx_ctrl_num,	trx_type,	sequence_id,	apply_to_num,	apply_trx_type,	
	amt_applied,    amt_disc_taken,	line_desc,	void_flag,	payment_hold_flag,	
	vendor_code,	vo_amt_applied,	vo_amt_disc_taken,gain_home,	gain_oper,	
	nat_cur_code,	cross_rate,	org_id		)
SELECT	trx_ctrl_num,	trx_type,	sequence_id,	apply_to_num,	apply_trx_type,	
	amt_applied,    amt_disc_taken,	line_desc,	void_flag,	payment_hold_flag,	
	vendor_code,	vo_amt_applied,	vo_amt_disc_taken,gain_home,	gain_oper,	
	nat_cur_code,	cross_rate,	org_id		
FROM	#apinppdt3450
	


DROP TABLE #apinppyt3450
DROP TABLE #apinppdt3450
DROP TABLE #apinpstl
DROP TABLE #gain_loss

exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.2',-1,''

RETURN  0  

GO
GRANT EXECUTE ON  [dbo].[NBNetVoucherVsPaymentDebitMemo_sp] TO [public]
GO
