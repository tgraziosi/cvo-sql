SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amCompleteVoucher_sp]
(
	@company_id				smCompanyID,		
 	@trx_ctrl_num 			smControlNumber,	
	@user_id				smUserID,			
	@debug_level			smDebugLevel = 0 	
)
AS

DECLARE
	@result					smErrorCode,			
	@sequence_id			smCounter,				
	@line_id				smCounter,				
	@am_trx_ctrl_num		smControlNumber,		
	@co_trx_id				smSurrogateKey,			
	@co_asset_id			smSurrogateKey,			
	@asset_ctrl_num			smControlNumber,
	@item_sequence_id		smSurrogateKey,
	@create_item			smLogical,				 
	@item_tag				smTag,
	@apply_date				smApplyDate,			
	@invoice_date			smApplyDate,			
	@vendor_code			smVendorCode,
	@doc_ctrl_num			smControlNumber,
	@home_currency_code		smCurrencyCode,			
	@fixed_asset_acct		smAccountCode,			
	@fixed_asset_ref_code	smAccountReferenceCode,	
	@fixed_asset_account_id	smSurrogateKey,
	@imm_exp_acct			smAccountCode,			
	@imm_exp_ref_code		smAccountReferenceCode,	
	@imm_exp_account_id		smSurrogateKey,
	@asset_quantity			smCounter,				
	@update_asset_quantity	smLogical,
	@temp_string 	 	varchar(35),
	@terminator 	varchar(35),
	@term_pattern 	varchar(35),
	@length_imm_exp_acct	smCounter,				
	@item_code				smItemCode,
	@vendor_address_name	smStdDescription,
	@voucher_po_ctrl_num	smControlNumber,		
	@po_ctrl_num			smControlNumber,
	@po_sequence_id			smCounter,
	@curr_precision			smallint,				
	@rounding_factor		float					

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcomvch.sp" + ", line " + STR( 95, 5 ) + " -- ENTRY: "

SELECT dummy_select = 1


EXEC	@result = amGetCurrencyPrecision_sp
					@curr_precision		OUTPUT,
					@rounding_factor 	OUTPUT

IF @result <> 0
	RETURN @result




SELECT	@co_asset_id = 0

SELECT 	@co_asset_id 				= ISNULL(MIN(ap.co_asset_id), 0)
FROM	amapdet ap,
		amastbk ab
WHERE	ap.co_asset_id 				= ab.co_asset_id
AND		ap.apply_date				<= ab.last_posted_depr_date
AND		ab.last_posted_depr_date 	IS NOT NULL
AND		ap.company_id				= @company_id
AND		ap.trx_ctrl_num				= @trx_ctrl_num

IF @co_asset_id != 0
BEGIN
	

	DECLARE	@message		smErrorLongDesc,
			@param1			smErrorParam,
			@param2			smErrorParam

	SELECT	@asset_ctrl_num	= asset_ctrl_num
	FROM	amasset
	WHERE	co_asset_id		= @co_asset_id

	SELECT 	@param1 		= RTRIM(CONVERT(char(255), MIN(apply_date), 107))
	FROM	amapdet ap
	WHERE	ap.co_asset_id 	= @co_asset_id
	AND		ap.company_id	= @company_id
	AND		ap.trx_ctrl_num	= @trx_ctrl_num

	SELECT 	@param2					= RTRIM(CONVERT(char(255), MAX(last_posted_depr_date), 107)	)
	FROM	amastbk
	WHERE	co_asset_id				= @co_asset_id
	AND		last_posted_depr_date	IS NOT NULL

	IF @debug_level >= 5
		SELECT asset_ctrl_num = @asset_ctrl_num,
		 	 param1 = @param1,
			 param2 = @param2
		
		EXEC 		amGetErrorMessage_sp 
							20088, "tmp/amcomvch.sp", 154, 
							@asset_ctrl_num, @param1, @param2,
							@error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20088 @message 
	RETURN 

END
			

