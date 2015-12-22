SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[arinvrec_sp]	@batch_ctrl_num	varchar(16),
				@process_ctrl_num	varchar(16),
				@sys_date		int, 
				@debug_level		smallint = 0,
				@perf_level		smallint = 0
AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									







DECLARE	
	@unit_code 		varchar(8),			 
	@item_code		varchar(30),			 
	@bulk_flag 		smallint,					
	@discount_prc		float,					
	@extended_price	float,					
	@next_invo 		varchar(16),			 
	@trx_ctrl_num 	varchar(16),	 
	@trx_type		smallint,			
	@amt_net 		float,			
	@date_applied 	int,					
	@date_aging		int,					 
	@date_doc 		int,					 
	@date_required 	int,					 
	@date_shipped 	int,					
	@date_due 		int,					 
	@result 		int,					 
	@terms_code 		varchar(8),		 
	@doc_desc		varchar(40),		
	@sequence_id		int,					
	@apply_to_num		varchar(16),	
	@apply_trx_type	smallint,				
	@tax_type_code	varchar(8),		
	@order_ctrl_num	varchar(16),	
	@customer_code	varchar(8),		
	@location_code	varchar(8),		
	@ship_to_code		varchar(8),		
	@line_desc		varchar(60),	
	@amt_taxable		float,					
	@salesperson_code	varchar(8),		
	@territory_code	varchar(8),		
	@qty_ordered		float,					
	@amt_gross		float,			
	@comment_code		varchar(8),		
	@qty_shipped		float,					
	@amt_tax		float,					
	@amt_tax_included	float,					
	@price_code		varchar(8),		
	@fob_code		varchar(8),		
	@unit_price		float,					
	@amt_final_tax	float,					
	@amt_due		float,					
	@freight_code		varchar(8),		
	@unit_cost		float,					
	@fin_chg_code		varchar(8),		
	@weight		float,					
	@dest_zone_code	varchar(8),		
	@serial_id		int,					
	@posting_code		varchar(8),		
	@tax_code		varchar(8),		
	@recurring_flag	smallint,				
	@gl_rev_acct		varchar(32),	
	@recurring_code	varchar(8),		
	@disc_prc_flag	smallint,				
	@cust_po_num		varchar(25),		
	@discount_amt		float,					
	@total_weight		float,					
	@commission_flag	smallint,				
	@amt_freight		float,					
	@rma_num		varchar(16),	
	@return_code		varchar(8),		
	@amt_discount		float,					
	@qty_returned		float,					
	@amt_cost		float,					
	@qty_prev_returned	float,					
	@amt_profit		float,					
	@new_gl_rev_acct	varchar(32),	
	@next_serial_id	int,				
	@user_id		smallint,				
	@customer_addr1	varchar(40),		
	@customer_addr2	varchar(40),		
	@customer_addr3	varchar(40),		
	@customer_addr4	varchar(40),		
	@customer_addr5	varchar(40),		
	@customer_addr6	varchar(40),		
	@ship_to_addr1	varchar(40),		
	@ship_to_addr2	varchar(40),		
	@ship_to_addr3	varchar(40),		
	@ship_to_addr4	varchar(40),		
	@ship_to_addr5	varchar(40),		
	@ship_to_addr6	varchar(40),		
	@attention_name	varchar(40),		
	@attention_phone	varchar(30),		
	@amt_rem_rev		float,					
	@amt_rem_tax		float,					
	@amt_commission	float,					
	@percent_flag		smallint,				
	@exclusive_flag	smallint,				
	@split_flag		smallint,				
	@nat_cur_code		varchar(8),					
	@rate_type_home	varchar(8),				
	@rate_type_oper	varchar(8),		
	@home_cur_code	varchar(8),		
	@oper_cur_code	varchar(8),		
	@calc_tax		float,			
	@reference_code	varchar(32),
	@cust_po		varchar(20),
	@org_id			varchar(30)		      

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arinvrec.cpp", 301, "Entering arinvrec_sp", @PERF_time_last OUTPUT
			
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinvrec.cpp" + ", line " + STR( 304, 5 ) + " -- ENTRY: "

	SELECT	@home_cur_code = home_currency,
		@oper_cur_code = oper_currency
	FROM	glco (nolock)

	
