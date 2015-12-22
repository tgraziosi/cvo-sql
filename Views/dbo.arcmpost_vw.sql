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


























CREATE VIEW	[dbo].[arcmpost_vw]
AS
SELECT	*
FROM 	arinpchg
WHERE	trx_type = 2032		
AND	printed_flag = 1
AND	hold_flag = 0

/**/                                              
GO
GRANT REFERENCES ON  [dbo].[arcmpost_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[arcmpost_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[arcmpost_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[arcmpost_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[arcmpost_vw] TO [public]
GO
