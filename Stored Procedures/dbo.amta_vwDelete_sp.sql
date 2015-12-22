SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amta_vwDelete_sp]
(
	@timestamp						timestamp,
	@trx_type 		smTrxType,
	@account_type_name smName
)
AS
 
DECLARE	@rowcount		smCounter
DECLARE	@error			smErrorCode
DECLARE	@ts				timestamp
DECLARE	@message		smErrorLongDesc
DECLARE @account_type	smAccountTypeID

SELECT 	@account_type		= account_type
FROM	amta_vw		
WHERE	trx_type			= @trx_type
AND		account_type_name	= @account_type_name

SELECT @rowcount = @@rowcount
IF @rowcount = 0
BEGIN
	EXEC		amGetErrorMessage_sp 20002, "tmp/amtadl.sp", 72, 'amtrxact', @error_message = @message OUT
	IF @message IS NOT NULL RAISERROR	20002 @message
	RETURN		20002
END



DELETE	amtrxact
WHERE 	trx_type = @trx_type
AND		account_type	 = @account_type
AND		timestamp = @timestamp
 
SELECT @error = @@error, @rowcount = @@rowcount
IF @error <> 0
	RETURN @error
 
IF @rowcount = 0
BEGIN
	SELECT	@ts				 = timestamp
	FROM	amta_vw
	WHERE	trx_type		 = @trx_type
	AND		account_type_name= @account_type_name
 
	SELECT @error = @@error, @rowcount = @@rowcount
	IF @error <> 0
		RETURN @error
 
	IF @rowcount = 0
	BEGIN
		EXEC		amGetErrorMessage_sp 20002, "tmp/amtadl.sp", 101, 'amtrxact', @error_message = @message OUT
		IF @message IS NOT NULL RAISERROR	20002 @message
		RETURN		20002
	END
 
	IF @ts <> @timestamp
	BEGIN
		EXEC		amGetErrorMessage_sp 20001, "tmp/amtadl.sp", 108, 'amtrxact', @error_message = @message OUT
		IF @message IS NOT NULL RAISERROR	20001 @message
		RETURN		20001
	END
END


 
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amta_vwDelete_sp] TO [public]
GO
