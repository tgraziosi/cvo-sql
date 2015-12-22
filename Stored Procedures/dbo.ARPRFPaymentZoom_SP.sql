SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARPRFPaymentZoom_SP]	@doc_ctrl_num		varchar( 16 ),
					@apply_trx_type1	smallint,
					@apply_trx_type2	smallint,
					@trx_type1		smallint,
					@trx_type2		smallint
AS
BEGIN
	DELETE #arinptmp

	INSERT INTO #arinptmp 
	( 
		trx_ctrl_num, 
		doc_ctrl_num, 
		date_applied, 
		amt_applied, 
		amt_disc_taken, 
		amt_wr_off, 
		trx_type, 
		customer_code, 
		nat_cur_code, 
		sequence_id, 
		amt_mask, 
		invoice_mask 
	) 
	SELECT	a.trx_ctrl_num, 
		a.doc_ctrl_num, 
		a.date_applied, 
		a.amt_applied, 
		a.inv_amt_disc_taken, 
		a.inv_amt_wr_off, 
		a.trx_type,
		a.payer_cust_code,
		a.inv_cur_code,
		a.sequence_id, 
		g2.currency_mask,
		g2.currency_mask 
	FROM	artrxpdt a, glcurr_vw g2 
	WHERE	a.apply_to_num = @doc_ctrl_num
	AND	a.apply_trx_type IN ( @apply_trx_type1, @apply_trx_type2 ) 
	AND	a.trx_type in (@trx_type1, @trx_type2) 
	AND	a.void_flag = 0 
	AND	a.inv_cur_code = g2.currency_code 

	UPDATE	#arinptmp
	SET	nat_cur_code = trx.nat_cur_code,
		amt_mask = g.currency_mask
	FROM	artrx trx, glcurr_vw g
	WHERE	#arinptmp.doc_ctrl_num = trx.doc_ctrl_num
	AND	trx.trx_type = @trx_type1
	AND	trx.nat_cur_code = g.currency_code
END
GO
GRANT EXECUTE ON  [dbo].[ARPRFPaymentZoom_SP] TO [public]
GO
