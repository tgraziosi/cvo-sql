SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amcommentUpdate_sp] 
( 
	@timestamp	timestamp,
	@company_id smCompanyID, @key_type smallint, @key_1 varchar(32), @sequence_id int, @date_updated varchar(20), @updated_by int, @user_name smStdDescription, @link_path smLongDesc, @note smLongDesc
) 
AS 
DECLARE 
	@rowcount 	int,
	@error 		int, 
	@ts 		timestamp, 
	@message 	varchar(255),
	@date_up	int


EXEC @error = appdate_sp @date_up OUTPUT
IF @error <> 1 
	RETURN @error

UPDATE comments 
SET 
	link_path		= @link_path,
	note			= @note,
	updated_by		= @updated_by,
	date_updated	= @date_up				 
FROM
	comments 	a,
	glco	 	co

WHERE 	a.company_code 	= co.company_code
AND		co.company_id	= @company_id
AND		a.key_type		= @key_type
AND		a.key_1			= @key_1
AND		a.sequence_id	= @sequence_id 
AND 	a.timestamp	 = @timestamp 

SELECT @error = @@error, @rowcount = @@rowcount 
IF @error <> 0  
	RETURN @error 

IF @rowcount = 0  
BEGIN 
	 
	SELECT 	@ts 		= a.timestamp 
	FROM
		comments 	a,
	 	glco	 	co

	WHERE 	a.company_code 	= co.company_code
	AND		co.company_id	= @company_id
 	AND		a.key_type		= @key_type
	AND		a.key_1			= @key_1 
	AND		a.sequence_id	= @sequence_id 

	 	

	SELECT @error = @@error, @rowcount = @@rowcount 
	IF @error <> 0  
		RETURN @error 

	IF @rowcount = 0  
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20004, "tmp/amcommup.sp", 112, comments, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20004 @message 
		RETURN 		20004 
	END 

	IF @ts <> @timestamp 
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20003, "tmp/amcommup.sp", 119, comments, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20003 @message 
		RETURN 		20003 
	END 
END 

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amcommentUpdate_sp] TO [public]
GO
