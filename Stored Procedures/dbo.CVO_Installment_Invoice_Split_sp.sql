SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[CVO_Installment_Invoice_Split_sp]
AS
BEGIN
	-- DECLARATIONS
	DECLARE	@terms_code			varchar(8),
			@st_cycle_code		varchar(8),
			@trx_ctrl_num		varchar(16),
			@last_trx_ctrl_num	varchar(16),
			@customer_code		varchar(8),
			@statement_day		int,
			@date_doc			int,
			@orig_date_doc		int,
			@date_due			int,
			@statement_date		int,
			@install_no			int,
			@last_install_no	int,
			@install_days		int,
			@install_prc		decimal(20,8),
			@install_count		int,
			@install_num		int,
			@install_split		decimal(20,8),
			@amt_gross			decimal(20,8),
			@amt_freight		decimal(20,8),
			@amt_tax			decimal(20,8),
			@amt_tax_included	decimal(20,8),
			@amt_discount		decimal(20,8),
			@amt_net			decimal(20,8),
			@amt_due			decimal(20,8),
			@amt_gross_s		decimal(20,8),
			@amt_freight_s		decimal(20,8),
			@amt_tax_s			decimal(20,8),
			@amt_tax_included_s	decimal(20,8),
			@amt_discount_s		decimal(20,8),
			@amt_net_s			decimal(20,8),
			@amt_due_s			decimal(20,8),
			@amt_gross_r		decimal(20,8),
			@amt_freight_r		decimal(20,8),
			@amt_tax_r			decimal(20,8),
			@amt_tax_included_r	decimal(20,8),
			@amt_discount_r		decimal(20,8),
			@amt_net_r			decimal(20,8),
			@amt_due_r			decimal(20,8),
			@doc_ctrl_num		varchar(16),
			@new_doc_ctrl_num	varchar(16),
			@new_trx_ctrl_num	varchar(16),
			@first				smallint,
			@num				int,
			@clearing_acct		varchar(32),
			@acct_not_set		smallint,
			@date_applied		int,
			@date_entered		int,
			@user_id			int,
			@org_id				varchar(30),
			@result				smallint,
			@trx_type			int, -- v1.6
			@alter				int, --v1.7
			@st_alter			int -- v1.8

	-- WORKING TABLES
	IF OBJECT_ID('tempdb..#temp_arinpchg') IS NOT NULL DROP TABLE #temp_arinpchg
	IF OBJECT_ID('tempdb..#temp_arinpcdt') IS NOT NULL DROP TABLE #temp_arinpcdt
	IF OBJECT_ID('tempdb..#temp_arinpage') IS NOT NULL DROP TABLE #temp_arinpage
	IF OBJECT_ID('tempdb..#temp_arinptax') IS NOT NULL DROP TABLE #temp_arinptax

	SELECT * INTO #temp_arinpchg FROM #arinpchg WHERE 1 = 2
	SELECT * INTO #temp_arinpcdt FROM #arinpcdt WHERE 1 = 2
	SELECT * INTO #temp_arinpage FROM #arinpage WHERE 1 = 2
	SELECT * INTO #temp_arinptax FROM #arinptax WHERE 1 = 2

	IF @@ERROR <> 0
		RETURN -1

	-- Get the clearing acct from the config
	SELECT	@clearing_acct = value_str
	FROM	dbo.config (NOLOCK)
	WHERE	flag = 'INSTALL CLEAR ACCT'
	
	-- If the clearing acct has not been set up then just to the due dates
	IF ISNULL(@clearing_acct,'') = ''
		SET @acct_not_set = 1
	ELSE
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM dbo.glchart WHERE account_code = @clearing_acct 
						AND inactive_flag = 0)
			SET @acct_not_set = 1
		ELSE
			SET @acct_not_set = 0
	END

	-- Loop through each invoice being created
	-- Check the statement cycle and if there are any installment terms
	-- The statement date will always be applied

	SET	@last_trx_ctrl_num = ''

	SELECT	TOP 1 @trx_ctrl_num = trx_ctrl_num,
			@customer_code = customer_code,
			@terms_code = terms_code,
			@date_doc = date_doc,
			@doc_ctrl_num = doc_ctrl_num,
			@date_applied = date_applied,
			@date_entered = date_entered,
			@user_id = user_id,
			@org_id = org_id,
			@trx_type = trx_type -- v1.6
	FROM	#arinpchg
	WHERE	trx_type IN (2031,2032) -- v1.6
	AND		trx_ctrl_num > @last_trx_ctrl_num
	ORDER BY trx_ctrl_num ASC

	WHILE @@ROWCOUNT <> 0
	BEGIN

		-- v1.6
		IF @trx_type = 2032
			SET @acct_not_set = 1

		-- Check if there are any installments
		IF NOT EXISTS (SELECT 1 FROM dbo.cvo_artermsd_installment WHERE terms_code = @terms_code)
						OR @acct_not_set = 1
		BEGIN
			-- If there are no installments then just calc the due date			
			EXEC dbo.CVO_CalcDueDate_sp @customer_code, @date_doc, @date_due OUTPUT, @terms_code

			IF @@ERROR <> 0
				RETURN -1


			-- Update the invoice with the statement date
			UPDATE	#arinpchg
			SET		date_due = @date_due,
					date_aging = @date_due,
					date_required = @date_due
			WHERE	trx_ctrl_num = @trx_ctrl_num

			IF @@ERROR <> 0
				RETURN -1


			UPDATE	#arinpage
			SET		date_due = @date_due,
					date_aging = @date_due
			WHERE	trx_ctrl_num = @trx_ctrl_num

			IF @@ERROR <> 0
				RETURN -1

		END
		ELSE
		BEGIN
			-- Installments exist so we need to split up the invoices
			-- Loop through each installment		

			-- Get the invoice values
			SELECT	@amt_gross = amt_gross,
					@amt_gross_r = amt_gross,
					@amt_freight = amt_freight,
					@amt_freight_r = amt_freight,
					@amt_tax = amt_tax,
					@amt_tax_r = amt_tax,
					@amt_tax_included = amt_tax_included,
					@amt_tax_included_r = amt_tax_included,
					@amt_discount = amt_discount,
					@amt_discount_r = amt_discount,
					@amt_net = amt_net,
					@amt_net_r = amt_net,
					@amt_due = amt_due,
					@amt_due_r = amt_due,
					@orig_date_doc = date_doc
			FROM	#arinpchg
			WHERE	trx_ctrl_num = @trx_ctrl_num

			-- Get some base values
			SELECT	@install_count = COUNT(1)
			FROM	dbo.cvo_artermsd_installment (NOLOCK)
			WHERE	terms_code = @terms_code

			-- Calc the split
			SET @install_split = (100.00 / CAST(@install_count AS decimal(20,8))) / 100.00

			IF @@ERROR <> 0
				RETURN -1

			SET @last_install_no = 0
			SET @install_num = 0
			SET @first = 1

			SELECT	TOP 1 @install_no = sequence_id,
					@install_days =	installment_days,
					@install_prc = installment_prc
			FROM	dbo.cvo_artermsd_installment (NOLOCK)
			WHERE	terms_code = @terms_code
			AND		sequence_id > @last_install_no
			ORDER BY sequence_id ASC

			WHILE @@ROWCOUNT <> 0
			BEGIN

				-- Increment the installment
				SET @install_num = @install_num + 1

				-- Set the document number
				SET @new_doc_ctrl_num = @doc_ctrl_num + '-' + LTRIM(RTRIM(STR(@install_num)))
		
				-- If this is the first invoice then use the trx_ctrl_num already generated
				-- otherwise we need to get one
				IF @first = 1
				BEGIN
					EXEC dbo.CVO_CalcDueDate_sp @customer_code, @date_doc, @statement_date OUTPUT				
					SET @new_trx_ctrl_num = @trx_ctrl_num
					SET @first = 0
				END
				ELSE
				BEGIN
					EXEC dbo.ARGetNextControl_SP	2000,
													@new_trx_ctrl_num OUTPUT, 
													@num OUTPUT
					
					IF @@ERROR <> 0
						RETURN -1

				END

				-- Calculate the new due date
				-- v1.7 Start
				SET	@alter = 0
				IF (DATEPART(month,DATEADD(day,@date_doc-693596,'1900-01-01')) = 2) -- In February
				BEGIN
