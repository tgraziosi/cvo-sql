SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[ammasast_vwInsert_sp]
(
	 @mass_maintenance_id smSurrogateKey, @company_id smCompanyID, @asset_ctrl_num smControlNumber, @asset_description smStdDescription, @activity_state smSystemState, @comment smLongDesc						
)
AS
 
DECLARE @co_asset_id smSurrogateKey,
		@message 	smErrorLongDesc


SELECT 	@co_asset_id 	= co_asset_id
FROM	amasset
WHERE	company_id		= @company_id
AND		asset_ctrl_num	= @asset_ctrl_num

IF @co_asset_id IS NULL
BEGIN
	EXEC 		amGetErrorMessage_sp 20030, "tmp/ammasain.sp", 65,@asset_ctrl_num, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20030 @message 
	RETURN 0
END

INSERT INTO ammasast
(
	mass_maintenance_id,
	company_id,
	asset_ctrl_num,
	co_asset_id,
	error_code,
	error_message
)
VALUES
(
	@mass_maintenance_id,
	@company_id,
	@asset_ctrl_num,
	@co_asset_id,
	@activity_state,
	@comment
)

RETURN @@error
GO
GRANT EXECUTE ON  [dbo].[ammasast_vwInsert_sp] TO [public]
GO
