SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


 
CREATE VIEW [dbo].[amtrxast_vw] 
AS 

SELECT 
 	ta.timestamp,
 	ta.co_trx_id,
 	ta.company_id,
 	ta.asset_ctrl_num,
 	a.asset_description 
FROM 	amtrxast ta,
 	amasset a 
WHERE 	ta.company_id		= a.company_id 
AND ta.asset_ctrl_num = a.asset_ctrl_num

GO
GRANT REFERENCES ON  [dbo].[amtrxast_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[amtrxast_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[amtrxast_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[amtrxast_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[amtrxast_vw] TO [public]
GO
