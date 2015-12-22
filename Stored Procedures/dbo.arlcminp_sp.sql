SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO






CREATE PROC [dbo].[arlcminp_sp]	@apply_to_num		varchar(16),
				@trx_ctrl_num		varchar(16),
				@trx_type		smallint,
				@date_entered		int,
				@date_applied		int,
				@user_id		smallint,
				@option_flag		smallint,
				@batch_code		varchar(16),
				@revenue_flag		smallint,
				@writeoff_code		varchar(8)
AS

DECLARE	@cust_code		varchar(8),	
		@ship_to_code		varchar(8),
		@ship_to1		varchar(40),	
		@ship_to2		varchar(40),
		@ship_to3		varchar(40),	
		@ship_to4		varchar(40),
		@ship_to5		varchar(40),	
		@ship_to6		varchar(40),
		@ship_tocity		varchar(40),
		@ship_tostate		varchar(15),
		@ship_tozip		varchar(3),
		@ship_tocoun		varchar(40),
		@cust_to1		varchar(40),	
		@cust_to2		varchar(40),
		@cust_to3		varchar(40),	
		@cust_to4		varchar(40),
		@cust_to5		varchar(40),	
		@cust_to6		varchar(40),
		@cust_tocity		varchar(40),
		@cust_tostate		varchar(40),
		@cust_tozip		varchar(15),
		@cust_tocoun		varchar(3),
		@att_name		varchar(40),
		@att_phone		varchar(30),
		@location_code	varchar(10),	
		@next_id		int,
		@totalweight		float,	    		
		@apply_ctrl_num	varchar(16),
		@precision		smallint,
		@salesperson_code	varchar(8),	
		@territory_code	varchar(8),				
		@fob_code		varchar(8),		
		@freight_code		varchar(8),	
		@terms_code		varchar(8),			
		@fin_chg_code		varchar(8),	
		@price_code		varchar(8),		
		@dest_zone_code	varchar(8),		
		@posting_code		varchar(8),		
		@tax_code		varchar(8),		
		@cust_po_num		varchar(25),					
		@amt_freight		float,					
		@rate_type_home	varchar(8),
		@rate_type_oper	varchar(8),	
		@nat_cur_code		varchar(8),	
		@rate_home		float,
		@rate_oper		float,
		@order_ctrl_num	varchar(16),
		@detail_count		int,
		@org_id			varchar(30)

