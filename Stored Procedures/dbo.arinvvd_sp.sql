SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[arinvvd_sp]	@posted_flag int,
				@sys_date int
AS




DECLARE	
	@trx_num	varchar(16),	
	@trx_type	smallint,	
	@total_trx	float, 	
	@trx_done	float, 	
	@cust_code	varchar(8), 	
	@shp_code	varchar(8),	
	@prc_code	varchar(8),	
	@ter_code	varchar(8),	
	@slp_code	varchar(8), 
	@amt_net	float,		
	@err_mess	char(80),	
	@cust_flag	smallint,
	@shp_flag	smallint,	
	@slp_flag	smallint, 	
	@prc_flag	smallint, 
	@ter_flag	smallint,	
	@mast_flag	smallint,	
	@perc_done	float,	
	@nat_cur_code	varchar(8),
	@rate_type_oper	varchar(8),
	@rate_type_home	varchar(8),
	@rate_home	float,
	@rate_oper	float,
	@home_precision	smallint,
	@oper_precision	smallint,
	@order_ctrl_num	varchar(16),
	@tax_code varchar(8)





SELECT	@home_precision = curr_precision
FROM	glco, glcurr_vw
WHERE	glco.home_currency = glcurr_vw.currency_code

SELECT	@oper_precision = curr_precision
FROM	glco, glcurr_vw
WHERE	glco.oper_currency = glcurr_vw.currency_code




SELECT	@total_trx = 0.0, @trx_done = 0.0

SELECT  @total_trx = COUNT( trx_ctrl_num )
FROM	arinpchg
WHERE	posted_flag = @posted_flag


IF (( @total_trx IS NULL ) OR ((@total_trx) < (0.0) - 0.0000001))
BEGIN
	RETURN
END





