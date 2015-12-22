SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                




















































  



					  

























































 





























































































































































































































































































































                       



















































































































CREATE PROC [dbo].[artrxinp_sp]	@apply_to_num	varchar( 16 ),
				@trx_ctrl_num	varchar( 16 ),
				@date_entered	int,
				@user_id	smallint,
				@batch_code	varchar(16)
AS

BEGIN
	


	IF EXISTS( SELECT * FROM artrx WHERE doc_ctrl_num = @apply_to_num AND trx_type = 2031 )
	BEGIN

		

















CREATE TABLE #arinpchg
(
  link      varchar(16) NULL,
  trx_ctrl_num    varchar(16) NULL,
  doc_ctrl_num    varchar(16) NULL,
  doc_desc    varchar(40) NULL,
  apply_to_num    varchar(16) NULL,
  apply_trx_type  smallint NULL,
  order_ctrl_num  varchar(16) NULL,
  batch_code    varchar(16) NULL,
  trx_type    smallint NULL,
  date_entered    int NULL,
  date_applied    int NULL,
  date_doc    int NULL,
  date_shipped    int NULL,
  date_required   int NULL,
  date_due    int NULL,
  date_aging    int NULL,
  customer_code   varchar(8),
  ship_to_code    varchar(8) NULL,
  salesperson_code  varchar(8) NULL,
  territory_code  varchar(8) NULL,
  comment_code    varchar(8) NULL,
  fob_code    varchar(8) NULL,
  freight_code    varchar(8) NULL,
  terms_code    varchar(8) NULL,
  fin_chg_code    varchar(8) NULL,
  price_code    varchar(8) NULL,
  dest_zone_code  varchar(8) NULL,
  posting_code    varchar(8) NULL,
  recurring_flag  smallint NULL,
  recurring_code  varchar(8) NULL,
  tax_code    varchar(8) NULL,
  cust_po_num   varchar(20) NULL,
  total_weight    float NULL,
  amt_gross   float NULL,
  amt_freight   float NULL,
  amt_tax   float NULL,
  amt_tax_included  float NULL,
  amt_discount    float NULL,
  amt_net   float NULL,
  amt_paid    float NULL,
  amt_due   float NULL,
  amt_cost    float NULL,
  amt_profit    float NULL,
  next_serial_id  smallint NULL,
  printed_flag    smallint NULL,
  posted_flag   smallint NULL,
  hold_flag   smallint NULL,
  hold_desc   varchar(40) NULL,
  user_id   smallint NULL,
  customer_addr1  varchar(40) NULL,
  customer_addr2  varchar(40) NULL,
  customer_addr3  varchar(40) NULL,
  customer_addr4  varchar(40) NULL,
  customer_addr5  varchar(40) NULL,
  customer_addr6  varchar(40) NULL,
  ship_to_addr1   varchar(40) NULL,
  ship_to_addr2   varchar(40) NULL,
  ship_to_addr3   varchar(40) NULL,
  ship_to_addr4   varchar(40) NULL,
  ship_to_addr5   varchar(40) NULL,
  ship_to_addr6   varchar(40) NULL,
  attention_name  varchar(40) NULL,
  attention_phone varchar(30) NULL,
  amt_rem_rev   float NULL,
  amt_rem_tax   float NULL,
  date_recurring  int NULL,
  location_code   varchar(8) NULL,
  process_group_num varchar(16) NULL,
  trx_state   smallint NULL,
  mark_flag   smallint   NULL,
  amt_discount_taken  float NULL,
  amt_write_off_given float NULL, 
  source_trx_ctrl_num varchar(16) NULL,
  source_trx_type smallint NULL,
  nat_cur_code    varchar(8) NULL,  
  rate_type_home  varchar(8) NULL,  
  rate_type_oper  varchar(8) NULL,  
  rate_home   float NULL, 
  rate_oper   float NULL, 
  edit_list_flag  smallint NULL,
  ddid      varchar(32) NULL,
  org_id	varchar(30)
)

