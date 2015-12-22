CREATE TABLE [dbo].[amtrxhdr]
(
[timestamp] [timestamp] NOT NULL,
[company_id] [dbo].[smCompanyID] NOT NULL,
[trx_ctrl_num] [dbo].[smControlNumber] NOT NULL,
[journal_ctrl_num] [dbo].[smControlNumber] NOT NULL,
[co_trx_id] [dbo].[smSurrogateKey] NOT NULL,
[trx_type] [dbo].[smTrxType] NOT NULL,
[trx_subtype] [dbo].[smTrxSubtype] NOT NULL,
[batch_ctrl_num] [dbo].[smControlNumber] NULL,
[last_modified_date] [dbo].[smApplyDate] NOT NULL,
[modified_by] [dbo].[smUserID] NOT NULL,
[apply_date] [dbo].[smApplyDate] NOT NULL,
[posting_flag] [dbo].[smPostingState] NOT NULL,
[date_posted] [dbo].[smApplyDate] NULL,
[hold_flag] [dbo].[smLogicalTrue] NOT NULL,
[trx_description] [dbo].[smStdDescription] NOT NULL,
[doc_reference] [dbo].[smDocumentReference] NOT NULL,
[note_id] [dbo].[smSurrogateKey] NOT NULL,
[user_field_id] [dbo].[smSurrogateKey] NOT NULL,
[intercompany_flag] [dbo].[smLogicalFalse] NOT NULL,
[source_company_id] [dbo].[smCompanyID] NOT NULL,
[home_currency_code] [dbo].[smCurrencyCode] NOT NULL,
[total_paid] [dbo].[smMoneyZero] NOT NULL,
[total_received] [dbo].[smMoneyZero] NOT NULL,
[linked_trx] [dbo].[smSurrogateKey] NOT NULL,
[revaluation_rate] [dbo].[smRevaluationRate] NOT NULL,
[process_id] [dbo].[smSurrogateKey] NOT NULL,
[process_ctrl_num] [dbo].[smProcessCtrlNum] NULL,
[trx_source] [dbo].[smTrxSource] NOT NULL,
[co_asset_id] [dbo].[smSurrogateKey] NOT NULL,
[fixed_asset_account_id] [dbo].[smSurrogateKey] NOT NULL,
[imm_exp_account_id] [dbo].[smSurrogateKey] NOT NULL,
[change_in_quantity] [dbo].[smQuantity] NOT NULL,
[org_id] [dbo].[smOrgId] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[amtrxhdr_del_trg] 
ON 				[dbo].[amtrxhdr] 
FOR 			DELETE 
AS 

DECLARE 
	@rowcount 		smCounter,
	@message		smErrorLongDesc

SELECT @rowcount = @@rowcount


IF 	(EXISTS (SELECT book_code
			FROM	amastbk ab,
					deleted d
			WHERE	d.co_asset_id 	= ab.co_asset_id
			AND		d.trx_type		!= 50
			AND		d.posting_flag 	!= 0))
OR	(EXISTS (SELECT trx_type
			FROM	deleted
			WHERE	trx_type		= 50
			AND		posting_flag	!= 0))
BEGIN
			
	EXEC 		amGetErrorMessage_sp 20574, ".\\amtrxhdr.dtr", 116, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20574 @message 
	ROLLBACK	TRANSACTION 
	RETURN
END

 
DELETE 	amcalval 
FROM 	deleted d, 
		amcalval cv 
WHERE 	cv.co_trx_id 	= d.co_trx_id 
AND 	d.trx_type 		= 50 

IF @@error <> 0 
BEGIN
	ROLLBACK TRANSACTION 
	RETURN
END

 
DELETE 	amdprcrt 
FROM 	deleted d, 
		amdprcrt dc 
WHERE 	dc.co_trx_id 	= d.co_trx_id 

IF @@error <> 0 
BEGIN
	ROLLBACK TRANSACTION 
	RETURN
END

 
DELETE 	amtrxast
FROM 	deleted d, 
	amtrxast ta 
WHERE 	ta.co_trx_id 	= d.co_trx_id 

IF @@error <> 0 
BEGIN
	ROLLBACK TRANSACTION 
	RETURN
END

 
DELETE 	amacthst 
FROM 	deleted d, 
		amacthst ah 
WHERE 	ah.co_trx_id = d.co_trx_id 

IF @@error <> 0 
BEGIN
	ROLLBACK TRANSACTION 
	RETURN
END

DELETE 	amvalues 
FROM 	deleted d, 
		amvalues v 
WHERE 	v.co_trx_id = d.co_trx_id 

IF @@error <> 0 
BEGIN
	ROLLBACK TRANSACTION 
	RETURN
END

GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[amtrxhdr_ins_trg] 
ON 				[dbo].[amtrxhdr] 
FOR 			INSERT 
AS 

DECLARE 
	@rowcount 			smCounter, 
	@error 				smErrorCode,
	@message 			smErrorLongDesc, 
	@param				smErrorParam,
	@param2				smErrorParam,
	@company_id 		smCompanyID, 
	@trx_ctrl_num 		smControlNumber, 
	@co_trx_id 			smSurrogateKey,
	@co_asset_id		smSurrogateKey,
	@trx_type			smTrxType,
	@activity_state		smSystemState,
	@apply_date			smApplyDate,
	@last_disp_date		smApplyDate,		
	@last_depr_date		smApplyDate,		
	@asset_ctrl_num		smControlNumber,
	@acquisition_date	smApplyDate,
	@trx_source			smTrxSource 

SELECT @rowcount = @@rowcount 


IF ( SELECT COUNT(i.company_id) 
		FROM 	inserted i, 	
				amco f 
		WHERE 	f.company_id = i.company_id) <> @rowcount 
BEGIN 
	EXEC 		amGetErrorMessage_sp 
						20508, ".\\amtrxhdr.itr", 148, 
						@error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20508 @message 
	ROLLBACK 	TRANSACTION 
	RETURN 
END 


SELECT 	@company_id = MIN(company_id)
FROM 	inserted 

WHILE @company_id IS NOT NULL 
BEGIN 
	SELECT 	@trx_ctrl_num 	= MIN(trx_ctrl_num)
	FROM 	inserted 
	WHERE 	company_id 		= @company_id 

	WHILE @trx_ctrl_num IS NOT NULL 
	BEGIN 
		SELECT 	@co_trx_id 		= co_trx_id,
				@co_asset_id	= co_asset_id,
				@trx_type		= trx_type,
				@apply_date		= apply_date,
				@trx_source		= trx_source
		FROM 	inserted 
		WHERE 	company_id 		= @company_id 
		AND 	trx_ctrl_num 	= @trx_ctrl_num 


		IF NOT	@trx_type IN (SELECT trx_type FROM amtrxdef)
		BEGIN

			SELECT		@param 	= RTRIM(CONVERT(varchar(255), @trx_type))

			EXEC 		amGetErrorMessage_sp 
									20588, ".\\amtrxhdr.itr", 189,
									@param, 
									@error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20588 @message 
			ROLLBACK 	TRANSACTION 
			RETURN

		END

		IF @co_asset_id != 0
		BEGIN
			SELECT 	@last_depr_date = NULL,
					@last_disp_date = NULL
					
			
			IF NOT EXISTS (SELECT	co_asset_id
							FROM	amasset
							WHERE	co_asset_id = @co_asset_id)
			BEGIN
				EXEC 		amGetErrorMessage_sp 
									20571, ".\\amtrxhdr.itr", 212, 
									@error_message = @message OUT 
				IF @message IS NOT NULL RAISERROR 	20571 @message 
				ROLLBACK 	TRANSACTION 
				RETURN 
			END	

			SELECT	@activity_state 	= activity_state,
					@acquisition_date	= acquisition_date,
					@asset_ctrl_num		= asset_ctrl_num
			FROM	amasset
			WHERE	co_asset_id 		= @co_asset_id
			
			IF 	@activity_state = 101
			OR (@activity_state = 1
				AND	@trx_type NOT IN (30, 60))
			BEGIN
				EXEC 		amGetErrorMessage_sp 
										20572, ".\\amtrxhdr.itr", 230, 
										@asset_ctrl_num, 
										@error_message = @message OUT 
				IF @message IS NOT NULL RAISERROR 	20572 @message 
				ROLLBACK 	TRANSACTION 
				RETURN 
		 	END

			IF @apply_date < @acquisition_date
			BEGIN
				SELECT		@param = RTRIM(CONVERT(varchar(255), @apply_date, 107))

				EXEC 		amGetErrorMessage_sp 
										20573, ".\\amtrxhdr.itr", 243, 
										@param, @asset_ctrl_num, 
										@error_message = @message OUT 
				IF @message IS NOT NULL RAISERROR 	20573 @message 
				ROLLBACK 	TRANSACTION 
				RETURN 
			END

			
			IF 	@trx_type 	!= 60
			AND	@trx_source	!= 2
			BEGIN
				SELECT	@last_disp_date		= MAX(apply_date)
				FROM	amtrxhdr
				WHERE	co_asset_id			= @co_asset_id
				AND		trx_type			IN (30, 70)
				AND		co_trx_id			!= @co_trx_id
				
				IF 	@last_disp_date 	IS NOT NULL
				AND	@apply_date <= 		@last_disp_date
				BEGIN
					SELECT		@param = RTRIM(CONVERT(varchar(255), @apply_date, 107))

					EXEC 		amGetErrorMessage_sp 
											20577, ".\\amtrxhdr.itr", 270, 
											@param, @asset_ctrl_num, 
											@error_message = @message OUT 
					IF @message IS NOT NULL RAISERROR 	20577 @message 
					ROLLBACK 	TRANSACTION 
					RETURN 
				END			
			END			
		
			
			SELECT	@last_depr_date		= MAX(last_posted_depr_date)
			FROM	amastbk
			WHERE	co_asset_id			= @co_asset_id
			
			IF 	@last_depr_date 	IS NOT NULL
			AND	@apply_date <= 		@last_depr_date
			BEGIN
				SELECT		@param 	= RTRIM(CONVERT(varchar(255), @apply_date, 107)),
							@param2 = RTRIM(CONVERT(varchar(255), @last_depr_date, 107))

				EXEC 		amGetErrorMessage_sp 
										20585, ".\\amtrxhdr.itr", 293, 
										@param, @asset_ctrl_num, @param2,
										@error_message = @message OUT 
				IF @message IS NOT NULL RAISERROR 	20585 @message 
				ROLLBACK 	TRANSACTION 
				RETURN 
			END
		END

		
		IF @co_trx_id = 0 
		BEGIN 
			EXEC @error = amNextKey_sp 7, @co_trx_id OUT 
			IF @error <> 0 
			BEGIN 



				ROLLBACK TRANSACTION 
				RETURN 
			END 

			UPDATE 	amtrxhdr 
			SET 	co_trx_id 		= @co_trx_id 
			WHERE 	company_id 		= @company_id 
			AND 	trx_ctrl_num 	= @trx_ctrl_num 
			
			SELECT @error = @@error 
			IF @error <> 0 
			BEGIN 



				ROLLBACK TRANSACTION 
				RETURN 
			END 
		END 

		SELECT 	@trx_ctrl_num 	= MIN(trx_ctrl_num)
		FROM 	inserted 
		WHERE 	company_id 		= @company_id 
		AND 	trx_ctrl_num 	> @trx_ctrl_num 

	END 

	SELECT 	@company_id = MIN(company_id)
	FROM 	inserted 
	WHERE 	company_id 	> @company_id 

END 
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[amtrxhdr_upd_trg] 
ON 				[dbo].[amtrxhdr] 
FOR 			UPDATE 
AS 

DECLARE 
	@result				smErrorCode,
	@message			smErrorLongDesc,
	@param				smErrorParam,
	@param2				smErrorParam,
	@co_trx_id			smSurrogateKey,
	@old_apply_date		smApplyDate,
	@new_apply_date		smApplyDate,
	@co_asset_id		smSurrogateKey,
	@asset_ctrl_num		smControlNumber,
	@trx_source			smTrxSource,
	@last_disp_date		smApplyDate,
	@last_depr_date		smApplyDate,		
	@trx_type			smTrxType



IF UPDATE (apply_date)
BEGIN
	SELECT 	@co_trx_id	= MIN(co_trx_id)
	FROM	inserted
	
 	WHILE @co_trx_id IS NOT NULL
 	BEGIN
 		SELECT	@old_apply_date		= apply_date
 		FROM	deleted
 		WHERE	co_trx_id			= @co_trx_id
 		
 		SELECT	@new_apply_date		= apply_date,
				@trx_type			= trx_type,
				@co_asset_id		= co_asset_id,
				@trx_source			= trx_source
 		FROM	inserted
 		WHERE	co_trx_id			= @co_trx_id


		IF NOT	@trx_type IN (SELECT trx_type FROM amtrxdef)
		BEGIN

			SELECT		@param 	= RTRIM(CONVERT(varchar(255), @trx_type))

			EXEC 		amGetErrorMessage_sp 
									20588, ".\\amtrxhdr.utr", 111,
									@param, 
									@error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20588 @message 
			ROLLBACK 	TRANSACTION 
			RETURN

		END

 		
 		IF 	@old_apply_date <> @new_apply_date
		AND	@trx_type		!= 50
 		BEGIN
			IF 	@trx_type 	!= 60
			AND	@trx_source	!= 2
			BEGIN
				SELECT	@last_disp_date		= MAX(apply_date)
				FROM	amtrxhdr
				WHERE	co_asset_id			= @co_asset_id
				AND		trx_type			IN (30, 70)
				
				IF 	@last_disp_date 	IS NOT NULL
				AND	@new_apply_date <= 	@last_disp_date
				BEGIN
					SELECT		@asset_ctrl_num = ""
					
					SELECT		@asset_ctrl_num 	= asset_ctrl_num
					FROM		amasset
					WHERE		co_asset_id			= @co_asset_id
					
					SELECT		@param = RTRIM(CONVERT(varchar(255), @new_apply_date, 107))

					EXEC 		amGetErrorMessage_sp 
											20578, ".\\amtrxhdr.utr", 144, 
											@param, @asset_ctrl_num, 
											@error_message = @message OUT 
					IF @message IS NOT NULL RAISERROR 	20578 @message 
					ROLLBACK 	TRANSACTION 
					RETURN 
				END			
			END
 		
			
			SELECT	@last_depr_date		= MAX(last_posted_depr_date)
			FROM	amastbk
			WHERE	co_asset_id			= @co_asset_id
			
			IF 	@last_depr_date 	IS NOT NULL
			AND	@new_apply_date 	<= @last_depr_date
			BEGIN
				SELECT		@asset_ctrl_num = ""
				
				SELECT		@asset_ctrl_num 	= asset_ctrl_num
				FROM		amasset
				WHERE		co_asset_id			= @co_asset_id
				
				SELECT		@param 	= RTRIM(CONVERT(varchar(255), @new_apply_date, 107)),
							@param2 = RTRIM(CONVERT(varchar(255), @last_depr_date, 107))

				EXEC 		amGetErrorMessage_sp 
										20586, ".\\amtrxhdr.utr", 173, 
										@param, @asset_ctrl_num, @param2,
										@error_message = @message OUT 
				IF @message IS NOT NULL RAISERROR 	20586 @message 
				ROLLBACK 	TRANSACTION 
				RETURN 
			END
	 		
	 		UPDATE	amacthst
			SET		apply_date		= i.apply_date
			FROM	inserted i,
					amacthst ah
			WHERE	i.co_trx_id 	= ah.co_trx_id

			SELECT @result = @@error
			IF @result <> 0
			BEGIN
				ROLLBACK TRANSACTION
				RETURN
			END
		END

		SELECT	@co_trx_id 	= MIN(co_trx_id)
		FROM	inserted
		WHERE	co_trx_id	> @co_trx_id
	END
END
ELSE
BEGIN
	IF UPDATE(trx_type)
	BEGIN

		SELECT 	@co_trx_id	= MIN(co_trx_id)
		FROM	inserted
	
	 	WHILE @co_trx_id IS NOT NULL
	 	BEGIN
	 			 		
	 		SELECT	@trx_type			= trx_type
			FROM	inserted
	 		WHERE	co_trx_id			= @co_trx_id


			IF NOT	@trx_type IN (SELECT trx_type FROM amtrxdef)
			BEGIN

					SELECT		@param 	= RTRIM(CONVERT(varchar(255), @trx_type))

					EXEC 		amGetErrorMessage_sp 
											20588, ".\\amtrxhdr.utr", 222,
											@param, 
											@error_message = @message OUT 
					IF @message IS NOT NULL RAISERROR 	20588 @message 
					ROLLBACK 	TRANSACTION 
					RETURN

			END

			SELECT	@co_trx_id 	= MIN(co_trx_id)
			FROM	inserted
			WHERE	co_trx_id	> @co_trx_id

		END 
	END
END

GO
CREATE NONCLUSTERED INDEX [amtrxhdr_ind_2] ON [dbo].[amtrxhdr] ([co_asset_id], [trx_source]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [amtrxhdr_ind_1] ON [dbo].[amtrxhdr] ([co_trx_id]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [amtrxhdr_ind_0] ON [dbo].[amtrxhdr] ([company_id], [trx_ctrl_num]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [amtrxhdr_ind_3] ON [dbo].[amtrxhdr] ([trx_type]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amtrxhdr].[co_trx_id]'
GO
EXEC sp_bindrule N'[dbo].[smTrxType_rl]', N'[dbo].[amtrxhdr].[trx_type]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amtrxhdr].[trx_subtype]'
GO
EXEC sp_bindefault N'[dbo].[smTodaysDate_df]', N'[dbo].[amtrxhdr].[last_modified_date]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amtrxhdr].[modified_by]'
GO
EXEC sp_bindefault N'[dbo].[smPostingState_df]', N'[dbo].[amtrxhdr].[posting_flag]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amtrxhdr].[hold_flag]'
GO
EXEC sp_bindefault N'[dbo].[smTrue_df]', N'[dbo].[amtrxhdr].[hold_flag]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amtrxhdr].[trx_description]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amtrxhdr].[doc_reference]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amtrxhdr].[note_id]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amtrxhdr].[user_field_id]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amtrxhdr].[intercompany_flag]'
GO
EXEC sp_bindefault N'[dbo].[smFalse_df]', N'[dbo].[amtrxhdr].[intercompany_flag]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amtrxhdr].[source_company_id]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amtrxhdr].[home_currency_code]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amtrxhdr].[total_paid]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amtrxhdr].[total_received]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amtrxhdr].[linked_trx]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amtrxhdr].[revaluation_rate]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amtrxhdr].[process_id]'
GO
EXEC sp_bindrule N'[dbo].[smTrxSource_rl]', N'[dbo].[amtrxhdr].[trx_source]'
GO
EXEC sp_bindefault N'[dbo].[smTrxSource_df]', N'[dbo].[amtrxhdr].[trx_source]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amtrxhdr].[co_asset_id]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amtrxhdr].[fixed_asset_account_id]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amtrxhdr].[imm_exp_account_id]'
GO
EXEC sp_bindefault N'[dbo].[smQuantity_df]', N'[dbo].[amtrxhdr].[change_in_quantity]'
GO
GRANT REFERENCES ON  [dbo].[amtrxhdr] TO [public]
GO
GRANT SELECT ON  [dbo].[amtrxhdr] TO [public]
GO
GRANT INSERT ON  [dbo].[amtrxhdr] TO [public]
GO
GRANT DELETE ON  [dbo].[amtrxhdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[amtrxhdr] TO [public]
GO
