SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/* PVCS Revision or Version:Revision              
I:\vcs\GL\VW\gltrx.VWv - e7.2.2 : 1.8
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1999 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1999 Epicor Software Corporation, 1999  
                 All Rights Reserved                    
*/                                                


CREATE VIEW [dbo].[gltrx_vw]
AS 
SELECT 	* 
FROM 	gltrx 
WHERE 	type_flag IN ( 0, 2, 3, 4, 5, 6 ) 
AND	posted_flag = 0
AND 	trx_type != 101



/**/                                              
GO
GRANT REFERENCES ON  [dbo].[gltrx_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[gltrx_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[gltrx_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[gltrx_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[gltrx_vw] TO [public]
GO
