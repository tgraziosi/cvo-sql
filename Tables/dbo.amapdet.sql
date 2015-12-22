CREATE TABLE [dbo].[amapdet]
(
[timestamp] [timestamp] NOT NULL,
[company_id] [dbo].[smCompanyID] NOT NULL,
[trx_ctrl_num] [dbo].[smControlNumber] NOT NULL,
[sequence_id] [dbo].[smCounter] NOT NULL,
[line_id] [dbo].[smCounter] NOT NULL,
[co_asset_id] [dbo].[smSurrogateKey] NULL,
[asset_ctrl_num] [dbo].[smControlNumber] NULL,
[line_description] [dbo].[smStdDescription] NULL,
[fixed_asset_acct] [dbo].[smAccountCode] NULL,
[fixed_asset_ref_code] [dbo].[smAccountReferenceCode] NULL,
[imm_exp_acct] [dbo].[smAccountCode] NULL,
[imm_exp_ref_code] [dbo].[smAccountReferenceCode] NULL,
[quantity] [dbo].[smQuantity] NULL,
[update_asset_quantity] [dbo].[smLogicalTrue] NULL,
[asset_amount] [dbo].[smMoneyZero] NULL,
[imm_exp_amount] [dbo].[smMoneyZero] NULL,
[activity_type] [dbo].[smTrxType] NULL,
[apply_date] [dbo].[smApplyDate] NULL,
[create_item] [dbo].[smLogicalTrue] NULL,
[asset_tag] [dbo].[smTag] NULL,
[item_tag] [dbo].[smTag] NULL,
[completed_date] [dbo].[smApplyDate] NULL,
[completed_by] [dbo].[smUserID] NULL,
[co_trx_id] [dbo].[smSurrogateKey] NULL,
[item_id] [dbo].[smSurrogateKey] NULL,
[last_modified_date] [dbo].[smApplyDate] NULL,
[modified_by] [dbo].[smUserID] NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[amapdet_ins_trg] 
ON 				[dbo].[amapdet] 
FOR 			INSERT 
AS 

DECLARE 
	@rowcount 			smCounter, 
	@rollback 			smLogical, 
	@message 			smErrorLongDesc, 
	@co_asset_id		smSurrogateKey,
	@asset_ctrl_num		smControlNumber,
	@apply_date			smApplyDate,
	@param				smErrorParam

SELECT @rowcount = @@rowcount 
SELECT @rollback = 0 






IF ( SELECT COUNT(i.co_asset_id) 
		FROM 	inserted i, 
				amasset a 
		WHERE 	a.co_asset_id 	= i.co_asset_id) <> @rowcount 
BEGIN 
	
	SELECT	@co_asset_id = MIN(co_asset_id)
	FROM	inserted
	
	WHILE @co_asset_id IS NOT NULL
	BEGIN
		IF NOT EXISTS(SELECT 	a.co_asset_id
						FROM 	inserted i,
								amasset a
						WHERE	i.co_asset_id = a.co_asset_id)
		BEGIN
			SELECT	@asset_ctrl_num = asset_ctrl_num
			FROM	inserted i
			WHERE 	co_asset_id 	= @co_asset_id
			
			EXEC 		amGetErrorMessage_sp 20568, ".\\amapdet.itr", 97, @asset_ctrl_num, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20568 @message 
			SELECT 		@rollback = 1 
			BREAK
		END

		SELECT	@co_asset_id 	= MIN(co_asset_id)
		FROM	inserted
		WHERE	co_asset_id		> @co_asset_id

	END
END 



SELECT	@asset_ctrl_num = NULL

SELECT	@asset_ctrl_num 	= MIN(i.asset_ctrl_num)
FROM	inserted i,
		amasset a
WHERE 	a.co_asset_id 		= i.co_asset_id
AND		a.activity_state 	IN (101, 1)
 
IF @asset_ctrl_num <> NULL
BEGIN
	EXEC 		amGetErrorMessage_sp 20569, ".\\amapdet.itr", 124, @asset_ctrl_num, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20569 @message 
	SELECT 		@rollback = 1 
END


SELECT	@co_asset_id = NULL

SELECT	@co_asset_id 		= MIN(i.co_asset_id)
FROM	inserted i,
		amasset a
WHERE 	a.co_asset_id 		= i.co_asset_id
AND		i.apply_date		< a.acquisition_date
 
IF @co_asset_id <> NULL
BEGIN
	
	SELECT	@asset_ctrl_num		= i.asset_ctrl_num
	FROM	inserted i,
			amasset a
	WHERE 	a.co_asset_id 		= @co_asset_id
	AND		i.co_asset_id		= @co_asset_id
	AND		i.apply_date		< a.acquisition_date
	
	SELECT	@apply_date 		= MIN(i.apply_date)
	FROM	inserted i,
			amasset a
	WHERE 	a.co_asset_id 		= @co_asset_id
	AND		i.co_asset_id		= @co_asset_id
	AND		i.apply_date		< a.acquisition_date
	
	SELECT	@param			= CONVERT(char(255), @apply_date, 107)
	
	EXEC 		amGetErrorMessage_sp 20570, ".\\amapdet.itr", 157, @param, @asset_ctrl_num, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20570 @message 
	SELECT 		@rollback = 1 
END
 

IF @rollback = 1 
BEGIN 
	ROLLBACK TRANSACTION 
	RETURN 
END 





GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[amapdet_upd_trg] 
ON 				[dbo].[amapdet] 
FOR 			UPDATE 
AS 

DECLARE 
	@rowcount 			smCounter, 
	@rollback 			smLogical, 
	@message 			smErrorLongDesc, 
	@co_asset_id		smSurrogateKey,
	@asset_ctrl_num		smControlNumber,
	@apply_date			smApplyDate,
	@param				smErrorParam

SELECT @rowcount = @@rowcount 
SELECT @rollback = 0 






IF ( SELECT COUNT(i.co_asset_id) 
		FROM 	inserted i, 
				amasset a 
		WHERE 	a.co_asset_id 	= i.co_asset_id) <> @rowcount 
BEGIN 
	
	SELECT	@co_asset_id = MIN(co_asset_id)
	FROM	inserted
	
	WHILE @co_asset_id IS NOT NULL
	BEGIN
		IF NOT EXISTS(SELECT 	a.co_asset_id
						FROM 	inserted i,
								amasset a
						WHERE	i.co_asset_id = a.co_asset_id)
		BEGIN
			SELECT	@asset_ctrl_num = asset_ctrl_num
			FROM	inserted i
			WHERE 	co_asset_id 	= @co_asset_id
			
			EXEC 		amGetErrorMessage_sp 20568, ".\\amapdet.utr", 97, @asset_ctrl_num, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20568 @message 
			SELECT 		@rollback = 1 
			BREAK
		END

		SELECT	@co_asset_id 	= MIN(co_asset_id)
		FROM	inserted
		WHERE	co_asset_id		> @co_asset_id

	END
END 


SELECT	@asset_ctrl_num = NULL

SELECT	@asset_ctrl_num 	= MIN(i.asset_ctrl_num)
FROM	inserted i,
		amasset a
WHERE 	a.co_asset_id 		= i.co_asset_id
AND		a.activity_state 	IN (101, 1)
 
IF @asset_ctrl_num <> NULL
BEGIN
	EXEC 		amGetErrorMessage_sp 20569, ".\\amapdet.utr", 123, @asset_ctrl_num, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20569 @message 
	SELECT 		@rollback = 1 
END

SELECT	@co_asset_id = NULL

SELECT	@co_asset_id 		= MIN(i.co_asset_id)
FROM	inserted i,
		amasset a
WHERE 	a.co_asset_id 		= i.co_asset_id
AND		i.apply_date		< a.acquisition_date
 
IF @co_asset_id <> NULL
BEGIN
	
	SELECT	@asset_ctrl_num		= i.asset_ctrl_num
	FROM	inserted i,
			amasset a
	WHERE 	a.co_asset_id 		= @co_asset_id
	AND		i.co_asset_id		= @co_asset_id
	AND		i.apply_date		< a.acquisition_date
	
	SELECT	@apply_date 		= MIN(i.apply_date)
	FROM	inserted i,
			amasset a
	WHERE 	a.co_asset_id 		= @co_asset_id
	AND		i.co_asset_id		= @co_asset_id
	AND		i.apply_date		< a.acquisition_date
	
	SELECT	@param			= CONVERT(char(255), @apply_date, 107)
	
	EXEC 		amGetErrorMessage_sp 20570, ".\\amapdet.utr", 155, @param, @asset_ctrl_num, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20570 @message 
	SELECT 		@rollback = 1 
END
 

IF @rollback = 1 
BEGIN 
	ROLLBACK TRANSACTION 
	RETURN 
END 





GO
CREATE UNIQUE CLUSTERED INDEX [amapdet_ind_0] ON [dbo].[amapdet] ([company_id], [trx_ctrl_num], [sequence_id], [line_id]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amapdet].[sequence_id]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amapdet].[line_id]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amapdet].[co_asset_id]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amapdet].[line_description]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amapdet].[fixed_asset_ref_code]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amapdet].[imm_exp_ref_code]'
GO
EXEC sp_bindefault N'[dbo].[smQuantity_df]', N'[dbo].[amapdet].[quantity]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amapdet].[update_asset_quantity]'
GO
EXEC sp_bindefault N'[dbo].[smTrue_df]', N'[dbo].[amapdet].[update_asset_quantity]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amapdet].[asset_amount]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amapdet].[imm_exp_amount]'
GO
EXEC sp_bindrule N'[dbo].[smTrxType_rl]', N'[dbo].[amapdet].[activity_type]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amapdet].[create_item]'
GO
EXEC sp_bindefault N'[dbo].[smTrue_df]', N'[dbo].[amapdet].[create_item]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amapdet].[asset_tag]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amapdet].[item_tag]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amapdet].[completed_by]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amapdet].[co_trx_id]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amapdet].[item_id]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amapdet].[modified_by]'
GO
GRANT REFERENCES ON  [dbo].[amapdet] TO [public]
GO
GRANT SELECT ON  [dbo].[amapdet] TO [public]
GO
GRANT INSERT ON  [dbo].[amapdet] TO [public]
GO
GRANT DELETE ON  [dbo].[amapdet] TO [public]
GO
GRANT UPDATE ON  [dbo].[amapdet] TO [public]
GO
