CREATE TABLE [dbo].[amastprf]
(
[timestamp] [timestamp] NOT NULL,
[co_asset_book_id] [dbo].[smSurrogateKey] NOT NULL,
[fiscal_period_end] [dbo].[smApplyDate] NOT NULL,
[current_cost] [dbo].[smMoneyZero] NOT NULL,
[accum_depr] [dbo].[smMoneyZero] NOT NULL,
[effective_date] [dbo].[smApplyDate] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[amastprf_ins_trg] 
ON 				[dbo].[amastprf] 
FOR 			INSERT 
AS 

DECLARE 
	@rowcount 			smCounter, 
	@rollback 			smLogical, 
	@message 			smErrorLongDesc,
	@param				smErrorParam,
	@co_asset_book_id	smSurrogateKey,
	@acquisition_date	smApplyDate,
	@asset_ctrl_num		smControlNumber 

SELECT @rowcount = @@rowcount 
SELECT @rollback = 0 

 
IF (SELECT 	COUNT(i.co_asset_book_id) 
		FROM 	inserted i, 
				amastbk f 
		WHERE 	f.co_asset_book_id = i.co_asset_book_id) <> @rowcount 
BEGIN 
	EXEC 		amGetErrorMessage_sp 20554, ".\\amastprf.itr", 108, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20554 @message 
	SELECT 		@rollback = 1 
END 


IF @rowcount = 1
BEGIN
	SELECT	@co_asset_book_id = MIN(co_asset_book_id)
	FROM	inserted

	WHILE	@co_asset_book_id IS NOT NULL
	BEGIN
		SELECT	@acquisition_date	= acquisition_date,
				@asset_ctrl_num		= asset_ctrl_num
		FROM	amasset		a,
				amastbk		ab
		WHERE	a.co_asset_id		= ab.co_asset_id
		AND		ab.co_asset_book_id	= @co_asset_book_id
		
		IF EXISTS (SELECT 	fiscal_period_end
					FROM 	inserted
					WHERE	co_asset_book_id 	= @co_asset_book_id
					AND		fiscal_period_end 	< @acquisition_date)
		BEGIN 
			SELECT		@param = RTRIM(CONVERT(char(255), @acquisition_date, 107))

			EXEC 		amGetErrorMessage_sp 20035, ".\\amastprf.itr", 142, @asset_ctrl_num, @param, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20035 @message 
			SELECT 		@rollback = 1 
		END
		
		SELECT 	@co_asset_book_id	= MIN(co_asset_book_id)
		FROM	inserted
		WHERE	co_asset_book_id	> @co_asset_book_id 
	END
END

IF @rollback <> 0 
	ROLLBACK TRANSACTION 
GO
CREATE UNIQUE CLUSTERED INDEX [amastprf_ind_0] ON [dbo].[amastprf] ([co_asset_book_id], [fiscal_period_end]) WITH (FILLFACTOR=50) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [amastprf_ind_1] ON [dbo].[amastprf] ([effective_date]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amastprf].[co_asset_book_id]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amastprf].[current_cost]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amastprf].[accum_depr]'
GO
GRANT REFERENCES ON  [dbo].[amastprf] TO [public]
GO
GRANT SELECT ON  [dbo].[amastprf] TO [public]
GO
GRANT INSERT ON  [dbo].[amastprf] TO [public]
GO
GRANT DELETE ON  [dbo].[amastprf] TO [public]
GO
GRANT UPDATE ON  [dbo].[amastprf] TO [public]
GO
