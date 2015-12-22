CREATE TABLE [dbo].[amastbk]
(
[timestamp] [timestamp] NOT NULL,
[co_asset_id] [dbo].[smSurrogateKey] NOT NULL,
[book_code] [dbo].[smBookCode] NOT NULL,
[co_asset_book_id] [dbo].[smSurrogateKey] NOT NULL,
[orig_salvage_value] [dbo].[smMoneyZero] NOT NULL,
[orig_amount_expensed] [dbo].[smMoneyZero] NOT NULL,
[orig_amount_capitalised] [dbo].[smMoneyZero] NOT NULL,
[placed_in_service_date] [dbo].[smApplyDate] NULL,
[last_posted_activity_date] [dbo].[smApplyDate] NULL,
[next_entered_activity_date] [dbo].[smApplyDate] NULL,
[last_posted_depr_date] [dbo].[smApplyDate] NULL,
[prev_posted_depr_date] [dbo].[smApplyDate] NULL,
[first_depr_date] [dbo].[smApplyDate] NULL,
[last_modified_date] [dbo].[smApplyDate] NULL,
[proceeds] [dbo].[smMoneyZero] NOT NULL,
[gain_loss] [dbo].[smMoneyZero] NOT NULL,
[last_depr_co_trx_id] [dbo].[smSurrogateKey] NOT NULL,
[process_id] [dbo].[smSurrogateKey] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE TRIGGER 	[dbo].[amastbk_del_trg] 
ON 				[dbo].[amastbk] 
FOR 			DELETE 
AS 

DECLARE 
	@rowcount 	smCounter, 
	@rollback 	smLogical, 
	@message 	smErrorLongDesc 

SELECT @rowcount = @@rowcount 
SELECT @rollback = 0 

DELETE 	amcalval 
FROM 	deleted d, 
		amcalval f 
WHERE 	f.co_asset_book_id = d.co_asset_book_id 

IF @@error <> 0 
	SELECT @rollback = 1 

IF @rollback = 0 
BEGIN 
	DELETE 	amacthst 
	FROM 	deleted d, 
			amacthst f 
	WHERE 	f.co_asset_book_id = d.co_asset_book_id 
	
	IF @@error <> 0 
		SELECT @rollback = 1 
END 

IF @rollback = 0 
BEGIN 
	
	DELETE 	amvalues 
	FROM 	deleted d, 
			amvalues f 
	WHERE 	f.co_asset_book_id = d.co_asset_book_id 
	
	IF @@error <> 0 
		SELECT @rollback = 1 
END 

IF @rollback = 0 
BEGIN 
	DELETE 	ammandpr 
	FROM 	deleted d, 
			ammandpr f 
	WHERE 	f.co_asset_book_id = d.co_asset_book_id 

	IF @@error <> 0 
		SELECT @rollback = 1 
END 


IF @rollback = 0 
BEGIN 
	DELETE 	amastprf 
	FROM 	deleted d, 
			amastprf f 
	WHERE 	f.co_asset_book_id = d.co_asset_book_id 

	IF @@error <> 0 
		SELECT @rollback = 1 
END 

IF @rollback = 0 
BEGIN 
	DELETE 	amdprhst 
	FROM 	deleted d, 
			amdprhst f 
	WHERE	f.co_asset_book_id = d.co_asset_book_id 

	IF @@error <> 0 
		SELECT @rollback = 1 
END 

IF @rollback = 1 
	ROLLBACK TRANSACTION 
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[amastbk_ins_trg] 
ON 				[dbo].[amastbk] 
FOR 			INSERT 
AS 

DECLARE 
	@rowcount 	smCounter, 
	@rollback 	smLogical, 
	@message 	smErrorLongDesc 

SELECT @rowcount = @@rowcount 
SELECT @rollback = 0 

 

 
IF ( SELECT COUNT(i.book_code) 
		FROM 	inserted i, 
				ambook f 
		WHERE 	f.book_code = i.book_code) <> @rowcount 
BEGIN 
	EXEC 		amGetErrorMessage_sp 20555, ".\\amastbk.itr", 92, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20555 @message 
	SELECT 		@rollback = 1 
END 

IF @rollback = 1 
	ROLLBACK TRANSACTION 
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[amastbk_upd_trg] 
ON 				[dbo].[amastbk] 
FOR 			UPDATE 
AS 

DECLARE 
	@rowcount 				smCounter,
	@result					smErrorCode,
	@message 				smErrorLongDesc,
	@param					smErrorParam,
	@co_asset_book_id		smSurrogateKey,
	@old_placed_date		smApplyDate,
	@new_placed_date		smApplyDate,
	@acquisition_date		smApplyDate,
	@last_posted_depr_date	smApplyDate,
	@part_disp_apply_date	smApplyDate,
	@asset_ctrl_num			smControlNumber,
	@book_code				smBookCode,
	@is_valid				smLogical


SELECT @rowcount = @@rowcount 


IF UPDATE(placed_in_service_date)
BEGIN




	
	SELECT	@co_asset_book_id	= MIN(co_asset_book_id)
	FROM	inserted
	
	WHILE @co_asset_book_id IS NOT NULL
	BEGIN
		SELECT	@new_placed_date 		= placed_in_service_date,
				@last_posted_depr_date	= last_posted_depr_date
		FROM	inserted
		WHERE	co_asset_book_id		= @co_asset_book_id

		SELECT	@old_placed_date 	= placed_in_service_date
		FROM	deleted
		WHERE	co_asset_book_id	= @co_asset_book_id

		




		IF @old_placed_date <> @new_placed_date
		BEGIN
			
			IF 	@old_placed_date IS NOT NULL
			AND @last_posted_depr_date IS NOT NULL
			BEGIN 
						
				SELECT	@book_code			= ab.book_code,
						@asset_ctrl_num		= a.asset_ctrl_num
				FROM	amasset	a,
						amastbk ab
				WHERE	ab.co_asset_book_id	= @co_asset_book_id
				AND		ab.co_asset_id		= a.co_asset_id

				IF @book_code IS NOT NULL
				BEGIN
					EXEC 		amGetErrorMessage_sp 20075, ".\\amastbk.utr", 164, @book_code, @asset_ctrl_num, @error_message = @message OUT 
					IF @message IS NOT NULL RAISERROR 	20075 @message 
					ROLLBACK 	TRANSACTION 
					RETURN 		 
				END
				ELSE
				BEGIN
					SELECT		@param = RTRIM(CONVERT(char(255), @co_asset_book_id))
					
					EXEC 		amGetErrorMessage_sp 20025, ".\\amastbk.utr", 173, @param, @error_message = @message OUT 
					IF @message IS NOT NULL RAISERROR 	20025 @message 
					ROLLBACK 	TRANSACTION 
					RETURN 		 
				END
			END
			
			ELSE
			BEGIN
				EXEC @result = amValidatePlacedDate_sp
										@co_asset_book_id,
										@new_placed_date,
										@is_valid OUTPUT
				
				IF 	@result 	<> 0 
				OR	@is_valid 	= 0
				BEGIN
					ROLLBACK 	TRANSACTION 
					RETURN 		 
				END
			END
			
			
			
			SELECT @part_disp_apply_date = NULL

			SELECT	@part_disp_apply_date 	= MAX(apply_date)
			FROM	amacthst
			WHERE	co_asset_book_id		= @co_asset_book_id
			AND		trx_type				= 70

			




		
			IF 	@part_disp_apply_date 	IS NOT NULL
			BEGIN
				IF (	@old_placed_date 	IS NULL
					OR 	@old_placed_date 	<= @part_disp_apply_date)
				AND	@new_placed_date 	< @part_disp_apply_date
				BEGIN
							
					SELECT	@book_code			= ab.book_code,
							@asset_ctrl_num		= a.asset_ctrl_num
					FROM	amasset	a,
							amastbk ab
					WHERE	ab.co_asset_book_id	= @co_asset_book_id
					AND		ab.co_asset_id		= a.co_asset_id

					SELECT		@param = RTRIM(CONVERT(char(255), @part_disp_apply_date, 107))
					
					EXEC 		amGetErrorMessage_sp 
										20089, ".\\amastbk.utr", 232, 
										@asset_ctrl_num, @book_code, @param, 
										@error_message = @message OUT 
					IF @message IS NOT NULL RAISERROR 	20089 @message 
					ROLLBACK 	TRANSACTION 
					RETURN 		 
				END
				IF @old_placed_date IS NOT NULL
				AND	@old_placed_date <= @part_disp_apply_date
				BEGIN
					SELECT	@book_code			= ab.book_code,
							@asset_ctrl_num		= a.asset_ctrl_num
					FROM	amasset	a,
							amastbk ab
					WHERE	ab.co_asset_book_id	= @co_asset_book_id
					AND		ab.co_asset_id		= a.co_asset_id

					SELECT		@param = RTRIM(CONVERT(char(255), @part_disp_apply_date, 107))
					
					EXEC 		amGetErrorMessage_sp 
										20090, ".\\amastbk.utr", 252, 
										@asset_ctrl_num, @book_code, @param, 
										@error_message = @message OUT 
					IF @message IS NOT NULL RAISERROR 	20090 @message 
					ROLLBACK 	TRANSACTION 
					RETURN 		 
				END

			END

			IF (@new_placed_date is NOT NULL) 
			BEGIN 
				IF @old_placed_date IS NULL
				OR @new_placed_date <> @old_placed_date
				BEGIN
					
					EXEC @result = amUpdateEffectiveDates_sp 
			 						@co_asset_book_id,
											@new_placed_date 							
					IF @result <> 0 
					BEGIN 
						ROLLBACK TRANSACTION 
						RETURN 
					END 
				END

			END
			
			EXEC @result = amUpdateEndLifeDate_sp 
	 						@co_asset_book_id,
									@new_placed_date 							
			IF @result <> 0 
			BEGIN 
				ROLLBACK TRANSACTION 
				RETURN 
			END 
		END
		
		
		SELECT	@co_asset_book_id	= MIN(co_asset_book_id)
		FROM	inserted
		WHERE	co_asset_book_id	> @co_asset_book_id
	END 
END	

GO
CREATE UNIQUE NONCLUSTERED INDEX [amastbk_ind_1] ON [dbo].[amastbk] ([co_asset_book_id]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [amastbk_ind_0] ON [dbo].[amastbk] ([co_asset_id], [book_code]) WITH (FILLFACTOR=50) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amastbk].[co_asset_id]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amastbk].[co_asset_book_id]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amastbk].[orig_salvage_value]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amastbk].[orig_amount_expensed]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amastbk].[orig_amount_capitalised]'
GO
EXEC sp_bindefault N'[dbo].[smTodaysDate_df]', N'[dbo].[amastbk].[last_modified_date]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amastbk].[proceeds]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amastbk].[gain_loss]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amastbk].[last_depr_co_trx_id]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amastbk].[process_id]'
GO
GRANT REFERENCES ON  [dbo].[amastbk] TO [public]
GO
GRANT SELECT ON  [dbo].[amastbk] TO [public]
GO
GRANT INSERT ON  [dbo].[amastbk] TO [public]
GO
GRANT DELETE ON  [dbo].[amastbk] TO [public]
GO
GRANT UPDATE ON  [dbo].[amastbk] TO [public]
GO
