SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amastbkUpdate_sp] 
( 
	@timestamp					timestamp,				
	@co_asset_id				smSurrogateKey,			
	@book_code					smBookCode,				
	@co_asset_book_id			smSurrogateKey, 		
	@orig_salvage_value			smMoneyZero,			
	@orig_amount_expensed		smMoneyZero,			
	@orig_amount_capitalised	smMoneyZero,			
	@placed_in_service_date 	varchar(30), 			
	@last_posted_activity_date 	varchar(30), 			
	@next_entered_activity_date varchar(30), 
	@last_posted_depr_date 		varchar(30), 
	@prev_posted_depr_date 		varchar(30), 
	@first_depr_date 			varchar(30), 
	@last_modified_date 		varchar(30), 			
	@proceeds					smMoneyZero,	
	@gain_loss					smMoneyZero,
	@last_depr_co_trx_id		smSurrogateKey,
	@process_id 				smSurrogateKey
) 
AS 

DECLARE @rowcount 	int, 
		@error 		int, 
		@ts 		timestamp, 
		@message 	varchar(255)


SELECT @placed_in_service_date = RTRIM(@placed_in_service_date) IF @placed_in_service_date = "" SELECT @placed_in_service_date = NULL
SELECT @last_posted_activity_date = RTRIM(@last_posted_activity_date) IF @last_posted_activity_date = "" SELECT @last_posted_activity_date = NULL
SELECT @next_entered_activity_date = RTRIM(@next_entered_activity_date) IF @next_entered_activity_date = "" SELECT @next_entered_activity_date = NULL
SELECT @last_posted_depr_date = RTRIM(@last_posted_depr_date) IF @last_posted_depr_date = "" SELECT @last_posted_depr_date = NULL
SELECT @prev_posted_depr_date = RTRIM(@prev_posted_depr_date) IF @prev_posted_depr_date = "" SELECT @prev_posted_depr_date = NULL
SELECT @first_depr_date = RTRIM(@first_depr_date) IF @first_depr_date = "" SELECT @first_depr_date = NULL
SELECT @last_modified_date = RTRIM(@last_modified_date) IF @last_modified_date = "" SELECT @last_modified_date = NULL

UPDATE amastbk 
SET 
	orig_salvage_value 				= @orig_salvage_value,
	orig_amount_expensed			= @orig_amount_expensed,
	orig_amount_capitalised			= @orig_amount_capitalised,
	placed_in_service_date 			= @placed_in_service_date,
	last_posted_activity_date = @last_posted_activity_date,
	next_entered_activity_date = @next_entered_activity_date,
	last_posted_depr_date = @last_posted_depr_date,
	prev_posted_depr_date = @prev_posted_depr_date,
	first_depr_date 		= @first_depr_date,
	last_modified_date = @last_modified_date,
	proceeds 				= @proceeds,
	gain_loss 		= @gain_loss,
	last_depr_co_trx_id = @last_depr_co_trx_id,
	process_id 	= @process_id
WHERE 	co_asset_book_id = @co_asset_book_id 
AND 	timestamp = @timestamp 

SELECT @error = @@error, @rowcount = @@rowcount 
IF @error <> 0  
	RETURN @error 

IF @rowcount = 0  
BEGIN 
	 
	SELECT 	@ts 				= timestamp 
	FROM 	amastbk 
	WHERE 	co_asset_book_id 	= @co_asset_book_id 

	SELECT @error = @@error, @rowcount = @@rowcount 

	IF @error <> 0  
		RETURN @error 

	IF @rowcount = 0  
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20004, "tmp/ambkup.sp", 123, amastbk, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20004 @message 
		RETURN 		20004 
	END 

	IF @ts <> @timestamp 
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20003, "tmp/ambkup.sp", 130, amastbk, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20003 @message 
		RETURN 		20003 
	END 
END 

RETURN @@error 
GO
GRANT EXECUTE ON  [dbo].[amastbkUpdate_sp] TO [public]
GO
