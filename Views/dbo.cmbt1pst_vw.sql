SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/* PVCS Revision or Version:Revision              
I:\vcs\CM\VW\cmbt1pst.VWv - e7.2.2 : 1.0
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1999 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1999 Epicor Software Corporation, 1999  
                 All Rights Reserved                    
*/                                                





CREATE VIEW [dbo].[cmbt1pst_vw] AS
SELECT 
	trx_ctrl_num,
	doc_ctrl_num,
	description,
	hold_flag = 'No',
	posted_flag = 'Yes',
	cash_acct_code_from,
	currency_code_from,
	amount_from,
	bank_charge_amt_from,
	trx_type_cls_from,
	cash_acct_code_to,
	currency_code_to,
	amount_to,
	bank_charge_amt_to,
	trx_type_cls_to,
	date_applied,
	date_entered,
	date_document,
	date_posted,
	gl_trx_id,
	user_name
	
FROM 
	cmtrxbtr cmtrxbtr, CVO_Control..smusers smusers
WHERE
	cmtrxbtr.user_id = smusers.user_id
 	 
 


/**/                                              
GO
GRANT REFERENCES ON  [dbo].[cmbt1pst_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cmbt1pst_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cmbt1pst_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cmbt1pst_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cmbt1pst_vw] TO [public]
GO
