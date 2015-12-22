SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[ammasfldDelete_sp]
(
	@timestamp 	timestamp,
	@mass_maintenance_id 	smSurrogateKey,
	@mass_maintenance_type 	smMaintenanceType,
	@field_type 	smFieldType
)
AS
 
DECLARE	@rowcount	smCounter
DECLARE	@ts			timestamp
DECLARE	@error		smErrorCode
DECLARE	@message	smErrorLongDesc
 
DELETE
FROM	ammasfld
WHERE	mass_maintenance_id 	= @mass_maintenance_id
AND		mass_maintenance_type 	= @mass_maintenance_type
AND		field_type 	= @field_type
AND		timestamp 	= @timestamp
 
SELECT @error = @@error, @rowcount = @@rowcount
IF @error <> 0
	RETURN @error
 
IF @rowcount = 0
BEGIN
	SELECT	@ts	= timestamp
	FROM	ammasfld
	WHERE	mass_maintenance_id	= @mass_maintenance_id
	AND		mass_maintenance_type	= @mass_maintenance_type
	AND		field_type	= @field_type
 
	SELECT @error = @@error, @rowcount = @@rowcount
	IF @error <> 0
		RETURN @error
 
	IF @rowcount = 0
	BEGIN
		EXEC 		amGetErrorMessage_sp 20002, "tmp/ammsfddl.sp", 86, 'ammasfld', @error_message = @message OUT
		IF @message IS NOT NULL RAISERROR 	20002 @message
		RETURN 		20002
	END
 
	IF @ts <> @timestamp
	BEGIN
		EXEC 		amGetErrorMessage_sp 20001, "tmp/ammsfddl.sp", 93, 'ammasfld', @error_message = @message OUT
		IF @message IS NOT NULL RAISERROR 	20001 @message
		RETURN 		20001
	END
END
 
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[ammasfldDelete_sp] TO [public]
GO
