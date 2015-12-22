SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE  PROCEDURE [dbo].[arinsav2_sp]  @proc_user_id smallint, @new_batch_code varchar(16) OUTPUT
				
AS
DECLARE 
	@tran_started		smallint,
	@batch_module_id	smallint, 
	@batch_date_applied	int,            
	@batch_source		varchar(16),
	@batch_trx_type   	smallint,
	@trx_type         	smallint,
	@home_company     	varchar(8),
	@result           	smallint,
	@cus_flag        	smallint,
	@shp_flag         	smallint,
	@prc_flag         	smallint,
	@ter_flag         	smallint,
	@slp_flag		smallint,
	@bat_count		int
BEGIN
	SELECT  @tran_started = 0
	SELECT	@new_batch_code = ' '
	
	SELECT	@home_company = company_code 
	FROM	glco
	IF( @@error != 0 )
		RETURN 34563

	



	IF EXISTS(    SELECT  *
			FROM    arco
			WHERE   batch_proc_flag = 1 )
	BEGIN
		



		INSERT  #arinbat
		(
			date_applied,		process_group_num,	trx_type,
			flag,			batch_ctrl_num, 	org_id 
		)
		SELECT  DISTINCT date_applied, 	process_group_num,	trx_type,
			0,			"",	org_id  
		FROM    #arinpchg

		IF( @@error != 0 )
			RETURN 34563

		SELECT	@bat_count = count(*)
		FROM	#arinbat
		
		WHILE ( @bat_count > 0 )
		BEGIN
			INSERT INTO #arbatnum
			(
				date_applied,	process_group_num,	trx_type,
				flag,	org_id 
			)
			SELECT	date_applied,	process_group_num,	trx_type,
				flag,	org_id  
			FROM	#arinbat
			WHERE	flag = 0

			EXEC ARCreateBatchBlock_SP	@proc_user_id

			UPDATE	#arinbat
			SET	batch_ctrl_num = batnum.batch_ctrl_num,
				flag = batnum.flag
			FROM	#arbatnum batnum
			WHERE	batnum.flag = 1
			AND	batnum.date_applied = #arinbat.date_applied
			AND	batnum.process_group_num = #arinbat.process_group_num
			AND	batnum.trx_type = #arinbat.trx_type
			AND	batnum.org_id = #arinbat.org_id 

			DELETE	#arbatnum

			SELECT	@bat_count = count(*)
			FROM	#arinbat
			WHERE	flag = 0
			
		END

		UPDATE	#arinpchg
		SET	batch_code = batch_ctrl_num
		FROM	#arinbat
		WHERE	#arinbat.date_applied = #arinpchg.date_applied
		AND	#arinbat.process_group_num = #arinpchg.process_group_num
		AND	#arinbat.trx_type = #arinpchg.trx_type
		AND 	#arinbat.org_id	= #arinpchg.org_id	

		INSERT INTO #arbatsum
		(
			batch_ctrl_num,	actual_number,	actual_total
		)
		SELECT	batch_code,	count(*),	sum(amt_net)
		FROM	#arinpchg
		GROUP BY batch_code

		UPDATE	batchctl
		SET	actual_number = batsum.actual_number,
			actual_total = batsum.actual_total
		FROM	#arbatsum batsum
		WHERE	batsum.batch_ctrl_num = batchctl.batch_ctrl_num

		DELETE	#arbatsum

		



		SET rowcount 1

		SELECT	@new_batch_code = batch_ctrl_num
		FROM	#arinbat

		SET rowcount 0
	END
	ELSE
	BEGIN
		





		UPDATE  #arinpchg
		SET     batch_code = ' '
		IF ( @@error != 0 )
		BEGIN
			RETURN  34563
		END
	END
		
	




	IF ( @@trancount = 0 )
	BEGIN
		BEGIN TRANSACTION
		SELECT  @tran_started = 1
	END

	


	EXEC    @result = arinupa2_sp
	IF ( @result != 0 )
	BEGIN
		IF( @tran_started = 1 )
			ROLLBACK TRAN
		RETURN  @result
	END




	


	INSERT	arcdtext
	(
			trx_ctrl_num,
			trx_type,
			serial_id,
			ord_ctrl_num,
			iv_trx_ctrl_num,
			iv_trx_type
	)
	SELECT
			trx_ctrl_num,
			trx_type,
			serial_id,
			ord_ctrl_num,
			iv_trx_ctrl_num,
			iv_trx_type
	FROM
			#arcdtext

	IF (@@error != 0)
	BEGIN
		ROLLBACK 
