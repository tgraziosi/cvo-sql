SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\PROCS\arcmchdr.SPv - e7.2.2 : 1.2
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                



CREATE PROC [dbo].[arcmchdr_sp]	
	@b_sys_date int,	@b_trx_type smallint,	@b_trx_num char(32),	
	@b_doc_num char(32), 	@b_gl_jcc char(32), 	@b_date_applied int,
	@b_posted_flag smallint, @b_proc_key int,	@b_user_id int,
	@b_paid_flag smallint, @b_date_doc int
AS


DECLARE	@error_occured int,	@E_ARCMCHDR_FAILED int

SELECT @error_occured = 0


INSERT	artrx (
	trx_ctrl_num,	doc_ctrl_num,	doc_desc,	
	batch_code,	trx_type,	non_ar_flag, 
	apply_to_num,	apply_trx_type,	gl_acct_code,	
	date_posted,	date_applied,	date_doc,	
	gl_trx_id,	customer_code,	payment_code,	
	amt_net,	payment_type,	prompt1_inp,	
	prompt2_inp,	prompt3_inp,	prompt4_inp,	
	deposit_num,	void_flag,	amt_on_acct,
	paid_flag,	user_id,	posted_flag,
	date_entered,	date_paid,
	order_ctrl_num,	date_shipped,
	date_required,	date_due,	date_aging,
	ship_to_code,	salesperson_code, territory_code,
	comment_code,	fob_code,	freight_code,
	terms_code,	price_code,	dest_zone_code,
	posting_code,	recurring_flag,	recurring_code,
	cust_po_num,	amt_gross,	amt_freight,
	amt_tax,	amt_discount,	amt_paid_to_date,
	amt_cost,	amt_tot_chg,	fin_chg_code,
	tax_code,	commission_flag, cash_acct_code,
	non_ar_doc_num, purge_flag )
SELECT	trx_ctrl_num,	doc_ctrl_num,	doc_desc,
	batch_code,	trx_type,	0,
	apply_to_num,	apply_trx_type,	" ",
	@b_sys_date,	date_applied,	date_doc,	
	@b_gl_jcc,	customer_code,	" ",
	amt_net,	0,	" ",
	" ",		" ",		" ",
	" ",		0,		0,
	@b_paid_flag,	user_id,	1,
	date_entered,	0,
	order_ctrl_num,	date_shipped,
	date_required,	date_due,	date_aging,
	ship_to_code,	salesperson_code, territory_code,
	comment_code,	fob_code,	freight_code,
	terms_code,	price_code,	dest_zone_code,
	posting_code,	recurring_flag,	recurring_code,
	cust_po_num,	amt_gross,	amt_freight,
	amt_tax,	amt_discount,	0,
	amt_cost,	0,		fin_chg_code,
	tax_code,	0,		" ",
	" ", 0
FROM	arinpchg
WHERE trx_ctrl_num = @b_trx_num
 AND	trx_type = @b_trx_type
IF @@error != 0
	SELECT @error_occured = 1


INSERT	artrxtax(
	trx_type,	doc_ctrl_num,	tax_type_code,
	date_applied,	amt_gross,	amt_taxable,	
	amt_tax,	date_doc )
SELECT	trx_type,	@b_doc_num,	tax_type_code,
	@b_date_applied, amt_gross,	amt_taxable,	
	amt_final_tax,	@b_date_doc
FROM	arinptax
WHERE	trx_type = @b_trx_type
 AND	trx_ctrl_num = @b_trx_num
IF @@error != 0
	SELECT @error_occured = 1


INSERT	artrxcom(
	trx_ctrl_num,	trx_type,	doc_ctrl_num,	sequence_id,
	salesperson_code, amt_commission, percent_flag,	exclusive_flag,
	split_flag,	commission_flag )
SELECT	trx_ctrl_num,	trx_type,	@b_doc_num,	sequence_id,
	salesperson_code, amt_commission, percent_flag,	exclusive_flag,
	split_flag,	0
FROM	arinpcom
WHERE	trx_type = @b_trx_type
 AND	trx_ctrl_num = @b_trx_num
IF @@error != 0
	SELECT @error_occured = 1


IF @error_occured = 1
BEGIN
	SELECT	@E_ARCMCHDR_FAILED = e_code
	FROM	arerrdef
	WHERE	e_sdesc = "E_ARCMCHDR_FAILED"
	AND	client_id = "POSTCM"

	RETURN @E_ARCMCHDR_FAILED
END
ELSE
	RETURN 0



/**/                                              
GO
GRANT EXECUTE ON  [dbo].[arcmchdr_sp] TO [public]
GO
