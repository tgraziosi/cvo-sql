SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amtrxdef_amta_vwChildFetch_sp]
(
	@rowsrequested		smCounter = 1,
	@trx_type smTrxType,
	@account_type_name smName	
)
AS

SELECT 	timestamp, trx_type, account_type, system_defined, display_order, account_type_name, debit_positive, credit_positive, debit_negative, credit_negative, auto_balancing, updated_by, import_order
FROM 	amta_vw
WHERE	trx_type 		= @trx_type
AND		account_type_name 	= @account_type_name


RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amtrxdef_amta_vwChildFetch_sp] TO [public]
GO
