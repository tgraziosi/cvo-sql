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





CREATE VIEW [dbo].[apinpapr_vw]
AS

	SELECT 	trx_ctrl_num, 
		settlement_ctrl_num
	FROM 	apinppyt
	WHERE	trx_type=4111
	
	UNION

	SELECT	trx_ctrl_num,
		settlement_ctrl_num=""
	FROM	apinpchg
	WHERE	trx_type=4091

	UNION

	SELECT po_no, "" as settlement_ctrl_num 
	FROM purchase
	where approval_flag = 1

GO
GRANT SELECT ON  [dbo].[apinpapr_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[apinpapr_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[apinpapr_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[apinpapr_vw] TO [public]
GO
