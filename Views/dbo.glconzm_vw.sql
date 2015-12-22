SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2002 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2002 Epicor Software Corporation, 2002    
                  All Rights Reserved                    
*/                                                





















CREATE VIEW [dbo].[glconzm_vw]
AS select a.consol_ctrl_num, a.description, a.date_asof, b.journal_ctrl_num, a.status_type  
from glcon a LEFT OUTER JOIN glcondet b ON (a.consol_ctrl_num = b.consol_ctrl_num AND b.sequence_id = 1)
where a.status_type !=2



                                              
GO
GRANT REFERENCES ON  [dbo].[glconzm_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[glconzm_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[glconzm_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[glconzm_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[glconzm_vw] TO [public]
GO
