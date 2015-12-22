SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amvchr_vwFetch_sp]
(
	@rowsrequested		smCounter = 1,
	@trx_ctrl_num                	smControlNumber
	
)
AS
 

SELECT timestamp, trx_ctrl_num, doc_ctrl_num, vendor_code, apply_date=CONVERT(char(8),date_applied,112), amt_net, org_id
FROM amvchr_vw
			WHERE  trx_ctrl_num 	= @trx_ctrl_num	
			
 

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amvchr_vwFetch_sp] TO [public]
GO
