SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\VW\appytpst.VWv - e7.2.2 : 1.8
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1999 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1999 Epicor Software Corporation, 1999  
                 All Rights Reserved                    
*/                                                




CREATE VIEW [dbo].[appytpst_vw]
AS SELECT 
		appyhdr.vendor_code,
		apvend.vendor_name,
		appyhdr.pay_to_code,
		appyhdr.doc_ctrl_num,
		appyhdr.cash_acct_code,
		appyhdr.trx_ctrl_num
FROM appyhdr, apvend
WHERE appyhdr.vendor_code = apvend.vendor_code
AND appyhdr.void_flag = 0


GO
GRANT REFERENCES ON  [dbo].[appytpst_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[appytpst_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[appytpst_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[appytpst_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[appytpst_vw] TO [public]
GO