SELECT	@vendor_code			= trx.vendor_code,
		@vendor_address_name	= vend.address_name,
		@doc_ctrl_num			= trx.doc_ctrl_num,
		@invoice_date 			= DATEADD(dd, trx.date_doc - 722815, "1/1/1980"),
		@apply_date				= DATEADD(dd, trx.date_applied - 722815, "1/1/1980"),
		@voucher_po_ctrl_num	= trx.po_ctrl_num
FROM	apvohdr trx,
		apmaster vend
WHERE	trx.trx_ctrl_num		= @trx_ctrl_num
AND		trx.vendor_code			= vend.vendor_code
AND		vend.address_type		= 0
		
EXEC 	@result = amGetCurrencyCode_sp
					@company_id,
					@home_currency_code OUTPUT
IF @result <> 0
	RETURN @result
						

CREATE TABLE	#amtrxhdr
(
	sequence_id				int,		
	line_id					int,		
	co_asset_id				int,		
	co_trx_id				int,		
	trx_ctrl_num			char(16),	
	fixed_asset_account_id	int,		
	imm_exp_account_id		int,		
	asset_quantity			int,		
	item_sequence_id		int,		
	po_ctrl_num				char(16),	
	po_sequence_id			int,		
	item_code				varchar(22)	
)

SELECT	@sequence_id 	= MIN(sequence_id)
FROM	amapdet
WHERE	company_id		= @company_id
AND		trx_ctrl_num	= @trx_ctrl_num

