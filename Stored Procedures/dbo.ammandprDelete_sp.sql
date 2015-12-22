SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[ammandprDelete_sp] 
( 
	@timestamp 	timestamp,
	@co_asset_book_id 	smSurrogateKey, 
	@fiscal_period_end 	varchar(30)
) 
AS 

DECLARE 
	@rowcount 	int, 
	@error 		int, 
	@ts 		timestamp, 
	@message 	varchar(255)

SELECT @fiscal_period_end = RTRIM(@fiscal_period_end) IF @fiscal_period_end = "" SELECT @fiscal_period_end = NULL

DELETE 
FROM 	ammandpr 
WHERE 	co_asset_book_id = @co_asset_book_id 
AND 	fiscal_period_end = @fiscal_period_end 
AND 	timestamp = @timestamp 

SELECT @error = @@error, @rowcount = @@rowcount 
IF @error <> 0  
	RETURN @error
	 
IF @rowcount = 0  
BEGIN 
	 
	SELECT 	@ts = timestamp 
	FROM 	ammandpr 
	WHERE 	co_asset_book_id = @co_asset_book_id 
	AND 	fiscal_period_end = @fiscal_period_end 

	SELECT @error = @@error, @rowcount = @@rowcount 
	IF @error <> 0  
		RETURN @error 
	
	IF @rowcount = 0  
	BEGIN 
		EXEC		amGetErrorMessage_sp 20002, "tmp/ammdprdl.sp", 105, ammandpr, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20002 @message 
		RETURN 		20002 
	END 
	IF @ts <> @timestamp 
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20001, "tmp/ammdprdl.sp", 111, ammandpr, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR	20001 @message 
		RETURN 		20001 
	END 
END 
RETURN @@error 
GO
GRANT EXECUTE ON  [dbo].[ammandprDelete_sp] TO [public]
GO
