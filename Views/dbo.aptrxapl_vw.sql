SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\VW\aptrxapl.VWv - e7.2.2 : 1.7
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1999 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1999 Epicor Software Corporation, 1999  
                 All Rights Reserved                    
*/                                                




CREATE VIEW [dbo].[aptrxapl_vw]
	AS SELECT	*
	FROM 		apvohdr
	WHERE	accrual_flag = 0
	AND		paid_flag = 0
	AND		payment_hold_flag = 0


GO
GRANT REFERENCES ON  [dbo].[aptrxapl_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[aptrxapl_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[aptrxapl_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[aptrxapl_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[aptrxapl_vw] TO [public]
GO
