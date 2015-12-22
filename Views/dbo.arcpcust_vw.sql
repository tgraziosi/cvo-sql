SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\VW\arcpcust.VWv - e7.2.2 : 1.10
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1999 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1999 Epicor Software Corporation, 1999  
                 All Rights Reserved                    
*/                                                



CREATE VIEW [dbo].[arcpcust_vw]
AS 
SELECT DISTINCT	
	artrx.customer_code, 
	artrx.doc_ctrl_num, 
	artrx.nat_cur_code,
	artrx.date_doc,
	artrx.payment_code,
	artrx.payment_type,
	artrx.non_ar_flag,
	artrx.gl_acct_code,
	artrx.prompt1_inp,
	artrx.prompt2_inp,
	artrx.prompt3_inp,
	artrx.prompt4_inp,
	artrx.deposit_num,
	artrx.amt_net,
	artrx.amt_on_acct,
	artrx.cash_acct_code,
	artrx.non_ar_doc_num,
	artrx.reference_code,
	artrx.date_applied,		
	artrx.rate_type_home,
	artrx.rate_type_oper,
	artrx.rate_home,
	artrx.rate_oper,
    artrx.org_id
FROM	artrx
WHERE	artrx.trx_type = 2111
AND	artrx.void_flag = 0
AND	(artrx.payment_type = 1
	OR artrx.payment_type = 3 AND amt_on_acct < amt_net)	 



/**/                                              
GO
GRANT REFERENCES ON  [dbo].[arcpcust_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[arcpcust_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[arcpcust_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[arcpcust_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[arcpcust_vw] TO [public]
GO
