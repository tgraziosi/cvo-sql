SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[ammasast_vwDelete_sp]
(
	@timestamp						timestamp,
	@mass_maintenance_id smSurrogateKey, @company_id smSurrogateKey, @asset_ctrl_num smControlNumber
)
AS
 
DECLARE	@rowcount	smCounter
DECLARE	@ts			timestamp
DECLARE	@error		smErrorCode
DECLARE	@message	smErrorLongDesc
 
DELETE	ammasast
FROM	ammasast 
WHERE	mass_maintenance_id 	= @mass_maintenance_id
AND		company_id 	= @company_id
AND		asset_ctrl_num 	= @asset_ctrl_num
AND		timestamp				= @timestamp
 
SELECT @error = @@error, @rowcount = @@rowcount
IF @error <> 0
	RETURN @error
 
IF @rowcount = 0
BEGIN
	SELECT	@ts						= timestamp
	FROM	ammasast 
	WHERE	mass_maintenance_id 	= @mass_maintenance_id
	AND		company_id 	= @company_id
	AND		asset_ctrl_num 	= @asset_ctrl_num
	
	SELECT @error = @@error, @rowcount = @@rowcount
	IF @error <> 0
		RETURN @error
 
	IF @rowcount = 0
	BEGIN
		EXEC 		amGetErrorMessage_sp 20002, "tmp/ammasadl.sp", 88, 'ammasast', @error_message = @message OUT
		IF @message IS NOT NULL RAISERROR 	20002 @message
		RETURN 		20002
	END
 
	IF @ts <> @timestamp
	BEGIN
		EXEC 		amGetErrorMessage_sp 20001, "tmp/ammasadl.sp", 95, 'ammasast', @error_message = @message OUT
		IF @message IS NOT NULL RAISERROR 	20001 @message
		RETURN 		20001
	END
END
 
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[ammasast_vwDelete_sp] TO [public]
GO
