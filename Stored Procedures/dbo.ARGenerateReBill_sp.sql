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

































































  



					  

























































 

































































































































































































































































































CREATE PROCEDURE [dbo].[ARGenerateReBill_sp] 	 
	@original_doc_ctrl_num varchar(16),
	@user_param varchar (30), 
	@new_trx_ctrl_num varchar(16) OUTPUT,
	@new_batch_code varchar(16) OUTPUT,
	@debug_level 	int = 0
AS




DECLARE @company_code varchar (30), 
		@original_trx_ctrl_num varchar(16),
		@num int 
DECLARE @control_total float, @hdr_org_id varchar(30)
DECLARE @date_applied int
DECLARE @num2 int 
DECLARE @total_weight float

SELECT @company_code = min(company_code)
FROM ewcomp_vw a JOIN arco b ON (a.company_id = b.company_id)




SELECT @original_trx_ctrl_num = a.trx_ctrl_num, @control_total = a.amt_net,
	@hdr_org_id = a.org_id, @date_applied = a.date_applied
FROM artrx a WHERE a.doc_ctrl_num = @original_doc_ctrl_num AND a.trx_type = 2031

IF @@ROWCOUNT = 0
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ARGenerateReBill.cpp" + ", line " + STR( 50, 5 ) + " -- EXIT: "
	RETURN -1
END




EXEC ARGetNextControl_SP 2000, @new_trx_ctrl_num OUTPUT, @num OUTPUT
IF( @@error != 0 )
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ARGenerateReBill.cpp" + ", line " + STR( 60, 5 ) + " -- EXIT: "
	RETURN -1
END




IF EXISTS(select 1 from arco where batch_proc_flag = 1)
begin
	EXEC ARGetNextControl_SP 2100, @new_batch_code OUTPUT, @num2 OUTPUT 
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ARGenerateReBill.cpp" + ", line " + STR( 72, 5 ) + " -- EXIT: "
		RETURN -1
	END
end
ELSE
begin 
	SELECT @new_batch_code = ''
end




begin tran ARGen01




IF EXISTS(select 1 from arco where batch_proc_flag = 1)
begin
	INSERT batchctl 
	( batch_ctrl_num,batch_description,start_date,start_time,
	completed_date,completed_time,control_number,control_total,
	actual_number,actual_total,batch_type,document_name,hold_flag,
	posted_flag,void_flag,selected_flag,number_held,date_applied,
	date_posted,time_posted,start_user,completed_user,posted_user,
	company_code,selected_user_id,process_group_num,page_fill_1,
	page_fill_2,page_fill_3,page_fill_4,page_fill_5,page_fill_6,
	page_fill_7,page_fill_8,org_id,timestamp ) 
	VALUES (  @new_batch_code,  'From Invoice ' + @original_doc_ctrl_num,  @date_applied,  0 ,  
	0,  0,  1,  @control_total,  1,  @control_total,  2010,  "Invoice",  0,  
	0,  0,  0,  0,  @date_applied,  
	0,  0,  @user_param ,  "",  "",  
	@company_code,  0,  "",  "",  
	"",  "",  "",  "",  "",  
	"",  "",  @hdr_org_id,  NULL )
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ARGenerateReBill.cpp" + ", line " + STR( 109, 5 ) + " -- EXIT: "
		ROLLBACK TRAN ARGen01
		RETURN -1
	END
end




SELECT @total_weight = ISNULL(SUM(artrxcdt.weight),0) 
FROM artrxcdt WHERE trx_ctrl_num = @original_trx_ctrl_num AND trx_type = 2031




