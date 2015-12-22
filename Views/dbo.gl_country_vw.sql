SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2006 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2006 Epicor Software Corporation, 2006    
                  All Rights Reserved                    
*/                                                

CREATE VIEW [dbo].[gl_country_vw]
AS
SELECT country_code, description FROM gl_country

GO
GRANT REFERENCES ON  [dbo].[gl_country_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[gl_country_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[gl_country_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[gl_country_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[gl_country_vw] TO [public]
GO
