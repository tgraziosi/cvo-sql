SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[ammasfldUpdate_sp]
(
	@timestamp 	timestamp,
	@mass_maintenance_id 	smSurrogateKey,
	@mass_maintenance_type 	smMaintenanceType,
	@field_type 	smFieldType,
	@new_value 	smFieldData
)
AS
 
DECLARE	@rowcount	smCounter
DECLARE	@error		smErrorCode
DECLARE	@ts			timestamp
DECLARE	@message	smErrorLongDesc
 
UPDATE	ammasfld
SET
	new_value 	= @new_value
WHERE	mass_maintenance_id 	= @mass_maintenance_id
AND		mass_maintenance_type 	= @mass_maintenance_type
AND		field_type 	= @field_type
AND	timestamp 	= @timestamp
 
SELECT @error = @@error, @rowcount = @@rowcount
IF @error <> 0
	RETURN @error
 
IF @rowcount = 0
BEGIN
	SELECT	@ts		= timestamp
	FROM	ammasfld
	WHERE	mass_maintenance_id	= @mass_maintenance_id
	AND		mass_maintenance_type	= @mass_maintenance_type
	AND		field_type	= @field_type
 
	SELECT @error = @@error, @rowcount = @@rowcount
	IF @error <> 0
		RETURN @error
 
	IF @rowcount = 0
	BEGIN
		EXEC		amGetErrorMessage_sp 20004, "tmp/ammsfdup.sp", 90, 'ammasfld', @error_message = @message OUT
		IF @message IS NOT NULL RAISERROR	20004 @message
		RETURN		20004
	END
 
	IF @ts <> @timestamp
	BEGIN
		EXEC		amGetErrorMessage_sp 20003, "tmp/ammsfdup.sp", 97, 'ammasfld', @error_message = @message OUT
		IF @message IS NOT NULL RAISERROR	20003 @message
		RETURN		20003
	END
END
 
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[ammasfldUpdate_sp] TO [public]
GO
