SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amcommentInsert_sp] 
( 
	@company_id smCompanyID, @key_type smallint, @key_1 varchar(32), @sequence_id int, @date_updated varchar(20), @updated_by int, @user_name smStdDescription, @link_path smLongDesc, @note smLongDesc
 
) 
AS 

DECLARE 
	@rowcount 	smCounter,
	@error 		smErrorCode, 
	@ts			timestamp, 
	@message 	smErrorLongDesc,
	@date_up	int,
	@seq_id		int,
	@company_code varchar(8)




EXEC @error = appdate_sp @date_up OUTPUT
IF @error <> 1 
	RETURN @error

BEGIN TRANSACTION

SELECT 	@seq_id = MAX(a.sequence_id)
FROM	comments 	a,
		glco	 	co
WHERE	a.company_code 	= co.company_code
AND		co.company_id	= @company_id
AND		a.key_type		= @key_type
AND		a.key_1			= @key_1

	
IF @seq_id IS NULL 
	SELECT 	@seq_id = 1
ELSE
	SELECT	@seq_id = @seq_id + 1

SELECT @company_code 	= company_code
FROM glco
WHERE company_id 		= @company_id	

INSERT INTO comments 
( 
		company_code,
		key_type, 
		key_1, 
		sequence_id,
		date_updated, 
		updated_by, 
		date_created,
		created_by,
		link_path, 
		note	
)
VALUES
(
	 @company_code,
	 @key_type,
	 @key_1,
	 @seq_id,
	 @date_up,
	 @updated_by,	
	 @date_up,
	 @updated_by,
	 ISNULL(@link_path,""),
	 ISNULL(@note,"")
 
 )


SELECT @error = @@error

IF @error <> 0
BEGIN
	ROLLBACK TRANSACTION
	RETURN @error
END



SELECT 	sequence_id
FROM
	comments 	a,
	glco	 	co

WHERE 	a.company_code 	= co.company_code
AND		co.company_id	= @company_id
AND		a.key_type		= @key_type
AND		a.key_1			= @key_1
AND		a.sequence_id	= @seq_id 
 
IF @@rowcount > 1 
BEGIN
 ROLLBACK TRANSACTION
	RETURN 1

END

COMMIT TRANSACTION

RETURN @@error 
GO
GRANT EXECUTE ON  [dbo].[amcommentInsert_sp] TO [public]
GO
