SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[amChangeClassName_sp] 
( 	
	@company_id					smCompanyID,
	@classification_id 		smSurrogateKey, 	
	@new_name 					smClassificationName, 	
	@user_id			smUserID,			
	@timestamp		 	timestamp OUT		
 ) 
AS 

DECLARE 
	@result 			smErrorCode
	



BEGIN TRANSACTION

	
	UPDATE	amclshdr
	SET		classification_name	= @new_name,
			updated_by			= @user_id,
			last_updated		= GETDATE()
	FROM	amclshdr
	WHERE	company_id			= @company_id
	AND classification_id = @classification_id
	AND timestamp = @timestamp
	
	SELECT @result = @@error 
	IF @result <> 0 
	BEGIN
		ROLLBACK TRANSACTION
		RETURN @result
	END

			
COMMIT TRANSACTION 


SELECT	@timestamp 	= timestamp
FROM	amclshdr
WHERE	company_id			= @company_id
AND 	classification_id = @classification_id



RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amChangeClassName_sp] TO [public]
GO
