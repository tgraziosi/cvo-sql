SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/* PVCS Revision or Version:Revision              
I:\vcs\GL\VW\glusers.VWv - e7.2.2 : 1.0
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1999 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1999 Epicor Software Corporation, 1999  
                 All Rights Reserved                    
*/                                                


CREATE VIEW [dbo].[glusers_vw]
AS SELECT * FROM CVO_Control..smusers


/**/                                              
GO
GRANT REFERENCES ON  [dbo].[glusers_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[glusers_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[glusers_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[glusers_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[glusers_vw] TO [public]
GO