CREATE TABLE #arinpchg_rec
(
	trx_ctrl_num	varchar(16),
	doc_ctrl_num	varchar(16),
	doc_desc	varchar(40),
	apply_to_num	varchar(16),
	apply_trx_type	smallint,
	order_ctrl_num	varchar(16),
	batch_code	varchar(16),
	trx_type	smallint,
	date_entered	int,
	date_applied	int,
	date_doc	int,
	date_shipped	int,
	date_required	int,
	date_due	int,
	date_aging	int,
	customer_code	varchar(8),
	ship_to_code	varchar(8),
	salesperson_code	varchar(8),
	territory_code	varchar(8),
	comment_code	varchar(8),
	fob_code	varchar(8),
	freight_code	varchar(8),
	terms_code	varchar(8),
	fin_chg_code	varchar(8),
	price_code	varchar(8),
	dest_zone_code	varchar(8),
	posting_code	varchar(8),
	recurring_flag	smallint,
	recurring_code	varchar(8),
	tax_code	varchar(8),
	cust_po_num	varchar(20),
	total_weight	float,
	amt_gross	float,
	amt_freight	float,
	amt_tax	float,
	amt_tax_included	float,
	amt_discount	float,
	amt_net	float,
	amt_paid	float,
	amt_due	float,
	amt_cost	float,
	amt_profit	float,
	next_serial_id	smallint,
	printed_flag	smallint,
	posted_flag	smallint,
	hold_flag	smallint,
	hold_desc	varchar(40),
	user_id	smallint,
	customer_addr1	varchar(40),
	customer_addr2	varchar(40),
	customer_addr3	varchar(40),
	customer_addr4	varchar(40),
	customer_addr5	varchar(40),
	customer_addr6	varchar(40),
	ship_to_addr1	varchar(40),
	ship_to_addr2	varchar(40),
	ship_to_addr3	varchar(40),
	ship_to_addr4	varchar(40),
	ship_to_addr5	varchar(40),
	ship_to_addr6	varchar(40),
	attention_name	varchar(40),
	attention_phone	varchar(30),
	amt_rem_rev	float,
	amt_rem_tax	float,
	date_recurring	int,
	location_code	varchar(8),
	process_group_num	varchar(16) NULL,
	source_trx_ctrl_num	varchar(16) NULL,
	source_trx_type	smallint NULL,
	amt_discount_taken	float NULL,
	amt_write_off_given	float NULL,
	nat_cur_code	varchar(8),  
	rate_type_home	varchar(8), 
	rate_type_oper	varchar(8), 
	rate_home	float,
	rate_oper	float,
	org_id 		varchar(30) NULL,
	mark_flag	smallint
)

CREATE INDEX #arinpchg_rec_ind_0 
ON #arinpchg_rec(trx_ctrl_num, trx_type, batch_code, apply_to_num )

CREATE INDEX #arinpchg_rec_ind_1
ON #arinpchg_rec(apply_to_num, batch_code, apply_trx_type )

CREATE INDEX #arinpchg_rec_ind_2
ON #arinpchg_rec(posting_code, batch_code )

CREATE INDEX #arinpchg_rec_ind_3 
ON #arinpchg_rec(trx_ctrl_num, trx_type,mark_flag)


	
CREATE TABLE #arinpcdt_rec
(
	trx_ctrl_num		varchar(16),
	doc_ctrl_num		varchar(16),
	sequence_id	 	int,
	trx_type	 	smallint,
	location_code		varchar(8),
	item_code	 	varchar(30),	
	bulk_flag	 	smallint,
	date_entered		int,
	line_desc	 	varchar(60),	   
	qty_ordered	 	float,
	qty_shipped	 	float,
	unit_code	 	varchar(8),
	unit_price	 	float,
	unit_cost	 	float,
	extended_price	float,
	weight	 		float,
	serial_id	 	int,
	tax_code	 	varchar(8),
	gl_rev_acct	 	varchar(32),
	disc_prc_flag		smallint,
	discount_amt		float,
	discount_prc		float,
	commission_flag	smallint,
	rma_num		varchar(16),
	return_code	 	varchar(8),
	qty_returned		float,
	qty_prev_returned	float,
	new_gl_rev_acct	varchar(32),	   
	iv_post_flag		smallint,   
	oe_orig_flag		smallint,
	calc_tax		float,
	reference_code	varchar(32) NULL,
	cust_po		varchar(20) NULL,
	org_id 		varchar(30) NULL,
	mark_flag		smallint   
)

