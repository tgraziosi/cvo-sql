SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2002 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2002 Epicor Software Corporation, 2002    
                  All Rights Reserved                    
*/                                                


CREATE VIEW [dbo].[smgrpdet_vw]
AS
SELECT d.group_id, d.user_id, d.sequence_id, u.user_name, u.designer, u.manager, u.domain_username
FROM CVO_Control..smusers u, CVO_Control..smgrpdet d
WHERE d.user_id = u.user_id

/**/                                              
GO
GRANT REFERENCES ON  [dbo].[smgrpdet_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[smgrpdet_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[smgrpdet_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[smgrpdet_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[smgrpdet_vw] TO [public]
GO
