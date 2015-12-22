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


CREATE PROCEDURE [dbo].[gltc_dm_profile_sp]
	@trx_ctrl_num	varchar(20)
AS
BEGIN

if exists (select * from sysobjects where id = object_id('#gltcdocprofile'))
   DROP TABLE #gltcdocprofile

	DECLARE @posted_flag int
	DECLARE @trx_type int
	select @posted_flag =  posted_flag, @trx_type = trx_type  from gltcrecon where trx_ctrl_num = @trx_ctrl_num

			if (@posted_flag = 1)
				insert #gltcdocprofile 
				select a.trx_ctrl_num, a.doc_ctrl_num, a.apply_to_num, a.po_ctrl_num, a.ticket_num,
					a.currency_code AS nat_cur_code, a.vend_order_num, a.user_trx_type_code,
					approval_code = '', a.tax_code,  a.posting_code, terms_code = '',
					a.branch_code, a.class_code, a.fob_code, recurring_code = '', a.comment_code, 
					a.date_entered, a.date_doc, a.date_applied,	date_required = '', date_received = '', 
					date_due = '', date_aging = '', a.date_posted, date_paid = '', date_discount = '',
					a.amt_gross, a.amt_discount, a.amt_freight, a.amt_misc, a.amt_tax, 
					a.amt_net, amt_paid_to_date = '', balance = '', a.doc_desc,
					c.vendor_code, c.vendor_name, 
					b.pay_to_code, 
					CASE WHEN b.pay_to_code = '' THEN ''
					ELSE b.address_name 
					END AS pay_to_name, b.attention_name, b.attention_phone, 
					b.addr1, b.addr2, b.addr3, b.addr4, b.addr5, b.addr6
					from apdmhdr a, apmaster b, apvend c 
					where a.trx_ctrl_num = @trx_ctrl_num AND c.vendor_code = a.vendor_code
					AND b.vendor_code = a.vendor_code AND b.pay_to_code = a.pay_to_code 
			else if (@posted_flag = 0)
					insert #gltcdocprofile 
				select a.trx_ctrl_num, a.doc_ctrl_num, a.apply_to_num, a.po_ctrl_num, a.ticket_num,
					a.nat_cur_code, a.vend_order_num, a.user_trx_type_code,
					approval_code = '', a.tax_code,  a.posting_code, terms_code = '',
					a.branch_code, a.class_code, a.fob_code, recurring_code = '', a.comment_code, 
					a.date_entered, a.date_doc, a.date_applied,	date_required = '', date_received = '', 
					date_due = '', date_aging = '', date_posted = '', date_paid = '', date_discount = '',
					a.amt_gross, a.amt_discount, a.amt_freight, a.amt_misc, a.amt_tax, 
					a.amt_net, amt_paid_to_date = '', balance = '', a.doc_desc,
					c.vendor_code, c.vendor_name, 
					b.pay_to_code, 
					CASE WHEN b.pay_to_code = '' THEN ''
					ELSE b.address_name 
					END AS pay_to_name, b.attention_name, b.attention_phone, 
					b.addr1, b.addr2, b.addr3, b.addr4, b.addr5, b.addr6
					from apinpchg a, apmaster b, apvend c 
					where a.trx_ctrl_num = @trx_ctrl_num AND c.vendor_code = a.vendor_code
					AND b.vendor_code = a.vendor_code AND b.pay_to_code = a.pay_to_code 
		
					
END
/**/                                              

GO
GRANT EXECUTE ON  [dbo].[gltc_dm_profile_sp] TO [public]
GO
