SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_unapply_cashapp_trans_sp]	@process char(1),
												@cust_code	varchar(10),
												@doc_ctrl_num varchar(16),
												@prow_id int = 0,
												@date_from int = 0, -- v1.2
												@date_to int = 0 -- v1.2								
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	-- DECLARATIONS
	DECLARE	@row_id				int,
			@userid				int,
			@rows				int,
			@last_row_id		int,
			@pay_doc_number		varchar(16),
			@new_adj_num		varchar(16), 
			@num				int,
			@today				int,
			@period_end_date	int,
			@last_pay_doc		varchar(16),
			@sequence_id		int,
			@customer_code		varchar(10),
			@amt_applied		float,
			@date_aging			int,
			@amt_tot_chg		float,
			@amt_paid_to_date	float,
			@nat_cur_code		varchar(8),
			@writeoff_code		varchar(8),
			@detail_set			int,
			@date_doc			int,
			@payment_code		varchar(8),
			@deposit_num		varchar(16),
			@cash_acct_code		varchar(32),
			@rate_home			float,
			@rate_oper			float,
			@rate_type_home		varchar(8),
			@rate_type_oper		varchar(8),
			@adj_string			varchar(255),
			@payment_type		int, -- v1.1
			@age_trx_type		int, -- v1.1
			@trx_type			int -- v1.1

	-- PROCESSING
	SET @userid = user_id()
	SET @rows = 0
	SET @row_id = 0

	IF (@process = 'G')
	BEGIN
		DELETE	cvo_unapply_cashapp_hdr 
		WHERE	customer_code = @cust_code

		DELETE	cvo_unapply_cashapp_det 
		WHERE	payer_cust_code = @cust_code

		INSERT	cvo_unapply_cashapp_hdr (customer_code, doc_ctrl_num, entry_date, process_flag, userid)
		VALUES	(@cust_code, @doc_ctrl_num, DATEDIFF(day, '01/01/1900', GETDATE()) + 693596, 0, @userid)

		SET @row_id = @@IDENTITY

		CREATE TABLE #det_temp (
			row_id					int,
			seq_id					int IDENTITY(1,1),
			payer_cust_code			varchar(10),
			pay_doc_num				varchar(16),
			customer_code			varchar(10),
			doc_ctrl_num			varchar(16),
			trx_ctrl_num			varchar(16),
			applied_amount			float,
			date_applied			int) -- v1.3
	
		IF (@doc_ctrl_num = '')
			SET @doc_ctrl_num = NULL
		
		-- v1.2 Start
		IF (@date_to = 0)
			SET @date_to = 99999999
		-- v1.2 End

		INSERT	#det_temp (row_id, payer_cust_code, pay_doc_num, customer_code, doc_ctrl_num, trx_ctrl_num, applied_amount, date_applied) -- v1.3
		SELECT	@row_id, a.payer_cust_code, a.doc_ctrl_num, a.customer_code, a.apply_to_num, MIN(a.trx_ctrl_num), 
				SUM(CASE WHEN a.trx_type IN (2112, 2113) THEN (a.amt_applied * -1) ELSE a.amt_applied END), MIN(a.date_applied) -- v1.3
		FROM	artrxpdt a (NOLOCK)
		LEFT JOIN arvdcash_vw b (NOLOCK)
		ON		a.doc_ctrl_num = b.doc_ctrl_num
		AND		a.payer_cust_code = b.customer_code
		WHERE	a.payer_cust_code = @cust_code
		AND		(a.doc_ctrl_num = @doc_ctrl_num OR @doc_ctrl_num IS NULL) 
		AND		b.doc_ctrl_num IS NULL
-- v1.3	AND		a.date_applied >= @date_from -- v1.2
-- v1.3	AND		a.date_applied <= @date_to -- v1.2
		GROUP BY a.payer_cust_code, a.doc_ctrl_num, a.customer_code, a.apply_to_num
		HAVING ABS(SUM(CASE WHEN a.trx_type IN (2112, 2113) THEN (a.amt_applied * -1) ELSE a.amt_applied END)) > 0.01

		SET @rows = @@ROWCOUNT

		IF (@rows = 0)
		BEGIN
			DELETE	cvo_unapply_cashapp_hdr 
			WHERE	customer_code = @cust_code

			DROP TABLE #det_temp
			
			SELECT 0, @rows
			RETURN

		END

		-- v1.3 Start
		UPDATE	a
		SET		date_applied = b.date_applied
		FROM	#det_temp a
		JOIN	artrxage b (NOLOCK)
		ON		a.payer_cust_code = b.customer_code
		AND		a.pay_doc_num = b.doc_ctrl_num
		WHERE	b.trx_type = 2161
		AND		b.ref_id < 0 -- v1.4
