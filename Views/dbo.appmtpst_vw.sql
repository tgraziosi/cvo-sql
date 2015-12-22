SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\VW\appmtpst.VWv - e7.2.2 : 1.2
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1999 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1999 Epicor Software Corporation, 1999  
                 All Rights Reserved                    
*/                                                


CREATE VIEW [dbo].[appmtpst_vw]
AS SELECT 
		*
FROM appyhdr
WHERE void_flag = 0
AND				payment_type IN (1,3)


GO
GRANT REFERENCES ON  [dbo].[appmtpst_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[appmtpst_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[appmtpst_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[appmtpst_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[appmtpst_vw] TO [public]
GO
