SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amclshdrDelete_sp] 
( 
	@timestamp timestamp,
	@company_id smCompanyID, 
	@classification_name				smClassificationName 
) 
AS 

DECLARE 
	@rowcount 	int, 
	@error 		int, 
	@ts 		timestamp, 
	@message 	varchar(255)


DELETE 
FROM 	amclshdr 
WHERE 	company_id		= @company_id 
AND 	classification_name= @classification_name
AND 	timestamp		= @timestamp 

SELECT @error = @@error, @rowcount = @@rowcount 
IF @error <> 0  
	RETURN @error 
IF @rowcount = 0  
BEGIN 
	 
	SELECT 	@ts = timestamp 
	FROM 	amclshdr 
	WHERE 	company_id = @company_id 
	AND 	classification_name= @classification_name

	SELECT @error = @@error, @rowcount = @@rowcount 
	IF @error <> 0  
		RETURN @error 

	IF @rowcount = 0  
	BEGIN 
		EXEC	 	amGetErrorMessage_sp 20002, "tmp/amclshdrdl.sp", 82, amcls, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20002 @message 
		RETURN 		20002 
	END 
	IF @ts <> @timestamp 
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20001, "tmp/amclshdrdl.sp", 88, amcls, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20001 @message
		RETURN 		20001 
	END 
END 
RETURN @@error 
GO
GRANT EXECUTE ON  [dbo].[amclshdrDelete_sp] TO [public]
GO
