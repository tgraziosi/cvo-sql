SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\VW\arhold.VWv - e7.2.2 : 1.4
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1999 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1999 Epicor Software Corporation, 1999  
                 All Rights Reserved                    
*/                                                



CREATE VIEW [dbo].[arhold_vw] 
AS
SELECT customer_code, 
	hold_flag, 
	amt_net,
	nat_cur_code, 
	hold_desc, 
	trx_type, 
	trx_ctrl_num, 
 date_doc, 
 date_required, 
 batch_code, 
 user_id
FROM arinpchg
WHERE hold_flag = 1 
AND	trx_type <= 2031
AND	recurring_flag = 1



/**/                                              
GO
GRANT REFERENCES ON  [dbo].[arhold_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[arhold_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[arhold_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[arhold_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[arhold_vw] TO [public]
GO
