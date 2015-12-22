SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/* PVCS Revision or Version:Revision              
I:\vcs\GL\VW\glretern.VWv - e7.2.2 : 1.1
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1999 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1999 Epicor Software Corporation, 1999  
                 All Rights Reserved                    
*/                                                


CREATE VIEW [dbo].[glretern_vw] AS
SELECT * FROM glchart WHERE account_type = 350 AND inactive_flag = 0



/**/                                              
GO
GRANT REFERENCES ON  [dbo].[glretern_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[glretern_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[glretern_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[glretern_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[glretern_vw] TO [public]
GO
