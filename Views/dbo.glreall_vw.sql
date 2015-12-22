SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/* PVCS Revision or Version:Revision              
I:\vcs\GL\VW\glreall.VWv - e7.2.2 : 1.1
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1999 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1999 Epicor Software Corporation, 1999  
                 All Rights Reserved                    
*/                                                


CREATE VIEW [dbo].[glreall_vw] AS SELECT * FROM glreall WHERE posted_flag = 0



/**/                                              
GO
GRANT REFERENCES ON  [dbo].[glreall_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[glreall_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[glreall_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[glreall_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[glreall_vw] TO [public]
GO
