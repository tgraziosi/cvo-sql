SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\APPCORE\VW\control_db.VWv - e7.2.2 : 1.0
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1999 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1999 Epicor Software Corporation, 1999  
                 All Rights Reserved                    
*/                                                

create view [dbo].[control_db_vw]
as
select "CVO_Control" control_db




/**/                                              
GO
GRANT REFERENCES ON  [dbo].[control_db_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[control_db_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[control_db_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[control_db_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[control_db_vw] TO [public]
GO
