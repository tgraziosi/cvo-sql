SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\VW\apalert.VWv - e7.2.2 : 1.0
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1999 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1999 Epicor Software Corporation, 1999  
                 All Rights Reserved                    
*/                                                





create view [dbo].[apalert_vw] as
select trx_type = 4091, trx_ctrl_num, vendor_code, amt_net, date_doc 
FROM apvohdr
UNION
select trx_type = 4092, trx_ctrl_num, vendor_code, amt_net, date_doc 
FROM apdmhdr
UNION
select trx_type = 4021, a.trx_ctrl_num, b.vendor_code, b.amt_net, b.date_doc 
FROM apvahdr a, apvohdr b
WHERE a.apply_to_num = b.trx_ctrl_num
UNION
select trx_type = 4111, trx_ctrl_num, vendor_code, amt_net, date_doc 
FROM appyhdr
WHERE payment_type = 1
UNION
select trx_type = 4112, a.trx_ctrl_num, b.vendor_code, b.amt_net, b.date_doc 
FROM appahdr a, appyhdr b
WHERE a.cash_acct_code = b.cash_acct_code
and a.doc_ctrl_num = b.doc_ctrl_num



GO
GRANT REFERENCES ON  [dbo].[apalert_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[apalert_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[apalert_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[apalert_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[apalert_vw] TO [public]
GO
