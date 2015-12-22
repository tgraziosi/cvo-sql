SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                

/*
**
**	Rev	Name		When		Why
**	-----	---------	----------	-----------------------------------
**	1.0	JGallegos	06/21/2005	Develop 736. organizatio default added when the invoice is created.
**      2.0     jvillarreal     10/12/2005      add the table cca
*/
























CREATE PROCEDURE [dbo].[ARINCreateMultipleInvoice_SP]
AS

DECLARE @result                 int,
	@trx_ctrl_num		varchar(16),
	@sequence_id		int,
	@ship_to_code		varchar(8),
	@date_shipped		int
BEGIN

CREATE TABLE #arinpchg_temp
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
	org_id varchar(30) NULL				/*  Rev 1.0  */
)

CREATE TABLE #arinpcdt_temp
(
	link			varchar(16) NULL,
	trx_ctrl_num	 	varchar(16) NULL,
	doc_ctrl_num	 	varchar(16) NULL,
	sequence_id	 	int identity,
	trx_type	 	smallint NULL,
	location_code	 	varchar(8) NULL,
	item_code	 	varchar(30) NULL,
	bulk_flag	 	smallint NULL,
	date_entered	 	int NULL,
	line_desc	 	varchar(60) NULL,
	qty_ordered	 	float NULL,
	qty_shipped	 	float NULL,
	unit_code	 	varchar(8) NULL,
	unit_price	 	float,
	unit_cost	 	float NULL,
	weight	 		float NULL,
	serial_id	 	int NULL,
	tax_code	 	varchar(8) NULL,
	gl_rev_acct	 	varchar(32) NULL,
	disc_prc_flag	 	smallint NULL,
	discount_amt	 	float NULL,
	commission_flag	smallint NULL,
	rma_num		varchar(16) NULL,
	return_code	 	varchar(8) NULL,
	qty_returned	 	float NULL,
	qty_prev_returned	float NULL,
	new_gl_rev_acct	varchar(32) NULL,
	iv_post_flag	 	smallint NULL,
	oe_orig_flag	 	smallint NULL,
	discount_prc		float NULL,	
	extended_price	float NULL,	
	calc_tax		float NULL,
	reference_code	varchar(32)	NULL,
	trx_state		smallint	NULL,
	mark_flag		smallint	NULL,
	cust_po 		VARCHAR(20) NULL,	
        ship_to_code    varchar(8) NULL,	
        date_shipped    int NULL,
	org_id varchar(30) NULL				/*  Rev 1.0  */		
)



CREATE TABLE #arinptmp_temp 
( 			
	trx_ctrl_num		varchar(16)  	NULL , 
	doc_ctrl_num		varchar(16)  	NULL , 
	trx_desc		varchar(40)  	NULL , 
	date_doc		int		NULL , 
	customer_code		varchar(8)	NULL ,	
	payment_code		varchar(8)	NULL , 	
	amt_payment		float		NULL , 	
	prompt1_inp		varchar(30)	NULL ,  
	prompt2_inp		varchar(30)	NULL ,  
	prompt3_inp		varchar(30)	NULL ,  
	prompt4_inp		varchar(30)	NULL ,  
	amt_disc_taken		float		NULL ,  
	cash_acct_code		varchar(32)	NULL
)

