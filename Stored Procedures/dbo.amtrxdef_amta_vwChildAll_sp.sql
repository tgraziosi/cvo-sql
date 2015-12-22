SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amtrxdef_amta_vwChildAll_sp]
(
	
	@trx_type 	smTrxType

)
AS
 
SELECT 	timestamp, trx_type, account_type, system_defined, display_order, account_type_name, debit_positive, credit_positive, debit_negative, credit_negative, auto_balancing, updated_by, import_order
FROM 	amta_vw
WHERE	trx_type = @trx_type order by display_order

 
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amtrxdef_amta_vwChildAll_sp] TO [public]
GO
