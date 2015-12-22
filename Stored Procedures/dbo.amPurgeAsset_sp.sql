SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amPurgeAsset_sp] 
( 	
	@co_asset_id 		 smSurrogateKey,		
	@user_id			 smUserID 		= 0,
	@mass_maintenance_id smSurrogateKey = 0, 
	@comment			 smLongDesc = '', 
	@debug_level		 smDebugLevel 	= 0	 
) 
AS 

DECLARE 
	@message		smErrorLongDesc,
	@result			smErrorCode,
	@param			smErrorParam,
	@trans_count	int,
	@activity_state	smSystemState,
	@rowcount		int,
	@tran_started 	smLogical,
	@co_asset_book_id smSurrogateKey, 
	@lp_date	 	smApplyDate,
	@lp_cost		smMoneyZero,
	@lp_accum		smMoneyZero

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ampurge.sp" + ", line " + STR( 75, 5 ) + " -- ENTRY: "


SELECT @tran_started = 0 

IF (@@trancount = 0)
BEGIN 
	SELECT @tran_started = 1 
	BEGIN TRANSACTION 
END


SELECT 	@activity_state 	= activity_state
FROM 	amasset
WHERE 	co_asset_id			= @co_asset_id

SELECT @result = @@error,	@rowcount	= @@rowcount
IF @rowcount <> 1 OR @result <> 0
BEGIN
	
	SELECT	@param = RTRIM(CONVERT(char(255), @co_asset_id))

 	EXEC 		amGetErrorMessage_sp 20063, "tmp/ampurge.sp", 97, @param, @error_message = @message OUT 
 	IF @message IS NOT NULL 
 		RAISERROR 	20063 @message
 	 
	IF (@tran_started= 1)
 BEGIN 
 	SELECT 		@tran_started = 0 
 	ROLLBACK 	TRANSACTION 
 END 	
	RETURN		20063
	
END



IF @comment = '' OR @comment IS NULL 
	IF @mass_maintenance_id <> 0 
	BEGIN

		SELECT @comment = error_message
		FROM 	ammasast
		WHERE	mass_maintenance_id = @mass_maintenance_id
		AND 	co_asset_id			= @co_asset_id

		SELECT @result = @@error				
		IF @result <> 0
		BEGIN

			IF @debug_level >= 5
				SELECT error_message = "select comment failed"
			
			IF (@tran_started= 1)
		 BEGIN 
 			SELECT 		@tran_started = 0 
		 	ROLLBACK 	TRANSACTION 
		 END 	
		 	RETURN @result
		END
	END




IF @activity_state <> 100 AND @activity_state <> 101
BEGIN

	UPDATE 	amasset
	SET 	activity_state	= 101
	WHERE 	co_asset_id		= @co_asset_id

	SELECT @result 	= @@error
	IF @result <> 0
	BEGIN

		IF @debug_level >= 5
			SELECT error_message = "update activity_state failed"
			

		IF (@tran_started= 1)
		BEGIN 
 		SELECT 		@tran_started = 0 
		 	ROLLBACK 	TRANSACTION 
		END 	
		RETURN @result
	END

END


SELECT @co_asset_book_id = a.co_asset_book_id 
FROM 	amastbk a, ambook b
WHERE	b.post_to_gl	= 1
AND		a.book_code 	= b.book_code
AND		a.co_asset_id	= @co_asset_id

IF @@rowcount = 1
BEGIN

	
	SELECT	@lp_date 	= MAX(fiscal_period_end)
	FROM 	amastprf
	WHERE	co_asset_book_id = @co_asset_book_id

	SELECT	@lp_cost 	= current_cost,
			@lp_accum 	= accum_depr	
	FROM 	amastprf
	WHERE	co_asset_book_id = @co_asset_book_id
	AND 	@lp_date 	= fiscal_period_end
			
END
ELSE
 IF @debug_level >= 5
		SELECT error_message = "no book or more than one book exists to post to gl"


INSERT ampurge(
	company_id,
	asset_ctrl_num,
	asset_description,
	co_asset_id,
	mass_maintenance_id,
	activity_state,
	comment,
	last_updated,
	updated_by,
	date_created,
	created_by,
	acquisition_date,
	disposition_date,
	original_cost,
	lp_fiscal_period_end,
	lp_accum_depr,
	lp_current_cost
	)
SELECT
	a.company_id,
	a.asset_ctrl_num,
	a.asset_description,
	@co_asset_id,
	@mass_maintenance_id,
	@activity_state,
	@comment,
	GetDate(),
	@user_id,
	GetDate(),
	@user_id,
	a.acquisition_date,
	a.disposition_date,
	a.original_cost,
	@lp_date,
	@lp_accum,
	@lp_cost

FROM 	amasset a
WHERE 	co_asset_id 	= @co_asset_id

SELECT @result 	= @@error
IF @result <> 0
BEGIN

	IF @debug_level >= 5
		SELECT error_message = "insert into ampurge failed"
			
	IF (@tran_started= 1)
	BEGIN 
 	SELECT 		@tran_started = 0 
	 	ROLLBACK 	TRANSACTION 
	END 	
	RETURN @result
END



		
UPDATE 	amtrxhdr 
SET 	posting_flag = 0 
WHERE 	co_asset_id = @co_asset_id

SELECT @result 	= @@error
IF @result <> 0
BEGIN

	IF @debug_level >= 5
		SELECT error_message = "update amtrxhdr failed"


	IF (@tran_started= 1)
	BEGIN 
 	SELECT 		@tran_started = 0 
	 	ROLLBACK 	TRANSACTION 
	END 	
	RETURN @result
END
	

UPDATE 	amacthst 
SET 	posting_flag = 0 
FROM 	amastbk ab,
		amacthst ah
WHERE 	ab.co_asset_id 		= @co_asset_id
AND 	ab.co_asset_book_id = ah.co_asset_book_id

SELECT @result 	= @@error
IF @result <> 0
BEGIN

	IF @debug_level >= 5
		SELECT error_message = "update amacthst failed"

	IF (@tran_started= 1)
	BEGIN 
 	SELECT 		@tran_started = 0 
	 	ROLLBACK 	TRANSACTION 
	END 	
	RETURN @result
END


DELETE 
FROM 	amasset 
WHERE 	co_asset_id = @co_asset_id

SELECT @result 	= @@error
IF @result <> 0
BEGIN

	IF @debug_level >= 5
		SELECT error_message = "delete from amasset failed"


	IF (@tran_started= 1)
	BEGIN 
 	SELECT 		@tran_started = 0 
	 	ROLLBACK 	TRANSACTION 
	END 	
	RETURN @result
END



IF (@tran_started = 1)
BEGIN 
 SELECT 	@tran_started = 0 
 COMMIT 	TRANSACTION 
END 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ampurge.sp" + ", line " + STR( 343, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amPurgeAsset_sp] TO [public]
GO