CREATE TABLE #cca_trx_temp                        		/* rev 2.0 ccacryptaccts */
(
	company_code	varchar(8),
	order_no	int,
	order_ext	int,
	trx_ctrl_num	varchar(16),
	trx_type	varchar(16),
	customer_code	varchar(8),
	ccnumber	varchar(255),
	date_last_used	int,
	doc_desc    varchar(40)
)



	INSERT #arinpchg_temp
	(
	link,	 	 	trx_ctrl_num,   	doc_ctrl_num,  		doc_desc,
	apply_to_num,  		apply_trx_type, 	order_ctrl_num, 	batch_code,
	trx_type,	 	date_entered,   	date_applied,   	date_doc,
	date_shipped,  		date_required,  	date_due,       	date_aging,  
	customer_code, 		ship_to_code,   	salesperson_code,  	territory_code,
	comment_code,  		fob_code,	 	freight_code,		terms_code,
	fin_chg_code,  		price_code,	 	dest_zone_code,		posting_code,
	recurring_flag,		recurring_code,  	tax_code,		cust_po_num,
	total_weight,  		amt_gross, 	 	amt_freight,		amt_tax,
	amt_tax_included,  	amt_discount,		amt_net,		amt_paid,
	amt_due,		amt_cost,		amt_profit,		next_serial_id,
	printed_flag,		posted_flag,		hold_flag,		hold_desc,
	user_id,		customer_addr1,		customer_addr2,		customer_addr3,
	customer_addr4,		customer_addr5,		customer_addr6,		ship_to_addr1,
	ship_to_addr2,		ship_to_addr3,		ship_to_addr4,		ship_to_addr5,
	ship_to_addr6,		attention_name,		attention_phone,	amt_rem_rev,
	amt_rem_tax,		date_recurring,		location_code,		process_group_num,
	trx_state,		mark_flag,		amt_discount_taken,	amt_write_off_given, 
	source_trx_ctrl_num,	source_trx_type, 	nat_cur_code,  		rate_type_home,  
	rate_type_oper,  	rate_home, 		rate_oper, 		edit_list_flag,
	ddid,			org_id										/*  Rev 1.0  */
	)
	SELECT
	link,	 	 	trx_ctrl_num,   	doc_ctrl_num,  		doc_desc,
	apply_to_num,  		apply_trx_type, 	order_ctrl_num, 	batch_code,
	trx_type,	 	date_entered,   	date_applied,   	date_doc,
	date_shipped,  		date_required,  	date_due,       	date_aging,  
	customer_code, 		ship_to_code,   	salesperson_code,  	territory_code,
	comment_code,  		fob_code,	 	freight_code,		terms_code,
	fin_chg_code,  		price_code,	 	dest_zone_code,		posting_code,
	recurring_flag,		recurring_code,  	tax_code,		cust_po_num,
	total_weight,  		amt_gross, 	 	amt_freight,		amt_tax,
	amt_tax_included,  	amt_discount,		amt_net,		amt_paid,
	amt_due,		amt_cost,		amt_profit,		next_serial_id,
	printed_flag,		posted_flag,		hold_flag,		hold_desc,
	user_id,		customer_addr1,		customer_addr2,		customer_addr3,
	customer_addr4,		customer_addr5,		customer_addr6,		ship_to_addr1,
	ship_to_addr2,		ship_to_addr3,		ship_to_addr4,		ship_to_addr5,
	ship_to_addr6,		attention_name,		attention_phone,	amt_rem_rev,
	amt_rem_tax,		date_recurring,		location_code,		process_group_num,
	trx_state,		mark_flag,		amt_discount_taken,	amt_write_off_given, 
	source_trx_ctrl_num,	source_trx_type, 	nat_cur_code,  		rate_type_home,  
	rate_type_oper,  	rate_home, 		rate_oper, 		edit_list_flag,
	ddid,			org_id										/*  Rev 1.0  */
	FROM #arinpchg

	INSERT #arinpcdt_temp
	(
	link,		trx_ctrl_num,		doc_ctrl_num,		
	trx_type,	location_code,		item_code,		bulk_flag,
	date_entered,	line_desc,		qty_ordered,		qty_shipped,
	unit_code,	unit_price,		unit_cost,		weight,
	serial_id,	tax_code,		gl_rev_acct,		disc_prc_flag,
	discount_amt,	commission_flag,	rma_num,		return_code,
	qty_returned,	qty_prev_returned,	new_gl_rev_acct,	iv_post_flag,
	oe_orig_flag,	discount_prc,		extended_price,		calc_tax,
	reference_code,	trx_state,		mark_flag,		cust_po,
	ship_to_code,   date_shipped,		org_id										/*  Rev 1.0  */
	)
	SELECT
	link,		trx_ctrl_num,		doc_ctrl_num,		
	trx_type,	location_code,		item_code,		bulk_flag,
	date_entered,	line_desc,		qty_ordered,		qty_shipped,
	unit_code,	unit_price,		unit_cost,		weight,
	serial_id,	tax_code,		gl_rev_acct,		disc_prc_flag,
	discount_amt,	commission_flag,	rma_num,		return_code,
	qty_returned,	qty_prev_returned,	new_gl_rev_acct,	iv_post_flag,
	oe_orig_flag,	discount_prc,		extended_price,		calc_tax,
	reference_code,	trx_state,		mark_flag,		cust_po,
	ship_to_code,   date_shipped,		org_id										/*  Rev 1.0  */
	FROM #arinpcdt




	INSERT #arinptmp_temp 
	(
	trx_ctrl_num, 		doc_ctrl_num	, 	trx_desc, 	
	date_doc, 		customer_code	,	payment_code,	
	amt_payment,		prompt1_inp	, 	prompt2_inp, 	
	prompt3_inp, 		prompt4_inp	, 	amt_disc_taken,	
	cash_acct_code
	)
	select 
	trx_ctrl_num, 		doc_ctrl_num	, 	trx_desc, 	
	date_doc, 		customer_code	,	payment_code,	
	amt_payment,		prompt1_inp	, 	prompt2_inp, 	
	prompt3_inp, 		prompt4_inp	, 	amt_disc_taken,	
	cash_acct_code
	FROM 	#arinptmp