--					IF (DATEPART(day,DATEADD(day,@date_doc-693596,'1900-01-01')) > 22) -- v1.8
						SET @alter = 3
				END

--				SET @date_doc = @statement_date + @install_days - @alter -- Force Calc					
				-- v1.7 End

				-- v1.8 Start
				SET	@st_alter = 0
				IF (DATEPART(month,DATEADD(day,@statement_date-693596,'1900-01-01')) = 2) -- In February
				BEGIN
--					IF (DATEPART(day,DATEADD(day,@date_doc-693596,'1900-01-01')) > 22)
						SET @st_alter = 3
				END

				SET @date_doc = @statement_date - @st_alter + @install_days - @alter -- Force Calc					
				-- v1.8 End

				EXEC dbo.CVO_CalcDueDate_sp @customer_code, @date_doc, @date_due OUTPUT

				IF @@ERROR <> 0
					RETURN -1

				-- If an installment prc has been specified then use this instead of an equal split
				IF @install_prc <> 0.00
					SET	@install_split = (@install_prc / 100)

				-- If we are on the last installment then need to use the remainder rather than a calc
				IF @install_num = @install_count
				BEGIN
					SELECT	@amt_gross_s = @amt_gross_r,
							@amt_freight_s = @amt_freight_r,
							@amt_tax_s = @amt_tax_r,
							@amt_tax_included_s = @amt_tax_included_r,
							@amt_discount_s = @amt_discount_r,
							@amt_net_s = @amt_net_r,
							@amt_due_s = @amt_due_r
				END
				ELSE
				BEGIN
					-- Calc the split invoice values
					SELECT	@amt_gross_s = ROUND(@amt_gross * @install_split,2),
							@amt_freight_s = ROUND(@amt_freight * @install_split,2),
							@amt_tax_s = ROUND(@amt_tax * @install_split,2),
							@amt_tax_included_s = ROUND(@amt_tax_included * @install_split,2),
							@amt_discount_s = ROUND(@amt_discount * @install_split,2),
							@amt_net_s = @amt_gross_s + @amt_freight_s + @amt_tax_s - @amt_discount_s,
							@amt_due_s = @amt_gross_s + @amt_freight_s + @amt_tax_s - @amt_discount_s