WHILE @sequence_id IS NOT NULL
BEGIN

	IF @debug_level >= 5
		SELECT	sequence_id = @sequence_id
	
	IF @sequence_id < 0			
	BEGIN
		SELECT 
			@po_ctrl_num	= @voucher_po_ctrl_num,
			@po_sequence_id	= 0,
			@item_code		= ""
	END
	ELSE
	BEGIN
		SELECT
			@po_ctrl_num	= @voucher_po_ctrl_num

		SELECT
 				@po_sequence_id	= ABS(po_orig_flag),
				@item_code		= item_code
		FROM	apvodet
		WHERE	trx_ctrl_num	= @trx_ctrl_num
		AND		sequence_id		= @sequence_id

	END
	
	SELECT 	@line_id 		= MIN(line_id)
	FROM	amapdet
	WHERE	company_id		= @company_id
	AND		trx_ctrl_num	= @trx_ctrl_num
	AND		sequence_id		= @sequence_id

	WHILE @line_id IS NOT NULL
	BEGIN
		
		IF @debug_level >= 5
			SELECT	line_id = @line_id
			
		
		SELECT	@create_item 			= create_item,
				@asset_quantity 		= quantity, 
				@update_asset_quantity	= update_asset_quantity,
			 	@co_asset_id			= co_asset_id,
				@fixed_asset_acct		= ISNULL(fixed_asset_acct, ""),
				@fixed_asset_ref_code 	= ISNULL(fixed_asset_ref_code, ""),
				@imm_exp_acct			= ISNULL(imm_exp_acct, ""),
				@imm_exp_ref_code 		= ISNULL(imm_exp_ref_code, "")
		FROM	amapdet
		WHERE	company_id		 		= @company_id
		AND		trx_ctrl_num			= @trx_ctrl_num
		AND		sequence_id				= @sequence_id
		AND		line_id					= @line_id
		
		SELECT	@asset_ctrl_num	= asset_ctrl_num
		FROM	amasset
		WHERE	co_asset_id		= @co_asset_id

		
		EXEC @result = amValidateAcctAndRef_sp
							@home_currency_code,
							@asset_ctrl_num,
							@fixed_asset_acct,
							@fixed_asset_ref_code,
							@apply_date,
							@debug_level	= @debug_level


		IF 	@result <> 0
		AND	@result NOT BETWEEN 20210 AND 20219
		BEGIN
		 IF @debug_level >= 3
		 	SELECT result = @result
		 	
		 DROP TABLE #amtrxhdr
		 RETURN @result 
		END
		
		
		SELECT @terminator = '$$$'
		SELECT @temp_string = RTRIM(@imm_exp_acct) + @terminator

		
		SELECT @term_pattern = '%' + @terminator + '%'
		SELECT @length_imm_exp_acct = PATINDEX(@term_pattern, @temp_string) - 1 
	 
	 IF @length_imm_exp_acct > 0
	 BEGIN
			EXEC @result = amValidateAcctAndRef_sp
								@home_currency_code,
								@asset_ctrl_num,
								@imm_exp_acct,
								@imm_exp_ref_code,
								@apply_date,
								@debug_level	= @debug_level

			IF 	@result <> 0
			AND	@result NOT BETWEEN 20210 AND 20219
			BEGIN
			 IF @debug_level >= 3
			 	SELECT result = @result
			 	
			 DROP TABLE #amtrxhdr
			 RETURN @result 
			END
		END

		
		IF @update_asset_quantity	= 0
			SELECT	@asset_quantity = 0
			
		
		EXEC @result = amNextControlNumber_sp
						@company_id, 	
						5, 
	 @am_trx_ctrl_num OUTPUT,
	 @debug_level 

		IF @result <> 0
		BEGIN
		 DROP TABLE #amtrxhdr
		 RETURN @result 
		END

		EXEC @result = amNextKey_sp 	
						7, 
	 @co_trx_id OUTPUT 

		IF @result <> 0
		BEGIN
		 DROP TABLE #amtrxhdr
		 RETURN @result 
		END
	
	 EXEC @result = amGetAccountID_sp 	
							@company_id,
	 	@fixed_asset_acct,
	 @fixed_asset_ref_code,
	 @fixed_asset_account_id OUTPUT 
	
		IF @result <> 0
		BEGIN
		 DROP TABLE #amtrxhdr
		 RETURN @result 
		END
			 
	 IF @length_imm_exp_acct > 0
	 BEGIN
		 
		 EXEC @result = amGetAccountID_sp 	
								@company_id,
		 	@imm_exp_acct,
		 @imm_exp_ref_code,
		 @imm_exp_account_id OUTPUT 
			IF @result <> 0
			BEGIN
			 DROP TABLE #amtrxhdr
			 RETURN @result 
			END
		END
		ELSE	
			SELECT	@imm_exp_account_id	= 0
			
		
		SELECT	@item_sequence_id	= -1		
		IF @create_item = 1
		BEGIN

			IF EXISTS (SELECT 	item_sequence_id 
						FROM	#amtrxhdr
						WHERE	co_asset_id		= @co_asset_id
						AND		item_sequence_id >= 0 )

			BEGIN
				SELECT	@item_sequence_id	= MAX(item_sequence_id) + 1
				FROM	#amtrxhdr
				WHERE	co_asset_id			= @co_asset_id
				AND		item_sequence_id	>= 0

			END
			ELSE
			BEGIN
				IF EXISTS (SELECT 	sequence_id 
							FROM	amitem
							WHERE	co_asset_id	= @co_asset_id)
				BEGIN
					SELECT	@item_sequence_id	= MAX(sequence_id) + 1
					FROM	amitem
					WHERE	co_asset_id			= @co_asset_id
			 	END
			 	ELSE
					SELECT	@item_sequence_id = 0
			END
				
		END
		
		IF @debug_level >= 5
			SELECT item_sequence_id = @item_sequence_id
			
		
		INSERT INTO #amtrxhdr
		(
			sequence_id,
			line_id,
			co_asset_id,
			co_trx_id,
			trx_ctrl_num,
			fixed_asset_account_id,
			imm_exp_account_id,
			asset_quantity,
			item_sequence_id,
			po_ctrl_num,
			po_sequence_id,
			item_code			
		)
		VALUES
		(
			@sequence_id, 	 
			@line_id, 	 
			@co_asset_id,
			@co_trx_id,
			@am_trx_ctrl_num,
			@fixed_asset_account_id,
			@imm_exp_account_id,
			@asset_quantity,
			@item_sequence_id,
			@po_ctrl_num,
			@po_sequence_id,
			@item_code
		)
		
		SELECT @result = @@error
		IF @result <> 0
		BEGIN
		 DROP TABLE #amtrxhdr
		 RETURN @result 
		END

		SELECT 	@line_id 		= MIN(line_id)
		FROM	amapdet
		WHERE	company_id		= @company_id
		AND		trx_ctrl_num	= @trx_ctrl_num
		AND		sequence_id		= @sequence_id
		AND		line_id			> @line_id
	
	END

	SELECT 	@sequence_id 	= MIN(sequence_id)
	FROM	amapdet
	WHERE	company_id		= @company_id
	AND		trx_ctrl_num	= @trx_ctrl_num
	AND		sequence_id		> @sequence_id