BEGIN

	SELECT	@cust_code = ' ',	
		@ship_to1 = ' ',	
		@ship_to2 = ' ',
		@ship_to3 = ' ',	
		@ship_to4 = ' ',	
		@ship_to5 = ' ',
		@ship_to6 = ' ',
		@ship_tocity = ' ',
		@ship_tostate = ' ',
		@ship_tozip = ' ',
		@ship_tocoun = ' ',		
		@att_name = ' ',	
		@att_phone = ' ',
		@ship_to_code = NULL, 	
		@cust_code = NULL,	
		@location_code = NULL,
		@totalweight = NULL

	SELECT	@apply_ctrl_num = trx_ctrl_num,
		@cust_code = customer_code,
		@ship_to_code = ship_to_code,
		@salesperson_code = salesperson_code,	
		@territory_code = territory_code,				
		@fob_code = fob_code,		
		@freight_code = freight_code,	
		@terms_code = terms_code,			
		@fin_chg_code = fin_chg_code,	
		@price_code = price_code,		
		@dest_zone_code = dest_zone_code,		
		@posting_code = posting_code,		
		@tax_code = tax_code,		
		@cust_po_num = cust_po_num,					
		@order_ctrl_num = order_ctrl_num,
		@amt_freight = amt_freight,					
		@rate_type_home = rate_type_home,
		@rate_type_oper = rate_type_oper,	
		@nat_cur_code = nat_cur_code,	
		@rate_home = rate_home,
		@rate_oper = rate_oper,
		@org_id = org_id
	FROM	artrx
	WHERE	doc_ctrl_num = @apply_to_num
	AND	trx_type = 2031

	
	IF @@rowcount = 0 
		RETURN

	IF @cust_code IS NULL
		RETURN

	SELECT @precision = curr_precision
	FROM	glcurr_vw
	WHERE	currency_code = @nat_cur_code

	



	SELECT	@location_code = location_code,
		@ship_to1 = addr1,
		@ship_to2 = addr2,
		@ship_to3 = addr3,
		@ship_to4 = addr4,
		@ship_to5 = addr5,
		@ship_to6 = addr6,
		@ship_tocity = city,
		@ship_tostate = state,
		@ship_tozip = postal_code,
		@ship_tocoun = country_code,	
		@att_name = attention_name,
		@att_phone = attention_phone
	FROM	arshipto
	WHERE	ship_to_code = @ship_to_code
	AND	customer_code = @cust_code
	AND	status_type = 1

	SELECT	@location_code = ISNULL(@location_code,location_code),
		@att_name = ISNULL(@att_name,attention_name),
		@att_phone = ISNULL(@att_phone,attention_phone),
		@cust_to1 = addr1,		
		@cust_to2 = addr2,		
		@cust_to3 = addr3,		
		@cust_to4 = addr4,		
		@cust_to5 = addr5,		
		@cust_to6 = addr6,
		@cust_tocity = city,
		@cust_tostate = state,
		@cust_tozip = postal_code,
		@cust_tocoun = country_code
	FROM	arcust
	WHERE	customer_code = @cust_code

	IF @@rowcount = 0 
		RETURN
	IF @location_code IS NULL
		SELECT	@location_code = SPACE(1)


	



	IF (@writeoff_code = '' or @writeoff_code = NULL )
		SELECT 	@writeoff_code = writeoff_code 
		FROM 	arcust
		WHERE 	customer_code = @cust_code


	SELECT	@next_id = NULL,
		@totalweight = NULL

	IF @option_flag != 0 
	BEGIN
		CREATE TABLE #arinpcdt_inv
		(
			id			numeric identity,
			trx_ctrl_num		varchar(16),
			sequence_id	       int,
			location_code	       varchar(10),
			item_code            varchar(30),
			date_entered	       int,
			line_desc            varchar(60),		
			qty_shipped          float,		      
			unit_code            varchar(8),	      
			unit_price           float,		      
			weight               float,		      
			serial_id            int,
			tax_code             varchar(8),	      
			gl_rev_acct          varchar(32),	      
			disc_prc_flag	       smallint,	      
			discount_amt	       float,		      
			discount_prc		float,	      
			return_code          varchar(8),	      
			qty_returned	       float,		      
			extended_price	float,
			reference_code	varchar(32) NULL,
			org_id		varchar(30) NULL	      
		)


		INSERT	#arinpcdt_inv 
			(
			trx_ctrl_num,
		  	sequence_id,		
		  	location_code,
		  	item_code,	
			date_entered,
		  	line_desc,		
		  	qty_shipped,
		  	unit_code,		
		  	unit_price,		
		  	weight,		
		  	serial_id,		
		  	tax_code,	  	
		  	gl_rev_acct,		
		  	disc_prc_flag,	
		  	discount_amt,	  	
		  	discount_prc,		
		  	return_code,		
			qty_returned, 	
			extended_price,
			reference_code,
			org_id
		)
		SELECT	@trx_ctrl_num,
			sequence_id,		
			location_code,	
			item_code,			
			@date_entered,
			line_desc,		
			qty_shipped,	
			unit_code,		
			unit_price,		
			weight,		
			serial_id,		
			tax_code,		
			gl_rev_acct,	
			disc_prc_flag,	
			discount_amt,		
			discount_prc,		
			return_code,		
			qty_returned, 	
			extended_price,
			reference_code,
			org_id
		FROM	artrxcdt
		WHERE	trx_ctrl_num = @apply_ctrl_num
		AND	trx_type = 2031
		
		SELECT @detail_count = @@rowcount

		IF @revenue_flag != 1
		BEGIN
			UPDATE	#arinpcdt_inv
			SET	gl_rev_acct = 	dbo.IBAcctMask_fn(sales_ret_acct_code,#arinpcdt_inv.org_id), 
				reference_code = " "
			FROM	araccts 
			WHERE	posting_code = @posting_code
		END


		SELECT	@next_id = ISNULL(MAX( serial_id ), 0) + 1,
			@totalweight = ISNULL(SUM( weight ), 0.0)
		FROM	#arinpcdt_inv
	END

	IF @next_id IS NULL
		SELECT @next_id = 1
		
	IF @next_id > 32000 SELECT @next_id = 1
	


	BEGIN TRAN

	


	DELETE	arinpchg
	WHERE	trx_ctrl_num = @trx_ctrl_num
	AND	trx_type = @trx_type
	
	


	DELETE	arinpcdt
	WHERE	trx_ctrl_num = @trx_ctrl_num
	AND	trx_type = @trx_type
	
	


	IF @trx_type = 2032
	BEGIN
		


		DELETE	arinptax
		WHERE	trx_ctrl_num = @trx_ctrl_num
		AND	trx_type = @trx_type
		
		INSERT	arinpchg 
		(
			trx_ctrl_num,		doc_ctrl_num,
			doc_desc,		apply_to_num,		apply_trx_type,
			order_ctrl_num,	batch_code,		trx_type,
			date_entered,		date_applied,		date_doc,
			date_shipped,		date_required,	date_due,
			date_aging,		customer_code,	ship_to_code,
			salesperson_code,	territory_code,	comment_code,
			fob_code,		freight_code,		terms_code,
			fin_chg_code,		price_code,		dest_zone_code,
			posting_code,		recurring_flag,	recurring_code,
			tax_code,		cust_po_num,		total_weight,
			amt_gross,		amt_freight,		amt_tax,
			amt_discount,		amt_net,		amt_paid,
			amt_due,		amt_cost,		amt_profit,
			next_serial_id,	printed_flag,		posted_flag,
			hold_flag,		hold_desc,		user_id,
			customer_addr1,	customer_addr2,	customer_addr3,
			customer_addr4,	customer_addr5,	customer_addr6,
			customer_city, customer_state, customer_postal_code,
			customer_country_code, ship_to_addr1,	ship_to_addr2,	
			ship_to_addr3, ship_to_addr4,	ship_to_addr5,	
			ship_to_addr6, ship_to_city, ship_to_state, 
			ship_to_postal_code, ship_to_country_code,
			attention_name,	attention_phone,	amt_rem_rev,
			amt_rem_tax,		date_recurring,	location_code, 	
			amt_discount_taken, 	amt_write_off_given,	rate_type_home,
			rate_type_oper,	nat_cur_code,		rate_home,
			rate_oper,		edit_list_flag,	amt_tax_included,
			writeoff_code, org_id
		)
		SELECT	@trx_ctrl_num,	SPACE(1),			
			SPACE(1),		@apply_to_num, 	2031, 			
			@order_ctrl_num,	@batch_code,		@trx_type,			
			@date_entered,	@date_applied,	@date_entered, 			
			0,			0,			0,				
			0,			@cust_code,		@ship_to_code,			
			@salesperson_code,	@territory_code,	SPACE(1),			
			@fob_code,		@freight_code,	@terms_code,			
			@fin_chg_code,	@price_code,		@dest_zone_code,		
			@posting_code,	1,			SPACE(1),			
			@tax_code,		@cust_po_num,		0.0,				
			0.0,			@amt_freight,		0.0,				
			0.0,			0.0,			0.0,				
			0.0,			0.0,			0.0,				
			@next_id,		0,			0,				
			0,			SPACE(1),		@user_id,			
			@cust_to1,		@cust_to2,		@cust_to3,			
			@cust_to4,		@cust_to5,		@cust_to6,
			@cust_tocity,		@cust_tostate,		@cust_tozip,
			@cust_tocoun,		@ship_to1, 		@ship_to2, 		
			@ship_to3,		@ship_to4,		@ship_to5,		
			@ship_to6,		@ship_tocity,		@ship_tostate,		
			@ship_tozip,		@ship_tocoun,			
			@att_name,     		@att_phone,		0.0,				
			0.0,			0,			@location_code, 
			0.0, 			0.0,			@rate_type_home,
			@rate_type_oper,	@nat_cur_code,	@rate_home,
			@rate_oper,		0,			0.0,
			@writeoff_code, @org_id

		IF 	@@rowcount = 0 
		BEGIN
			ROLLBACK TRAN
			IF @option_flag != 0 
			BEGIN
				DROP TABLE #arinpcdt_inv
			END
			RETURN
		END

		


		IF @option_flag = 0 
		BEGIN
			COMMIT TRAN
			RETURN
		END

		


		IF @option_flag = 1
		BEGIN
			INSERT	arinpcdt 
			(
				trx_ctrl_num,		doc_ctrl_num,
			  	sequence_id,		trx_type,		location_code,
			  	item_code,		bulk_flag,		date_entered,
			  	line_desc,		qty_ordered,		qty_shipped,
			  	unit_code,		unit_price,		unit_cost,
			  	weight,		serial_id,		tax_code,
			  	gl_rev_acct,		disc_prc_flag,	discount_amt,
				discount_prc,	  	commission_flag,	rma_num,		
				return_code,  	qty_returned,  	qty_prev_returned,	
				new_gl_rev_acct,  	iv_post_flag,		oe_orig_flag,
				extended_price, 	calc_tax,		reference_code, org_id
			)
		  	SELECT	@trx_ctrl_num,	SPACE(1),
			  	sequence_id,		@trx_type,		location_code,
			  	item_code,		0,			@date_entered,
			  	line_desc,		0,			qty_shipped,
			  	unit_code,		unit_price,		0.0,
			  	0.0,			serial_id,		tax_code,
			  	gl_rev_acct,		0,			0.0,
				0.0,		  	0,			SPACE(1),		
				return_code,	  	0.0,			qty_returned, 	
				SPACE(1),	  	0,			0,
				0.0,			0.0,			reference_code, org_id
		  	FROM	#arinpcdt_inv
		END    
		ELSE IF @option_flag = 2
		BEGIN
			INSERT	arinpcdt 
  			(
  				trx_ctrl_num,		doc_ctrl_num,
			  	sequence_id,		trx_type,		location_code,
			  	item_code,		bulk_flag,		date_entered,
			  	line_desc,		qty_ordered,		qty_shipped,
			  	unit_code,		unit_price,		unit_cost,
			  	weight,		serial_id,		tax_code,	  	
			  	gl_rev_acct,		disc_prc_flag,	discount_amt,	  	
			  	discount_prc,		commission_flag,	rma_num,		
			  	return_code,		qty_returned,  	qty_prev_returned,	
			  	new_gl_rev_acct,  	iv_post_flag,		oe_orig_flag,
				extended_price,	calc_tax,		reference_code, org_id
			)
			SELECT	@trx_ctrl_num,	' ',	
				sequence_id,		@trx_type,		location_code,	
				item_code,		0,			@date_entered,	
				line_desc,		0,			qty_shipped,	
				unit_code,		unit_price,		0.0,		
				weight,		serial_id,		tax_code,		
				gl_rev_acct,		disc_prc_flag,	discount_amt,		
				discount_prc,		0,			' ',			
				return_code,		qty_shipped,    	qty_returned, 	
				' ',			0,			0,
				extended_price,	0.0,			reference_code, org_id
			FROM	#arinpcdt_inv
		END 

	END 

	COMMIT TRAN

	DROP TABLE #arinpcdt_inv

	RETURN
END
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[arlcminp_sp] TO [public]
GO
