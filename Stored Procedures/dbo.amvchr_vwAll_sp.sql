SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amvchr_vwAll_sp] 
AS 

SELECT
	timestamp, trx_ctrl_num, doc_ctrl_num, vendor_code, apply_date=CONVERT(char(8),date_applied,112), amt_net, org_id
FROM
	amvchr_vw
ORDER BY
	trx_ctrl_num 
	
RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amvchr_vwAll_sp] TO [public]
GO
