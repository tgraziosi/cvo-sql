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
create view [dbo].[apcheck_vw] as select a.trx_ctrl_num, a.doc_ctrl_num, a.batch_code, a.user_id, 
a.payment_code, a.vendor_code, apvend.vendor_name, vend_acct = case  when c.print_acct_num = 1 then ISNULL(apvend.vend_acct,"") 
 else ''  end, ISNULL(apvend.vend_class_code,"") vend_class_code, apvend.addr_sort1, 
apvend.addr_sort2, apvend.addr_sort3, apvend.addr1, apvend.addr2, apvend.addr3, apvend.addr4, 
apvend.addr5, apvend.addr6, a.pay_to_code, "" pay_to_name, trx_desc = case  when c.payment_memo = 1 then a.trx_desc 
 else ''  end, a.date_doc printed_check_date, a.date_doc date_doc, a.date_applied, 
0 mark_flag, ROUND(a.amt_payment,2) amt_payment, a.nat_cur_code, a.print_batch_num, 
a.cash_acct_code from apinppyt a, appymeth b, apchkstb c, apvend where a.printed_flag = 1 
and a.payment_code = b.payment_code and b.payment_type = 2 AND a.vendor_code = apvend.vendor_code 
AND a.trx_ctrl_num = c.payment_num union select a.trx_ctrl_num, a.doc_ctrl_num, a.batch_code, 
a.user_id, a.payment_code, a.vendor_code, apvend.vendor_name, ISNULL(apvend.vend_acct,""), 
ISNULL(apvend.vend_class_code,""), apvend.addr_sort1, apvend.addr_sort2, apvend.addr_sort3, 
apvend.addr1, apvend.addr2, apvend.addr3, apvend.addr4, apvend.addr5, apvend.addr6, 
a.pay_to_code, "" pay_to_name, a.doc_desc, a.date_doc printed_check_date, a.date_doc date_doc, 
a.date_applied, 0 mark_flag, ROUND(a.amt_net,2) amt_payment, a.currency_code, a.print_batch_num, 
a.cash_acct_code from appyhdr a, appymeth b, apvend where a.payment_code = b.payment_code 
and a.void_flag = 0 and b.payment_type = 2 AND a.vendor_code = apvend.vendor_code 


 /**/
GO
GRANT REFERENCES ON  [dbo].[apcheck_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[apcheck_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[apcheck_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[apcheck_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[apcheck_vw] TO [public]
GO
