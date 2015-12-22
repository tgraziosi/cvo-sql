SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\VW\arsalmgr.VWv - e7.2.2 : 1.2
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1999 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1999 Epicor Software Corporation, 1999  
                 All Rights Reserved                    
*/                                                



CREATE VIEW [dbo].[arsalmgr_vw] 
AS
SELECT salesperson_code, salesperson_name, phone_1
FROM arsalesp
WHERE salesperson_type = 1



/**/                                              
GO
GRANT REFERENCES ON  [dbo].[arsalmgr_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[arsalmgr_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[arsalmgr_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[arsalmgr_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[arsalmgr_vw] TO [public]
GO