WHILE ( 1 = 1 )
BEGIN
	



	SELECT	@trx_num = NULL

	SET ROWCOUNT  1

	SELECT	@trx_num = trx_ctrl_num, 
		@trx_type = trx_type,
		@amt_net = amt_net,
		@cust_code = customer_code,
		@shp_code = ship_to_code,
		@prc_code = price_code,
		@ter_code = territory_code,
		@slp_code = salesperson_code,
		@nat_cur_code = nat_cur_code,
		@rate_type_oper = rate_type_oper,
		@rate_type_home = rate_type_home,
		@rate_home = rate_home,
		@rate_oper = rate_oper,
		@order_ctrl_num = order_ctrl_num,
		@tax_code = tax_code
	FROM	arinpchg
	WHERE	posted_flag = @posted_flag
        ORDER	BY trx_ctrl_num

	SET ROWCOUNT  0

	


	IF ( @trx_num IS NULL )
	BEGIN
		RETURN
	END

	



	IF( ( LTRIM(@order_ctrl_num) IS NOT NULL AND LTRIM(@order_ctrl_num) != " " ) )
	BEGIN
		




		UPDATE	arinpchg
		SET	posted_flag = 0
		WHERE	trx_ctrl_num = @trx_num
		AND	trx_type = @trx_type

		CONTINUE
	END

	




	BEGIN TRAN

	


	INSERT	artrx (
		


		trx_ctrl_num,	doc_ctrl_num,	doc_desc,	
		batch_code,	trx_type,	non_ar_flag, 
		apply_to_num,	apply_trx_type,	gl_acct_code,	
		date_posted,	date_applied,	date_doc,	
		gl_trx_id,	customer_code,	payment_code,	
		amt_net,	payment_type,	prompt1_inp,	
		prompt2_inp,	prompt3_inp,	prompt4_inp,	
		deposit_num,	void_flag,	amt_on_acct,
		paid_flag,	user_id,	posted_flag,
		date_entered,	date_paid,
		


		order_ctrl_num,	date_shipped,
		date_required,	date_due,	date_aging,
		ship_to_code,	salesperson_code, territory_code,
		comment_code,	fob_code,	freight_code,
		terms_code,	price_code,	dest_zone_code,
		posting_code,	recurring_flag,	recurring_code,
		cust_po_num,	amt_gross,	amt_freight,
		amt_tax,	amt_discount,	amt_paid_to_date,
		amt_cost,	amt_tot_chg,	fin_chg_code,
		tax_code,	commission_flag, cash_acct_code,
		non_ar_doc_num, purge_flag,	nat_cur_code, 
		rate_type_home,	rate_type_oper,	rate_home,
		rate_oper,	amt_tax_included
		 )
	SELECT	trx_ctrl_num,	doc_ctrl_num,	"VOID",
		batch_code,	trx_type,	0,
		apply_to_num,	apply_trx_type,	" ",
		@sys_date,	date_applied,	date_doc,	
		" ",		customer_code,	" ",
		0,		0,		" ",
		" ",		" ",		" ",
		" ",		1,		0,
		0,		user_id,	1,
		date_entered,	0,
		order_ctrl_num,	date_shipped,
		date_required,	date_due,	date_aging,
		ship_to_code,	salesperson_code, territory_code,
		comment_code,	fob_code,	freight_code,
		terms_code,	price_code,	dest_zone_code,
		posting_code,	recurring_flag,	recurring_code,
		cust_po_num,	0,		0,
		0,		0,		0,
		0,		0,		fin_chg_code,
		tax_code,	0,		" ",
		" ", 0,	@nat_cur_code,
		@rate_type_home,	@rate_type_oper,	@rate_home,
		@rate_oper,	0.0
	FROM	arinpchg
	WHERE   trx_ctrl_num = @trx_num
	  AND	trx_type = @trx_type
	
	





	SELECT	@cust_flag = aractcus_flag,
		@shp_flag = aractshp_flag,
		@slp_flag = aractslp_flag,
		@prc_flag = aractprc_flag,
		@ter_flag = aractter_flag
	FROM	arco
	
	IF ( @@ROWCOUNT = 0 )
	BEGIN
		ROLLBACK TRAN
		SELECT	@err_mess = "ARCO is missing!"
		RETURN
	END
	
	


	SELECT	@mast_flag = ship_to_history
	FROM	arcust
	WHERE	customer_code = @cust_code
	
	IF ( @@ROWCOUNT = 0 )
		SELECT	@mast_flag = 0
	
	


	UPDATE	aractcus
	SET	amt_inv_unposted = amt_inv_unposted - ROUND(( SIGN(1 + SIGN(@rate_home))*(@rate_home) + (SIGN(ABS(SIGN(ROUND(@rate_home,6))))/(@rate_home + SIGN(1 - ABS(SIGN(ROUND(@rate_home,6)))))) * SIGN(SIGN(@rate_home) - 1) ) * @amt_net,@home_precision),
		amt_inv_unp_oper = amt_inv_unp_oper - ROUND(( SIGN(1 + SIGN(@rate_oper))*(@rate_oper) + (SIGN(ABS(SIGN(ROUND(@rate_oper,6))))/(@rate_oper + SIGN(1 - ABS(SIGN(ROUND(@rate_oper,6)))))) * SIGN(SIGN(@rate_oper) - 1) ) * @amt_net,@oper_precision) 
	WHERE	customer_code = @cust_code
	AND	@cust_flag > 0 
	AND	( LTRIM(@cust_code) IS NOT NULL AND LTRIM(@cust_code) != " " )  
	
	


	UPDATE	aractshp
	SET	amt_inv_unposted = amt_inv_unposted - ROUND(( SIGN(1 + SIGN(@rate_home))*(@rate_home) + (SIGN(ABS(SIGN(ROUND(@rate_home,6))))/(@rate_home + SIGN(1 - ABS(SIGN(ROUND(@rate_home,6)))))) * SIGN(SIGN(@rate_home) - 1) ) * @amt_net,@home_precision),
		amt_inv_unp_oper = amt_inv_unp_oper - ROUND(( SIGN(1 + SIGN(@rate_oper))*(@rate_oper) + (SIGN(ABS(SIGN(ROUND(@rate_oper,6))))/(@rate_oper + SIGN(1 - ABS(SIGN(ROUND(@rate_oper,6)))))) * SIGN(SIGN(@rate_oper) - 1) ) * @amt_net,@oper_precision) 
	WHERE	customer_code = @cust_code
	AND	ship_to_code = @shp_code
	AND	@shp_flag > 0 
	AND	@mast_flag > 0
	AND	( LTRIM(@shp_code) IS NOT NULL AND LTRIM(@shp_code) != " " )  
	
	


	UPDATE	aractslp
	SET	amt_inv_unposted = amt_inv_unposted - ROUND(( SIGN(1 + SIGN(@rate_home))*(@rate_home) + (SIGN(ABS(SIGN(ROUND(@rate_home,6))))/(@rate_home + SIGN(1 - ABS(SIGN(ROUND(@rate_home,6)))))) * SIGN(SIGN(@rate_home) - 1) ) * @amt_net,@home_precision),
		amt_inv_unp_oper = amt_inv_unp_oper - ROUND(( SIGN(1 + SIGN(@rate_oper))*(@rate_oper) + (SIGN(ABS(SIGN(ROUND(@rate_oper,6))))/(@rate_oper + SIGN(1 - ABS(SIGN(ROUND(@rate_oper,6)))))) * SIGN(SIGN(@rate_oper) - 1) ) * @amt_net,@oper_precision) 
	WHERE	salesperson_code = @slp_code
	AND	@slp_flag > 0 
	AND	( LTRIM(@slp_code) IS NOT NULL AND LTRIM(@slp_code) != " " ) 
	
	


	UPDATE	aractter
	SET	amt_inv_unposted = amt_inv_unposted - ROUND(( SIGN(1 + SIGN(@rate_home))*(@rate_home) + (SIGN(ABS(SIGN(ROUND(@rate_home,6))))/(@rate_home + SIGN(1 - ABS(SIGN(ROUND(@rate_home,6)))))) * SIGN(SIGN(@rate_home) - 1) ) * @amt_net,@home_precision),
		amt_inv_unp_oper = amt_inv_unp_oper - ROUND(( SIGN(1 + SIGN(@rate_oper))*(@rate_oper) + (SIGN(ABS(SIGN(ROUND(@rate_oper,6))))/(@rate_oper + SIGN(1 - ABS(SIGN(ROUND(@rate_oper,6)))))) * SIGN(SIGN(@rate_oper) - 1) ) * @amt_net,@oper_precision) 
	WHERE	territory_code = @ter_code
	AND	@ter_flag > 0 
	AND	( LTRIM(@ter_code) IS NOT NULL AND LTRIM(@ter_code) != " " )  
	
	


	UPDATE	aractprc
	SET	amt_inv_unposted = amt_inv_unposted - ROUND(( SIGN(1 + SIGN(@rate_home))*(@rate_home) + (SIGN(ABS(SIGN(ROUND(@rate_home,6))))/(@rate_home + SIGN(1 - ABS(SIGN(ROUND(@rate_home,6)))))) * SIGN(SIGN(@rate_home) - 1) ) * @amt_net,@home_precision),
		amt_inv_unp_oper = amt_inv_unp_oper - ROUND(( SIGN(1 + SIGN(@rate_oper))*(@rate_oper) + (SIGN(ABS(SIGN(ROUND(@rate_oper,6))))/(@rate_oper + SIGN(1 - ABS(SIGN(ROUND(@rate_oper,6)))))) * SIGN(SIGN(@rate_oper) - 1) ) * @amt_net,@oper_precision) 
	WHERE	price_code = @prc_code
	AND	@prc_flag > 0 
	AND	@prc_code IS NOT NULL 
	
	



	DELETE	arinpchg			
	WHERE   trx_ctrl_num = @trx_num
	  AND	trx_type = @trx_type

	DELETE	arinpcdt			
	WHERE   trx_ctrl_num = @trx_num
	  AND	trx_type = @trx_type

	DELETE	arinptax			
	WHERE   trx_ctrl_num = @trx_num
	  AND	trx_type = @trx_type

	DELETE	arinpage			
	WHERE   trx_ctrl_num = @trx_num
	  AND	trx_type = @trx_type

	DELETE	arinpcom			
	WHERE   trx_ctrl_num = @trx_num
	  AND	trx_type = @trx_type

	DELETE	arinprev			
	WHERE   trx_ctrl_num = @trx_num
	  AND	trx_type = @trx_type

	DELETE	arinptmp			
	WHERE   trx_ctrl_num = @trx_num

	IF(@@trancount != 0)
	COMMIT TRAN 

	


	
	if exists(select tax_code from artax where tax_connect_flag = 1 and tax_code = @tax_code)
	begin
		declare @err_msg varchar(255)
		declare @rc int
		exec @rc = TXavataxlink_upd_sp @trx_num, @trx_type, 'DELETE', @err_msg
	end
	
	


	SELECT	@trx_done = @trx_done + 1
	SELECT	@perc_done = @trx_done / @total_trx * 100

END

/**/                                              
GO
GRANT EXECUTE ON  [dbo].[arinvvd_sp] TO [public]
GO
