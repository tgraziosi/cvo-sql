SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/* PVCS Revision or Version:Revision              
I:\vcs\GL\VW\glapp.VWv - e7.2.2 : 1.2
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1999 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1999 Epicor Software Corporation, 1999  
                 All Rights Reserved                    
*/                                                


CREATE VIEW [dbo].[glapp_vw]
AS SELECT app_id, app_name, "app_code" = journal_type FROM glappid


/**/                                              
GO
GRANT REFERENCES ON  [dbo].[glapp_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[glapp_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[glapp_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[glapp_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[glapp_vw] TO [public]
GO
