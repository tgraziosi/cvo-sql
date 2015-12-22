SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amln_vwDelete_sp]
(
	@timestamp				timestamp,
	@company_id				smCompanyID,
	@trx_ctrl_num			smControlNumber,
	@sequence_id			smCounter,
	@line_id				smCounter
) 
AS

DECLARE @rowcount 		smCounter
DECLARE @error 			smErrorCode
DECLARE @ts 			timestamp
DECLARE @message 		smErrorLongDesc


DELETE 
FROM 	amapdet 
WHERE	company_id 			= @company_id 
AND		trx_ctrl_num		= @trx_ctrl_num 
AND		sequence_id			= @sequence_id 
AND		line_id				= @line_id 
AND		timestamp 			= @timestamp

SELECT @error = @@error, @rowcount = @@rowcount
IF @error <> 0 
	RETURN @error

IF @rowcount = 0 
BEGIN
	
	SELECT 	@ts 			= timestamp 
	FROM 	amapdet 
	WHERE	company_id 		= @company_id 
	AND		trx_ctrl_num 	= @trx_ctrl_num 
	AND		sequence_id 	= @sequence_id 
	AND		line_id 		= @line_id

	SELECT @error = @@error, @rowcount = @@rowcount
	IF @error <> 0 
		RETURN @error
	
	IF @rowcount = 0 
	BEGIN
		
		IF @line_id <> 1
		BEGIN
			EXEC 	amGetErrorMessage_sp 20002, "tmp/amlndl.sp", 96, "amln_vw", @error_message = @message OUT
			IF @message IS NOT NULL RAISERROR 	20002 @message
			RETURN 		20002
		END
		ELSE
			RETURN 0
	END
	
	IF @ts <> @timestamp
	BEGIN
		EXEC	 	amGetErrorMessage_sp 20001, "tmp/amlndl.sp", 106, "amln_vw", @error_message = @message OUT
		IF @message IS NOT NULL RAISERROR 	20001 @message
		RETURN 		20001
	END
END

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amln_vwDelete_sp] TO [public]
GO