-- v1.4	AND		b.ref_id = 0
		
		DELETE	#det_temp
		WHERE	date_applied < @date_from
		OR		date_applied > @date_to
		-- v1.3 End

		INSERT	cvo_unapply_cashapp_det
		SELECT	row_id, seq_id, payer_cust_code, pay_doc_num, customer_code, doc_ctrl_num, trx_ctrl_num, applied_amount, 0, NULL
		FROM	#det_temp

		DROP TABLE #det_temp

		SELECT	@row_id, @rows

		RETURN

	END

	IF (@process = 'P')
	BEGIN

		IF (@prow_id = 0)
		BEGIN
			SELECT 0, ''
			RETURN
		END

		IF NOT EXISTS (SELECT 1 FROM cvo_unapply_cashapp_det WHERE row_id = @prow_id AND process_flag = 1)
		BEGIN
			SELECT 0, ''
			RETURN
		END

		CREATE TABLE #pay_to_process (
			row_id			int IDENTITY(1,1),
			pay_doc_number	varchar(16),
			doc_ctrl_num	varchar(16),
			customer_code	varchar(10),
			amt_applied		float)

		INSERT	#pay_to_process (pay_doc_number, doc_ctrl_num, customer_code, amt_applied)
		SELECT	pay_doc_num, doc_ctrl_num, customer_code, applied_amount
		FROM	cvo_unapply_cashapp_det
		WHERE	row_id = @prow_id
		AND		process_flag = 1
		ORDER BY pay_doc_num ASC, doc_ctrl_num ASC

		EXEC appdate_sp @today OUTPUT, 0

		SELECT	@period_end_date = period_end_date
		FROM	arco

		IF (@period_end_date > @today)
			SET @period_end_date = @today

		SELECT	@writeoff_code = writeoff_code
		FROM	arcust
		WHERE	customer_code = @cust_code

		SET @last_row_id = 0
		SET @last_pay_doc = ''
		SET @sequence_id = 0
		SET @detail_set = 0
		SET @rows = 0
		SET @adj_string = ''

		SELECT	TOP 1 @row_id = row_id,
				@pay_doc_number = pay_doc_number,
				@doc_ctrl_num = doc_ctrl_num,
				@customer_code = customer_code,
				@amt_applied = amt_applied
		FROM	#pay_to_process
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC
		
		WHILE (@@ROWCOUNT <> 0)
		BEGIN

			IF (@last_pay_doc <> @pay_doc_number)
			BEGIN

				EXEC ARGetNextControl_SP 2010, @new_adj_num OUTPUT, @num OUTPUT 
				SET @sequence_id = 0
				SET @rows = @rows + 1
				SET @adj_string = @adj_string + RTRIM(@new_adj_num) + ', '
				SET @last_pay_doc = @pay_doc_number

				SELECT	@date_doc = date_doc,
						@payment_code = payment_code,					
						@deposit_num = deposit_num,
						@cash_acct_code = cash_acct_code,
						@nat_cur_code = nat_cur_code,
						@rate_home = rate_home,
						@rate_oper = rate_oper,
						@rate_type_home = rate_type_home,
						@rate_type_oper = rate_type_oper,
						@trx_type = trx_type -- v1.1
				FROM	artrx (NOLOCK)
				WHERE	customer_code = @cust_code
				AND		doc_ctrl_num = @pay_doc_number	
				AND		trx_type IN (2111, 2161) -- v1.1			