INSERT INTO arinpchg
( trx_ctrl_num, doc_ctrl_num, doc_desc, apply_to_num, apply_trx_type, order_ctrl_num, batch_code, 
trx_type, date_entered, date_applied, date_doc, date_shipped, date_required, date_due, date_aging, 
customer_code, ship_to_code, salesperson_code, territory_code, comment_code, fob_code, freight_code, 
terms_code, fin_chg_code, price_code, dest_zone_code, posting_code, recurring_flag, recurring_code, 
tax_code, cust_po_num, total_weight, amt_gross, amt_freight, amt_tax, amt_tax_included, amt_discount, 
amt_net, amt_paid, amt_due, amt_cost, amt_profit, next_serial_id, printed_flag, posted_flag, hold_flag, 
hold_desc, user_id, customer_addr1, customer_addr2, customer_addr3, customer_addr4, customer_addr5, 
customer_addr6, customer_city, customer_state, customer_postal_code, customer_country_code, 
ship_to_addr1, ship_to_addr2, ship_to_addr3, ship_to_addr4, ship_to_addr5, ship_to_addr6, 
ship_to_city, ship_to_state, ship_to_postal_code, ship_to_country_code, 
attention_name, attention_phone, amt_rem_rev, amt_rem_tax, date_recurring, location_code, process_group_num, 
source_trx_ctrl_num, source_trx_type, amt_discount_taken, amt_write_off_given, nat_cur_code, rate_type_home, 
rate_type_oper, rate_home, rate_oper, edit_list_flag, ddid, writeoff_code, vat_prc, org_id)
SELECT @new_trx_ctrl_num trx_ctrl_num, '' doc_ctrl_num, 'Created from Invoice ' + @original_doc_ctrl_num, 
'' apply_to_num, 0 apply_trx_type, a.order_ctrl_num, @new_batch_code batch_code, 
a.trx_type, a.date_entered, a.date_applied, a.date_doc, a.date_shipped, a.date_required, 
a.date_due, a.date_aging, a.customer_code, a.ship_to_code, a.salesperson_code, a.territory_code, 
a.comment_code, a.fob_code, a.freight_code, a.terms_code, a.fin_chg_code, a.price_code, a.dest_zone_code,
 a.posting_code, a.recurring_flag, a.recurring_code, a.tax_code, a.cust_po_num, @total_weight total_weight, 
 a.amt_gross, a.amt_freight, a.amt_tax, a.amt_tax_included, a.amt_discount, a.amt_net, 0 amt_paid, 
 a.amt_net amt_due, a.amt_cost, 0 amt_profit, 0 next_serial_id, 0 printed_flag, 
 0 posted_flag, 0 hold_flag, '' hold_desc, a.user_id, c.addr1 customer_addr1, c.addr2 customer_addr2, 
 c.addr3 customer_addr3, c.addr4 customer_addr4, c.addr5 customer_addr5, c.addr6 customer_addr6, 
c.customer_city, c.customer_state, c.customer_postal_code, c.customer_country_code,
 c.ship_addr1 ship_to_addr1, c.ship_addr2 ship_to_addr2, c.ship_addr3 ship_to_addr3, 
c.ship_addr4 ship_to_addr4, c.ship_addr5 ship_to_addr5, c.ship_addr6 ship_to_addr6, 
c.ship_to_city, c.ship_to_state, c.ship_to_postal_code, c.ship_to_country_code, 
c.attention_name, c.attention_phone, 0 amt_rem_rev, 0 amt_rem_tax, 0 date_recurring, 
b.location_code, NULL process_group_num, a.source_trx_ctrl_num, a.source_trx_type, a.amt_discount_taken,
 a.amt_write_off_given, a.nat_cur_code, a.rate_type_home, 
a.rate_type_oper, a.rate_home, a.rate_oper, '' edit_list_flag, a.ddid, '' writeoff_code, 0 vat_prc, a.org_id
FROM artrx a LEFT OUTER JOIN arcust b ON (a.customer_code = b.customer_code)
LEFT OUTER JOIN artrxxtr c ON (a.trx_ctrl_num = c.trx_ctrl_num AND a.trx_type = c.trx_type)
WHERE a.trx_ctrl_num = @original_trx_ctrl_num AND a.trx_type = 2031
IF( @@error != 0 )
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ARGenerateReBill.cpp" + ", line " + STR( 161, 5 ) + " -- EXIT: "
	ROLLBACK TRAN ARGen01
	RETURN -1
END




