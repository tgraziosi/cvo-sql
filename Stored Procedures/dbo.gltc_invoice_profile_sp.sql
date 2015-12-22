SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2006 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2006 Epicor Software Corporation, 2006    
                  All Rights Reserved                    
*/                                  


CREATE PROCEDURE [dbo].[gltc_invoice_profile_sp]
	@trx_ctrl_num	varchar(20)
AS
BEGIN

if exists (select * from sysobjects where id = object_id('#gltcdocprofile'))
   DROP TABLE #gltcdocprofile

	DECLARE @posted_flag int
	DECLARE @trx_type int
	DECLARE @table	varchar(20)
	select @posted_flag =  posted_flag, @trx_type = trx_type  from gltcrecon where trx_ctrl_num = @trx_ctrl_num

			
			if (@posted_flag = 1)
				insert #gltcdocprofile 
				select a.trx_ctrl_num, a.customer_code, a.cust_po_num, a.doc_ctrl_num, a.apply_to_num, a.order_ctrl_num, a.doc_desc,
					a.nat_cur_code, a.tax_code, a.posting_code, a.terms_code, a.salesperson_code,  a.territory_code, a.dest_zone_code,
					a.freight_code, a.price_code, a.fob_code, a.recurring_code, a.comment_code, a.date_entered, a.date_doc, a.date_applied,
					a.date_required, a.date_shipped, a.date_due, a.date_aging, a.date_posted, a.date_paid, a.amt_gross, a.amt_discount,
					a.amt_freight, a.amt_tax, a.amt_net, a.amt_tot_chg, a.amt_paid_to_date, a.ship_to_code, a.recurring_flag,
					b.attention_name, b.attention_phone, b.ship_addr1, b.ship_addr2, b.ship_addr3, b.ship_addr4, b.ship_addr5, b.ship_addr6, b.amt_due 
					from artrx a, artrxxtr b where a.trx_ctrl_num = @trx_ctrl_num AND a.trx_ctrl_num = b.trx_ctrl_num 
			else if (@posted_flag = 0)
				insert #gltcdocprofile 		
				select a.trx_ctrl_num, a.customer_code, a.cust_po_num, a.doc_ctrl_num, a.apply_to_num, a.order_ctrl_num, a.doc_desc,
				a.nat_cur_code, a.tax_code, a.posting_code, a.terms_code, a.salesperson_code,  a.territory_code, a.dest_zone_code,
				a.freight_code, a.price_code, a.fob_code, a.recurring_code, a.comment_code, a.date_entered, a.date_doc, a.date_applied,
				a.date_required, a.date_shipped, a.date_due, a.date_aging, date_posted = 0, date_paid = 0, a.amt_gross, a.amt_discount,
				a.amt_freight, a.amt_tax, a.amt_net, amt_tot_chg = 0, amt_paid_to_date = 0, a.ship_to_code, a.recurring_flag,
				a.attention_name, a.attention_phone, a.ship_to_addr1 AS ship_addr1, a.ship_to_addr2 AS ship_addr2, 
				a.ship_to_addr3 AS ship_addr3, a.ship_to_addr4 AS ship_addr4, a.ship_to_addr5 AS ship_addr5, a.ship_to_addr6 AS ship_addr6, a.amt_due
				from arinpchg a where a.trx_ctrl_num = @trx_ctrl_num

END
/**/                                              

GO
GRANT EXECUTE ON  [dbo].[gltc_invoice_profile_sp] TO [public]
GO
