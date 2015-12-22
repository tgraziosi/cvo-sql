SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE  PROCEDURE  [dbo].[aramtdue_sp]  
				@cash_acct_code varchar(32),
				@date_through   int
AS

DECLARE	@result		int,
		@cash_acct_rate	float,
		@divide_flag		smallint,
		@cash_acct_cur_code	varchar(8),
		@home_currency	varchar(8),
		@precision		smallint,
		@rate_type		varchar(8),
		@today			int,
		@rec_count		int





SELECT @today	= datediff(dd,"1/1/80",getdate())+722815

IF (SELECT bb_flag FROM arco) = 0 RETURN






INSERT #amounts_due (trx_ctrl_num,
					 apply_trx_type, 
					 doc_ctrl_num, 
					 module, 
					 date_applied, 
					 date_due,
					 currency_code,
					 nat_amount,
					 rate_home, 
					 amount) 
SELECT a.apply_to_num,
	   a.apply_trx_type,
	   a.apply_to_num,	 
	   'AR', 
	   0,
	   a.date_due,
	   '',
	   SUM(a.amount),
	   0.0,
	   SUM(a.amount)
FROM	artrxage a, arcust b, arpymeth p
WHERE	a.customer_code = b.customer_code
AND	b.payment_code = p.payment_code
AND	p.asset_acct_code = @cash_acct_code
AND a.date_due <= @date_through
AND a.ref_id > 0
GROUP BY a.apply_to_num, a.date_due, a.apply_trx_type
HAVING ABS(SUM(amount)) > 0.000001
	   



UPDATE #amounts_due
SET date_applied = b.date_applied,
	currency_code = b.nat_cur_code,
	rate_home = b.rate_home
FROM #amounts_due a, artrx b
WHERE a.doc_ctrl_num = b.doc_ctrl_num
AND a.apply_trx_type = b.trx_type


SELECT @home_currency = home_currency
FROM	glco


SELECT	@cash_acct_cur_code = nat_cur_code
FROM	apcash
WHERE	cash_acct_code = @cash_acct_code
AND	( LTRIM(nat_cur_code) IS NOT NULL AND LTRIM(nat_cur_code) != " " )

SELECT @precision = curr_precision
FROM	glcurr_vw
WHERE	currency_code	= @cash_acct_cur_code

SELECT @rec_count = @@rowcount

SELECT	@rate_type = rate_type_home
FROM	glchart
WHERE	account_code = @cash_acct_code
AND	( LTRIM(rate_type_home) IS NOT NULL AND LTRIM(rate_type_home) != " " )

SELECT @rec_count = @rec_count + @@rowcount

IF(@rec_count = 2)
BEGIN
	EXEC @result = CVO_Control..mccurate_sp
				@today,
				@home_currency,		
				@cash_acct_cur_code,	
				@rate_type,	
				@cash_acct_rate	OUTPUT,
				0,
				@divide_flag		OUTPUT

	IF ( @result != 0 )
		SELECT @cash_acct_rate = 0
END
ELSE
		SELECT @cash_acct_rate = 0








IF @cash_acct_rate = 0
	UPDATE #amounts_due
	SET	amount = -1
ELSE	
	UPDATE	#amounts_due
	SET	amount = (SIGN(amount*( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )*( SIGN(1 + SIGN(@cash_acct_rate))*(@cash_acct_rate) + (SIGN(ABS(SIGN(ROUND(@cash_acct_rate,6))))/(@cash_acct_rate + SIGN(1 - ABS(SIGN(ROUND(@cash_acct_rate,6)))))) * SIGN(SIGN(@cash_acct_rate) - 1) )) * ROUND(ABS(amount*( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )*( SIGN(1 + SIGN(@cash_acct_rate))*(@cash_acct_rate) + (SIGN(ABS(SIGN(ROUND(@cash_acct_rate,6))))/(@cash_acct_rate + SIGN(1 - ABS(SIGN(ROUND(@cash_acct_rate,6)))))) * SIGN(SIGN(@cash_acct_rate) - 1) )) + 0.0000001, @precision))
	WHERE	currency_code !=@cash_acct_cur_code
	AND     trx_ctrl_num in (SELECT trx_ctrl_num from artrxage)

GO
GRANT EXECUTE ON  [dbo].[aramtdue_sp] TO [public]
GO