END

IF @debug_level >= 3
BEGIN
	SELECT	* 
	FROM	#amtrxhdr
END



BEGIN TRANSACTION
	
	declare @quantity1 int,
		@co_asset_id1 int
	SELECT 
		@co_asset_id1= isnull(apdet.co_asset_id,0),
		@quantity1 = isnull(tmp.asset_quantity,0)
	FROM	#amtrxhdr	tmp,
			amapdet		apdet
	WHERE	apdet.company_id	= @company_id
	AND		apdet.trx_ctrl_num	= @trx_ctrl_num
	AND		apdet.sequence_id	= tmp.sequence_id
	AND		apdet.line_id		= tmp.line_id
	
     IF @quantity1 = 0 and @co_asset_id1 = 0
	BEGIN		
		EXEC	 	amGetErrorMessage_sp 27062, "tmp/amcomvch.sp", 653, 'AM', @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	27062 @message 
		ROLLBACK TRANSACTION
	 	DROP TABLE #amtrxhdr
	 	RETURN @result 
	END

	
 	INSERT INTO amtrxhdr 
	( 
		company_id,
		trx_ctrl_num,
		journal_ctrl_num,
		co_trx_id,
		trx_type,
		trx_subtype,
		batch_ctrl_num,
		last_modified_date,
		modified_by,
		apply_date,
		posting_flag,
		date_posted,
		hold_flag,
		trx_description,
		doc_reference,
		note_id,
		user_field_id,
		intercompany_flag,
		source_company_id,
		home_currency_code,
		total_paid,
		total_received,
		linked_trx,
		revaluation_rate,
		process_id,
		trx_source,
		co_asset_id,
		fixed_asset_account_id,
		imm_exp_account_id,
		change_in_quantity,
		org_id 			/*GGarcia SCR 36661*/
	)
	SELECT 
		@company_id,
		tmp.trx_ctrl_num,
		"",
		tmp.co_trx_id,
		apdet.activity_type,
		0,					
		NULL,				
		GETDATE(),
		@user_id,
		apdet.apply_date,
		0,
		NULL,
		0,				
		apdet.line_description,/*added to SP*/
		@trx_ctrl_num,
		0,					
		0,					
		0,					
		@company_id,		
		@home_currency_code,
		0,
		0,
		0,
		0,				
		0,
		4,
		apdet.co_asset_id,
		tmp.fixed_asset_account_id,
		tmp.imm_exp_account_id,
		tmp.asset_quantity,
		apdet.org_id	 	/*GGarcia SCR 36661*/			
	FROM	#amtrxhdr	tmp,
			amapdet		apdet
	WHERE	apdet.company_id	= @company_id
	AND		apdet.trx_ctrl_num	= @trx_ctrl_num
	AND		apdet.sequence_id	= tmp.sequence_id
	AND		apdet.line_id		= tmp.line_id
	
	SELECT @result = @@error
	IF @result <> 0
	BEGIN
		ROLLBACK TRANSACTION
	 DROP TABLE #amtrxhdr
	 RETURN @result 
	END
	
	INSERT INTO amacthst
	(
		co_trx_id, 	 
		co_asset_book_id, 	 
		apply_date, 			
		trx_type, 				
		last_modified_date, 			
		modified_by, 	
		effective_date,	
		revised_cost, 	 
		revised_accum_depr,
		delta_cost, 	 
		delta_accum_depr, 			
		percent_disposed, 			
		posting_flag,			
		journal_ctrl_num,		
		created_by_trx			
	)
	SELECT
		tmp.co_trx_id, 	 
		ab.co_asset_book_id, 	 
		apdet.apply_date, 			
		apdet.activity_type, 				
		GETDATE(), 			
		@user_id, 	
		NULL,					
		0, 						
		0,						
		0, 						
		0,						
		0, 			
		0,					
		"",						
		0								
	FROM	#amtrxhdr	tmp,
			amastbk		ab,
			amapdet		apdet
	WHERE	ab.co_asset_id		= apdet.co_asset_id
	AND		apdet.company_id	= @company_id
	AND		apdet.trx_ctrl_num	= @trx_ctrl_num
	AND		apdet.sequence_id	= tmp.sequence_id
	AND		apdet.line_id		= tmp.line_id
	
	SELECT @result = @@error
	IF @result <> 0
	BEGIN
		ROLLBACK TRANSACTION
	 DROP TABLE #amtrxhdr
	 RETURN @result 
	END

	
	INSERT INTO amvalues
	(
 co_trx_id, 
 co_asset_book_id, 
 account_type_id, 
 apply_date, 
 trx_type, 
 amount, 
 account_id, 
 posting_flag
	)
	SELECT
		tmp.co_trx_id, 	 
		ab.co_asset_book_id, 	 
 0, 
 apdet.apply_date, 
 apdet.activity_type, 
 apdet.asset_amount, 
 0,					
 0				
	FROM	#amtrxhdr	tmp,
			amastbk		ab,
			amapdet		apdet
	WHERE	ab.co_asset_id		= apdet.co_asset_id
	AND		apdet.company_id	= @company_id
	AND		apdet.trx_ctrl_num	= @trx_ctrl_num
	AND		apdet.sequence_id	= tmp.sequence_id
	AND		apdet.line_id		= tmp.line_id

	SELECT @result = @@error
	IF @result <> 0
	BEGIN
		ROLLBACK TRANSACTION
	 DROP TABLE #amtrxhdr
	 RETURN @result 
	END

	INSERT INTO amvalues
	(
 co_trx_id, 
 co_asset_book_id, 
 account_type_id, 
 apply_date, 
 trx_type, 
 amount, 
 account_id, 
 posting_flag
	)
	SELECT
		tmp.co_trx_id, 	 
		ab.co_asset_book_id, 	 
 9, 
 apdet.apply_date, 
 apdet.activity_type, 
 imm_exp_amount, 
 tmp.imm_exp_account_id,
 0				
	FROM	#amtrxhdr	tmp,
			amastbk		ab,
			amapdet		apdet
	WHERE	ab.co_asset_id		= apdet.co_asset_id
	AND		apdet.company_id	= @company_id
	AND		apdet.trx_ctrl_num	= @trx_ctrl_num
	AND		apdet.sequence_id	= tmp.sequence_id
	AND		apdet.line_id		= tmp.line_id

	SELECT @result = @@error
	IF @result <> 0
	BEGIN
		ROLLBACK TRANSACTION
	 DROP TABLE #amtrxhdr
	 RETURN @result 
	END

	INSERT INTO amvalues
	(
 co_trx_id, 
 co_asset_book_id, 
 account_type_id, 
 apply_date, 
 trx_type, 
 amount, 
 account_id, 
 posting_flag
	)
	SELECT
		tmp.co_trx_id, 	 
		ab.co_asset_book_id, 	 
 3, 
 apdet.apply_date, 
 apdet.activity_type, 
 (SIGN(-apdet.asset_amount - apdet.imm_exp_amount) * ROUND(ABS(-apdet.asset_amount - apdet.imm_exp_amount) + 0.0000001, @curr_precision)), 
 tmp.fixed_asset_account_id,
 0				
	FROM	#amtrxhdr 	tmp,
			amastbk		ab,
			amapdet		apdet
	WHERE	ab.co_asset_id		= apdet.co_asset_id
	AND		apdet.company_id	= @company_id
	AND		apdet.trx_ctrl_num	= @trx_ctrl_num
	AND		apdet.sequence_id	= tmp.sequence_id
	AND		apdet.line_id		= tmp.line_id

	SELECT @result = @@error
	IF @result <> 0
	BEGIN
		ROLLBACK TRANSACTION
	 DROP TABLE #amtrxhdr
	 RETURN @result 
	END

	
	INSERT INTO amitem 
	( 
		co_asset_id,
		sequence_id,
		posting_flag,
		co_trx_id,
		manufacturer,
		model_num,
		serial_num,
		item_code,
		item_description,
		po_ctrl_num,
		contract_number,
		vendor_code,
		vendor_description,
		invoice_num,
		invoice_date, 
		original_cost,
		manufacturer_warranty,
		vendor_warranty,
		item_tag,
		item_quantity,
		item_disposition_date,
		last_modified_date,
		modified_by 
	)
	SELECT
		apdet.co_asset_id,
		tmp.item_sequence_id,
	 	0,
		tmp.co_trx_id,
		"",
		"",
		"",
		tmp.item_code, 
		apdet.line_description,
		tmp.po_ctrl_num,
		"",
		@vendor_code,
		@vendor_address_name,
	 	@doc_ctrl_num,
		@invoice_date,
		apdet.asset_amount,
		0,
		0,
		ISNULL(apdet.item_tag, ""),
		apdet.quantity,
		NULL,
		GETDATE(),
		@user_id
	FROM	#amtrxhdr	tmp,
			amapdet		apdet
	WHERE	apdet.company_id		= @company_id
	AND		apdet.trx_ctrl_num		= @trx_ctrl_num
	AND		apdet.sequence_id		= tmp.sequence_id
	AND		apdet.line_id			= tmp.line_id
	AND		apdet.create_item		= 1

	SELECT @result = @@error
	IF @result <> 0
	BEGIN
		ROLLBACK TRANSACTION
	 DROP TABLE #amtrxhdr
		RETURN @result
	END
	
	
	UPDATE 	amasset
	SET		tag					= asset_tag
	FROM	amasset a,
			amapdet ap
	WHERE	ap.trx_ctrl_num		= @trx_ctrl_num
	AND		ap.co_asset_id		= a.co_asset_id
	AND		( LTRIM(ap.asset_tag) IS NOT NULL AND LTRIM(ap.asset_tag) != " " )

	SELECT @result = @@error
	IF @result <> 0
	BEGIN
		ROLLBACK TRANSACTION
	 DROP TABLE #amtrxhdr
		RETURN @result
	END
	
	
	
	UPDATE	amaphdr
	SET		completed_flag	= 1,
			completed_date	= GETDATE(),
			completed_by	= @user_id
	FROM	amaphdr
	WHERE	company_id		= @company_id
	AND		trx_ctrl_num	= @trx_ctrl_num

	SELECT	@result = @@error
	IF @result <> 0
	BEGIN
		ROLLBACK TRANSACTION
	 DROP TABLE #amtrxhdr
		RETURN @result
	END

	UPDATE amapdet
	SET		completed_by	= @user_id,
			completed_date	= GETDATE(),
			co_trx_id		= tmp.co_trx_id,
			item_id			= tmp.item_sequence_id
	FROM	#amtrxhdr tmp,
			amapdet ap
	WHERE	ap.trx_ctrl_num	= @trx_ctrl_num
	AND		ap.sequence_id	= tmp.sequence_id
	AND		ap.line_id		= tmp.line_id

	SELECT	@result = @@error
	IF @result <> 0
	BEGIN
		ROLLBACK TRANSACTION
	 DROP TABLE #amtrxhdr
		RETURN @result
	END

COMMIT TRANSACTION

IF @debug_level >= 3
BEGIN
	SELECT	* 
	FROM	#amtrxhdr 	tmp,
			amtrxhdr 	trx
	WHERE	tmp.co_trx_id	= trx.co_trx_id

	SELECT	* 
	FROM	#amtrxhdr 	tmp,
			amacthst 	act
	WHERE	tmp.co_trx_id	= act.co_trx_id

	SELECT	* 
	FROM	#amtrxhdr 	tmp,
			amvalues 	val
	WHERE	tmp.co_trx_id	= val.co_trx_id

	SELECT	* 
	FROM	#amtrxhdr 	tmp,
			amitem 		item
	WHERE	tmp.co_trx_id	= item.co_trx_id
END

DROP TABLE #amtrxhdr

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcomvch.sp" + ", line " + STR( 896, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amCompleteVoucher_sp] TO [public]
GO
