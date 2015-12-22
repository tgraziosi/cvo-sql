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
CREATE view [dbo].[apcheckdet_vw] AS SELECT a.payment_num, a.invoice_num, a.invoice_date, 
voucher_num, a.voucher_date_due, a.amt_paid, a.amt_disc_taken, a.amt_net, a.check_num, 
a.description, a.payment_type, c.symbol, c.curr_precision, voucher_internal_memo = case 
 when a.voucher_memo = 1 then a.voucher_internal_memo  else ''  end, comment_line = case 
 when a.voucher_comment = 1 then a.comment_line  else ''  end, voucher_classify = case 
 when a.voucher_classification = 1 then a.voucher_classify  else ''  end, a.nat_cur_code 
FROM apchkstb a, apcheck_vw b, glcurr_vw c WHERE a.payment_num = b.trx_ctrl_num AND a.nat_cur_code = c.currency_code 
UNION SELECT a.trx_ctrl_num payment_num, d.doc_ctrl_num invoice_num, d.date_doc invoice_date, 
a.trx_ctrl_num voucher_num, d.date_due voucher_date_due, a.amt_applied amt_paid, 
a.amt_disc_taken, (a.amt_applied - a.amt_disc_taken) amt_net, b.doc_ctrl_num check_num, 
a.line_desc description, e.payment_type, c.symbol, c.curr_precision, "" voucher_internal_memo, 
"" comment_line, "" voucher_classify, e.currency_code nat_cur_code FROM appydet a, apcheck_vw b, glcurr_vw c, apvohdr d, appyhdr e 
WHERE a.trx_ctrl_num = b.trx_ctrl_num AND a.apply_to_num = d.trx_ctrl_num AND a.trx_ctrl_num = e.trx_ctrl_num 
AND e.currency_code = c.currency_code 

 /**/
GO
GRANT REFERENCES ON  [dbo].[apcheckdet_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[apcheckdet_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[apcheckdet_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[apcheckdet_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[apcheckdet_vw] TO [public]
GO
