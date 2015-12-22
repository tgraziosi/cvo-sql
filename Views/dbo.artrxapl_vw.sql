SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\VW\artrxapl.VWv - e7.2.2 : 1.5
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1999 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1999 Epicor Software Corporation, 1999  
                 All Rights Reserved                    
*/                                                



CREATE VIEW [dbo].[artrxapl_vw]
AS 
SELECT	* 
FROM 		artrx 
WHERE		doc_ctrl_num = apply_to_num
	AND	trx_type = apply_trx_type
	AND	trx_type in (2021, 2031)
	AND 	paid_flag = 0 
	AND	void_flag = 0



/**/                                              
GO
GRANT REFERENCES ON  [dbo].[artrxapl_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[artrxapl_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[artrxapl_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[artrxapl_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[artrxapl_vw] TO [public]
GO
