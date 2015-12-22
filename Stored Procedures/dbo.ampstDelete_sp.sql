SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[ampstDelete_sp] 
( 
	@timestamp timestamp,
	@company_id smCompanyID, 
	@posting_code smPostingCode 
) 
AS 

DECLARE 
	@rowcount 	int, 
	@error 		int, 
	@ts 		timestamp, 
	@message 	varchar(255)


DELETE 
FROM 	ampsthdr 
WHERE 	company_id		= @company_id 
AND 	posting_code	= @posting_code 
AND 	timestamp		= @timestamp 

SELECT @error = @@error, @rowcount = @@rowcount 
IF @error <> 0  
	RETURN @error 
IF @rowcount = 0  
BEGIN 
	 
	SELECT 	@ts = timestamp 
	FROM 	ampsthdr 
	WHERE 	company_id = @company_id 
	AND 	posting_code = @posting_code 

	SELECT @error = @@error, @rowcount = @@rowcount 
	IF @error <> 0  
		RETURN @error 

	IF @rowcount = 0  
	BEGIN 
		EXEC	 	amGetErrorMessage_sp 20002, "tmp/ampstdl.sp", 101, ampst, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20002 @message 
		RETURN 		20002 
	END 
	IF @ts <> @timestamp 
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20001, "tmp/ampstdl.sp", 107, ampst, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20001 @message
		RETURN 		20001 
	END 
END 
RETURN @@error 
GO
GRANT EXECUTE ON  [dbo].[ampstDelete_sp] TO [public]
GO