--							@amt_net_s = ROUND(@amt_net * @install_split,2),
--							@amt_due_s = ROUND(@amt_due * @install_split,2)

					IF @@ERROR <> 0
						RETURN -1
							
					-- Set the remainder
					SELECT	@amt_gross_r = @amt_gross_r - @amt_gross_s,
							@amt_freight_r = @amt_freight_r - @amt_freight_s,
							@amt_tax_r = @amt_tax_r - @amt_tax_s,
							@amt_tax_included_r	= @amt_tax_included_r - @amt_tax_included_s,
							@amt_discount_r	= @amt_discount_r - @amt_discount_s,
							@amt_net_r = @amt_net_r - @amt_net_s,
							@amt_due_r = @amt_due_r - @amt_due_s
				
				END

				-- Create the new invoice records
				-- arinchg - invoice header
				INSERT	#temp_arinpchg (trx_ctrl_num, doc_ctrl_num, doc_desc, apply_to_num,
							apply_trx_type, order_ctrl_num, batch_code, trx_type, date_entered, 
							date_applied, date_doc, date_shipped, date_required, date_due, date_aging, 
							customer_code, ship_to_code, salesperson_code, territory_code, comment_code, 
							fob_code, freight_code, terms_code, fin_chg_code, price_code, dest_zone_code, 
							posting_code, recurring_flag, recurring_code, tax_code, cust_po_num,  
							total_weight, amt_gross, amt_freight, amt_tax, amt_tax_included, amt_discount, 
							amt_net, amt_paid, amt_due, amt_cost, amt_profit, next_serial_id, printed_flag, 
							posted_flag, hold_flag, hold_desc, user_id, customer_addr1, customer_addr2,
							customer_addr3, customer_addr4, customer_addr5, customer_addr6, ship_to_addr1,
							ship_to_addr2, ship_to_addr3, ship_to_addr4, ship_to_addr5, ship_to_addr6, 
							attention_name, attention_phone, amt_rem_rev, amt_rem_tax, date_recurring, 
							location_code, process_group_num, trx_state, mark_flag, amt_discount_taken,
							amt_write_off_given, source_trx_ctrl_num, source_trx_type, nat_cur_code, 
							rate_type_home, rate_type_oper, rate_home, rate_oper, edit_list_flag, ddid, 
							org_id, customer_city, customer_state, customer_postal_code, customer_country_code,
							ship_to_city, ship_to_state, ship_to_postal_code, ship_to_country_code, writeoff_code)
				SELECT	@new_trx_ctrl_num, @new_doc_ctrl_num, doc_desc, apply_to_num,
						apply_trx_type, order_ctrl_num, batch_code, trx_type, date_entered, 
						date_applied, date_doc, date_shipped, @statement_date, @date_due, @date_due, 
						customer_code, ship_to_code, salesperson_code, territory_code, comment_code, 
						fob_code, freight_code, terms_code, fin_chg_code, price_code, dest_zone_code, 
						posting_code, recurring_flag, recurring_code, tax_code, cust_po_num,						-- v1.5
						total_weight, @amt_gross_s, @amt_freight_s, @amt_tax_s, @amt_tax_included_s, 
						@amt_discount_s, @amt_net_s, amt_paid, @amt_due_s, amt_cost, amt_profit, next_serial_id, 
						printed_flag, posted_flag, hold_flag, hold_desc, user_id, customer_addr1, 
						customer_addr2, customer_addr3, customer_addr4, customer_addr5, customer_addr6, 
						ship_to_addr1, ship_to_addr2, ship_to_addr3, ship_to_addr4, ship_to_addr5, ship_to_addr6, 
						attention_name, attention_phone, amt_rem_rev, amt_rem_tax, date_recurring, 
						location_code, process_group_num, trx_state, mark_flag, amt_discount_taken,
						amt_write_off_given, source_trx_ctrl_num, source_trx_type, nat_cur_code, 
						rate_type_home, rate_type_oper, rate_home, rate_oper, edit_list_flag, ddid, 
						org_id, customer_city, customer_state, customer_postal_code, customer_country_code,
						ship_to_city, ship_to_state, ship_to_postal_code, ship_to_country_code, writeoff_code
				FROM	#arinpchg
				WHERE	trx_ctrl_num = @trx_ctrl_num	
			
				IF @@ERROR <> 0
					RETURN -1

				-- arinpcdt - invoice detail - Only one line
				INSERT	#temp_arinpcdt (trx_ctrl_num, doc_ctrl_num, sequence_id, trx_type, location_code, 
							item_code, bulk_flag, date_entered, line_desc, qty_ordered, qty_shipped, 
							unit_code, unit_price, unit_cost, weight, serial_id, tax_code, gl_rev_acct, 
							disc_prc_flag, discount_amt, commission_flag, rma_num, return_code, qty_returned, 
							qty_prev_returned, new_gl_rev_acct, iv_post_flag, oe_orig_flag, discount_prc, 
							extended_price, calc_tax, reference_code, trx_state, mark_flag, cust_po,org_id)
				SELECT	TOP 1@new_trx_ctrl_num, @new_doc_ctrl_num, sequence_id, trx_type, '', 
						'', bulk_flag, date_entered, 'Installment Invoice', 1, 1, 
						unit_code, @amt_gross_s, unit_cost, weight, serial_id, tax_code, @clearing_acct, 
						0, @amt_discount_s, commission_flag, rma_num, return_code, qty_returned, 
						qty_prev_returned, new_gl_rev_acct, iv_post_flag, oe_orig_flag, @amt_discount_s, 
						@amt_gross_s - @amt_discount_s, @amt_tax_s, reference_code, trx_state, mark_flag, cust_po,org_id
				FROM	#arinpcdt
				WHERE	trx_ctrl_num = @trx_ctrl_num

				IF @@ERROR <> 0
					RETURN -1

				-- arinpage - invoice aging - Only one line
				INSERT	#temp_arinpage (trx_ctrl_num, sequence_id, doc_ctrl_num, apply_to_num, apply_trx_type, 
							trx_type, date_applied, date_due, date_aging, customer_code, salesperson_code, 
							territory_code, price_code, amt_due, trx_state, mark_flag)
				SELECT	TOP 1 @new_trx_ctrl_num, 1, @new_doc_ctrl_num, apply_to_num, apply_trx_type, 
						trx_type, date_applied, @date_due, @date_due, customer_code, salesperson_code, 
						territory_code, price_code, @amt_due_s, trx_state, mark_flag
				FROM	#arinpage
				WHERE	trx_ctrl_num = @trx_ctrl_num

				IF @@ERROR <> 0
					RETURN -1

				-- arinptax - invoice tax
				INSERT	#temp_arinptax (trx_ctrl_num, trx_type, sequence_id, tax_type_code, amt_taxable,
							amt_gross, amt_tax, amt_final_tax, trx_state, mark_flag)
				SELECT	TOP 1 @new_trx_ctrl_num, trx_type, 1, tax_type_code, @amt_gross_s - @amt_discount_s,
						@amt_gross_s - @amt_discount_s, @amt_tax_s, @amt_tax_s, trx_state, mark_flag
				FROM	#arinptax
				WHERE	trx_ctrl_num = @trx_ctrl_num

				IF @@ERROR <> 0
					RETURN -1

				SET @last_install_no = @install_no

				SELECT	TOP 1 @install_no = sequence_id,
						@install_days =	installment_days,
						@install_prc = installment_prc
				FROM	dbo.cvo_artermsd_installment (NOLOCK)
				WHERE	terms_code = @terms_code
				AND		sequence_id > @last_install_no
				ORDER BY sequence_id ASC

			END		

			-- Generate the GL Journal for the installment
			EXEC @result = dbo.CVO_Invoice_Split_GL_Journal_sp @trx_ctrl_num, @date_applied, @date_entered, @user_id, @org_id

			IF @@ERROR <> 0 OR @result <> 0
				RETURN -1

		END

		SET	@last_trx_ctrl_num = @trx_ctrl_num

		SELECT	TOP 1 @trx_ctrl_num = trx_ctrl_num,
				@customer_code = customer_code,
				@terms_code = terms_code,
				@date_doc = date_doc,
				@doc_ctrl_num = doc_ctrl_num,
				@date_applied = date_applied,
				@date_entered = date_entered,
				@user_id = user_id,
				@org_id = org_id,
				@trx_type = trx_type -- v1.6
		FROM	#arinpchg
		WHERE	trx_type IN (2031,2032) -- v1.6
		AND		trx_ctrl_num > @last_trx_ctrl_num
		ORDER BY trx_ctrl_num ASC

	END
	
	-- Are there any records to process
	IF EXISTS(SELECT 1 FROM #temp_arinpchg)
	BEGIN
		-- Remove the existing invoice record and replace with the installments
		DELETE	a
		FROM	#arinptax a
		JOIN	#temp_arinpchg b
		ON		a.trx_ctrl_num = b.trx_ctrl_num

		DELETE	a
		FROM	#arinpage a
		JOIN	#temp_arinpchg b
		ON		a.trx_ctrl_num = b.trx_ctrl_num

		DELETE	a
		FROM	#arinpcdt a
		JOIN	#temp_arinpchg b
		ON		a.trx_ctrl_num = b.trx_ctrl_num

		DELETE	a
		FROM	#arinpchg a
		JOIN	#temp_arinpchg b
		ON		a.trx_ctrl_num = b.trx_ctrl_num

		-- Insert the new records
		INSERT	#arinpchg
		SELECT * FROM #temp_arinpchg

		IF @@ERROR <> 0
			RETURN -1

		INSERT	#arinpcdt
		SELECT * FROM #temp_arinpcdt

		IF @@ERROR <> 0
			RETURN -1

		INSERT	#arinpage
		SELECT * FROM #temp_arinpage

		IF @@ERROR <> 0
			RETURN -1

		INSERT	#arinptax
		SELECT * FROM #temp_arinptax

		IF @@ERROR <> 0
			RETURN -1

	END

	-- Clean up
	DROP TABLE #temp_arinpchg
	DROP TABLE #temp_arinpcdt
	DROP TABLE #temp_arinpage
	DROP TABLE #temp_arinptax

	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[CVO_Installment_Invoice_Split_sp] TO [public]
GO