/* Rev 2.0 */
	INSERT #cca_trx_temp 
	(
	company_code	,	order_no	, 
	order_ext	,	trx_ctrl_num, 
	trx_type	,	customer_code	, 
	ccnumber	,	date_last_used,
	doc_desc    
	)
	SELECT 
	company_code	,	order_no	, 
	order_ext	,	trx_ctrl_num, 
	trx_type	,	customer_code	, 
	ccnumber	,	date_last_used	,
	doc_desc    
	FROM 	#cca_trx


DECLARE MultipleShipInv CURSOR FOR
	SELECT ship_to_code, date_shipped  FROM #arinpcdt_temp

OPEN MultipleShipInv

FETCH NEXT FROM MultipleShipInv into @ship_to_code, @date_shipped

WHILE @@FETCH_STATUS = 0
BEGIN
	DELETE #arinpchg
	DELETE #arinpcdt
	DELETE #arinptmp  		
        DELETE #cca_trx
	
	INSERT #arinpcdt
	(
	link,		trx_ctrl_num,		doc_ctrl_num,		sequence_id,
	trx_type,	location_code,		item_code,		bulk_flag,
	date_entered,	line_desc,		qty_ordered,		qty_shipped,
	unit_code,	unit_price,		unit_cost,		weight,
	serial_id,	tax_code,		gl_rev_acct,		disc_prc_flag,
	discount_amt,	commission_flag,	rma_num,		return_code,
	qty_returned,	qty_prev_returned,	new_gl_rev_acct,	iv_post_flag,
	oe_orig_flag,	discount_prc,		extended_price,		calc_tax,
	reference_code,	trx_state,		mark_flag,		cust_po,
	org_id										/*  Rev 1.0  */
	)
	SELECT
	link,		trx_ctrl_num,		doc_ctrl_num,		sequence_id,
	trx_type,	location_code,		item_code,		bulk_flag,
	date_entered,	line_desc,		qty_ordered,		qty_shipped,
	unit_code,	unit_price,		unit_cost,		weight,
	serial_id,	tax_code,		gl_rev_acct,		disc_prc_flag,
	discount_amt,	commission_flag,	rma_num,		return_code,
	qty_returned,	qty_prev_returned,	new_gl_rev_acct,	iv_post_flag,
	oe_orig_flag,	discount_prc,		extended_price,		calc_tax,
	reference_code,	trx_state,		mark_flag,		cust_po,
	org_id										/*  Rev 1.0  */
	FROM #arinpcdt_temp
	WHERE ship_to_code = @ship_to_code AND date_shipped = @date_shipped



	INSERT #arinpchg
	(
	link,	 	 	trx_ctrl_num,   	doc_ctrl_num,  		doc_desc,
	apply_to_num,  		apply_trx_type, 	order_ctrl_num, 	batch_code,
	trx_type,	 	date_entered,   	date_applied,   	date_doc,
	date_shipped,  		date_required,  	date_due,       	date_aging,  
	customer_code, 		ship_to_code,   	salesperson_code,  	territory_code,
	comment_code,  		fob_code,	 	freight_code,		terms_code,
	fin_chg_code,  		price_code,	 	dest_zone_code,		posting_code,
	recurring_flag,		recurring_code,  	tax_code,		cust_po_num,
	total_weight,  		amt_gross, 	 	amt_freight,		amt_tax,
	amt_tax_included,  	amt_discount,		amt_net,		amt_paid,
	amt_due,		amt_cost,		amt_profit,		next_serial_id,
	printed_flag,		posted_flag,		hold_flag,		hold_desc,
	user_id,		customer_addr1,		customer_addr2,		customer_addr3,
	customer_addr4,		customer_addr5,		customer_addr6,		ship_to_addr1,
	ship_to_addr2,		ship_to_addr3,		ship_to_addr4,		ship_to_addr5,
	ship_to_addr6,		attention_name,		attention_phone,	amt_rem_rev,
	amt_rem_tax,		date_recurring,		location_code,		process_group_num,
	trx_state,		mark_flag,		amt_discount_taken,	amt_write_off_given, 
	source_trx_ctrl_num,	source_trx_type, 	nat_cur_code,  		rate_type_home,  
	rate_type_oper,  	rate_home, 		rate_oper, 		edit_list_flag,
	ddid,			org_id										/*  Rev 1.0  */
	)
	SELECT
	chg.link,	 	chg.trx_ctrl_num,   	chg.doc_ctrl_num,  	chg.doc_desc,
	chg.apply_to_num,	chg.apply_trx_type, 	chg.order_ctrl_num, 	chg.batch_code,
	chg.trx_type,	 	chg.date_entered,   	chg.date_applied,   	chg.date_doc,
	@date_shipped,  	chg.date_required,  	chg.date_due,       	chg.date_aging,  
	chg.customer_code, 	@ship_to_code,   	chg.salesperson_code,  	chg.territory_code,
	chg.comment_code,  	chg.fob_code,	 	chg.freight_code,	chg.terms_code,
	chg.fin_chg_code,  	chg.price_code,	 	chg.dest_zone_code,	chg.posting_code,
	chg.recurring_flag,	chg.recurring_code,  	chg.tax_code,		chg.cust_po_num,
	chg.total_weight,	SUM(cdt.qty_shipped * cdt.unit_price), 
	chg.amt_freight,	SUM(cdt.calc_tax),
	chg.amt_tax_included,  	SUM(cdt.discount_amt),	chg.amt_net,		chg.amt_paid,
	chg.amt_due,		chg.amt_cost,		chg.amt_profit,		chg.next_serial_id,
	chg.printed_flag,	chg.posted_flag,	chg.hold_flag,		chg.hold_desc,
	chg.user_id,		chg.customer_addr1,	chg.customer_addr2,	chg.customer_addr3,
	chg.customer_addr4,	chg.customer_addr5,	chg.customer_addr6,	chg.ship_to_addr1,
	chg.ship_to_addr2,	chg.ship_to_addr3,	chg.ship_to_addr4,	chg.ship_to_addr5,
	chg.ship_to_addr6,	chg.attention_name,	chg.attention_phone,	chg.amt_rem_rev,
	chg.amt_rem_tax,	chg.date_recurring,	chg.location_code,	chg.process_group_num,
	chg.trx_state,		chg.mark_flag,		chg.amt_discount_taken,	chg.amt_write_off_given, 
	chg.source_trx_ctrl_num,chg.source_trx_type, 	chg.nat_cur_code,  	chg.rate_type_home,  
	chg.rate_type_oper,  	chg.rate_home, 		chg.rate_oper, 		chg.edit_list_flag,
	chg.ddid,		chg.org_id										/*  Rev 1.0  */
	FROM #arinpchg_temp chg, #arinpcdt_temp cdt
	WHERE cdt.ship_to_code = @ship_to_code AND cdt.date_shipped = @date_shipped
	GROUP BY chg.link,	chg.trx_ctrl_num,   
	chg.doc_ctrl_num,  	chg.doc_desc,
	chg.apply_to_num,	chg.apply_trx_type, 	chg.order_ctrl_num, 	chg.batch_code,
	chg.trx_type,	 	chg.date_entered,   	chg.date_applied,   	chg.date_doc,
	chg.date_required,  	chg.date_due,       	chg.date_aging,  
	chg.customer_code, 	chg.salesperson_code,  	chg.territory_code,
	chg.comment_code,  	chg.fob_code,	 	chg.freight_code,	chg.terms_code,
	chg.fin_chg_code,  	chg.price_code,	 	chg.dest_zone_code,	chg.posting_code,
	chg.recurring_flag,	chg.recurring_code,  	chg.tax_code,		chg.cust_po_num,
	chg.total_weight,	
	chg.amt_freight,	
	chg.amt_tax_included,  	chg.amt_net,		chg.amt_paid,
	chg.amt_due,		chg.amt_cost,		chg.amt_profit,		chg.next_serial_id,
	chg.printed_flag,	chg.posted_flag,	chg.hold_flag,		chg.hold_desc,
	chg.user_id,		chg.customer_addr1,	chg.customer_addr2,	chg.customer_addr3,
	chg.customer_addr4,	chg.customer_addr5,	chg.customer_addr6,	chg.ship_to_addr1,
	chg.ship_to_addr2,	chg.ship_to_addr3,	chg.ship_to_addr4,	chg.ship_to_addr5,
	chg.ship_to_addr6,	chg.attention_name,	chg.attention_phone,	chg.amt_rem_rev,
	chg.amt_rem_tax,	chg.date_recurring,	chg.location_code,	chg.process_group_num,
	chg.trx_state,		chg.mark_flag,		chg.amt_discount_taken,	chg.amt_write_off_given, 
	chg.source_trx_ctrl_num,chg.source_trx_type, 	chg.nat_cur_code,  	chg.rate_type_home,  
	chg.rate_type_oper,  	chg.rate_home, 		chg.rate_oper, 		chg.edit_list_flag,
	chg.ddid,		chg.org_id									/*  Rev 1.0  */		
	
	UPDATE #arinpchg
	SET amt_net = amt_gross + amt_freight + amt_tax - amt_discount

	UPDATE #arinpchg
	SET amt_due = amt_net - amt_paid

	UPDATE  #arinpchg
	SET ship_to_addr1 = ship_to.addr1,
	    ship_to_addr2 = ship_to.addr2,
	    ship_to_addr3 = ship_to.addr3,
	    ship_to_addr4 = ship_to.addr4,
	    ship_to_addr5 = ship_to.addr5,
	    ship_to_addr6 = ship_to.addr6
	FROM  	armaster ship_to
	WHERE 	#arinpchg.customer_code = ship_to.customer_code
	AND 	#arinpchg.ship_to_code = ship_to.ship_to_code
	AND 	ship_to.address_type = 1



	INSERT #arinptmp
	(
	trx_ctrl_num, 		doc_ctrl_num	, 	trx_desc, 	
	date_doc, 		customer_code	,	payment_code,	
	amt_payment,		prompt1_inp	, 	prompt2_inp, 	
	prompt3_inp, 		prompt4_inp	, 	amt_disc_taken,	
	cash_acct_code	
	)
	select 
	trx_ctrl_num, 		doc_ctrl_num, 		trx_desc, 	
	date_doc, 		customer_code,		payment_code,
	amt_payment,		prompt1_inp, 		prompt2_inp, 
	prompt3_inp, 		prompt4_inp, 	 	amt_disc_taken,
	''	
	FROM    #arinptmp_temp


	UPDATE 	#arinptmp
	SET 	cash_acct_code = araccts.ar_acct_code
	FROM 	araccts, arcust, #arinptmp
	where   araccts.posting_code = arcust.posting_code and arcust.customer_code = #arinptmp.customer_code


	INSERT #cca_trx
	(
	company_code	,	order_no	, 
	order_ext	,	trx_ctrl_num, 
	trx_type	,	customer_code	, 
	ccnumber	,	date_last_used	,
	doc_desc
	)
	SELECT 
	company_code	,	order_no	, 
	order_ext	,	trx_ctrl_num, 
	trx_type	,	customer_code	, 
	ccnumber	,	date_last_used	,
	doc_desc
	FROM 	#cca_trx_temp




	EXEC ARINImportBatch_SP 0, 0
	
	
	
	INSERT INTO CVO_Control..ccacryptaccts 
	(
	company_code	,	order_no	, 
	order_ext	,	trx_ctrl_num, 
	trx_type	,	customer_code	, 
	ccnumber	,	date_last_used  ,
	doc_desc
	)
	SELECT 
	company_code	,	order_no	, 
	order_ext	,	trx_ctrl_num, 
	trx_type	,	customer_code	, 
	ccnumber	,	date_last_used	,
	doc_desc
	FROM #cca_trx
	
	
	
	
	

	 CREATE TABLE #arinptmp (
	  trx_ctrl_num		varchar(16) NULL,
	  doc_ctrl_num		varchar(16) NULL,
	  trx_desc			varchar(40) NULL,
	  date_doc			int  NULL,
	  customer_code	varchar(8) NULL,
	  payment_code		varchar(8) NULL,
	  amt_payment		float NULL,
	  prompt1_inp		varchar(30) NULL,
	  prompt2_inp		varchar(30) NULL,
	  prompt3_inp		varchar(30) NULL,
	  prompt4_inp		varchar(30) NULL,
	  amt_disc_taken	float NULL,  
	  cash_acct_code	varchar(32) NULL
	  )

		
	DELETE #arinpcdt_temp WHERE ship_to_code = @ship_to_code AND date_shipped = @date_shipped

	
FETCH NEXT FROM MultipleShipInv into @ship_to_code, @date_shipped

END

  
CLOSE MultipleShipInv
DEALLOCATE MultipleShipInv


DROP TABLE #arinpchg_temp
DROP TABLE #arinpcdt_temp
DROP TABLE #arinptmp_temp


END
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[ARINCreateMultipleInvoice_SP] TO [public]
GO
