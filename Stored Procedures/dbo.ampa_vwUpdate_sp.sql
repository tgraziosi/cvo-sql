SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[ampa_vwUpdate_sp]
(
	@timestamp						timestamp,
	@company_id smCompanyID, @posting_code smPostingCode, @account_type smAccountTypeID, @account smAccountCode, @account_type_name smName, @display_order smCounter, @income_account smLogicalTrue, @updated_by smUserID,
	@permission	int
)
AS
 
DECLARE	@rowcount	smCounter
DECLARE	@error		smErrorCode
DECLARE	@ts			timestamp
DECLARE	@message	smErrorLongDesc
 
UPDATE	ampstact
SET
	account                       	= @account,
	last_updated					= GETDATE(),
	updated_by						= @updated_by	
	
WHERE	company_id                    	= @company_id
AND		posting_code                  	= @posting_code
AND		account_type                  	= @account_type
AND	timestamp                     	= @timestamp
 
SELECT @error = @@error, @rowcount = @@rowcount
IF @error <> 0
	RETURN @error
 
IF @rowcount = 0
BEGIN
	SELECT	@ts		= timestamp
	FROM	ampstact
	WHERE	company_id	= @company_id
	AND		posting_code	= @posting_code
	AND		account_type	= @account_type
 
	SELECT @error = @@error, @rowcount = @@rowcount
	IF @error <> 0
		RETURN @error
 
	IF @rowcount = 0
	BEGIN
		EXEC		amGetErrorMessage_sp 20004, "ampaup.cpp", 92, 'ampa_vw', @error_message = @message OUT
		IF @message IS NOT NULL RAISERROR	20004 @message
		RETURN		20004
	END
 
	IF @ts <> @timestamp
	BEGIN
		EXEC		amGetErrorMessage_sp 20003, "ampaup.cpp", 99, 'ampa_vw', @error_message = @message OUT
		IF @message IS NOT NULL RAISERROR	20003 @message
		RETURN		20003
	END
END
 
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[ampa_vwUpdate_sp] TO [public]
GO
