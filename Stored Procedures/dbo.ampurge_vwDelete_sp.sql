SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[ampurge_vwDelete_sp] 
( 
	@timestamp		timestamp,
	@company_id smallint, @date_purged char(8), @time_purged varchar(20)
 
) 
AS 

DECLARE 
	@rowcount 	int, 
	@error 		int,
	@ts 		timestamp, 
	@message 	varchar(255),
	@dt			datetime


SELECT @dt = @date_purged + " " + @time_purged

DELETE 
FROM 	ampurge 
WHERE 	company_id		= @company_id
AND		date_created	= @dt
AND 	timestamp		= @timestamp 

SELECT @error = @@error, @rowcount = @@rowcount 
IF @error <> 0  
	RETURN @error 
IF @rowcount = 0  
BEGIN 
	 
	SELECT 	@ts 			= timestamp 
	FROM 	ampurge 
	WHERE 	company_id		= @company_id
	AND		date_created	= @dt
	 

	SELECT @error = @@error, @rowcount = @@rowcount 
	IF @error <> 0  
		RETURN @error 
	IF @rowcount = 0  
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20002, "tmp/ampurgdl.sp", 90, ampurge_vw, @error_message = @message out 
		RAISERROR 	20002 @message 
		RETURN 		20002 
	END 
	if @ts <> @timestamp 
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20001, "tmp/ampurgdl.sp", 96, ampurge_vw, @error_message = @message out 
		RAISERROR 	20001 @message 
		RETURN 		20001 
	END 
END 
RETURN @@error 
GO
GRANT EXECUTE ON  [dbo].[ampurge_vwDelete_sp] TO [public]
GO
