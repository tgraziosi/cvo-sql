SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[ammashdrUpdate_sp]
(
	@timestamp 	timestamp,
	@mass_maintenance_id 	smSurrogateKey,
	@mass_description 	smStdDescription,
	@one_at_a_time 	smLogical,
	@user_id 	smUserID,
	@group_id 	smSurrogateKey,
	@assets_purged 	smLogical,
	@process_start_date 	varchar(30),
	@process_end_date 	varchar(30),
	@error_code 	smErrorCode,
	@error_message 	smErrorLongDesc
)
AS
 
DECLARE	@rowcount	smCounter
DECLARE	@error		smErrorCode
DECLARE	@ts			timestamp
DECLARE	@message	smErrorLongDesc
 
UPDATE	ammashdr
SET
	mass_description 	= @mass_description,
	one_at_a_time 	= @one_at_a_time,
	user_id 	= @user_id,
	group_id 	= @group_id,
	assets_purged 	= @assets_purged,
	process_start_date 	= @process_start_date,
	process_end_date 	= @process_end_date,
	error_code 	= @error_code,
	error_message 	= @error_message
WHERE	mass_maintenance_id 	= @mass_maintenance_id
AND	timestamp 	= @timestamp
 
SELECT @error = @@error, @rowcount = @@rowcount
IF @error <> 0
	RETURN @error
 
IF @rowcount = 0
BEGIN
	SELECT	@ts		= timestamp
	FROM	ammashdr
	WHERE	mass_maintenance_id	= @mass_maintenance_id
 
	SELECT @error = @@error, @rowcount = @@rowcount
	IF @error <> 0
		RETURN @error
 
	IF @rowcount = 0
	BEGIN
		EXEC		amGetErrorMessage_sp 20004, "tmp/ammassup.sp", 100, 'ammashdr', @error_message = @message OUT
		IF @message IS NOT NULL RAISERROR	20004 @message
		RETURN		20004
	END
 
	IF @ts <> @timestamp
	BEGIN
		EXEC		amGetErrorMessage_sp 20003, "tmp/ammassup.sp", 107, 'ammashdr', @error_message = @message OUT
		IF @message IS NOT NULL RAISERROR	20003 @message
		RETURN		20003
	END
END
 
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[ammashdrUpdate_sp] TO [public]
GO
