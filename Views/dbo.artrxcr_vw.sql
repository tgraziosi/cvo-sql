SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\VW\artrxcr.VWv - e7.2.2 : 1.5
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1999 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1999 Epicor Software Corporation, 1999  
                 All Rights Reserved                    
*/                                                



CREATE VIEW [dbo].[artrxcr_vw]
AS 
SELECT	* 
FROM 		artrx 
WHERE		doc_ctrl_num = apply_to_num
	AND	trx_type = apply_trx_type
	AND (paid_flag = 0 or (paid_flag = 1 and amt_net <> amt_paid_to_date)) 
	AND	void_flag = 0



/**/                                              
GO
GRANT REFERENCES ON  [dbo].[artrxcr_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[artrxcr_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[artrxcr_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[artrxcr_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[artrxcr_vw] TO [public]
GO