CREATE CLUSTERED INDEX #arinpcdt_rec_ind_0 ON #arinpcdt_rec(trx_ctrl_num, trx_type, sequence_id)

	
CREATE TABLE #arinpage_rec
(
	trx_ctrl_num		varchar(16),
	sequence_id		int,	
	doc_ctrl_num		varchar(16),
	apply_to_num		varchar(16),
	apply_trx_type	smallint,
	trx_type		smallint,
	date_applied		int,
	date_due		int,
	date_aging		int,
	customer_code		varchar(8),
	salesperson_code	varchar(8),
	territory_code	varchar(8),
	price_code		varchar(8),
	amt_due		float,
	mark_flag		smallint
)

CREATE CLUSTERED INDEX #arinpage_rec_ind_0 ON #arinpage_rec(trx_ctrl_num, trx_type, sequence_id)

	
CREATE TABLE #arinptax_rec
(
	trx_ctrl_num	varchar(16),
	trx_type	smallint,
	sequence_id	int,
	tax_type_code	varchar(8),
	amt_taxable	float,
	amt_gross	float,
	amt_tax	float,
	amt_final_tax	float,
	mark_flag	smallint
)

CREATE CLUSTERED INDEX #arinptax_rec_ind_0 ON #arinptax_rec(trx_ctrl_num, trx_type, sequence_id)
	
CREATE TABLE #arinpcom_rec
(
	trx_ctrl_num		varchar(16),
	trx_type		smallint,
	sequence_id		int,
	salesperson_code	varchar(8),
	amt_commission	float,
	percent_flag		smallint,
	exclusive_flag	smallint,	
						
	split_flag		smallint,
	mark_flag		smallint
)

