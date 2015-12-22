SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amgrphdrDelete_sp]
(
	@timestamp 	timestamp,
	@group_code 	smGroupCode
)
AS
 
DECLARE	@rowcount	smCounter
DECLARE	@ts			timestamp
DECLARE	@error		smErrorCode
DECLARE	@message	smErrorLongDesc
 
DELETE
FROM	amgrphdr
WHERE	group_code 	= @group_code
AND		timestamp 	= @timestamp
 
SELECT @error = @@error, @rowcount = @@rowcount
IF @error <> 0
	RETURN @error
 
IF @rowcount = 0
BEGIN
	SELECT	@ts	= timestamp
	FROM	amgrphdr
	WHERE	group_code	= @group_code
 
	SELECT @error = @@error, @rowcount = @@rowcount
	IF @error <> 0
		RETURN @error
 
	IF @rowcount = 0
	BEGIN
		EXEC 		amGetErrorMessage_sp 20002, "tmp/amgrpdl.sp", 80, 'amgrphdr', @error_message = @message OUT
		IF @message IS NOT NULL RAISERROR 	20002 @message
		RETURN 		20002
	END
 
	IF @ts <> @timestamp
	BEGIN
		EXEC 		amGetErrorMessage_sp 20001, "tmp/amgrpdl.sp", 87, 'amgrphdr', @error_message = @message OUT
		IF @message IS NOT NULL RAISERROR 	20001 @message
		RETURN 		20001
	END
END
 
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amgrphdrDelete_sp] TO [public]
GO
