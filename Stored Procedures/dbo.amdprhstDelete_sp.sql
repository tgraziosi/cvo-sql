SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amdprhstDelete_sp] 
( 
	@timestamp 	timestamp,
	@co_asset_book_id 	smSurrogateKey, 
	@effective_date 	varchar(30)
) 
AS 

DECLARE 
	@rowcount 			smCounter, 
	@error 				smErrorCode, 
	@ts 				timestamp, 
	@message 			smErrorLongDesc,
	@last_modified_by	smUserID


SELECT @effective_date = RTRIM(@effective_date) IF @effective_date = "" SELECT @effective_date = NULL


DELETE 
FROM 	amdprhst 
WHERE 	co_asset_book_id 	= @co_asset_book_id 
AND 	effective_date 		= @effective_date 
AND 	timestamp			= @timestamp 

SELECT @error = @@error, @rowcount = @@rowcount 
IF @error <> 0 
	RETURN @error 

IF @rowcount = 0 
BEGIN 
	SELECT 	@ts 				= timestamp,
			@last_modified_by	= modified_by 
	FROM 	amdprhst 
	WHERE 	co_asset_book_id 	= @co_asset_book_id 
	AND 	effective_date 		= @effective_date 

	SELECT @error = @@error, @rowcount = @@rowcount 
	IF @error <> 0 
		RETURN @error 

	IF @rowcount = 0 
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20002, "tmp/amdphsdl.sp", 113, amdprhst, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20002 @message 
		RETURN 		20002 
	END 
	IF @ts <> @timestamp 
	BEGIN 
		IF @last_modified_by < 0
		BEGIN
			DELETE 
			FROM 	amdprhst 
			WHERE 	co_asset_book_id 	= @co_asset_book_id 
			AND 	effective_date 		= @effective_date 

			SELECT @error = @@error 
			IF @error <> 0 
				RETURN @error 
		END
		ELSE
		BEGIN
			EXEC 		amGetErrorMessage_sp 20001, "tmp/amdphsdl.sp", 132, amdprhst, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20001 @message 
			RETURN 		20001 
		END
	END 
END 

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amdprhstDelete_sp] TO [public]
GO
