SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARCRGetDepositNum_SP]	@batch_ctrl_num	varchar( 16 ),
					@debug_level		smallint = 0,
					@perf_level		smallint = 0	
AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									







DECLARE
      	@result		int,
	@dnum			int,
	@deposit_count	int,	
	@deposit_num		varchar(16)


BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcrgdn.cpp' + ', line ' + STR( 67, 5 ) + ' -- ENTRY: '
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'arcrgdn.cpp', 68, 'Entering ARCRGetDepositNum_SP', @PERF_time_last OUTPUT
	
	









	
	




	INSERT	#ardepnum
	SELECT pyt.payment_code,
		pyt.cash_acct_code,
		pyt.nat_cur_code,
		pyt.date_applied,
		NULL,
		SUM(pyt.amt_payment),
		MAX(pyt.org_id)
	FROM	#arinppyt_work pyt, apcash ap
	WHERE	pyt.batch_code = @batch_ctrl_num
	AND	pyt.payment_type = 1
	AND	pyt.cash_acct_code = ap.cash_acct_code
	AND	pyt.nat_cur_code = ap.nat_cur_code 
	GROUP BY pyt.payment_code, pyt.cash_acct_code, pyt.nat_cur_code, pyt.date_applied
			
	DELETE #ardepnum
	FROM	arcrtran trn, #arinppyt_work pyt
	WHERE	trn.trx_ctrl_num = pyt.trx_ctrl_num
	AND	pyt.batch_code = @batch_ctrl_num
	AND	pyt.payment_type = 1
	AND	pyt.cash_acct_code = #ardepnum.cash_acct_code
	AND	pyt.nat_cur_code = #ardepnum.nat_cur_code 
	AND	pyt.date_applied = #ardepnum.date_applied

	SELECT @deposit_count = COUNT(*) FROM #ardepnum

	WHILE (@deposit_count > 0)
	BEGIN
	
		EXEC @result = ARGetNextControl_SP 2060,
							@deposit_num OUTPUT,
							@dnum OUTPUT,
							@debug_level
		IF( @result != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcrgdn.cpp' + ', line ' + STR( 121, 5 ) + ' -- EXIT: '
			RETURN @result
		END

		SET ROWCOUNT 1
		
		UPDATE #ardepnum
		SET	deposit_num = @deposit_num
		WHERE	deposit_num IS NULL
		
		SET ROWCOUNT 0		

		SELECT @deposit_count = @deposit_count - 1	
	END

	IF @debug_level > 0
	BEGIN
		SELECT 'Deposit Numbers created...'
		SELECT 'cash_acct_code = ' + cash_acct_code +
			'payment_code = ' + payment_code +
			'nat_cur_code = ' + nat_cur_code +
			'deposit_num = ' + deposit_num +
			'deposit_amount = ' + STR(deposit_amount,10,2) + 
			'org_id = ' + org_id
		FROM	#ardepnum
	END
	

	UPDATE	#arinppyt_work
	SET	deposit_num = dep.deposit_num
	FROM	#ardepnum dep
	WHERE	#arinppyt_work.payment_code = dep.payment_code
	AND	#arinppyt_work.cash_acct_code = dep.cash_acct_code
	AND	#arinppyt_work.nat_cur_code = dep.nat_cur_code
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcrgdn.cpp' + ', line ' + STR( 157, 5 ) + ' -- EXIT: '
		RETURN 34563
	END

	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'arcrgdn.cpp', 161, 'Leaving ARCRGetDepositNum_SP', @PERF_time_last OUTPUT
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcrgdn.cpp' + ', line ' + STR( 162, 5 ) + ' -- EXIT: '
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARCRGetDepositNum_SP] TO [public]
GO
