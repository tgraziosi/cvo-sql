SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[arpytcur_sp]	@trx_ctrl_num	varchar( 16 ), 
				@apply_to_num	varchar( 16 ),
				@date_aging	int,
				@nat_cur_code	varchar( 16 ),
				@apply_trx_type	smallint,
				@trx_type	smallint
AS
DECLARE	@date_applied		int, 
		@rate_home		float, 
		@rate_oper		float, 
		@home_amt_applied	float,
		@oper_amt_applied	float,
		@home_amt_disc_taken	float,
		@oper_amt_disc_taken	float,
		@home_amt_wr_off	float,
		@oper_amt_wr_off	float,
		@exchanged_rate	float,
		@gain_home		float,
		@gain_oper		float,
		@home_cur		varchar( 8 ),
		@home_mask		varchar( 100 ),
		@oper_cur		varchar( 8 ),
		@oper_mask		varchar( 100 ),
		@precision_home	smallint,
		@precision_oper	smallint

BEGIN
	DELETE #arpytcur


	SELECT @home_cur = home_currency,
		@oper_cur = oper_currency,
		@home_mask = h.currency_mask,
		@oper_mask = o.currency_mask,
		@precision_home = h.curr_precision,
		@precision_oper = o.curr_precision
	FROM	glco, glcurr_vw h, glcurr_vw o
	WHERE	home_currency = h.currency_code
	AND	oper_currency = o.currency_code

	SELECT	@rate_home = 0.0,
		@rate_oper = 0.0,
		@home_amt_applied = 0.0,
		@oper_amt_applied = 0.0,
		@home_amt_disc_taken = 0.0,
		@oper_amt_disc_taken = 0.0,
		@home_amt_wr_off = 0.0,
		@oper_amt_wr_off = 0.0,
		@exchanged_rate = 0.0,
		@gain_home = 0.0,
		@gain_oper = 0.0
		
	INSERT INTO #arpytcur
	(
		pyt_cur_code,			inv_cur_code,		
		inv_amt_disc_taken,		inv_amt_wr_off,		
		inv_amt_applied,		amt_applied,
		amt_disc_taken,		amt_wr_off,		
		home_amt_disc_taken,		oper_amt_disc_taken,		
		home_amt_wr_off,		oper_amt_wr_off,
		home_amt_applied,		oper_amt_applied,	
		rate_home_1,			rate_oper_1,				
		rate_home_2,			rate_oper_2,	
		rate_home_3,			rate_oper_3,			
		exchanged_rate,		gain_home,			
		gain_oper,			oper_curr,
		oper_currency_mask,		home_curr,		
		home_currency_mask
	)
	SELECT	@nat_cur_code,		pdt.inv_cur_code,	
		pdt.inv_amt_disc_taken,	pdt.inv_amt_wr_off,		
		pdt.inv_amt_applied,		pdt.amt_applied,
		pdt.amt_disc_taken,		pdt.amt_wr_off,	
		@home_amt_disc_taken,	@oper_amt_disc_taken,	
		@home_amt_wr_off,		@oper_amt_wr_off,
		@home_amt_applied,		@oper_amt_applied,	
		0.0,				0.0,			
		0.0,				0.0,
		0.0,				0.0,		
		amt_applied/inv_amt_applied,gain_home,			
		gain_oper,			@oper_cur,
		@oper_mask,			@home_cur,		
		@home_mask
	FROM	artrxpdt pdt 
	WHERE	pdt.trx_ctrl_num = @trx_ctrl_num
	AND	pdt.trx_type = @trx_type
	AND	pdt.sub_apply_num = @apply_to_num
	AND	pdt.date_aging = @date_aging
	
	UPDATE	#arpytcur
	SET	rate_home_1 = trx.rate_home, 
		rate_oper_1 = trx.rate_oper, 
		rate_home_2 = trx.rate_home, 
		rate_oper_2 = trx.rate_oper
	FROM	artrx trx
	WHERE	trx.doc_ctrl_num = @apply_to_num
	AND	trx.trx_type = @apply_trx_type
			
	UPDATE #arpytcur
	SET	rate_home_3 = age.rate_home,
		rate_oper_3 = age.rate_oper
	FROM	artrxage age
	WHERE	trx_ctrl_num = @trx_ctrl_num
	AND	trx_type = @trx_type
	AND	sub_apply_num = @apply_to_num
	AND	sub_apply_type = @apply_trx_type
	AND	date_aging = @date_aging
	
	


	UPDATE	#arpytcur
	SET	home_amt_disc_taken = ROUND(inv_amt_disc_taken * ( SIGN(1 + SIGN(rate_home_1))*(rate_home_1) + (SIGN(ABS(SIGN(ROUND(rate_home_1,6))))/(rate_home_1 + SIGN(1 - ABS(SIGN(ROUND(rate_home_1,6)))))) * SIGN(SIGN(rate_home_1) - 1) ), @precision_home),		
		oper_amt_disc_taken = ROUND(inv_amt_disc_taken * ( SIGN(1 + SIGN(rate_oper_1))*(rate_oper_1) + (SIGN(ABS(SIGN(ROUND(rate_oper_1,6))))/(rate_oper_1 + SIGN(1 - ABS(SIGN(ROUND(rate_oper_1,6)))))) * SIGN(SIGN(rate_oper_1) - 1) ), @precision_oper),		
		home_amt_wr_off = ROUND(inv_amt_wr_off * ( SIGN(1 + SIGN(rate_home_2))*(rate_home_2) + (SIGN(ABS(SIGN(ROUND(rate_home_2,6))))/(rate_home_2 + SIGN(1 - ABS(SIGN(ROUND(rate_home_2,6)))))) * SIGN(SIGN(rate_home_2) - 1) ), @precision_home),		
		oper_amt_wr_off = ROUND(inv_amt_wr_off * ( SIGN(1 + SIGN(rate_oper_2))*(rate_oper_2) + (SIGN(ABS(SIGN(ROUND(rate_oper_2,6))))/(rate_oper_2 + SIGN(1 - ABS(SIGN(ROUND(rate_oper_2,6)))))) * SIGN(SIGN(rate_oper_2) - 1) ), @precision_oper),
		home_amt_applied = ROUND(inv_amt_applied * ( SIGN(1 + SIGN(rate_home_3))*(rate_home_3) + (SIGN(ABS(SIGN(ROUND(rate_home_3,6))))/(rate_home_3 + SIGN(1 - ABS(SIGN(ROUND(rate_home_3,6)))))) * SIGN(SIGN(rate_home_3) - 1) ), @precision_home),		
		oper_amt_applied = ROUND(inv_amt_applied * ( SIGN(1 + SIGN(rate_oper_3))*(rate_oper_3) + (SIGN(ABS(SIGN(ROUND(rate_oper_3,6))))/(rate_oper_3 + SIGN(1 - ABS(SIGN(ROUND(rate_oper_3,6)))))) * SIGN(SIGN(rate_oper_3) - 1) ), @precision_oper)	
		

	UPDATE #arpytcur
	SET	pyt_currency_mask = p.currency_mask,
		nat_currency_mask = n.currency_mask
	FROM	glcurr_vw p, glcurr_vw n
	WHERE	pyt_cur_code = p.currency_code
	AND	inv_cur_code = n.currency_code


END
GO
GRANT EXECUTE ON  [dbo].[arpytcur_sp] TO [public]
GO
