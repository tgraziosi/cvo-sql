SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amtrxdpr_vwUpdate_sp] 
( 
	@timestamp				timestamp,
	@company_id             smCompanyID, 
	@trx_ctrl_num           smControlNumber, 
	@co_trx_id              smSurrogateKey, 
	@trx_type               smTrxType, 
	@last_modified_date		varchar(30), 
	@modified_by            smUserID, 
	@apply_date             varchar(30), 
	@posting_flag           smPostingState, 
	@date_posted            varchar(30), 
	@trx_description        smStdDescription, 
	@doc_reference          smDocumentReference, 
	@process_id             smSurrogateKey,
	@from_code				smCriteriaCode,
	@to_code				smCriteriaCode,
	@from_book				smCriteriaCode,
	@to_book				smCriteriaCode,
	@group_code				smGroupCode,
	@from_org_id			varchar(30),		
	@to_org_id				varchar(30) 		
) 
AS 

DECLARE 
	@rowcount 	smCounter, 
	@error 		smErrorCode, 
	@ts 		timestamp, 
	@message 	smErrorLongDesc

BEGIN TRANSACTION

	


 
	IF @from_code IS NULL
	SELECT @from_code = ""

	IF @to_code IS NULL
	SELECT @to_code = ""

	IF @group_code IS NULL
	SELECT @group_code = ""


	
	


	UPDATE amtrxhdr 
	SET 
			co_trx_id			= @co_trx_id,
			trx_type			= @trx_type,
			last_modified_date	= @last_modified_date,
			modified_by			= @modified_by,
			apply_date			= @apply_date,
			posting_flag		= @posting_flag,
			date_posted			= @date_posted,
			trx_description		= @trx_description,
			doc_reference		= @doc_reference,
			process_id			= @process_id 
	WHERE 	company_id			= @company_id 
	AND 	trx_ctrl_num		= @trx_ctrl_num 
	AND 	timestamp			= @timestamp 

	SELECT @error = @@error, @rowcount = @@rowcount 
	IF @error <> 0   
	BEGIN
		ROLLBACK 	TRANSACTION
		RETURN 		@error 
	END

	IF @rowcount = 0  
	BEGIN 
		
		 
		SELECT 	@ts 			= timestamp 
		FROM 	amtrxhdr 
		WHERE 	company_id 		= @company_id  
		AND		trx_ctrl_num 	= @trx_ctrl_num 

		SELECT  @rowcount = @@rowcount 

		IF @rowcount = 0 		 
		BEGIN 
			EXEC 		amGetErrorMessage_sp 20004, "amtrdpup.cpp", 190, amtrxhdr, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20004 @message 
			ROLLBACK 	TRANSACTION
			RETURN 		20004 
		END 

		IF @ts <> @timestamp 	
		BEGIN 
			EXEC 		amGetErrorMessage_sp 20003, "amtrdpup.cpp", 198, amtrxhdr, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20003 @message 
			ROLLBACK 	TRANSACTION
			RETURN 		20003 
		END 
	END 

	



	UPDATE	amdprcrt
	SET		from_code 	= @from_code,
			to_code		= @to_code
	FROM	amdprcrt
	WHERE	co_trx_id 	= @co_trx_id
	AND		field_type	= 7

	SELECT @error = @@error, @rowcount = @@rowcount 
	IF @error <> 0   
	BEGIN
		ROLLBACK 	TRANSACTION
		RETURN 		@error 
	END

	IF @rowcount = 0 		 
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20004, "amtrdpup.cpp", 225, amdprcrt, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20004 @message 
		ROLLBACK 	TRANSACTION
		RETURN 		20004 
	END 

	



	UPDATE	amdprcrt
	SET		from_code 	= @from_book,
			to_code		= @to_book
	FROM	amdprcrt
	WHERE	co_trx_id 	= @co_trx_id
	AND		field_type	= 8


	SELECT @error = @@error, @rowcount = @@rowcount 
	IF @error <> 0   
	BEGIN
		ROLLBACK 	TRANSACTION
		RETURN 		@error 
	END

	
	






	IF @rowcount = 0 		 
	BEGIN 
		INSERT INTO amdprcrt 
		( 
			co_trx_id,
			field_type,
			from_code,
			to_code 
		)
		VALUES 
		( 	@co_trx_id,
			8,
			@from_book,
			@to_book 
		)

	END 


	UPDATE	amdprcrt
	SET		from_code 	= @group_code
	FROM	amdprcrt
	WHERE	co_trx_id 	= @co_trx_id
	AND		field_type	= 19


	SELECT @error = @@error, @rowcount = @@rowcount 
	IF @error <> 0   
	BEGIN
		ROLLBACK 	TRANSACTION
		RETURN 		@error 
	END

	






	IF @rowcount = 0 		 
	BEGIN 
		INSERT INTO amdprcrt 
		( 
			co_trx_id,
			field_type,
			from_code,
			to_code 
		)
		VALUES 
		( 	@co_trx_id,
			19,
			@group_code,
			""
		)
	
		SELECT @error = @@error 
		IF @error <> 0 
		BEGIN 
			ROLLBACK TRANSACTION 
			RETURN @error 
		END 

	 END



	UPDATE	amdprcrt
	SET		from_code 	= isnull(@from_org_id, ""),
			to_code		= isnull(@to_org_id, "")
	FROM	amdprcrt
	WHERE	co_trx_id 	= @co_trx_id
	AND		field_type	= 20

	SELECT @error = @@error, @rowcount = @@rowcount 
	IF @error <> 0   
	BEGIN
		ROLLBACK 	TRANSACTION
		RETURN 		@error 
	END
	


	IF @rowcount = 0 		 
	BEGIN 
		INSERT INTO amdprcrt 
		( 
			co_trx_id,
			field_type,
			from_code,
			to_code 
		)
		VALUES 
		( 	@co_trx_id,
			20,
			isnull(@from_org_id, ""),
			isnull(@to_org_id, "")
		)
	
		SELECT @error = @@error 
		IF @error <> 0 
		BEGIN 
			ROLLBACK TRANSACTION 
			RETURN @error 
		END 

	 END


COMMIT TRANSACTION

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amtrxdpr_vwUpdate_sp] TO [public]
GO
