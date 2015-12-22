SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2006 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2006 Epicor Software Corporation, 2006    
                  All Rights Reserved                    
*/                                                


CREATE VIEW [dbo].[smisadmin_vw]
AS
	SELECT d.domain_username 
	FROM CVO_Control..smgrphdr h, smgrpdet_vw d
		  WHERE
			  h.group_id = d.group_id			
			  AND ISNULL(h.global_flag,0)=1

GO
GRANT REFERENCES ON  [dbo].[smisadmin_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[smisadmin_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[smisadmin_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[smisadmin_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[smisadmin_vw] TO [public]
GO
