CREATE TABLE [dbo].[amacthst]
(
[timestamp] [timestamp] NOT NULL,
[co_trx_id] [dbo].[smSurrogateKey] NOT NULL,
[co_asset_book_id] [dbo].[smSurrogateKey] NOT NULL,
[apply_date] [dbo].[smApplyDate] NOT NULL,
[trx_type] [dbo].[smTrxType] NOT NULL,
[last_modified_date] [dbo].[smApplyDate] NOT NULL,
[modified_by] [dbo].[smUserID] NOT NULL,
[effective_date] [dbo].[smApplyDate] NULL,
[revised_cost] [dbo].[smMoneyZero] NOT NULL,
[revised_accum_depr] [dbo].[smMoneyZero] NOT NULL,
[delta_cost] [dbo].[smMoneyZero] NOT NULL,
[delta_accum_depr] [dbo].[smMoneyZero] NOT NULL,
[percent_disposed] [dbo].[smPercentage] NOT NULL,
[posting_flag] [dbo].[smPostingState] NOT NULL,
[journal_ctrl_num] [dbo].[smControlNumber] NOT NULL,
[created_by_trx] [dbo].[smLogicalFalse] NOT NULL,
[disposed_depr] [dbo].[smMoneyZero] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE TRIGGER 	[dbo].[amacthst_del_trg] 
ON 				[dbo].[amacthst] 
FOR 			DELETE 
AS 

DECLARE 
	@message 			smErrorLongDesc, 
	@co_trx_id 			smSurrogateKey, 
	@co_asset_book_id 	smSurrogateKey, 
	@posting_flag		smLogical


SELECT 	@co_trx_id = MIN(co_trx_id)
FROM 	deleted 

WHILE @co_trx_id IS NOT NULL 
BEGIN 
	
	SELECT 	@co_asset_book_id 	= MIN(co_asset_book_id)
	FROM 	deleted 
	WHERE 	co_trx_id 			= @co_trx_id 
	
	WHILE @co_asset_book_id IS NOT NULL 
	BEGIN 
		
		IF EXISTS(SELECT 	co_asset_book_id
					FROM	amastbk
					WHERE	co_asset_book_id 	= @co_asset_book_id)
		BEGIN
			SELECT 	@posting_flag		= posting_flag 
			FROM 	deleted 
			WHERE 	co_trx_id 			= @co_trx_id 
			AND 	co_asset_book_id 	= @co_asset_book_id 
		
			
			IF @posting_flag != 0
			BEGIN
				EXEC 		amGetErrorMessage_sp 20575, ".\\amacthst.dtr", 127, @error_message = @message OUT 
				IF @message IS NOT NULL RAISERROR 	20575 @message 
				ROLLBACK	TRANSACTION
				RETURN 
			END
		END
			
		 
		SELECT 	@co_asset_book_id 	= MIN(co_asset_book_id)
		FROM 	deleted 
		WHERE 	co_trx_id 			= @co_trx_id 
		AND 	co_asset_book_id 	> @co_asset_book_id 

	END  

	 
	SELECT 	@co_trx_id 	= MIN(co_trx_id)
	FROM 	deleted 
	WHERE 	co_trx_id 	> @co_trx_id 

END  


DELETE 	amvalues 
FROM 	deleted d, 
		amvalues f 
WHERE 	f.co_trx_id 		= d.co_trx_id 
AND 	f.co_asset_book_id 	= d.co_asset_book_id 

IF @@error <> 0 
	ROLLBACK TRANSACTION 

RETURN
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[amacthst_ins_trg] 
ON 				[dbo].[amacthst] 
FOR 			INSERT 
AS 

DECLARE 
	@rowcount 			smCounter, 
	@rollback 			smLogical, 
	@ret_status 		smErrorCode, 
	@message 			smErrorLongDesc, 
	@co_trx_id 			smSurrogateKey, 
	@co_asset_book_id 	smSurrogateKey, 
	@trx_type 			smTrxType, 
	@jul_apply_date 	smJulianDate, 
	@yr_end_date		smApplyDate,
	@apply_date 		smApplyDate, 
	@acquisition_date	smApplyDate,
	@placed_date 		smApplyDate, 
	@effective_date 	smApplyDate 

SELECT @rowcount = @@rowcount 
SELECT @rollback = 0 





IF ( SELECT COUNT(i.co_asset_book_id) 
		FROM 	inserted i, 
				amastbk f 
		WHERE 	f.co_asset_book_id 	= i.co_asset_book_id) <> @rowcount 
BEGIN 
	EXEC 		amGetErrorMessage_sp 20551, ".\\amacthst.itr", 140, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20551 @message 
	SELECT 		@rollback = 1 
END 


IF @rollback = 1 
BEGIN
	ROLLBACK TRANSACTION 
	RETURN
END


IF EXISTS (SELECT 	effective_date 
			FROM	inserted 
			WHERE	effective_date IS NULL)
BEGIN
	 
	SELECT 	@co_trx_id = MIN(co_trx_id)
	FROM 	inserted 

	WHILE @co_trx_id IS NOT NULL 
	BEGIN 

		SELECT 	@co_asset_book_id 	= MIN(co_asset_book_id)
		FROM 	inserted 
		WHERE 	co_trx_id 			= @co_trx_id 
		
		WHILE 	@co_asset_book_id IS NOT NULL 
		BEGIN 
			 
			SELECT 	@trx_type 			= trx_type,
					@apply_date 		= apply_date 
			FROM 	inserted 
			WHERE 	co_trx_id 			= @co_trx_id 
			AND 	co_asset_book_id 	= @co_asset_book_id 

			IF @trx_type != 30
			BEGIN
				
				SELECT	@acquisition_date 	= a.acquisition_date,
						@placed_date		= ab.placed_in_service_date
				FROM	amasset a,
						amastbk ab
				WHERE	a.co_asset_id 		= ab.co_asset_id
				AND		ab.co_asset_book_id = @co_asset_book_id
				
				IF @placed_date IS NOT NULL
				BEGIN
					
					EXEC @ret_status = amGetFiscalYear_sp 
									 @placed_date, 	 
									 1,					
									 @yr_end_date OUTPUT 

					IF @ret_status <> 0 
					BEGIN
						ROLLBACK TRANSACTION 
						RETURN
					END

					IF @apply_date <= @yr_end_date
						SELECT	@effective_date 	= @acquisition_date
					ELSE
					BEGIN
						SELECT	@jul_apply_date 	= DATEDIFF(dd, "1/1/1980", @apply_date) + 722815

						SELECT	@effective_date 	= MAX(DATEADD(dd, period_start_date-722815, "1/1/1980"))
						FROM	glprd
						WHERE	period_start_date 	<= @jul_apply_date
						AND		period_end_date		>= @jul_apply_date
					END
				END
				ELSE
					SELECT @effective_date	= NULL
			END
			ELSE
				 
				SELECT	@effective_date	= @apply_date

			
			IF @effective_date IS NOT NULL
			BEGIN
				UPDATE 	amacthst 
				SET 	effective_date 		= @effective_date 
				WHERE 	co_trx_id 			= @co_trx_id 
				AND 	co_asset_book_id 	= @co_asset_book_id 

				SELECT	@ret_status = @@error
				IF @ret_status <> 0 
				BEGIN 
					ROLLBACK TRANSACTION 
					RETURN 
				END 
			END

			 
			SELECT 	@co_asset_book_id 	= MIN(co_asset_book_id)
			FROM 	inserted 
			WHERE 	co_trx_id 			= @co_trx_id 
			AND 	co_asset_book_id 	> @co_asset_book_id 
		END 

		 
		SELECT 	@co_trx_id 	= MIN(co_trx_id)
		FROM 	inserted 
		WHERE 	co_trx_id	> @co_trx_id 
		
	END 
END

 




UPDATE 	amvalues 
SET 	posting_flag 		= 1 
FROM 	amvalues 	v,
		inserted 	i 
WHERE 	v.co_trx_id 		= i.co_trx_id 
AND 	v.co_asset_book_id 	= i.co_asset_book_id 
AND 	i.posting_flag 		= 1 

SELECT	@ret_status = @@error
IF @ret_status <> 0 
BEGIN 
	ROLLBACK TRANSACTION 
	RETURN 
END 





GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[amacthst_upd_trg] 
ON 				[dbo].[amacthst] 
FOR 			UPDATE 
AS 

DECLARE 
	@rowcount 			smCounter, 
	@rollback 			smLogical, 
	@message 			smErrorLongDesc, 
	@co_trx_id 			smSurrogateKey, 
	@co_asset_book_id 	smSurrogateKey, 
	@old_apply_date		smApplyDate,
	@jul_apply_date		smJulianDate,
	@apply_date 		smApplyDate, 
	@yr_end_date		smApplyDate,
	@ret_status 		smErrorCode, 
	@trx_type 			smTrxType, 
	@effective_date 	smApplyDate, 
	@acquisition_date	smApplyDate,
	@placed_date		smApplyDate,
	@posting_flag		smLogical

SELECT @rowcount = @@rowcount 
SELECT @rollback = 0 





IF UPDATE(apply_date)
BEGIN 




	SELECT 	@co_trx_id = MIN(co_trx_id)
	FROM 	inserted 
	
	WHILE @co_trx_id IS NOT NULL 
	BEGIN 
		
		SELECT 	@co_asset_book_id = MIN(co_asset_book_id)
		FROM 	inserted 
		WHERE 	co_trx_id = @co_trx_id 
		
		WHILE @co_asset_book_id IS NOT NULL 
		BEGIN 
			SELECT 	@old_apply_date 	= apply_date,
					@trx_type 			= trx_type,
					@posting_flag		= posting_flag 
			FROM 	deleted 
			WHERE 	co_trx_id 			= @co_trx_id 
			AND 	co_asset_book_id 	= @co_asset_book_id 
			
			SELECT 	@apply_date 		= apply_date,
					@trx_type 			= trx_type 
			FROM 	inserted 
			WHERE 	co_trx_id 			= @co_trx_id 
			AND 	co_asset_book_id 	= @co_asset_book_id 

			IF @old_apply_date <> @apply_date
			BEGIN
			
				
				IF @posting_flag != 0
				BEGIN
					EXEC 		amGetErrorMessage_sp 20576, ".\\amacthst.utr", 176, @error_message = @message OUT 
					IF @message IS NOT NULL RAISERROR 	20576 @message 
					ROLLBACK	TRANSACTION
					RETURN 
				END
				
				UPDATE 	amvalues 
				SET 	apply_date 			= @apply_date 
				WHERE 	co_trx_id 			= @co_trx_id 
				AND 	co_asset_book_id 	= @co_asset_book_id 
				
				IF @@error <> 0 
				BEGIN 
	


					ROLLBACK TRANSACTION 
					RETURN 
				END 

				 
				IF @trx_type != 30
				BEGIN
					
					SELECT	@acquisition_date 	= a.acquisition_date,
							@placed_date		= ab.placed_in_service_date
					FROM	amasset a,
							amastbk ab
					WHERE	a.co_asset_id 		= ab.co_asset_id
					AND		ab.co_asset_book_id = @co_asset_book_id
					
					IF @placed_date IS NOT NULL
					BEGIN
						
						EXEC @ret_status = amGetFiscalYear_sp 
										 @placed_date, 	 
										 1,					
										 @yr_end_date OUTPUT 

						IF @ret_status <> 0 
						BEGIN
							ROLLBACK TRANSACTION 
							RETURN
						END

						IF @apply_date <= @yr_end_date
							SELECT	@effective_date = @acquisition_date
						ELSE
						BEGIN
							SELECT	@jul_apply_date 	= DATEDIFF(dd, "1/1/1980", @apply_date) + 722815
							
						 	SELECT	@effective_date 	= MAX(DATEADD(dd, period_start_date-722815, "1/1/1980"))
							FROM	glprd
							WHERE	period_start_date 	<= @jul_apply_date
							AND		period_end_date		>= @jul_apply_date
						END
					END
					ELSE
						SELECT @effective_date	= NULL
				END
				ELSE
					 
					SELECT	@effective_date	= @apply_date

				
				UPDATE 	amacthst 
				SET 	effective_date 		= @effective_date 
				WHERE 	co_trx_id 			= @co_trx_id 
				AND 	co_asset_book_id 	= @co_asset_book_id 

				SELECT	@ret_status = @@error
				IF @ret_status <> 0 
				BEGIN 
					ROLLBACK TRANSACTION 
					RETURN 
				END
			END

			 
			SELECT 	@co_asset_book_id 	= MIN(co_asset_book_id)
			FROM 	inserted 
			WHERE 	co_trx_id 			= @co_trx_id 
			AND 	co_asset_book_id 	> @co_asset_book_id 

		END  

		 
		SELECT 	@co_trx_id = MIN(co_trx_id)
		FROM 	inserted 
		WHERE 	co_trx_id > @co_trx_id 

	END  

END  

 
IF UPDATE(posting_flag)
BEGIN 



	UPDATE 	amvalues 
	SET 	posting_flag 		= i.posting_flag 
	FROM 	amvalues 	v,
			inserted 	i 
	WHERE 	v.co_trx_id 		= i.co_trx_id 
	AND 	v.co_asset_book_id 	= i.co_asset_book_id 
	
	IF @@error <> 0 
	BEGIN 
		ROLLBACK TRANSACTION 
		RETURN 
	END 

END 

IF @rollback <> 0 
BEGIN
	ROLLBACK TRANSACTION 
	RETURN
END





GO
CREATE CLUSTERED INDEX [amacthst_ind_1] ON [dbo].[amacthst] ([co_asset_book_id], [apply_date]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [amacthst_ind_3] ON [dbo].[amacthst] ([co_asset_book_id], [effective_date]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [amacthst_ind_0] ON [dbo].[amacthst] ([co_trx_id], [co_asset_book_id]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [amacthst_ind_4] ON [dbo].[amacthst] ([journal_ctrl_num]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [amacthst_ind_2] ON [dbo].[amacthst] ([trx_type]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amacthst].[co_trx_id]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amacthst].[co_asset_book_id]'
GO
EXEC sp_bindrule N'[dbo].[smTrxType_rl]', N'[dbo].[amacthst].[trx_type]'
GO
EXEC sp_bindefault N'[dbo].[smTodaysDate_df]', N'[dbo].[amacthst].[last_modified_date]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amacthst].[modified_by]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amacthst].[revised_cost]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amacthst].[revised_accum_depr]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amacthst].[delta_cost]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amacthst].[delta_accum_depr]'
GO
EXEC sp_bindefault N'[dbo].[smPercentage_df]', N'[dbo].[amacthst].[percent_disposed]'
GO
EXEC sp_bindefault N'[dbo].[smPostingState_df]', N'[dbo].[amacthst].[posting_flag]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amacthst].[created_by_trx]'
GO
EXEC sp_bindefault N'[dbo].[smFalse_df]', N'[dbo].[amacthst].[created_by_trx]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amacthst].[disposed_depr]'
GO
GRANT REFERENCES ON  [dbo].[amacthst] TO [public]
GO
GRANT SELECT ON  [dbo].[amacthst] TO [public]
GO
GRANT INSERT ON  [dbo].[amacthst] TO [public]
GO
GRANT DELETE ON  [dbo].[amacthst] TO [public]
GO
GRANT UPDATE ON  [dbo].[amacthst] TO [public]
GO
