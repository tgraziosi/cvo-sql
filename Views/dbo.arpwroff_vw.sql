SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2008 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2008 Epicor Software Corporation, 2008    
                  All Rights Reserved                    
*/                                                


CREATE VIEW [dbo].[arpwroff_vw]
AS
	SELECT * 
	FROM artrxpdt
	WHERE trx_type = 2151
/**/                                              
GO
GRANT REFERENCES ON  [dbo].[arpwroff_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[arpwroff_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[arpwroff_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[arpwroff_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[arpwroff_vw] TO [public]
GO
