SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amgrphdrUpdate_sp]
(
	@timestamp 	timestamp,
	@group_code 	smGroupCode,
	@group_id 	smSurrogateKey,
	@group_description 	smStdDescription,
	@group_edited 	smLogical
)
AS
 
DECLARE	@rowcount	smCounter
DECLARE	@error		smErrorCode
DECLARE	@ts			timestamp
DECLARE	@message	smErrorLongDesc
 
UPDATE	amgrphdr
SET
	group_id 	= @group_id,
	group_description 	= @group_description,
	group_edited 	= @group_edited
WHERE	group_code 	= @group_code
AND	timestamp 	= @timestamp
 
SELECT @error = @@error, @rowcount = @@rowcount
IF @error <> 0
	RETURN @error
 
IF @rowcount = 0
BEGIN
	SELECT	@ts		= timestamp
	FROM	amgrphdr
	WHERE	group_code	= @group_code
 
	SELECT @error = @@error, @rowcount = @@rowcount
	IF @error <> 0
		RETURN @error
 
	IF @rowcount = 0
	BEGIN
		EXEC		amGetErrorMessage_sp 20004, "tmp/amgrpup.sp", 88, 'amgrphdr', @error_message = @message OUT
		IF @message IS NOT NULL RAISERROR	20004 @message
		RETURN		20004
	END
 
	IF @ts <> @timestamp
	BEGIN
		EXEC		amGetErrorMessage_sp 20003, "tmp/amgrpup.sp", 95, 'amgrphdr', @error_message = @message OUT
		IF @message IS NOT NULL RAISERROR	20003 @message
		RETURN		20003
	END
END
 
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amgrphdrUpdate_sp] TO [public]
GO
