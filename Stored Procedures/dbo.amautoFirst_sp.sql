SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amautoFirst_sp] 
(
	 @rowsrequested smallint = 1	 
)
AS 

DECLARE 
	@company_id smCompanyID,
	@asset_timestamp timestamp, 
	@asset_mask 	smControlNumber, 
	@asset_next 	smCounter, 
	@period_timestamp timestamp, 
	@period_mask 	smControlNumber, 
	@period_next 	smCounter, 
	@message 	smErrorLongDesc







SELECT @company_id 	= company_id
FROM	amco

 
SELECT @asset_mask 	= num_mask,
		@asset_next 	= automatic_next,
		@asset_timestamp 	= timestamp 
FROM amauto 
WHERE company_id 			= @company_id 
AND automatic_id 		= 1 


IF @@rowcount = 0  
BEGIN 
	EXEC 		amGetErrorMessage_sp 20060, "tmp/amautoft.sp", 100, "amauto", @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20060 @message 
	RETURN 		20060 
END 

SELECT @period_mask = num_mask,
		@period_next = automatic_next,
		@period_timestamp = timestamp 
FROM amauto 
WHERE company_id 		= @company_id 
AND automatic_id 	= 2 


IF @@rowcount = 0  
BEGIN 
	EXEC 		amGetErrorMessage_sp 20060, "tmp/amautoft.sp", 115, "amauto", @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20060 @message 
	RETURN 		20060 
END 

SELECT 
	company_id = @company_id,
	asset_timestamp = @asset_timestamp,
	asset_mask = @asset_mask,
	asset_next = @asset_next,
	period_timestamp = @period_timestamp,
	period_mask = @period_mask,
	period_next = @period_next 

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amautoFirst_sp] TO [public]
GO
