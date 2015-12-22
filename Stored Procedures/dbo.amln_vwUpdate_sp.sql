SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amln_vwUpdate_sp]
(
	@timestamp				timestamp,
	@company_id				smallint,
	@trx_ctrl_num			smControlNumber,
	@sequence_id			smCounter,
	@line_id 				smCounter,
	@line_desc				varchar(60),		
	@gl_exp_acct			varchar(32),		
	@reference_code			varchar(32),		
	@amt_extended			float,				
	@qty_received			float,				
	@co_asset_id 			smSurrogateKey,
	@asset_ctrl_num 		smControlNumber,	
	@line_description		smStdDescription,
	@quantity				smQuantity,
	@update_asset_quantity	smLogical,
	@asset_amount			smMoneyZero,
	@imm_exp_amount			smMoneyZero,
	@imm_exp_acct			smAccountCode,
	@imm_exp_ref_code		smAccountReferenceCode,
	@create_item			smLogicalTrue,
	@activity_type 			smTrxType,
	@apply_date 			smISODate,
	@asset_tag				smTag,
	@item_tag				smTag,
	@last_modified_date		smISODate,
	@modified_by			smUserID,
	@org_id				varchar(30)
) 
AS




SELECT dummy_select = 1

DECLARE 
	@rowcount 		smCounter,
 	@error 			smErrorCode,
	@ts 			timestamp,
	@message 		smErrorLongDesc,
	@old_asset_tag	smTag


IF @line_id = 1 
BEGIN
	IF NOT EXISTS (SELECT	line_id 
					FROM 	amapdet 
					WHERE	company_id		=	@company_id 
					AND		trx_ctrl_num	=	@trx_ctrl_num 
					AND		sequence_id		=	@sequence_id 
					AND		line_id			=	@line_id)
	BEGIN
		EXEC @error = amln_vwInsert_sp
						@company_id,
						@trx_ctrl_num,
						@sequence_id,
						@line_id,
						@line_desc,
						@gl_exp_acct,
						@reference_code,
						@amt_extended,
						@qty_received,
						@co_asset_id,
						@asset_ctrl_num,
						@line_description,
						@quantity,
						@update_asset_quantity,
						@asset_amount,
						@imm_exp_amount,
						@imm_exp_acct,
						@imm_exp_ref_code,
						@create_item,
						@activity_type,
						@apply_date,
						@asset_tag,
						@item_tag,
						@last_modified_date,
						@modified_by,
						@org_id	  
   		IF @error <> 0
   			RETURN @error	

		SELECT @asset_tag
		
		IF ( LTRIM(@asset_tag) IS NOT NULL AND LTRIM(@asset_tag) != " " )
		BEGIN
			SELECT 	@old_asset_tag 	= tag
			FROM	amasset
			WHERE	co_asset_id		= @co_asset_id

			SELECT @old_asset_tag
			
			IF RTRIM(@old_asset_tag) != RTRIM(@asset_tag)
			BEGIN
				EXEC	 	amGetErrorMessage_sp 
								20179, "amlnup.cpp", 152, 
								@asset_ctrl_num, @old_asset_tag, @asset_tag,
								@error_message = @message OUT
				IF @message IS NOT NULL RAISERROR 	20179 @message
			END

		END

		RETURN 0
   	END				
END




UPDATE 	amapdet 
SET		co_asset_id				= @co_asset_id,
		asset_ctrl_num			= @asset_ctrl_num,	
		line_description		= @line_description,
		quantity				= @quantity,
		update_asset_quantity	= @update_asset_quantity,
		asset_amount			= @asset_amount,
		imm_exp_amount			= @imm_exp_amount,
		imm_exp_acct			= @imm_exp_acct,
		imm_exp_ref_code		= @imm_exp_ref_code,
		create_item				= @create_item,
		activity_type			= @activity_type,
		apply_date 				= @apply_date,
		asset_tag				= @asset_tag,
		item_tag				= @item_tag,
		last_modified_date		= @last_modified_date,
		modified_by				= @modified_by,
		org_id				= @org_id
WHERE	company_id				= @company_id 
AND		trx_ctrl_num			= @trx_ctrl_num 
AND		sequence_id				= @sequence_id 
AND		line_id					= @line_id 
AND		timestamp 				= @timestamp

SELECT @error = @@error, @rowcount = @@rowcount
IF @error <> 0  
	RETURN @error

IF @rowcount = 0 
BEGIN
	
	SELECT 	@ts 				= timestamp 
	FROM 	amapdet 
	WHERE	company_id			= @company_id 
	AND		trx_ctrl_num		= @trx_ctrl_num 
	AND		sequence_id			= @sequence_id 
	AND		line_id				= @line_id 

	SELECT @error = @@error, @rowcount = @@rowcount
	IF @error <> 0  
		RETURN @error

	IF @rowcount = 0 
	BEGIN
		EXEC	 	amGetErrorMessage_sp 20004, "amlnup.cpp", 211, "amapdet", @error_message = @message OUT
		IF @message IS NOT NULL RAISERROR 	20004 @message
		RETURN 		20004
	END

	IF @ts <> @timestamp
	BEGIN
		EXEC	 	amGetErrorMessage_sp 20003, "amlnup.cpp", 218, "amapdet", @error_message = @message OUT
		IF @message IS NOT NULL RAISERROR 	20003 @message
		RETURN 		20003
	END
END

IF ( LTRIM(@asset_tag) IS NOT NULL AND LTRIM(@asset_tag) != " " )
BEGIN
	SELECT 	@old_asset_tag 	= tag
	FROM	amasset
	WHERE	co_asset_id		= @co_asset_id

	IF RTRIM(@old_asset_tag) != RTRIM(@asset_tag)
	BEGIN
		EXEC	 	amGetErrorMessage_sp 
						20179, "amlnup.cpp", 233, 
						@asset_ctrl_num, @old_asset_tag, @asset_tag,
						@error_message = @message OUT
		IF @message IS NOT NULL RAISERROR 	20179 @message
	END

END

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amln_vwUpdate_sp] TO [public]
GO
