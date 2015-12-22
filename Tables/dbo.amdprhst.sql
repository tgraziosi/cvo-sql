CREATE TABLE [dbo].[amdprhst]
(
[timestamp] [timestamp] NOT NULL,
[co_asset_book_id] [dbo].[smSurrogateKey] NOT NULL,
[effective_date] [dbo].[smApplyDate] NOT NULL,
[last_modified_date] [dbo].[smApplyDate] NOT NULL,
[modified_by] [dbo].[smUserID] NOT NULL,
[posting_flag] [dbo].[smPostingState] NOT NULL,
[depr_rule_code] [dbo].[smDeprRuleCode] NOT NULL,
[limit_rule_code] [dbo].[smLimitRuleCode] NOT NULL,
[salvage_value] [dbo].[smMoneyZero] NOT NULL,
[catch_up_diff] [dbo].[smLogicalFalse] NOT NULL,
[end_life_date] [dbo].[smApplyDate] NULL,
[switch_to_sl_date] [dbo].[smApplyDate] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[amdprhst_del_trg] 
ON 				[dbo].[amdprhst] 
FOR 			DELETE 
AS 

DECLARE
 	@rowcount 			smCounter, 
	@rollback 			smLogical, 
	@error 				smErrorCode, 
	@message 			smErrorLongDesc,
	@asset_ctrl_num		smControlNumber,
	@book_code			smBookCode,
	@param				smErrorParam,

	@co_asset_book_id 	smSurrogateKey, 
	@effective_date 	smApplyDate, 

	@posting_flag 		smLogical 

SELECT @rowcount = @@rowcount 
SELECT @rollback = 0 





	
SELECT 	@co_asset_book_id 	= MIN(co_asset_book_id)
FROM 	deleted 
WHERE	posting_flag		!= 0

WHILE @co_asset_book_id IS NOT NULL 
BEGIN 
	
	IF EXISTS(SELECT 	co_asset_book_id
				FROM	amastbk
				WHERE	co_asset_book_id 	= @co_asset_book_id)
	BEGIN
		SELECT 	@effective_date 	= MIN(effective_date)
		FROM	deleted
		WHERE	co_asset_book_id	= @co_asset_book_id
		AND		posting_flag		!= 0

		
		SELECT 	@asset_ctrl_num		= asset_ctrl_num,
				@book_code			= book_code
		FROM	amasset a,
				amastbk ab
		WHERE	a.co_asset_id		= ab.co_asset_id
		AND		ab.co_asset_book_id	= @co_asset_book_id
		
		SELECT		@param = RTRIM(CONVERT(char(255), @effective_date, 107))
		
		EXEC 		amGetErrorMessage_sp 
							20587, ".\\amdprhst.dtr", 110, 
							@asset_ctrl_num, @book_code, @param,
							@error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20587 @message 
		SELECT @rollback = 1 
	END
		
	 
	SELECT 	@co_asset_book_id 	= MIN(co_asset_book_id)
	FROM 	deleted 
	WHERE 	co_asset_book_id 	> @co_asset_book_id 
	AND		posting_flag		!= 0

END  

IF @rollback = 1
BEGIN
	ROLLBACK	TRANSACTION
	RETURN 
END




GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[amdprhst_ins_trg] 
ON 				[dbo].[amdprhst] 
FOR 			INSERT 
AS 

DECLARE 
	@rowcount 			smCounter, 
	@rollback 			smLogical, 
	@message 			smErrorLongDesc, 
	@co_asset_book_id 	smSurrogateKey,
	@num_asset_books	smCounter,
	@effective_date 	smApplyDate, 
	@depr_rule_code 	smDeprRuleCode, 
	@end_life_date 		smApplyDate, 
	@placed_date 		smApplyDate, 
	@error 				smErrorCode,
	@last_depr_date		smApplyDate,	
	@asset_ctrl_num		smControlNumber,
	@book_code			smBookCode,
	@param				smErrorParam	

SELECT @rowcount = @@rowcount 
SELECT @rollback = 0 

 
IF ( SELECT COUNT(i.depr_rule_code) 
		FROM 	inserted i, 
				amdprrul f 
		WHERE 	f.depr_rule_code = i.depr_rule_code) <> @rowcount 
BEGIN 
	EXEC 		amGetErrorMessage_sp 20545, ".\\amdprhst.itr", 136, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20545 @message 
	SELECT 		@rollback = 1 
END 

IF @rollback = 1
BEGIN
 	ROLLBACK TRANSACTION 
	RETURN
END

IF @rowcount > 1
	SELECT 	@num_asset_books = COUNT(DISTINCT co_asset_book_id)
	FROM	inserted
	
IF @rowcount = 1
OR @num_asset_books > 1
BEGIN
	 
	SELECT 	@co_asset_book_id = MIN(co_asset_book_id)
	FROM 	inserted 

	WHILE 	@co_asset_book_id IS NOT NULL 
	BEGIN 
		SELECT 	@effective_date 	= MIN(effective_date)
		FROM 	inserted 
		WHERE 	co_asset_book_id 	= @co_asset_book_id 

		WHILE 	@effective_date IS NOT NULL 
		BEGIN 

			SELECT 	@last_depr_date 	= last_posted_depr_date
			FROM	amastbk
			WHERE	co_asset_book_id	= @co_asset_book_id
			
			IF 	@last_depr_date IS NOT NULL
			AND	@effective_date <= @last_depr_date
			BEGIN	
				SELECT 	@asset_ctrl_num 	= asset_ctrl_num,
						@book_code			= book_code
				FROM	amasset a,
						amastbk ab
				WHERE	ab.co_asset_book_id = @co_asset_book_id
				AND		ab.co_asset_id		= a.co_asset_id
				
				SELECT		@param = RTRIM(CONVERT(varchar(255), @effective_date, 107))
				
				EXEC 		amGetErrorMessage_sp 
								21051, ".\\amdprhst.itr", 187 , 
								@asset_ctrl_num, @book_code, @param,
								@error_message = @message OUT 
				IF @message IS NOT NULL RAISERROR 	21051 @message 
				ROLLBACK	TRANSACTION
				RETURN 
			END

			 
			SELECT 	@depr_rule_code 	= depr_rule_code,
					@end_life_date 		= end_life_date 
			FROM 	inserted 
			WHERE 	co_asset_book_id 	= @co_asset_book_id 
			AND 	effective_date 		= @effective_date 

			IF 	(@end_life_date IS NULL)
			BEGIN 
	


				 
				EXEC @error = amGetAssetDate_sp 
									@co_asset_book_id,
									@placed_date OUT 
				IF @error <> 0 
				BEGIN 
	


					ROLLBACK TRANSACTION 
					RETURN 
				END 
				
				 
				IF @placed_date IS NOT NULL 
				BEGIN 

					EXEC @error = amCalcEndLifeDate_sp 
										@depr_rule_code, 
										@placed_date, 
										@end_life_date OUT 
		


					IF @error <> 0 
					BEGIN 
		


						ROLLBACK TRANSACTION 
						RETURN 
					END 
	


					IF @end_life_date IS NOT NULL
					BEGIN
						UPDATE 	amdprhst 
						SET 	end_life_date 		= @end_life_date 
						FROM 	amdprhst 
						WHERE 	co_asset_book_id 	= @co_asset_book_id 
						AND 	effective_date 		= @effective_date 

						IF @@error <> 0 
						BEGIN 
		


							ROLLBACK TRANSACTION 
							RETURN 
						END 
					END
				END 
			END 

			 
			SELECT 	@effective_date 	= MIN(effective_date)
			FROM 	inserted 
			WHERE 	co_asset_book_id 	= @co_asset_book_id 
			AND 	effective_date 		> @effective_date 
		END 

		 
		SELECT 	@co_asset_book_id 	= MIN(co_asset_book_id)
		FROM 	inserted 
		WHERE 	co_asset_book_id 	> @co_asset_book_id 
	END
END 

GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[amdprhst_upd_trg] 
ON 				[dbo].[amdprhst] 
FOR 			UPDATE 
AS 

DECLARE
 	@rowcount 			smCounter, 
	@rollback 			smLogical, 
	@message 			smErrorLongDesc,

	@co_asset_book_id 	smSurrogateKey, 
	@effective_date 	smApplyDate, 

	@old_depr_rule_code smDeprRuleCode, 
	@new_depr_rule_code smDeprRuleCode, 
	@old_salvage_value 	smMoneyZero, 
	@new_salvage_value 	smMoneyZero, 
	@old_end_life_date 	smApplyDate, 
	@new_end_life_date 	smApplyDate, 
	@placed_date 		smApplyDate, 
	@posting_flag 		smLogical, 
	@error 				smErrorCode 

SELECT @rowcount = @@rowcount 
SELECT @rollback = 0 





 

 
IF UPDATE(depr_rule_code)
BEGIN 



	IF ( SELECT COUNT(i.depr_rule_code) 
			FROM 	inserted i, 
					amdprrul f 
			WHERE 	f.depr_rule_code = i.depr_rule_code) <> @rowcount 
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20546, ".\\amdprhst.utr", 139 , @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20546 @message 
		SELECT 		@rollback = 1 
	END 
END 

IF @rollback = 1 
BEGIN
 	ROLLBACK TRANSACTION 
	RETURN
END

 
IF UPDATE(depr_rule_code) OR UPDATE(salvage_value)
BEGIN 
	
	SELECT 	@co_asset_book_id = MIN(co_asset_book_id)
	FROM 	inserted 
	
	WHILE 	@co_asset_book_id IS NOT NULL 
	BEGIN 
		SELECT 	@effective_date 	= MIN(effective_date)
		FROM 	inserted 
		WHERE 	co_asset_book_id 	= @co_asset_book_id 

		WHILE 	@effective_date IS NOT NULL 
		BEGIN 

			 
			SELECT 	@old_depr_rule_code = depr_rule_code,
					@old_salvage_value 	= salvage_value,
					@old_end_life_date 	= end_life_date 
			FROM 	deleted 
			WHERE 	co_asset_book_id 	= @co_asset_book_id 
			AND 	effective_date 		= @effective_date 

			 
			SELECT 	@new_depr_rule_code = depr_rule_code,
					@new_salvage_value 	= salvage_value,
					@posting_flag 		= posting_flag 
			FROM 	inserted 
			WHERE 	co_asset_book_id 	= @co_asset_book_id 
			AND 	effective_date 		= @effective_date 

			 
			IF 	@posting_flag = 1 
			BEGIN 



				 
				IF (@old_depr_rule_code <> @new_depr_rule_code)
				OR (ABS((@old_salvage_value - @new_salvage_value)-(0.0)) > 0.0000001)
				BEGIN 
					DECLARE		@asset_ctrl_num 	smControlNumber,
								@book_code			smBookCode,
								@param				smErrorParam

				
					SELECT	@book_code			= ab.book_code,
							@asset_ctrl_num		= a.asset_ctrl_num
					FROM	amasset	a,
							amastbk ab
					WHERE	ab.co_asset_book_id	= @co_asset_book_id
					AND		ab.co_asset_id		= a.co_asset_id

					IF @book_code IS NOT NULL
					BEGIN
						EXEC 		amGetErrorMessage_sp 20086, ".\\amdprhst.utr", 214 , @asset_ctrl_num, @book_code, @error_message = @message OUT 
						IF @message IS NOT NULL RAISERROR 	20086 @message 
					END
					ELSE
					BEGIN
						SELECT		@param = RTRIM(CONVERT(char(255), @co_asset_book_id))
						
						EXEC 		amGetErrorMessage_sp 20025, ".\\amdprhst.utr", 221, @param, @error_message = @message OUT 
						IF @message IS NOT NULL RAISERROR 	20025 @message 
					END
					
					ROLLBACK 	TRANSACTION 
					RETURN 

				END 
			END 
			
			ELSE  
			BEGIN 
				IF (@old_depr_rule_code <> @new_depr_rule_code)
				BEGIN 



				
					 
					EXEC @error = amGetAssetDate_sp 
										@co_asset_book_id,
										@placed_date OUT 
					IF @error <> 0 
					BEGIN 



						ROLLBACK TRANSACTION 
						RETURN 
					END 
					
					 
					IF @placed_date IS NOT NULL 
					BEGIN 
					
						 
						EXEC @error = amCalcEndLifeDate_sp 
											@new_depr_rule_code, 
											@placed_date, 
											@new_end_life_date OUT 
						
						IF @error <> 0 
						BEGIN 
	


							ROLLBACK TRANSACTION 
							RETURN 
						END 

						 
						IF (@old_end_life_date <> @new_end_life_date)
						OR (@old_end_life_date IS NULL)
						OR (@new_end_life_date IS NULL)
						BEGIN 
	



							UPDATE 	amdprhst 
							SET 	end_life_date 		= @new_end_life_date 
							FROM 	amdprhst 
							WHERE 	co_asset_book_id 	= @co_asset_book_id 
							AND 	effective_date 		= @effective_date 

							SELECT @error = @@error 
							IF @error <> 0 
							BEGIN 
	


								ROLLBACK TRANSACTION 
								RETURN 
							END 
						END 
					END 
				END 
			END 

			 
			SELECT 	@effective_date = MIN(effective_date)
			FROM 	inserted 
			WHERE 	co_asset_book_id = @co_asset_book_id 
			AND 	effective_date > @effective_date 
		END 

		 
		SELECT 	@co_asset_book_id = MIN(co_asset_book_id)
		FROM 	inserted 
		WHERE 	co_asset_book_id > @co_asset_book_id 
	END 
END 




GO
CREATE UNIQUE NONCLUSTERED INDEX [amdprhst_ind_2] ON [dbo].[amdprhst] ([co_asset_book_id], [effective_date]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [amdprhst_ind_1] ON [dbo].[amdprhst] ([depr_rule_code]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [amdprhst_ind_0] ON [dbo].[amdprhst] ([effective_date], [co_asset_book_id]) WITH (FILLFACTOR=50) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amdprhst].[co_asset_book_id]'
GO
EXEC sp_bindefault N'[dbo].[smTodaysDate_df]', N'[dbo].[amdprhst].[last_modified_date]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amdprhst].[modified_by]'
GO
EXEC sp_bindefault N'[dbo].[smPostingState_df]', N'[dbo].[amdprhst].[posting_flag]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amdprhst].[limit_rule_code]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amdprhst].[salvage_value]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amdprhst].[catch_up_diff]'
GO
EXEC sp_bindefault N'[dbo].[smFalse_df]', N'[dbo].[amdprhst].[catch_up_diff]'
GO
GRANT REFERENCES ON  [dbo].[amdprhst] TO [public]
GO
GRANT SELECT ON  [dbo].[amdprhst] TO [public]
GO
GRANT INSERT ON  [dbo].[amdprhst] TO [public]
GO
GRANT DELETE ON  [dbo].[amdprhst] TO [public]
GO
GRANT UPDATE ON  [dbo].[amdprhst] TO [public]
GO