TRAN		RETURN (-1)
	END



	





	INSERT arinpage  
	(
		trx_ctrl_num,		sequence_id,
		doc_ctrl_num,		apply_to_num,			apply_trx_type,
		trx_type,		date_applied,			date_due,
		date_aging,		customer_code,		salesperson_code,
		territory_code,	price_code,			amt_due
	)
	SELECT  
		trx_ctrl_num,		sequence_id,
		doc_ctrl_num,		apply_to_num,			apply_trx_type,
		trx_type,		date_applied,			date_due,
		date_aging,		customer_code,		salesperson_code,
		territory_code,	price_code,			amt_due
	FROM    #arinpage
	IF ( @@error != 0 )
	BEGIN
		IF( @tran_started = 1 )
			ROLLBACK TRAN
		RETURN  34563
	END

	


	INSERT  arinpcdt 
	(
		trx_ctrl_num,		doc_ctrl_num,
		sequence_id,		trx_type,			location_code,
		item_code,		bulk_flag,			date_entered,
		line_desc,		qty_ordered,			qty_shipped,
		unit_code,		unit_price,			unit_cost,
		weight,		serial_id,			tax_code,
		gl_rev_acct,		disc_prc_flag,		discount_amt,
		commission_flag,	rma_num,			return_code,
		qty_returned,		qty_prev_returned,		new_gl_rev_acct,
		iv_post_flag,		oe_orig_flag,			extended_price,
		discount_prc,		calc_tax,			cust_po
	)				
	SELECT  
		trx_ctrl_num,		doc_ctrl_num,
		sequence_id,		trx_type,			location_code,
		item_code,		bulk_flag,			date_entered,
		line_desc,		qty_ordered,			qty_shipped,
		unit_code,		unit_price,			unit_cost,
		weight,		serial_id,			tax_code,
		gl_rev_acct,		disc_prc_flag,		discount_amt,
		commission_flag,	rma_num,			return_code,
		qty_returned,		qty_prev_returned,		new_gl_rev_acct,
		iv_post_flag,		oe_orig_flag,			extended_price,
		discount_prc,		calc_tax,			cust_po
	FROM    #arinpcdt
	IF ( @@error != 0 )
	BEGIN
		IF( @tran_started = 1 )
			ROLLBACK TRAN
		RETURN  34563
	END

	INSERT  arinpchg 
	(      
    		trx_ctrl_num,		doc_ctrl_num,
		doc_desc,    		apply_to_num,			apply_trx_type,
		order_ctrl_num,	batch_code,	    		trx_type,
		date_entered,		date_applied,			date_doc,
		date_shipped,		date_required,		date_due,
		date_aging,	    	customer_code,	    	ship_to_code,
	    	salesperson_code,	territory_code,		comment_code,
		fob_code,		freight_code,			terms_code,
		fin_chg_code,		price_code,			dest_zone_code,
		posting_code,		recurring_flag,		recurring_code,
		tax_code,	    	cust_po_num,			total_weight,
	    	amt_gross,	    	amt_freight,	    		amt_tax,
	    	amt_discount,    	amt_net,			amt_paid,
		amt_due,		amt_cost,			amt_profit,
		next_serial_id,	printed_flag,			posted_flag,
		hold_flag,		hold_desc,			user_id,
		customer_addr1,	customer_addr2,		customer_addr3,
		customer_addr4,	customer_addr5,		customer_addr6,
		ship_to_addr1,	ship_to_addr2,		ship_to_addr3,
		ship_to_addr4,	ship_to_addr5,		ship_to_addr6,
		attention_name,	attention_phone,		amt_rem_rev,
		amt_rem_tax,		date_recurring,		location_code,
		process_group_num,	source_trx_ctrl_num,		source_trx_type,
		amt_discount_taken,	amt_write_off_given,		nat_cur_code,	
		rate_type_home,	rate_type_oper,		rate_home,
		rate_oper,		edit_list_flag,		amt_tax_included
	)
	SELECT          
		trx_ctrl_num,		doc_ctrl_num,
		doc_desc,	    	apply_to_num,			apply_trx_type,
		order_ctrl_num,	batch_code,	    		trx_type,
		date_entered,		date_applied,			date_doc,
		date_shipped,		date_required,		date_due,
		date_aging,	    	customer_code,    		ship_to_code,
	    	salesperson_code,	territory_code,		comment_code,
		fob_code,		freight_code,			terms_code,
		fin_chg_code,		price_code,			dest_zone_code,
		posting_code,	    	recurring_flag,		recurring_code,
		tax_code,		cust_po_num,			total_weight,
	    	amt_gross,	    	amt_freight,	    		amt_tax,
	    	amt_discount,	    	amt_net,			amt_paid,
		amt_due,		amt_cost,			amt_profit,
		next_serial_id,	printed_flag,			posted_flag,
		hold_flag,		hold_desc,			user_id,
		customer_addr1,	customer_addr2,		customer_addr3,
		customer_addr4,	customer_addr5,		customer_addr6,
		ship_to_addr1,	ship_to_addr2,		ship_to_addr3,
		ship_to_addr4,	ship_to_addr5,		ship_to_addr6,
		attention_name,	attention_phone,		amt_rem_rev,
		amt_rem_tax,		date_recurring,		location_code,
		' ',			source_trx_ctrl_num,		source_trx_type,
		amt_discount_taken,	amt_write_off_given,		nat_cur_code,	
		rate_type_home,	rate_type_oper,		rate_home,
		rate_oper,		edit_list_flag,		amt_tax_included
	FROM    #arinpchg
	IF ( @@error != 0 )
	BEGIN
		IF( @tran_started = 1 )
			ROLLBACK TRAN
		RETURN  34563
	END

	


	INSERT arinpcom  
	(
		trx_ctrl_num,		trx_type,
		sequence_id,		salesperson_code,		amt_commission,
		percent_flag,		exclusive_flag,		split_flag 
	)
	SELECT
		trx_ctrl_num,		trx_type,
		sequence_id,		salesperson_code,		amt_commission,
		percent_flag,		exclusive_flag,		split_flag 
	FROM #arinpcom
	IF ( @@error != 0 )
	BEGIN
		IF( @tran_started = 1 )
			ROLLBACK TRAN
		RETURN  34563
	END
	
	


	INSERT arinptax  
	(
		trx_ctrl_num,		trx_type,
		sequence_id,		tax_type_code,		amt_taxable,
		amt_gross,		amt_tax,			amt_final_tax
	)
 	SELECT
		trx_ctrl_num,		trx_type,
		sequence_id,		tax_type_code,		amt_taxable,
		amt_gross,		amt_tax,			amt_final_tax
	FROM #arinptax
	IF ( @@error != 0 )
	BEGIN
		IF( @tran_started = 1 )
			ROLLBACK TRAN
		RETURN  34563
	END



	



	


	INSERT	arinptmp
	(
			trx_ctrl_num,
			doc_ctrl_num,	
			trx_desc,		
			date_doc,		
			customer_code,	
			payment_code,	
			amt_payment,		
			prompt1_inp,		
			prompt2_inp,		
			prompt3_inp,		
			prompt4_inp,		
			amt_disc_taken,
			cash_acct_code
	)
	SELECT
			trx_ctrl_num,
			doc_ctrl_num,	
			trx_desc,		
			date_doc,		
			customer_code,	
			payment_code,	
			amt_payment,		
			prompt1_inp,		
			prompt2_inp,		
			prompt3_inp,		
			prompt4_inp,		
			amt_disc_taken,
			cash_acct_code
	FROM
			#arinptmp
	WHERE
			updated_flag = 1

	IF (@@error != 0)
	BEGIN
		ROLLBACK TRAN
		RETURN (-1)
	END


	


	DELETE	arinptmp
	FROM	
			arinptmp r, #arinptmp t
	WHERE
			r.customer_code >= '' AND
			r.customer_code = t.customer_code AND
			r.trx_ctrl_num = t.trx_ctrl_num AND
			t.updated_flag = 0
	
	IF (@@error != 0)
	BEGIN
		ROLLBACK TRAN
		RETURN (-1)
	END



	






	EXEC    @result = arinusv_sp
	IF ( @result != 0 )
	BEGIN
		IF( @tran_started = 1 )
			ROLLBACK TRAN
		RETURN  @result
	END

	DELETE #arinpchg
	IF( @@error != 0 )
	BEGIN
		IF( @tran_started = 1 )
			ROLLBACK TRAN
		RETURN 34563
	END			

	DELETE #arinpcdt
	IF( @@error != 0 )
	BEGIN
		IF( @tran_started = 1 )
			ROLLBACK TRAN
		RETURN 34563
	END			

	DELETE #arinpage
	IF( @@error != 0 )
	BEGIN
		IF( @tran_started = 1 )
			ROLLBACK TRAN
		RETURN 34563
	END			

	DELETE #arinptax
	IF( @@error != 0 )
	BEGIN
		IF( @tran_started = 1 )
			ROLLBACK TRAN
		RETURN 34563
	END			

	DELETE #arinbat
	IF( @@error != 0 )
	BEGIN
		IF( @tran_started = 1 )
			ROLLBACK TRAN
		RETURN 34563
	END			

	IF ( @tran_started = 1 )
	BEGIN
		COMMIT TRANSACTION
		SELECT  @tran_started = 0
	END
	





END
GO
GRANT EXECUTE ON  [dbo].[arinsav2_sp] TO [public]
GO
