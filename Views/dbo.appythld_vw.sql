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


CREATE VIEW 	[dbo].[appythld_vw]
	AS	SELECT * FROM apinppyt a
		WHERE a.trx_type = 4111	
		AND a.hold_flag = 1
		AND a.trx_ctrl_num IN (SELECT trx_ctrl_num FROM apinppdt b 
					WHERE a.trx_ctrl_num = b.trx_ctrl_num 
					AND a.trx_type = b.trx_type)


GO
GRANT REFERENCES ON  [dbo].[appythld_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[appythld_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[appythld_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[appythld_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[appythld_vw] TO [public]
GO