-- v1.1			AND		paid_flag = 1

				-- v1.1 Start
				SELECT	@age_trx_type = trx_type
				FROM	artrxage (NOLOCK)
				WHERE	customer_code = @cust_code
				AND		doc_ctrl_num = @pay_doc_number
				AND		trx_type IN (2111, 2161) -- v1.1

				IF (@age_trx_type = 2111 AND @trx_type = 2111)		
				BEGIN
					SET @payment_type = 1
				END
				ELSE
					SET @payment_type = 3

				SET @amt_tot_chg = 0 
				-- v1.1 End

				SELECT	@amt_tot_chg = ABS(amount)
				FROM	artrxage (NOLOCK)
				WHERE	customer_code = @cust_code
				AND		doc_ctrl_num = @pay_doc_number
				AND		trx_type IN (2111, 2161)
				AND		apply_trx_type IN (2111, 2161)
				AND		ref_id = 0

				-- v1.1 Start
				IF (@amt_tot_chg = 0)
				BEGIN
					SELECT	@amt_tot_chg = amt_net
					FROM	artrx (NOLOCK)
					WHERE	customer_code = @cust_code
					AND		doc_ctrl_num = @pay_doc_number
					AND		trx_type IN (2111, 2161)

					SET @payment_type = 1
				END
				-- v1.1 End

				INSERT arvdcash_vw (trx_ctrl_num, doc_ctrl_num, trx_desc, batch_code, trx_type, non_ar_flag, non_ar_doc_num, gl_acct_code, date_entered, date_applied,
						date_doc, customer_code, payment_code, payment_type, amt_payment, amt_on_acct, prompt1_inp, prompt2_inp, prompt3_inp, prompt4_inp, deposit_num,
						bal_fwd_flag, printed_flag, posted_flag, hold_flag, wr_off_flag, on_acct_flag, user_id, max_wr_off, days_past_due, void_type, cash_acct_code,
						nat_cur_code, rate_type_home, rate_type_oper, rate_home, rate_oper, amt_discount, reference_code, org_id)
				SELECT	@new_adj_num, @pay_doc_number, '', '', 2121, 0, '', '', @today, @today, @date_doc, @cust_code, @payment_code, @payment_type, @amt_tot_chg, 0, '', '', '', '',
						@deposit_num, 0, 0, 0, 0, 0, 0, @userid, 0, 0, 3, @cash_acct_code, @nat_cur_code, @rate_type_home, @rate_type_oper, @rate_home, @rate_oper, 0, '', 'CVO'

			END
			
			SET @detail_set = 1

			SELECT	@date_aging = date_aging,
					@amt_tot_chg = amount,
					@amt_paid_to_date = amt_paid,
					@nat_cur_code = nat_cur_code,
					@date_doc = date_doc
			FROM	artrxage (NOLOCK)
			WHERE	customer_code = @customer_code
			AND		doc_ctrl_num = @doc_ctrl_num
			
			SELECT	@sequence_id = MAX(sequence_id) 
			FROM	artrxpdt (NOLOCK)
			WHERE	payer_cust_code = @cust_code
			AND		doc_ctrl_num = @pay_doc_number
			AND		apply_to_num = @doc_ctrl_num

			IF (@sequence_id IS NULL)
				SET @sequence_id = 1

			INSERT arinppdt (trx_ctrl_num, doc_ctrl_num, sequence_id, trx_type, apply_to_num, apply_trx_type, customer_code, date_aging, amt_applied,
					amt_disc_taken, wr_off_flag, amt_max_wr_off, void_flag, line_desc, sub_apply_num, sub_apply_type, amt_tot_chg, amt_paid_to_date, 
					terms_code, posting_code, date_doc, amt_inv, gain_home, gain_oper, inv_amt_applied, inv_amt_disc_taken, inv_amt_max_wr_off,
					inv_cur_code, writeoff_code, writeoff_amount, cross_rate, org_id)
			SELECT	@new_adj_num, @pay_doc_number, @sequence_id, 2121, @doc_ctrl_num, 2031, @customer_code, @date_aging, @amt_applied, 0, 0, 0, 1, '', @doc_ctrl_num,
					2031, @amt_tot_chg, @amt_paid_to_date, '', '', @date_doc, @amt_tot_chg, 0, 0, @amt_applied, 0, 0, @nat_cur_code, @writeoff_code, NULL, NULL, 'CVO' 	


			SET @last_row_id = @row_id

			SELECT	TOP 1 @row_id = row_id,
					@pay_doc_number = pay_doc_number,
					@doc_ctrl_num = doc_ctrl_num,
					@customer_code = customer_code,
					@amt_applied = amt_applied
			FROM	#pay_to_process
			WHERE	row_id > @last_row_id
			ORDER BY row_id ASC

		END

		IF (@detail_set > 0)
		BEGIN
			SET @adj_string = LEFT(@adj_string,LEN(@adj_string) - 1)
			SELECT @rows, @adj_string
		END
		ELSE
		BEGIN
			SELECT 0, ''
		END
	END

END
GO
GRANT EXECUTE ON  [dbo].[cvo_unapply_cashapp_trans_sp] TO [public]
GO