CREATE INDEX #arinpchg_ind_0 
ON #arinpchg ( trx_ctrl_num, trx_type )
CREATE INDEX  #arinpchg_ind_1 
ON  #arinpchg (batch_code)


		


		BEGIN TRAN
	
		INSERT	#arinpchg 
		(
			trx_ctrl_num,		doc_ctrl_num,		doc_desc,		
			apply_to_num,		apply_trx_type,	order_ctrl_num,	
			batch_code,		trx_type,		date_entered,		
			date_applied,		date_doc,		date_shipped,		
			date_required,	date_due,		date_aging,		
			customer_code,	ship_to_code,		salesperson_code,	
			territory_code,	comment_code,		fob_code,		
			freight_code,		terms_code,		fin_chg_code,		
			price_code,		dest_zone_code,	posting_code,		
			recurring_flag,	recurring_code,	tax_code,		
			cust_po_num,		total_weight,		amt_gross,		
			amt_freight,		amt_tax,		amt_discount,		
			amt_net,		amt_paid,		amt_due,					
			amt_cost,		amt_profit,		next_serial_id,	
			printed_flag,		posted_flag,		hold_flag,		
			hold_desc,		user_id,		customer_addr1,	
			customer_addr2,	customer_addr3,	customer_addr4,	
			customer_addr5,	customer_addr6,	ship_to_addr1,	
			ship_to_addr2,	ship_to_addr3,	ship_to_addr4,				
			ship_to_addr5,	ship_to_addr6,	attention_name,	
			attention_phone,	amt_rem_rev,		amt_rem_tax,		
			date_recurring,	location_code,	process_group_num,	
			source_trx_ctrl_num,	source_trx_type,	amt_discount_taken,	
			amt_write_off_given,	nat_cur_code,		rate_type_home,	
			rate_type_oper,	rate_home,		rate_oper,		
			edit_list_flag,	amt_tax_included, 	org_id
		)
		SELECT	@trx_ctrl_num,	' ',			' ',			
			@apply_to_num, 	2031,	x.order_ctrl_num,	
			@batch_code,		2051,	@date_entered,	
			x.date_applied,	@date_entered,	x.date_shipped,	
			x.date_required,	x.date_due,		x.date_aging,		
			x.customer_code,	x.ship_to_code,	x.salesperson_code,	
			x.territory_code,	x.comment_code,	x.fob_code,		
			x.freight_code,	x.terms_code,		x.fin_chg_code,	
			x.price_code,		x.dest_zone_code,	x.posting_code,	
			x.recurring_flag,	x.recurring_code,	x.tax_code,		
			x.cust_po_num,	0.0,			x.amt_gross,		
			x.amt_freight,	x.amt_tax,		x.amt_discount,	
			x.amt_net,		x.amt_paid_to_date,	(x.amt_net - x.amt_paid_to_date),		
			0,			0,			0,			
			0,			0,			0,			
			'',			@user_id,		c.addr1,		
			c.addr2,		c.addr3,		c.addr4,		
			c.addr5,		c.addr6,		'',
			'',			'',			'',			
			'',			'',			'',     	
			'',			0.0,			0.0,			
			0,			'',			'',			
			'',			0,			0.0,			
			0.0,			x.nat_cur_code,	x.rate_type_home,	
			x.rate_type_oper,	x.rate_home,		x.rate_oper,		
			0,			ISNULL(amt_tax_included,0.0), x.org_id
		FROM	artrx x, arcust c
		WHERE	x.doc_ctrl_num = @apply_to_num
		AND	x.trx_type = 2031
		AND	x.customer_code = c.customer_code

		UPDATE	#arinpchg	
		SET	ship_to_addr1 = ISNULL(s.addr1, ''),	
			ship_to_addr2 = ISNULL(s.addr2, ''),	
			ship_to_addr3 = ISNULL(s.addr3, ''),	
			ship_to_addr4 = ISNULL(s.addr4, ''),				
			ship_to_addr5 = ISNULL(s.addr5, ''),	
			ship_to_addr6	= ISNULL(s.addr6, ''),	
			attention_name = ISNULL(s.attention_name, ''),	
			attention_phone = ISNULL(s.attention_phone, '')		
			FROM	arshipto s	
			WHERE	#arinpchg.customer_code = s.customer_code
			AND	#arinpchg.ship_to_code = s.ship_to_code
			AND	s.status_type = 1


		DELETE arinpchg
		WHERE	trx_ctrl_num = @trx_ctrl_num
		AND	trx_type = 2051

		INSERT	arinpchg 
		(
			trx_ctrl_num,		doc_ctrl_num,		doc_desc,		
			apply_to_num,		apply_trx_type,	order_ctrl_num,	
			batch_code,		trx_type,		date_entered,		
			date_applied,		date_doc,		date_shipped,		
			date_required,	date_due,		date_aging,		
			customer_code,	ship_to_code,		salesperson_code,	
			territory_code,	comment_code,		fob_code,		
			freight_code,		terms_code,		fin_chg_code,		
			price_code,		dest_zone_code,	posting_code,		
			recurring_flag,	recurring_code,	tax_code,		
			cust_po_num,		total_weight,		amt_gross,		
			amt_freight,		amt_tax,		amt_discount,		
			amt_net,		amt_paid,		amt_due,					
			amt_cost,		amt_profit,		next_serial_id,	
			printed_flag,		posted_flag,		hold_flag,		
			hold_desc,		user_id,		customer_addr1,	
			customer_addr2,	customer_addr3,	customer_addr4,	
			customer_addr5,	customer_addr6,	ship_to_addr1,	
			ship_to_addr2,	ship_to_addr3,	ship_to_addr4,				
			ship_to_addr5,	ship_to_addr6,	attention_name,	
			attention_phone,	amt_rem_rev,		amt_rem_tax,		
			date_recurring,	location_code,	process_group_num,	
			source_trx_ctrl_num,	source_trx_type,	amt_discount_taken,	
			amt_write_off_given,	nat_cur_code,		rate_type_home,	
			rate_type_oper,	rate_home,		rate_oper,		
			edit_list_flag,	amt_tax_included,	org_id
		)
		SELECT
			trx_ctrl_num,		doc_ctrl_num,		doc_desc,		
			apply_to_num,		apply_trx_type,	order_ctrl_num,	
			batch_code,		trx_type,		date_entered,		
			date_applied,		date_doc,		date_shipped,		
			date_required,	date_due,		date_aging,		
			customer_code,	ship_to_code,		salesperson_code,	
			territory_code,	comment_code,		fob_code,		
			freight_code,		terms_code,		fin_chg_code,		
			price_code,		dest_zone_code,	posting_code,		
			recurring_flag,	recurring_code,	tax_code,		
			cust_po_num,		total_weight,		amt_gross,		
			amt_freight,		amt_tax,		amt_discount,		
			amt_net,		amt_paid,		amt_due,					
			amt_cost,		amt_profit,		next_serial_id,	
			printed_flag,		posted_flag,		hold_flag,		
			hold_desc,		user_id,		customer_addr1,	
			customer_addr2,	customer_addr3,	customer_addr4,	
			customer_addr5,	customer_addr6,	ship_to_addr1,	
			ship_to_addr2,	ship_to_addr3,	ship_to_addr4,				
			ship_to_addr5,	ship_to_addr6,	attention_name,	
			attention_phone,	amt_rem_rev,		amt_rem_tax,		
			date_recurring,	location_code,	process_group_num,	
			source_trx_ctrl_num,	source_trx_type,	amt_discount_taken,	
			amt_write_off_given,	nat_cur_code,		rate_type_home,	
			rate_type_oper,	rate_home,		rate_oper,		
			edit_list_flag,	amt_tax_included, org_id
		FROM	#arinpchg

		




		DELETE arinpcdt
		WHERE	trx_ctrl_num = @trx_ctrl_num
		AND	trx_type = 2051

		INSERT	arinpcdt 
		(
			trx_ctrl_num,		doc_ctrl_num,
			sequence_id,		trx_type,		location_code,
			item_code,		bulk_flag,		date_entered,
			line_desc,		qty_ordered,		qty_shipped,
			unit_code,		unit_price,		unit_cost,
			weight,		serial_id,		tax_code,
			gl_rev_acct,		disc_prc_flag,	discount_amt,
			commission_flag,	rma_num,		return_code,
			qty_returned,		qty_prev_returned,	new_gl_rev_acct,
			iv_post_flag,		oe_orig_flag,		discount_prc,
			extended_price,	calc_tax,		reference_code,
			new_reference_code, org_id
		)
		SELECT	@trx_ctrl_num,	'',
			sequence_id,		2051,	location_code,	  	
			item_code,		bulk_flag,		@date_entered,	  	
			line_desc,		qty_ordered,		qty_shipped,  		
			unit_code,		unit_price,		amt_cost,	  	
			weight,		serial_id,		tax_code,	  	
			gl_rev_acct,		disc_prc_flag,	discount_amt,  	  	
			0,			rma_num,		return_code,	  	
			qty_returned,		qty_returned,		gl_rev_acct,
			1,			0,			discount_prc,
			extended_price,	ISNULL(calc_tax,0.0),reference_code,
			reference_code, org_id
		FROM	artrxcdt
		WHERE	doc_ctrl_num = @apply_to_num
		AND	trx_type = 2031
		AND	(ABS((qty_shipped)-(0.0)) > 0.0000001)
		AND	(ABS((unit_price)-(0.0)) > 0.0000001)

		COMMIT TRAN
		
		DROP TABLE #arinpchg
	END
END
GO
GRANT EXECUTE ON  [dbo].[artrxinp_sp] TO [public]
GO