INSERT INTO arinpcdt
(trx_ctrl_num, doc_ctrl_num, sequence_id, trx_type, location_code, item_code, 
bulk_flag, date_entered, line_desc, qty_ordered, qty_shipped, unit_code, unit_price, 
unit_cost, weight, serial_id, tax_code, gl_rev_acct, disc_prc_flag, discount_amt, 
commission_flag, rma_num, return_code, qty_returned, qty_prev_returned, new_gl_rev_acct, 
iv_post_flag, oe_orig_flag, discount_prc, extended_price, calc_tax, 
reference_code, new_reference_code, cust_po, org_id)
SELECT @new_trx_ctrl_num, '' doc_ctrl_num, sequence_id, trx_type, location_code, item_code, 
bulk_flag, date_entered, line_desc, qty_ordered, qty_shipped, unit_code, unit_price, 
0 unit_cost, weight, serial_id, tax_code, gl_rev_acct, disc_prc_flag, discount_amt, 
0 commission_flag, rma_num, return_code, qty_returned, 0 qty_prev_returned, new_gl_rev_acct, 
1 iv_post_flag, 0 oe_orig_flag, discount_prc, extended_price, calc_tax, reference_code, 
new_reference_code, cust_po, org_id
from artrxcdt where trx_ctrl_num = @original_trx_ctrl_num AND trx_type = 2031
IF( @@error != 0 )
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ARGenerateReBill.cpp" + ", line " + STR( 185, 5 ) + " -- EXIT: "
	ROLLBACK TRAN ARGen01
	RETURN -1
END






SELECT @new_trx_ctrl_num trx_ctrl_num, trx_type, IDENTITY(int, 1, 1) sequence_id, tax_type_code, 
amt_taxable, amt_gross, amt_tax, amt_tax amt_final_tax
INTO #arinptax_REBILLS
FROM artrxtax where doc_ctrl_num = @original_doc_ctrl_num AND trx_type = 2031
IF( @@error != 0 )
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ARGenerateReBill.cpp" + ", line " + STR( 201, 5 ) + " -- EXIT: "
	ROLLBACK TRAN ARGen01
	RETURN -1
END

INSERT INTO arinptax
(trx_ctrl_num, trx_type, sequence_id, tax_type_code, 
amt_taxable, amt_gross, amt_tax, amt_final_tax)
SELECT trx_ctrl_num, trx_type, sequence_id, tax_type_code, 
amt_taxable, amt_gross, amt_tax, amt_final_tax
FROM #arinptax_REBILLS 
IF( @@error != 0 )
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ARGenerateReBill.cpp" + ", line " + STR( 214, 5 ) + " -- EXIT: "
	ROLLBACK TRAN ARGen01
	RETURN -1
END

DROP TABLE #arinptax_REBILLS
IF( @@error != 0 )
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ARGenerateReBill.cpp" + ", line " + STR( 222, 5 ) + " -- EXIT: "
	ROLLBACK TRAN ARGen01
	RETURN -1
END




INSERT INTO arinpage
(trx_ctrl_num, sequence_id, doc_ctrl_num, apply_to_num, apply_trx_type, trx_type, 
date_applied, date_due, date_aging, customer_code, 
salesperson_code, territory_code, price_code, amt_due)
SELECT @new_trx_ctrl_num, ref_id sequence_id, doc_ctrl_num, apply_to_num, apply_trx_type, trx_type, 
date_applied, date_due, date_aging, customer_code, 
salesperson_code, territory_code, price_code, amount amt_due
FROM artrxage where trx_ctrl_num = @original_trx_ctrl_num AND trx_type = 2031
IF( @@error != 0 )
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ARGenerateReBill.cpp" + ", line " + STR( 240, 5 ) + " -- EXIT: "
	ROLLBACK TRAN ARGen01
	RETURN -1
END




INSERT INTO arinpcom
(trx_ctrl_num, trx_type, sequence_id, salesperson_code, 
amt_commission, percent_flag, exclusive_flag, split_flag)
SELECT @new_trx_ctrl_num, trx_type, sequence_id, salesperson_code, 
amt_commission, percent_flag, exclusive_flag, split_flag
FROM artrxcom where trx_ctrl_num = @original_trx_ctrl_num AND trx_type = 2031
IF( @@error != 0 )
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ARGenerateReBill.cpp" + ", line " + STR( 256, 5 ) + " -- EXIT: "
	ROLLBACK TRAN ARGen01
	RETURN -1
END




INSERT INTO comments 
(company_code, key_1, key_type, sequence_id, date_created, 
created_by, date_updated, updated_by, link_path, note)
SELECT company_code, @new_trx_ctrl_num key_1, key_type, sequence_id, date_created, 
created_by, date_updated, updated_by, link_path, note
FROM comments where key_1 = @original_trx_ctrl_num AND key_type = 2031
IF( @@error != 0 )
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ARGenerateReBill.cpp" + ", line " + STR( 272, 5 ) + " -- EXIT: "
	ROLLBACK TRAN ARGen01
	RETURN -1
END


COMMIT TRAN ARGen01


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[ARGenerateReBill_sp] TO [public]
GO
