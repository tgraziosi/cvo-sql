SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2008 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2008 Epicor Software Corporation, 2008    
                  All Rights Reserved                    
*/                                                

CREATE PROC [dbo].[arwrscrn_sp]	@all_cust_flag	smallint,
				@from_cust		varchar(8),	
				@thru_cust		varchar(8),
				@amt_max_wr		float,	
				@date_entered		int,
				@days_past_due	smallint,
				@trx_num		char(16),
				@trx_desc		char(40),
				@org_id			varchar(30),
				@date_applied		int,
				@hold_flag 		smallint,
				@smuserid		smallint,
				@writeoff_code		varchar(8),
				@err_msg		varchar(60)	OUTPUT
AS
BEGIN
	DECLARE	@sqid		int,		
			@wr_type	smallint,
			@result	int

	


	SELECT	@wr_type = 2151

	CREATE TABLE #arinppdt_wr
	(
		trx_ctrl_num         varchar(16),
		sequence_id          numeric identity,
		trx_type             smallint,
		apply_to_num         varchar(16),
		apply_trx_type	smallint,
		amt_applied		float, 
		customer_code        varchar(8),
		date_aging           int,
		line_desc            varchar(40),
		amt_tot_chg          float,
		amt_paid_to_date     float,
		terms_code           varchar(8),
		posting_code         varchar(8),
		date_doc             int,
		amt_inv              float,
		inv_cur_code		varchar(8),
		writeoff_code		varchar(8),
		org_id			varchar(30)
	)

	CREATE TABLE #arinppyt_wr
	(
		trx_ctrl_num         varchar(16),
		trx_desc             varchar(40),
		trx_type             smallint,
		date_entered         int,
		date_applied         int,
		date_doc             int,
		hold_flag		smallint,
		user_id              smallint,
		max_wr_off           float,
		days_past_due        int,
		org_id		     varchar(30)
	)

	IF ( @all_cust_flag = 1 )

		INSERT #arinppdt_wr
		(
			trx_ctrl_num,		trx_type,		apply_to_num,		
			apply_trx_type,		customer_code,		amt_applied,
			date_aging,		line_desc,		amt_tot_chg,		
			amt_paid_to_date,	terms_code,		posting_code,		
			date_doc,		amt_inv,		inv_cur_code,
			writeoff_code,          org_id
		)
		SELECT	@trx_num,		@wr_type,		doc_ctrl_num,
			trx_type,		customer_code,		case when	rate_home  > 0 then (amt_net-amt_paid_to_date) * rate_home else	(amt_net-amt_paid_to_date) / rate_home 	end,
			date_aging,		str_text,		amt_tot_chg,		
			amt_paid_to_date,	terms_code,		posting_code,
			date_doc,		amt_net,		nat_cur_code,
			@writeoff_code,		org_id
		FROM	artrx, glcurr_vw gl, arstrdef
		WHERE	artrx.nat_cur_code = gl.currency_code
		AND	trx_type = apply_trx_type
		AND	doc_ctrl_num = apply_to_num
		AND	trx_type IN (2021, 2031, 2071)
		AND	void_flag = 0
		AND	ABS((( amt_tot_chg - amt_paid_to_date ) * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ))) < ABS(@amt_max_wr)    
		AND	( @date_applied - date_due ) >= @days_past_due
		AND	arstrdef.str_id = 12
		AND 	org_id =  @org_id
		AND ((SIGN(artrx.amt_tot_chg - artrx.amt_paid_to_date) * ROUND(ABS(artrx.amt_tot_chg - artrx.amt_paid_to_date) + 0.000001, gl.curr_precision)) > ((0.0) + 0.000001))
		ORDER BY doc_ctrl_num
	ELSE

		INSERT #arinppdt_wr
		(
			trx_ctrl_num,		trx_type,		apply_to_num,
			apply_trx_type,		customer_code,		amt_applied,
			date_aging,		line_desc,		amt_tot_chg,		
			amt_paid_to_date,	terms_code,		posting_code,		
			date_doc,		amt_inv,		inv_cur_code,
			writeoff_code,		org_id
		)
		SELECT	@trx_num,		@wr_type,		doc_ctrl_num,
			trx_type,		customer_code,		case when	rate_home  > 0 then (amt_net-amt_paid_to_date) * rate_home else	(amt_net-amt_paid_to_date) / rate_home 	end,
			date_aging,		str_text,		amt_tot_chg,		
			amt_paid_to_date,	terms_code,		posting_code,
			date_doc,		amt_net,		nat_cur_code,
			@writeoff_code,		org_id
		FROM	artrx, glcurr_vw gl, arstrdef
		WHERE	customer_code BETWEEN @from_cust AND @thru_cust
		AND	artrx.nat_cur_code = gl.currency_code
		AND	trx_type = apply_trx_type
		AND	doc_ctrl_num = apply_to_num
		AND	trx_type IN (2021, 2031, 2071)
		AND	void_flag = 0
		AND	ABS((( amt_tot_chg - amt_paid_to_date ) * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ))) < ABS(@amt_max_wr)    
		AND	( @date_applied - date_due ) >= @days_past_due
		AND	arstrdef.str_id = 12
		AND    org_id =@org_id
		AND ((SIGN(artrx.amt_tot_chg - artrx.amt_paid_to_date) * ROUND(ABS(artrx.amt_tot_chg - artrx.amt_paid_to_date) + 0.000001, gl.curr_precision)) > ((0.0) + 0.000001))
		ORDER BY doc_ctrl_num

	DELETE	#arinppdt_wr
	FROM	arinppdt t
	WHERE	#arinppdt_wr.apply_to_num = t.apply_to_num
	AND	t.trx_type = 2151


	IF ( SELECT COUNT( trx_ctrl_num ) from #arinppdt_wr where (amt_tot_chg - amt_paid_to_date) <> 0 ) = 0
	BEGIN
		SELECT	@err_msg = str_text
		FROM	arstrdef
		WHERE	str_id = 14
		RETURN	
	END

	INSERT #arinppyt_wr
	(
		trx_ctrl_num,		trx_desc,		trx_type,
		date_entered,		date_applied,		date_doc,
		hold_flag,		user_id,		max_wr_off,		
		days_past_due,		org_id
	)
	VALUES
	(
		@trx_num,		@trx_desc,		@wr_type,
		@date_entered,	@date_applied,	@date_applied,
		@hold_flag,		@smuserid,		@amt_max_wr,
		@days_past_due,		@org_id
	)

	BEGIN TRAN


	INSERT arinppdt
	(
		trx_ctrl_num,		doc_ctrl_num,			sequence_id,		trx_type,
		apply_to_num,		apply_trx_type,		customer_code,	date_aging,
		amt_applied,		amt_disc_taken,		wr_off_flag,		amt_max_wr_off,
		void_flag,		line_desc,			sub_apply_type,	sub_apply_num,
		amt_tot_chg,		amt_paid_to_date,		terms_code,		posting_code,
		date_doc,		amt_inv,			gain_home,		gain_oper,
		inv_amt_applied,	inv_amt_disc_taken,		inv_amt_max_wr_off,	inv_cur_code,
		writeoff_code,		org_id
	)
	SELECT	trx_ctrl_num,		" ", 				sequence_id, 		trx_type,
		apply_to_num,		apply_trx_type,		customer_code,	date_aging,
		amt_applied,			0,				0,			0.0,
		0,			str_text,			0,			" ",
		amt_tot_chg,		amt_paid_to_date,		terms_code,		posting_code,
		date_doc,		amt_inv,			0,			0,
		amt_tot_chg - amt_paid_to_date,			0,				0,			inv_cur_code,
		writeoff_code,		org_id
	FROM	#arinppdt_wr, arstrdef
	WHERE	str_id = 12
	AND	(amt_tot_chg - amt_paid_to_date) <> 0

	IF ( @@error != 0 )
	BEGIN
		GOTO exitproc	
	END

	INSERT arinppyt
	(
		trx_ctrl_num,		doc_ctrl_num,		trx_desc,
		batch_code,		trx_type,		non_ar_flag,		non_ar_doc_num,
		gl_acct_code,		date_entered,		date_applied,		date_doc,
		customer_code,	payment_code,		payment_type,		amt_payment,
		amt_on_acct,		prompt1_inp,		prompt2_inp,		prompt3_inp,
		prompt4_inp,		deposit_num,		bal_fwd_flag,		printed_flag,
		posted_flag,		hold_flag,		wr_off_flag,		on_acct_flag,
		user_id,		max_wr_off,		days_past_due,	void_type,
		cash_acct_code,	origin_module_flag,	process_group_num,	nat_cur_code,
		rate_type_home,	rate_type_oper,	rate_home,		rate_oper,	org_id
	)
	SELECT trx_ctrl_num,		" ",			trx_desc,
		" ",			trx_type,		0,			" ",
		" ",			date_entered,		date_applied,		date_doc,
		" ",			" ",			0,			0.0,
		0.0,			" ",			" ",			" ",
		" ",			" ",			0,			0,
		0,			hold_flag,		0,			0,
		user_id,		max_wr_off,		days_past_due,	0,
		" ",			0,			" ",			" ",
		" ",			" ",			0.0,			0.0, org_id
	FROM #arinppyt_wr
	where	trx_ctrl_num in ( select trx_ctrl_num
				FROM	#arinppdt_wr, arstrdef
				WHERE	str_id = 12
				AND	(amt_tot_chg - amt_paid_to_date) <> 0)


exitproc:
	IF ( @@error != 0 )
	BEGIN
		ROLLBACK TRAN
		SELECT @result = 34563

		SELECT @err_msg = str_text
		FROM	arstrdef
		WHERE	str_id = 15
	END
	ELSE
	BEGIN
		COMMIT TRAN
		SELECT @result = 0

		SELECT @err_msg = str_text
		FROM	arstrdef
		WHERE	str_id = 13
	END

	DROP TABLE #arinppyt_wr
	DROP TABLE #arinppdt_wr

	RETURN
END

/**/                                              
GO
GRANT EXECUTE ON  [dbo].[arwrscrn_sp] TO [public]
GO
