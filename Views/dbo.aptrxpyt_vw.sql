SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\VW\aptrxpyt.VWv - e7.2.2 : 1.4
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1999 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1999 Epicor Software Corporation, 1999  
                 All Rights Reserved                    
*/                                                




CREATE VIEW	[dbo].[aptrxpyt_vw]
	AS 	SELECT *
	FROM	appyhdr

GO
GRANT REFERENCES ON  [dbo].[aptrxpyt_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[aptrxpyt_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[aptrxpyt_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[aptrxpyt_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[aptrxpyt_vw] TO [public]
GO