CREATE CLUSTERED INDEX #arinpcom_rec_ind_0 ON #arinpcom_rec(trx_ctrl_num, trx_type, sequence_id)

	INSERT #arinpchg_rec
	(
		trx_ctrl_num,		doc_ctrl_num,
		doc_desc,		apply_to_num,		apply_trx_type,
		order_ctrl_num,	batch_code,    	trx_type,
		date_entered,		date_applied,		date_doc,
		date_shipped,		date_required,	date_due,
		date_aging,	    	customer_code,   	ship_to_code,
	    	salesperson_code,	territory_code,	comment_code,
		fob_code,		freight_code,		terms_code,
		fin_chg_code,		price_code,		dest_zone_code,
		posting_code,	    	recurring_flag,	recurring_code,
		tax_code,	    	cust_po_num,		total_weight,
	    	amt_gross,	    	amt_freight,	   
	    	amt_tax,	    	amt_discount,		amt_net,		
	    	amt_paid,		amt_due,		amt_cost,		
	    	amt_profit,		next_serial_id,	printed_flag,		
	    	posted_flag,		hold_flag,		hold_desc,		
	    	user_id,		customer_addr1,	customer_addr2,	
	    	customer_addr3,	customer_addr4,	customer_addr5,	
	    	customer_addr6,	ship_to_addr1,	ship_to_addr2,	
	    	ship_to_addr3,	ship_to_addr4,	ship_to_addr5,	
	    	ship_to_addr6,	attention_name,	attention_phone,	
	    	amt_rem_rev,		amt_rem_tax,		date_recurring,	
	    	location_code,	source_trx_ctrl_num,	
	    	source_trx_type,	amt_discount_taken,	amt_write_off_given,
		nat_cur_code,		rate_type_home,	rate_type_oper,   
		rate_home,		rate_oper,		mark_flag,
		amt_tax_included,	org_id
	)
	SELECT
		trx_ctrl_num,		doc_ctrl_num,
		doc_desc,		apply_to_num,		apply_trx_type,
		order_ctrl_num,	batch_code,    	trx_type,
		date_entered,		date_applied,		date_doc,
		date_shipped,		date_required,	date_due,
		date_aging,	    	customer_code,    	ship_to_code,
	    	salesperson_code,	territory_code,	comment_code,
		fob_code,		freight_code,		terms_code,
		fin_chg_code,		price_code,		dest_zone_code,
		posting_code,	    	recurring_flag,	recurring_code,
		tax_code,	    	cust_po_num,		total_weight,
	    	amt_gross,	      	amt_freight,	
	    	amt_tax,	    	amt_discount,		amt_net,		
	    	amt_paid,		amt_due,		amt_cost,		
	    	amt_profit,		next_serial_id,	printed_flag,		
	    	posted_flag,		hold_flag,		hold_desc,		
	    	user_id,		customer_addr1,	customer_addr2,	
	    	customer_addr3,	customer_addr4,	customer_addr5,	
	    	customer_addr6,	ship_to_addr1,	ship_to_addr2,	
	    	ship_to_addr3,	ship_to_addr4,	ship_to_addr5,	
	    	ship_to_addr6,	attention_name,	attention_phone,	
	    	amt_rem_rev,		amt_rem_tax,		date_recurring,	
	    	location_code,	source_trx_ctrl_num,	
	    	source_trx_type,	amt_discount_taken,	amt_write_off_given,
		nat_cur_code,		rate_type_home,	rate_type_oper,   
		rate_home,		rate_oper,		0,	
		amt_tax_included,	org_id	
	FROM	#arinpchg_work
	WHERE	batch_code = @batch_ctrl_num
	AND	recurring_flag > 0
    	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinvrec.cpp" + ", line " + STR( 379, 5 ) + " -- EXIT: "
        	RETURN 34563
	END

	



	SELECT	a.recurring_code, SUM(amt_net*b.tracked_flag) amount, 
				    MAX(date_applied) apply_date
	INTO	#cycles_info
	FROM	#arinpchg_rec a, #arcycle_work b
	WHERE	a.recurring_code = b.cycle_code	
	GROUP BY a.recurring_code
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinvrec.cpp" + ", line " + STR( 395, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	IF(@debug_level > 0)
	BEGIN
		SELECT "dumping #cycles_info"
		SELECT	"recurring_code = " + recurring_code +
			"amount = " + STR(amount,10,2) +
			"date_last_used = " + STR(apply_date,8)
		FROM	#cycles_info
	END

	UPDATE	#arcycle_work
	SET	amt_tracked_balance = c.amt_tracked_balance + a.amount,
		date_last_used = a.apply_date
	FROM	#arcycle_work c, #cycles_info a
	WHERE	c.cycle_code = a.recurring_code
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinvrec.cpp" + ", line " + STR( 415, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	DROP TABLE #cycles_info
	
	


	EXEC  @result = argetrec_sp	@debug_level,
					@perf_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinvrec.cpp" + ", line " + STR( 428, 5 ) + " -- EXIT: "
		RETURN @result
	END
	
	INSERT #arinpcdt_rec
	(
		trx_ctrl_num,		doc_ctrl_num,
		sequence_id,		trx_type,		location_code,
		item_code,		bulk_flag,		date_entered,
		line_desc,		qty_ordered,		qty_shipped,							
		unit_code,		unit_price,		unit_cost,
		weight,		serial_id,		tax_code,			
		gl_rev_acct,		disc_prc_flag,	discount_amt,		
		discount_prc,		commission_flag,	rma_num,		
		return_code,		qty_returned,		qty_prev_returned,	
		new_gl_rev_acct,	iv_post_flag,		oe_orig_flag,		
		extended_price,	mark_flag,		calc_tax,
		reference_code,		cust_po,	org_id
	)
	SELECT
		d.trx_ctrl_num,	d.doc_ctrl_num,
		d.sequence_id,	d.trx_type,		d.location_code,
		d.item_code,		d.bulk_flag,		d.date_entered,
		d.line_desc,		d.qty_ordered,	d.qty_shipped,			
		d.unit_code,		d.unit_price,		d.unit_cost,
		d.weight,		d.serial_id,		d.tax_code,		
		d.gl_rev_acct,	d.disc_prc_flag,	d.discount_amt,	
		d.discount_prc,	d.commission_flag,	d.rma_num,		
		d.return_code,	d.qty_returned, 	d.qty_prev_returned,	
		d.new_gl_rev_acct,	d.iv_post_flag,	d.oe_orig_flag,	
		d.extended_price,	0,			d.calc_tax,
		d.reference_code,	d.cust_po,	d.org_id
	FROM	#arinpcdt_work d, #arinpchg_rec h
    	WHERE  d.trx_ctrl_num = h.trx_ctrl_num 
      	AND   	d.trx_type = h.trx_type
    	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinvrec.cpp" + ", line " + STR( 465, 5 ) + " -- EXIT: "
        	RETURN 34563
	END

	


	INSERT #arinpage_rec
    	(	
		trx_ctrl_num,		sequence_id,
		doc_ctrl_num,		apply_to_num,		apply_trx_type,
		trx_type,		date_applied,		date_due,
		date_aging,		customer_code,	salesperson_code,
		territory_code,	price_code,		amt_due,
		mark_flag
	)
    	SELECT                 	
		d.trx_ctrl_num,	d.sequence_id,
		d.doc_ctrl_num,	d.apply_to_num,	
		d.apply_trx_type,	d.trx_type,		
		h.date_recurring,	d.date_due + h.date_recurring - d.date_applied,
		d.date_aging + h.date_recurring - d.date_applied, d.customer_code,	
		d.salesperson_code,	d.territory_code,	
		d.price_code,		d.amt_due,	0
    	FROM   #arinpage_work d, #arinpchg_rec h
    	WHERE  d.trx_ctrl_num = h.trx_ctrl_num
    	AND   	d.trx_type = h.trx_type
    	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinvrec.cpp" + ", line " + STR( 494, 5 ) + " -- EXIT: "
        	RETURN 34563
	END

	UPDATE	#arinpage_rec
	SET	date_due = c.date_due
	FROM	#arinpage_rec a, #arinpchg_rec b, arterms c (nolock)
	WHERE	a.trx_ctrl_num = b.trx_ctrl_num
	AND	a.trx_type = b.trx_type
	AND	b.terms_code = c.terms_code
	AND	c.terms_type = 3
	AND	a.sequence_id = 1

	


    	INSERT #arinptax_rec
    	(	
		trx_ctrl_num,		trx_type,
		sequence_id,		tax_type_code,	amt_taxable,
		amt_gross,		amt_tax,		amt_final_tax,
		mark_flag
	)		
    	SELECT                 	
		d.trx_ctrl_num,	d.trx_type,
		d.sequence_id,	d.tax_type_code,	d.amt_taxable,
		d.amt_gross,		d.amt_tax,		d.amt_final_tax,
		0
    	FROM   #arinptax_work d, #arinpchg_rec h
    	WHERE  d.trx_ctrl_num = h.trx_ctrl_num
      	AND   	d.trx_type = h.trx_type
    	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinvrec.cpp" + ", line " + STR( 527, 5 ) + " -- EXIT: "
        	RETURN 34563
	END

	INSERT #arinpcom_rec
	(	
		trx_ctrl_num,		trx_type,
		sequence_id,		salesperson_code,	amt_commission,
		percent_flag,		exclusive_flag,	split_flag,
		mark_flag
	)		
	SELECT                 	
    	d.trx_ctrl_num,		d.trx_type,			
    	d.sequence_id,		d.salesperson_code,	d.amt_commission,		
    	d.percent_flag,		d.exclusive_flag,	d.split_flag,
	0
	FROM	arinpcom d (nolock) , #arinpchg_rec h
	WHERE	d.trx_ctrl_num = h.trx_ctrl_num
	AND	d.trx_type = h.trx_type
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinvrec.cpp" + ", line " + STR( 548, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	IF(@debug_level > 0)
	BEGIN
		SELECT	"dumping #arinpchg_rec"
		SELECT	"recurring_code = " + recurring_code +
			"amt_net = " + STR(amt_net,10,2) +
			"date_applied = " + STR(date_applied,8)
		FROM	#arinpchg_rec
	END

	


	WHILE(1=1)
	BEGIN
		SET ROWCOUNT 1
		
		SELECT	@doc_desc = doc_desc,
			@apply_trx_type = apply_trx_type,
			@order_ctrl_num = order_ctrl_num,
			@trx_ctrl_num = trx_ctrl_num,
			@trx_type = trx_type,
			@customer_code = customer_code,
			@ship_to_code = ship_to_code,
			@salesperson_code = salesperson_code,
			@territory_code = territory_code, 	
			@comment_code = comment_code, 		
			@fob_code = fob_code, 
			@freight_code = freight_code, 		
			@terms_code = terms_code,			
			@fin_chg_code = fin_chg_code, 
			@price_code = price_code, 		
			@dest_zone_code = dest_zone_code, 	
			@posting_code = posting_code, 
			@recurring_flag = recurring_flag,		
			@recurring_code = recurring_code, 	
			@tax_code = tax_code, 
			@cust_po_num = cust_po_num, 		
			@total_weight = total_weight, 		
			@amt_gross = amt_gross, 
			@amt_freight = amt_freight, 		
			@amt_discount = amt_discount, 
			@amt_net = amt_net,
			@amt_cost = amt_cost,			
			@amt_profit = amt_profit, 		
			@next_serial_id = next_serial_id, 
			@user_id = user_id, 			
			@customer_addr1 = customer_addr1,
			@customer_addr2 = customer_addr2, 	
			@customer_addr3 = customer_addr3, 	
			@customer_addr4 = customer_addr4, 
			@customer_addr5 = customer_addr5, 	
			@customer_addr6 = customer_addr6, 	
			@ship_to_addr1 = ship_to_addr1, 
			@ship_to_addr2 = ship_to_addr2, 		
			@ship_to_addr3 = ship_to_addr3, 		
			@ship_to_addr4 = ship_to_addr4, 
			@ship_to_addr5 = ship_to_addr5, 		
			@ship_to_addr6 = ship_to_addr6,		
			@attention_name = attention_name, 
			@attention_phone = attention_phone, 	
			@amt_rem_rev = amt_rem_rev, 		
			@amt_rem_tax = amt_rem_tax,
			@location_code = location_code,
			@amt_tax = amt_tax,
			@nat_cur_code = nat_cur_code,
			@rate_type_home = rate_type_home,
			@rate_type_oper = rate_type_oper,
			@date_applied = date_applied,
			@date_doc = date_doc,
			@date_aging = date_aging,
			@date_due = date_due,
			@date_required = date_required,
			@date_shipped = date_shipped,
			@amt_tax_included = amt_tax_included,
			@org_id		= org_id
		FROM	#arinpchg_rec
		WHERE	mark_flag = 0

		IF @@rowcount = 0 BREAK
	  
		SET ROWCOUNT 0

		



		SELECT @next_invo = NULL

		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinvrec.cpp" + ", line " + STR( 640, 5 ) + " -- MSG: " + "Calling arincrh_sp"
		EXEC @result = arincrh_sp	2000,	
						2,		
						@next_invo OUTPUT,	
						" ",			
						@doc_desc,		
						" ", 			
						@apply_trx_type,	
						@order_ctrl_num, 	
						@batch_ctrl_num,	
						@trx_type, 		
						@sys_date, 		
						@date_applied,	
						@date_doc,	
						@date_shipped,	
						@date_required,	
						@date_due,	
						@date_aging,	 
						@customer_code,	 		
						@ship_to_code,	 		
						@salesperson_code,	
						@territory_code, 	
						@comment_code, 	
						@fob_code, 		
						@freight_code, 	
						@terms_code,		
						@fin_chg_code, 	
						@price_code, 		
						@dest_zone_code, 	
						@posting_code, 	
						@recurring_flag,	
						@recurring_code, 	
						@tax_code, 		
						@cust_po_num, 	
						@total_weight, 	
						@amt_gross, 		
						@amt_freight, 	
						@amt_tax, 		
						@amt_discount, 	
						@amt_net,		
						0.0,			
						@amt_net,		
						@amt_cost,		
						@amt_profit,		
						@next_serial_id,	
						0, 			
						0, 			
						1, 			
						" ", 			
						@user_id, 		
						@customer_addr1,	
						@customer_addr2, 	
						@customer_addr3, 	
						@customer_addr4,	
						@customer_addr5,	
						@customer_addr6, 	
						@ship_to_addr1, 	
						@ship_to_addr2, 	
						@ship_to_addr3, 	
						@ship_to_addr4,	
						@ship_to_addr5, 	
						@ship_to_addr6, 	
						@attention_name,	
						@attention_phone, 	
						@amt_rem_rev, 	
						@amt_rem_tax, 	
						0, 			
						@location_code,	
						@process_ctrl_num,	
						0.0,			
						0.0,			
						@trx_ctrl_num,	
						@trx_type,										
						@nat_cur_code,				
						@rate_type_home,			
						@rate_type_oper,		
						@amt_tax_included,	
						@org_id			

		IF( @result != 0 OR @@error != 0 )
		BEGIN
			IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinvrec.cpp" + ", line " + STR( 721, 5 ) + " -- MSG: " + "arincrh_sp failed: @result = " + STR( @result, 7)
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinvrec.cpp" + ", line " + STR( 722, 5 ) + " -- EXIT: "
			RETURN 34563
		END


                /****** secuence detail  SP2 performance*/
                
                
                SELECT @sequence_id = 0

                UPDATE rec
                    SET rec.mark_flag = 1 ,
                        rec.sequence_id =  @sequence_id ,
                        @sequence_id = @sequence_id  + 1 
              	FROM #arinpcdt_rec rec 
              	WHERE ( rec.trx_ctrl_num = @trx_ctrl_num
		   AND	rec.trx_type = @trx_type 
		   AND	rec.mark_flag = 0 )

                
                INSERT  #arinpcdt (  trx_ctrl_num, doc_ctrl_num, sequence_id, trx_type,	location_code,
			             item_code, bulk_flag, date_entered, line_desc, qty_ordered,
			             qty_shipped, unit_code, unit_price, unit_cost, weight, serial_id,
			             tax_code, 	gl_rev_acct, disc_prc_flag, discount_amt, commission_flag,
			             rma_num, 	return_code,  qty_returned, qty_prev_returned,	new_gl_rev_acct,
			             iv_post_flag, oe_orig_flag, trx_state, mark_flag,	discount_prc,
			             extended_price, calc_tax,	reference_code, cust_po, org_id)						
		   SELECT	@next_invo, ' ',   sequence_id , trx_type ,  location_code,
				item_code, bulk_flag, @sys_date , line_desc,  qty_ordered,
				qty_shipped, unit_code,  unit_price, unit_cost,  weight, serial_id, 
				tax_code, gl_rev_acct, disc_prc_flag,  discount_amt,  commission_flag, 
				rma_num,  return_code, qty_returned, qty_prev_returned,  new_gl_rev_acct,
				1, 0, 0, 0,  discount_prc,
				extended_price,  calc_tax,  reference_code, cust_po,  org_id
		   FROM	#arinpcdt_rec
			WHERE	trx_ctrl_num = @trx_ctrl_num
			AND	trx_type = @trx_type
			AND	mark_flag = 1
               
                /********/
                 

                /*** tax secuence detail  sp2 */
                
                SELECT @sequence_id = 0
                
                UPDATE rec
		     SET rec.mark_flag = 1 ,
		         rec.sequence_id = @sequence_id ,
                        @sequence_id = @sequence_id  + 1 
                FROM	#arinptax_rec rec
		   WHERE  rec.trx_ctrl_num = @trx_ctrl_num
		      AND rec.trx_type = @trx_type
		      AND rec.mark_flag = 0
                
                INSERT #arinptax ( trx_ctrl_num, trx_type,
			           sequence_id,  tax_type_code,
			           amt_taxable,  amt_gross,
			           amt_tax, amt_final_tax,
			           trx_state,	mark_flag )
		    SELECT     @next_invo, trx_type,
			       sequence_id, tax_type_code,
			       amt_taxable, amt_gross,
		               amt_tax, amt_final_tax,
			        2, 0
		    FROM #arinptax_rec
		     WHERE  trx_ctrl_num = @trx_ctrl_num
		      AND trx_type = @trx_type
		      AND mark_flag = 1
		
		/*******/	  
	        
                /* arinpage  */
                
                   SELECT @sequence_id = 0
                
                   UPDATE rec
		      SET rec.mark_flag = 1 ,
		          rec.sequence_id = @sequence_id ,
                             @sequence_id = @sequence_id  + 1 
		      FROM #arinpage_rec rec  
		   WHERE rec.trx_ctrl_num = @trx_ctrl_num
		     AND rec.trx_type = @trx_type
	   	     AND rec.mark_flag = 0
	   	     
	   	   INSERT #arinpage ( trx_ctrl_num, sequence_id, doc_ctrl_num,
	                            apply_to_num, apply_trx_type, trx_type,
	                            date_applied, date_due, date_aging,
	                            customer_code, salesperson_code, territory_code,
	                            price_code,	amt_due, trx_state, mark_flag )
	        	SELECT	@next_invo , sequence_id , ' ',
	        	        apply_to_num,  apply_trx_type, trx_type ,
	        	        @date_applied , date_due , date_aging, 
	        	        @customer_code,	@salesperson_code, @territory_code, 
	        	        @price_code , amt_due,  2 , 0
			FROM	#arinpage_rec   
			WHERE	trx_ctrl_num = @trx_ctrl_num
			    AND	trx_type = @trx_type
	   		    AND	mark_flag = 1
	   		    
                /***********/	                         

               /** arinpcom */

                   SELECT @sequence_id = 0
                
                   UPDATE rec
		      SET rec.mark_flag = 1 ,
		          rec.sequence_id = @sequence_id ,
                             @sequence_id = @sequence_id  + 1 
		      FROM #arinpcom_rec rec  
		   WHERE rec.trx_ctrl_num = @trx_ctrl_num
		     AND rec.trx_type = @trx_type
	   	     AND rec.mark_flag = 0
               

		   INSERT #arinpcom (
			trx_ctrl_num,
			trx_type,
			sequence_id,
			salesperson_code,
			amt_commission,
			percent_flag,
			exclusive_flag,
			split_flag,
			trx_state,
			mark_flag   )
	           SELECT	
	                @next_invo,
	                trx_type,
		        sequence_id, 
		        salesperson_code,
			amt_commission,
			percent_flag,
			exclusive_flag,
			split_flag,
			2,
			0 
		    FROM #arinpcom_rec
			WHERE	trx_ctrl_num = @trx_ctrl_num
			AND	trx_type = @trx_type
			AND	mark_flag = 0
			
                
                
		SET ROWCOUNT 1
		UPDATE	#arinpchg_rec
		SET	mark_flag = 1
		WHERE	trx_ctrl_num = @trx_ctrl_num
		AND	trx_type = @trx_type
		AND	mark_flag = 0
		SET ROWCOUNT 0
	END
	
	


	DROP TABLE #arinpchg_rec
	DROP TABLE #arinpcdt_rec
	DROP TABLE #arinpage_rec
	DROP TABLE #arinptax_rec
	DROP TABLE #arinpcom_rec
	
	



	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinvrec.cpp" + ", line " + STR( 990, 5 ) + " -- EXIT: "
	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[arinvrec_sp] TO [public]
GO
