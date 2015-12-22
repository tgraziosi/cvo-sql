SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[arcmvd_sp]	@posted_flag	smallint,
				@sys_date	int
AS




DECLARE	@trx_num	varchar(16),
		@trx_type	smallint,
		@total_trx	float,
		@tax_code varchar(8)

BEGIN

	


	SELECT	@total_trx = 0.0

	SELECT	@total_trx = COUNT( trx_ctrl_num )
	FROM	arinpchg
	WHERE	posted_flag = @posted_flag

	IF (( @total_trx IS NULL ) OR ((@total_trx) < (0.0) - 0.0000001) )
	BEGIN
		RETURN
	END

	WHILE ( 1 = 1 )
	BEGIN
		



		SELECT	@trx_num = NULL

		SET ROWCOUNT  1

		SELECT	@trx_num = trx_ctrl_num, 
			@trx_type = trx_type,
			@tax_code = tax_code
		FROM	arinpchg
		WHERE	posted_flag = @posted_flag
		ORDER	BY trx_ctrl_num

		SET ROWCOUNT  0

		


		IF ( @trx_num IS NULL )
		BEGIN
			RETURN
		END

		




		BEGIN TRAN

		


		INSERT	artrx
		(
			trx_ctrl_num,		doc_ctrl_num,		doc_desc,
			batch_code,		trx_type,		non_ar_flag,
			apply_to_num,		apply_trx_type,	gl_acct_code,
			date_posted,		date_applied,		date_doc,
			gl_trx_id,		customer_code,	payment_code,
			amt_net,		payment_type,		prompt1_inp,
			prompt2_inp,		prompt3_inp,		prompt4_inp,
			deposit_num,		void_flag,		amt_on_acct,
			paid_flag,		user_id,		posted_flag,
			date_entered,		date_paid,		order_ctrl_num,
			date_shipped,		date_required,	date_due,
			date_aging,		ship_to_code,		salesperson_code,
			territory_code,	comment_code,		fob_code,
			freight_code,		terms_code,		price_code,
			dest_zone_code,	posting_code,		recurring_flag,
			recurring_code,	cust_po_num,		amt_gross,
			amt_freight,		amt_tax,		amt_discount,
			amt_paid_to_date,	amt_cost,		amt_tot_chg,
			fin_chg_code,		tax_code,		commission_flag,
			cash_acct_code,	non_ar_doc_num,	purge_flag,
			nat_cur_code,		rate_type_home,	rate_type_oper,
			rate_home,		rate_oper,		amt_tax_included
		)
		SELECT	trx_ctrl_num,		doc_ctrl_num,		"VOID",
			batch_code,		trx_type,		0,
			apply_to_num,		apply_trx_type,	" ",
			@sys_date,		date_applied,		date_doc,
			" ",			customer_code,	" ",
			0,			0,			" ",
			" ",			" ",			" ",
			" ",			1,			0,
			0,			user_id,		1,
			date_entered,		0,			order_ctrl_num,
			date_shipped,		date_required,	date_due,
			date_aging,		ship_to_code,		salesperson_code,
			territory_code,	comment_code,		fob_code,
			freight_code,		terms_code,		price_code,
			dest_zone_code,	posting_code,		recurring_flag,
			recurring_code,	cust_po_num,		0,
			0,			0,			0,
			0,			0,			0,
			fin_chg_code,		tax_code,		0,
			" ",			" ",			0,
			nat_cur_code,		rate_type_home,	rate_type_oper,
			rate_home,		rate_oper,		0.0
		FROM	arinpchg
		WHERE	trx_ctrl_num = @trx_num
		AND	trx_type = @trx_type

		



		DELETE	arinpchg			
		WHERE	trx_ctrl_num = @trx_num
		AND	trx_type = @trx_type

		DELETE	arinpcdt			
		WHERE	trx_ctrl_num = @trx_num
		AND	trx_type = @trx_type

		DELETE	arinptax			
		WHERE	trx_ctrl_num = @trx_num
		AND	trx_type = @trx_type

		DELETE	arinpage			
		WHERE	trx_ctrl_num = @trx_num
		AND	trx_type = @trx_type

		DELETE	arinpcom			
		WHERE	trx_ctrl_num = @trx_num
		AND	trx_type = @trx_type

		DELETE	arinprev			
		WHERE	trx_ctrl_num = @trx_num
		AND	trx_type = @trx_type

		DELETE	arinptmp			
		WHERE  trx_ctrl_num = @trx_num

		COMMIT TRAN 

		


	
		if exists(select tax_code from artax where tax_connect_flag = 1 and tax_code = @tax_code)
		begin
			declare @err_msg varchar(255)
			declare @rc int
			exec @rc = TXavataxlink_upd_sp @trx_num, @trx_type, 'DELETE', @err_msg
		end

	END

END	
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[arcmvd_sp] TO [public]
GO
