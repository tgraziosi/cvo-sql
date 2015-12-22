CREATE TABLE [dbo].[ammandpr]
(
[timestamp] [timestamp] NOT NULL,
[co_asset_book_id] [dbo].[smSurrogateKey] NOT NULL,
[fiscal_period_end] [dbo].[smApplyDate] NOT NULL,
[last_modified_date] [dbo].[smApplyDate] NOT NULL,
[modified_by] [dbo].[smUserID] NOT NULL,
[posting_flag] [dbo].[smPostingState] NOT NULL,
[depr_expense] [dbo].[smMoneyZero] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[ammandpr_ins_trg] 
ON 				[dbo].[ammandpr] 
FOR 			INSERT 
AS 

DECLARE 
	@rowcount 	smCounter, 
	@rollback 	smLogical, 
	@message 	smErrorLongDesc

SELECT @rowcount = @@rowcount 
SELECT @rollback = 0 

 
IF ( SELECT COUNT(i.co_asset_book_id) 
		FROM 	inserted i,
				amastbk f 
		WHERE 	f.co_asset_book_id = i.co_asset_book_id ) <> @rowcount 
BEGIN 
	EXEC 		amGetErrorMessage_sp 20553, ".\\ammandpr.itr", 85, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20553 @message 
	SELECT 		@rollback = 1 
END 

IF @rollback <> 0 
	ROLLBACK TRANSACTION 
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[ammandpr_upd_trg] 
ON 				[dbo].[ammandpr] 
FOR 			UPDATE 
AS 

DECLARE 
	@rowcount 			smCounter, 
	@rollback 			smLogical, 
	@message 			smErrorLongDesc,
	@co_asset_book_id 	smSurrogateKey,
	@fiscal_period_end 	smApplyDate, 
	@old_depr_expense 	smMoneyZero, 
	@new_depr_expense 	smMoneyZero, 
	@posting_flag 		smLogical, 
	@error 				smErrorCode

SELECT @rowcount = @@rowcount 
SELECT @rollback = 0 

 

 
IF UPDATE(depr_expense)
BEGIN 
	
	SELECT 	@co_asset_book_id = MIN(co_asset_book_id)
	FROM 	inserted 
	
	WHILE 	@co_asset_book_id IS NOT NULL 
	BEGIN 
		SELECT 	@fiscal_period_end 	= MIN(fiscal_period_end)
		FROM 	inserted 
		WHERE 	co_asset_book_id 	= @co_asset_book_id 

		WHILE 	@fiscal_period_end IS NOT NULL 
		BEGIN 

			 
			SELECT 	@old_depr_expense 	= depr_expense 
			FROM 	deleted 
			WHERE 	co_asset_book_id 	= @co_asset_book_id 
			AND 	fiscal_period_end 	= @fiscal_period_end 

			 
			SELECT 	@new_depr_expense 	= depr_expense,
					@posting_flag 		= posting_flag 
			FROM 	inserted 
			WHERE	co_asset_book_id 	= @co_asset_book_id 
			AND 	fiscal_period_end 	= @fiscal_period_end 

			 
			IF 	@posting_flag = 1 
			BEGIN 



				 
				IF (ABS((@old_depr_expense - @new_depr_expense)-(0.0)) > 0.0000001)
	 			BEGIN 
					DECLARE 
						@asset_ctrl_num		smControlNumber,
						@book_code			smBookCode,
						@param				smErrorParam 

					SELECT		@asset_ctrl_num		= a.asset_ctrl_num,
								@book_code			= ab.book_code 
					FROM		amasset a,
								amastbk	ab
					WHERE		ab.co_asset_book_id = @co_asset_book_id
					AND			ab.co_asset_id		= a.co_asset_id
					
					IF @asset_ctrl_num IS NOT NULL
					BEGIN
						EXEC		amGetErrorMessage_sp 20085, ".\\ammandpr.utr", 154, @asset_ctrl_num, @book_code, @error_message = @message OUT 
						IF @message IS NOT NULL RAISERROR 	20085 @message 
					END
					ELSE
					BEGIN
						SELECT 	@param = RTRIM(CONVERT(char(255), @co_asset_book_id))
						EXEC 		amGetErrorMessage_sp 20025, ".\\ammandpr.utr", 160, @param, @error_message = @message OUT 
						IF @message IS NOT NULL RAISERROR 	20025 @message 
					END
		
					ROLLBACK 	TRANSACTION 
					RETURN 
				END 
			END 
			
			 
			SELECT 	@fiscal_period_end 	= MIN(fiscal_period_end)
			FROM 	inserted 
			WHERE 	co_asset_book_id 	= @co_asset_book_id 
			AND 	fiscal_period_end 	> @fiscal_period_end 
		END 

		 
		SELECT 	@co_asset_book_id 	= MIN(co_asset_book_id)
		FROM 	inserted 
		WHERE 	co_asset_book_id 	> @co_asset_book_id 
	END 
END 


IF @rollback = 1 
	ROLLBACK TRANSACTION 
GO
CREATE NONCLUSTERED INDEX [ammandpr_ind_2] ON [dbo].[ammandpr] ([co_asset_book_id]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [ammandpr_ind_0] ON [dbo].[ammandpr] ([fiscal_period_end], [co_asset_book_id]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ammandpr_ind_1] ON [dbo].[ammandpr] ([last_modified_date]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[ammandpr].[co_asset_book_id]'
GO
EXEC sp_bindefault N'[dbo].[smTodaysDate_df]', N'[dbo].[ammandpr].[last_modified_date]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[ammandpr].[modified_by]'
GO
EXEC sp_bindefault N'[dbo].[smPostingState_df]', N'[dbo].[ammandpr].[posting_flag]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[ammandpr].[depr_expense]'
GO
GRANT REFERENCES ON  [dbo].[ammandpr] TO [public]
GO
GRANT SELECT ON  [dbo].[ammandpr] TO [public]
GO
GRANT INSERT ON  [dbo].[ammandpr] TO [public]
GO
GRANT DELETE ON  [dbo].[ammandpr] TO [public]
GO
GRANT UPDATE ON  [dbo].[ammandpr] TO [public]
GO
