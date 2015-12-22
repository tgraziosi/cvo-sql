CREATE TABLE [dbo].[amdprrul]
(
[timestamp] [timestamp] NOT NULL,
[depr_rule_code] [dbo].[smDeprRuleCode] NOT NULL,
[rule_description] [dbo].[smStdDescription] NOT NULL,
[depr_method_id] [dbo].[smDeprMethodID] NOT NULL,
[convention_id] [dbo].[smConventionID] NOT NULL,
[units_of_measure] [dbo].[smUnitsOfMeasure] NOT NULL,
[service_life] [dbo].[smLife] NOT NULL,
[useful_life_end_date] [dbo].[smApplyDate] NULL,
[annual_depr_rate] [dbo].[smRate] NOT NULL,
[immediate_depr_rate] [dbo].[smRate] NOT NULL,
[first_year_depr_rate] [dbo].[smRate] NOT NULL,
[def_salvage_percent] [dbo].[smPercentZero] NOT NULL,
[def_salvage_value] [dbo].[smMoneyZero] NOT NULL,
[override_salvage] [dbo].[smLogicalFalse] NOT NULL,
[depr_below_salvage] [dbo].[smLogicalFalse] NOT NULL,
[p_and_l_on_partial_disp] [dbo].[smLogicalTrue] NOT NULL,
[use_convention_on_disp] [dbo].[smLogicalTrue] NOT NULL,
[max_asset_value] [dbo].[smMoneyZero] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE TRIGGER 	[dbo].[amdprrul_del_trg] 
ON 				[dbo].[amdprrul] 
FOR 			DELETE 
AS 


DECLARE
	@rollback 			smLogical, 
	@message 			smErrorLongDesc, 
	@depr_rule_code 	smDeprRuleCode, 
	@book_code			smBookCode, 
	@asset_ctrl_num		smControlNumber,
	@category_code		smCategoryCode,
	@co_asset_book_id	smSurrogateKey

SELECT @rollback 	= 0 

SELECT	@depr_rule_code = MIN(depr_rule_code)
FROM	deleted

WHILE @depr_rule_code IS NOT NULL
BEGIN
	SELECT	@co_asset_book_id = NULL,
			@category_code	= NULL
	
	SELECT	@category_code 	= MIN(category_code)
	FROM	amcatbk
	WHERE	depr_rule_code	= @depr_rule_code
	
	IF @category_code IS NOT NULL 
	BEGIN 
		SELECT	@book_code 		= MIN(book_code)
		FROM	amcatbk
		WHERE	depr_rule_code	= @depr_rule_code
		AND		category_code	= @category_code
	
		EXEC 		amGetErrorMessage_sp 20538, ".\\amdprrul.dtr", 104, @depr_rule_code, @category_code, @book_code, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20538 @message 
		SELECT 		@rollback = 1 
	END 
	ELSE
	BEGIN
		
		SELECT	@co_asset_book_id	= MIN(co_asset_book_id)
		FROM	amdprhst 
		WHERE	depr_rule_code		= @depr_rule_code
		
		IF @co_asset_book_id IS NOT NULL 
		BEGIN 
			SELECT	@asset_ctrl_num 	= a.asset_ctrl_num,
					@book_code			= ab.book_code
			FROM	amastbk	ab,
					amasset	a
			WHERE	ab.co_asset_book_id	= @co_asset_book_id
			AND		ab.co_asset_id		= a.co_asset_id

			EXEC 		amGetErrorMessage_sp 20539, ".\\amdprrul.dtr", 126, @depr_rule_code, @asset_ctrl_num, @book_code, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20539 @message 
			SELECT 		@rollback = 1 
		END 
	END

	
	SELECT	@depr_rule_code = MIN(depr_rule_code)
	FROM	deleted
	WHERE	depr_rule_code	> @depr_rule_code

END



IF @rollback = 1 
	ROLLBACK TRANSACTION 
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE TRIGGER 	[dbo].[amdprrul_ins_trg] 
ON 				[dbo].[amdprrul] 
FOR INSERT AS


DECLARE 
	@ret_status 	smErrorCode, 
	@depr_rule_code	smDeprRuleCode, 
	@method_id 		smDeprMethodID, 
	@convention_id	smConventionID,
	@is_valid 		smLogical 

SELECT	@depr_rule_code = MIN(depr_rule_code)
FROM	inserted

WHILE @depr_rule_code IS NOT NULL
BEGIN
	
	SELECT 	@method_id 		= depr_method_id,
			@convention_id	= convention_id
	FROM	inserted
	WHERE	depr_rule_code	= @depr_rule_code		

	
	EXEC @ret_status = amValidConvention_sp 
									@method_id,
									@convention_id,
									@is_valid		 OUT 
	IF 	@ret_status <> 0 
	OR	@is_valid = 0
	BEGIN 
		ROLLBACK TRANSACTION 
		RETURN 
	END 

	
	SELECT	@depr_rule_code = MIN(depr_rule_code)
	FROM	inserted
	WHERE	depr_rule_code	> @depr_rule_code

END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[amdprrul_upd_trg] 
ON 				[dbo].[amdprrul] 
FOR 			UPDATE 
AS 

DECLARE 
	@rollback 				smLogical, 
	@rowcount 				smCounter, 
	@keycount 				smCounter, 
	@ret_status			 	smErrorCode, 
	@message 				smErrorLongDesc, 
	@depr_rule_code			smDeprRuleCode, 
	@method_id 				smDeprMethodID, 
	@convention_id			smConventionID,
	@is_valid 				smLogical 

SELECT @rowcount = @@rowcount 
SELECT @rollback = 0 

 
SELECT 	@keycount = COUNT(i.depr_rule_code) 
FROM 	inserted 	i, 
		deleted 	d 
WHERE 	i.depr_rule_code = d.depr_rule_code 

IF @keycount <> @rowcount 
BEGIN 
	EXEC 		amGetErrorMessage_sp 20537, ".\\amdprrul.utr", 100, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20537 @message 
	SELECT 		@rollback = 1 
END 

IF @rollback = 1 
BEGIN
	ROLLBACK TRANSACTION 
	RETURN
END


SELECT	@depr_rule_code = MIN(depr_rule_code)
FROM	inserted

WHILE @depr_rule_code IS NOT NULL
BEGIN
	
	SELECT 	@method_id 		= depr_method_id,
			@convention_id	= convention_id
	FROM	inserted
	WHERE	depr_rule_code	= @depr_rule_code		

	
	EXEC @ret_status = amValidConvention_sp 
									@method_id,
									@convention_id,
									@is_valid		 OUT 
	IF 	@ret_status <> 0 
	OR	@is_valid = 0
	BEGIN 
		ROLLBACK TRANSACTION 
		RETURN 
	END 

	
	SELECT	@depr_rule_code = MIN(depr_rule_code)
	FROM	inserted
	WHERE	depr_rule_code	> @depr_rule_code

END
GO
CREATE UNIQUE CLUSTERED INDEX [amdprrul_ind_0] ON [dbo].[amdprrul] ([depr_rule_code]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amdprrul].[rule_description]'
GO
EXEC sp_bindrule N'[dbo].[smDeprMethodID_rl]', N'[dbo].[amdprrul].[depr_method_id]'
GO
EXEC sp_bindefault N'[dbo].[smDeprMethodID_df]', N'[dbo].[amdprrul].[depr_method_id]'
GO
EXEC sp_bindrule N'[dbo].[smConventionID_rl]', N'[dbo].[amdprrul].[convention_id]'
GO
EXEC sp_bindefault N'[dbo].[smConventionID_df]', N'[dbo].[amdprrul].[convention_id]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amdprrul].[units_of_measure]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amdprrul].[service_life]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amdprrul].[annual_depr_rate]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amdprrul].[immediate_depr_rate]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amdprrul].[first_year_depr_rate]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amdprrul].[def_salvage_percent]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amdprrul].[def_salvage_value]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amdprrul].[override_salvage]'
GO
EXEC sp_bindefault N'[dbo].[smFalse_df]', N'[dbo].[amdprrul].[override_salvage]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amdprrul].[depr_below_salvage]'
GO
EXEC sp_bindefault N'[dbo].[smFalse_df]', N'[dbo].[amdprrul].[depr_below_salvage]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amdprrul].[p_and_l_on_partial_disp]'
GO
EXEC sp_bindefault N'[dbo].[smTrue_df]', N'[dbo].[amdprrul].[p_and_l_on_partial_disp]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amdprrul].[use_convention_on_disp]'
GO
EXEC sp_bindefault N'[dbo].[smTrue_df]', N'[dbo].[amdprrul].[use_convention_on_disp]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amdprrul].[max_asset_value]'
GO
GRANT REFERENCES ON  [dbo].[amdprrul] TO [public]
GO
GRANT SELECT ON  [dbo].[amdprrul] TO [public]
GO
GRANT INSERT ON  [dbo].[amdprrul] TO [public]
GO
GRANT DELETE ON  [dbo].[amdprrul] TO [public]
GO
GRANT UPDATE ON  [dbo].[amdprrul] TO [public]
GO
