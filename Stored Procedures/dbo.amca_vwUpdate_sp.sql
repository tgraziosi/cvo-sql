SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amca_vwUpdate_sp]
(
	@timestamp						timestamp,
	@company_id smCompanyID, @classification_id smSurrogateKey, @account_type smAccountTypeID, @override_account_flag smLogicalFalse, @account_type_name smName, @display_order smCounter, @income_account smLogicalTrue, @updated_by smUserID
)
AS
 
DECLARE	@rowcount	smCounter
DECLARE	@error		smErrorCode
DECLARE	@ts			timestamp
DECLARE	@message	smErrorLongDesc
 
UPDATE	amclsact
SET
	override_account_flag = @override_account_flag,
	last_updated					= GETDATE(),
	updated_by						= @updated_by	
	
WHERE	company_id 	= @company_id
AND		classification_id = @classification_id
AND		account_type 	= @account_type
AND	timestamp 	= @timestamp
 
SELECT @error = @@error, @rowcount = @@rowcount
IF @error <> 0
	RETURN @error
 
IF @rowcount = 0
BEGIN
	SELECT	@ts		= timestamp
	FROM	amclsact
	WHERE	company_id	= @company_id
	AND		classification_id	= @classification_id
	AND		account_type	= @account_type
 
	SELECT @error = @@error, @rowcount = @@rowcount
	IF @error <> 0
		RETURN @error
 
	IF @rowcount = 0
	BEGIN
		EXEC		amGetErrorMessage_sp 20004, "tmp/amcaup.sp", 91, 'amca_vw', @error_message = @message OUT
		IF @message IS NOT NULL RAISERROR	20004 @message
		RETURN		20004
	END
 
	IF @ts <> @timestamp
	BEGIN
		EXEC		amGetErrorMessage_sp 20003, "tmp/amcaup.sp", 98, 'amca_vw', @error_message = @message OUT
		IF @message IS NOT NULL RAISERROR	20003 @message
		RETURN		20003
	END
END
 
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amca_vwUpdate_sp] TO [public]
GO
