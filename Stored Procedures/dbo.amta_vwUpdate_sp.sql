SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amta_vwUpdate_sp]
(
	@timestamp						timestamp,
	@trx_type smTrxType, @account_type smAccountTypeID, @system_defined smLogicalFalse, @display_order smCounter, @account_type_name smName, @debit_positive smLogicalFalse, @credit_positive smLogicalFalse, @debit_negative smLogicalFalse, @credit_negative smLogicalFalse, @auto_balancing smLogicalFalse, @updated_by smUserID, @import_order smCounter
)
AS
 
DECLARE	@rowcount	smCounter
DECLARE	@error		smErrorCode
DECLARE	@ts			timestamp
DECLARE	@message	smErrorLongDesc


SELECT 	@account_type		= account_type
FROM	amta_vw		
WHERE	trx_type			= @trx_type
AND		account_type_name	= @account_type_name

SELECT @rowcount = @@rowcount
IF @rowcount = 0
BEGIN
	EXEC		amGetErrorMessage_sp 20004, "tmp/amtaup.sp", 71, 'amtrxact', @error_message = @message OUT
	IF @message IS NOT NULL RAISERROR	20004 @message
	RETURN		20004
END




UPDATE	amtrxact
SET	
	display_order 	= @display_order,
	import_order					= @import_order,
	debit_positive					= @debit_positive,
	credit_positive					= @credit_positive,
	debit_negative					= @debit_negative,
	credit_negative					= @credit_negative,
	auto_balancing					= @auto_balancing,
	last_updated					= GETDATE(),
	updated_by						= @updated_by	
	
WHERE 	trx_type 	= @trx_type
AND		account_type	 = @account_type
AND		timestamp = @timestamp
 
SELECT @error = @@error, @rowcount = @@rowcount
IF @error <> 0
	RETURN @error
 
IF @rowcount = 0
BEGIN
	SELECT	@ts		= timestamp
	FROM	amtrxact
	WHERE	trx_type	= @trx_type
	AND		account_type= @account_type 

	SELECT @error = @@error, @rowcount = @@rowcount
	IF @error <> 0
		RETURN @error
 
	IF @rowcount = 0
	BEGIN
		EXEC		amGetErrorMessage_sp 20004, "tmp/amtaup.sp", 116, 'amtrxact', @error_message = @message OUT
		IF @message IS NOT NULL RAISERROR	20004 @message
		RETURN		20004
	END
 
	IF @ts <> @timestamp
	BEGIN
		EXEC		amGetErrorMessage_sp 20003, "tmp/amtaup.sp", 123, 'amtrxact', @error_message = @message OUT
		IF @message IS NOT NULL RAISERROR	20003 @message
		RETURN		20003
	END
END


 
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amta_vwUpdate_sp] TO [public]
GO
