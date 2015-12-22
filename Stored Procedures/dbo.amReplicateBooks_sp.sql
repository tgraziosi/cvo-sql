SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amReplicateBooks_sp] 
(
 @company_id				smCompanyID,				
 @old_co_asset_id		smSurrogateKey, 		
 @new_co_asset_id		smSurrogateKey, 		
	@user_id 				smUserID, 				
	@apply_date				smApplyDate,			
	@debug_level	 		smDebugLevel 	= 0 	
)
AS 

DECLARE 
	@result					smErrorCode,
	@message 				smErrorLongDesc,
	@old_co_asset_book_id 	smSurrogateKey, 
	@new_co_asset_book_id 	smSurrogateKey, 
	@old_co_trx_id		 	smSurrogateKey, 
	@new_co_trx_id		 	smSurrogateKey,
	@new_trx_ctrl_num		smControlNumber 
 
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amrepbks.sp" + ", line " + STR( 69, 5 ) + " -- ENTRY: "

IF @debug_level >= 5
	SELECT 	old 		= @old_co_asset_id,
			new_asset 	= @new_co_asset_id
			


CREATE TABLE #new_book_keys
(
	old_co_asset_book_id		int,
	new_co_asset_book_id		int
)

INSERT INTO #new_book_keys
(
	old_co_asset_book_id,
	new_co_asset_book_id
)
SELECT DISTINCT
	co_asset_book_id,
	0
FROM	amastbk 
WHERE	co_asset_id		= @old_co_asset_id


SELECT	@old_co_asset_book_id = MIN(old_co_asset_book_id)
FROM	#new_book_keys

WHILE @old_co_asset_book_id IS NOT NULL
BEGIN
	EXEC 	@result = amNextKey_sp
						6,
						@new_co_asset_book_id OUTPUT
	IF @result <> 0
		RETURN @result

	UPDATE	#new_book_keys
	SET		new_co_asset_book_id	= @new_co_asset_book_id
	WHERE	old_co_asset_book_id	= @old_co_asset_book_id

	SELECT	@result = @@error
	IF @result <> 0
		RETURN @result

	SELECT	@old_co_asset_book_id	= MIN(old_co_asset_book_id)
	FROM	#new_book_keys
	WHERE	old_co_asset_book_id 	> @old_co_asset_book_id

END

IF @debug_level >= 5
	SELECT 	* 
	FROM	#new_book_keys



CREATE TABLE #new_trx_keys
(
	old_co_trx_id		int,
	new_co_trx_id		int,
	new_trx_ctrl_num 	char(16)
)

INSERT INTO #new_trx_keys
(
	old_co_trx_id,
	new_co_trx_id,
	new_trx_ctrl_num
)
SELECT DISTINCT
	co_trx_id,
	0,
	""
FROM	amacthst ah,
		amastbk ab
WHERE	ab.co_asset_id		= @old_co_asset_id
AND		ab.co_asset_book_id = ah.co_asset_book_id
AND		ah.apply_date		<= @apply_date
AND		ah.trx_type			IN (SELECT 	trx_type
								FROM 	amtrxdef
								WHERE	copy_trx_on_replicate = 1
								)


SELECT	@old_co_trx_id = MIN(old_co_trx_id)
FROM	#new_trx_keys

WHILE @old_co_trx_id IS NOT NULL
BEGIN
	EXEC 	@result = amNextKey_sp
						7,
						@new_co_trx_id OUTPUT
	IF @result <> 0
		RETURN @result

	EXEC 	@result = amNextControlNumber_sp
						@company_id,
						5,
						@new_trx_ctrl_num OUTPUT,
						@debug_level
	IF @result <> 0
		RETURN @result

	UPDATE	#new_trx_keys
	SET		new_co_trx_id		= @new_co_trx_id,
			new_trx_ctrl_num	= @new_trx_ctrl_num
	WHERE	old_co_trx_id		= @old_co_trx_id

	SELECT	@result = @@error
	IF @result <> 0
		RETURN @result

	SELECT	@old_co_trx_id	= MIN(old_co_trx_id)
	FROM	#new_trx_keys
	WHERE	old_co_trx_id 	> @old_co_trx_id

END

IF @debug_level >= 5
	SELECT 	* 
	FROM	#new_trx_keys


INSERT INTO amastbk 
(
		co_asset_id,
		book_code,
		co_asset_book_id,
		orig_salvage_value,
		orig_amount_expensed,
		orig_amount_capitalised,
		placed_in_service_date,
		last_posted_activity_date,
		next_entered_activity_date,
		last_posted_depr_date,
		prev_posted_depr_date,
		first_depr_date,
		last_modified_date,
		proceeds,
		gain_loss,
		last_depr_co_trx_id,
		process_id

)
SELECT 
		@new_co_asset_id,
		book_code,
		tmp.new_co_asset_book_id,
		orig_salvage_value,
		orig_amount_expensed,
		orig_amount_capitalised,
		placed_in_service_date,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		GETDATE(),
		0,
		0,
		0,
		0
FROM	#new_book_keys tmp,
		amastbk	ab
WHERE	ab.co_asset_book_id	= tmp.old_co_asset_book_id

SELECT @result = @@error 
IF @result <> 0 
	RETURN @result 

IF @debug_level >= 5
	SELECT 	* 
	FROM	amastbk
	WHERE	co_asset_id = @new_co_asset_id

INSERT INTO 	amdprhst
(
 co_asset_book_id, 
 effective_date, 
 last_modified_date, 
 modified_by, 
 posting_flag, 
 depr_rule_code, 
 limit_rule_code, 
 salvage_value, 
 catch_up_diff, 
 end_life_date,
 switch_to_sl_date
)
SELECT
 tmp.new_co_asset_book_id, 
 effective_date, 
 GETDATE(), 
 @user_id, 
 0,			
 depr_rule_code, 
 limit_rule_code, 
 salvage_value, 
 catch_up_diff, 
 end_life_date,
 NULL				
FROM	#new_book_keys tmp,
		amdprhst dh
WHERE	dh.co_asset_book_id	= tmp.old_co_asset_book_id

SELECT @result = @@error 
IF @result <> 0
	RETURN @result
					

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
	change_in_quantity 
)
SELECT 
	trx.company_id,
	tmp.new_trx_ctrl_num,
	"",
	tmp.new_co_trx_id,
	trx.trx_type,
	trx.trx_subtype,
	NULL,
	GETDATE(),
	@user_id,
	trx.apply_date,
	0,
	NULL,
	trx.hold_flag,
	trx.trx_description,
	trx.doc_reference,
	0,
	0,
	trx.intercompany_flag,
	trx.source_company_id,
	trx.home_currency_code,
	trx.total_paid,
	trx.total_received,
	trx.linked_trx,
	trx.revaluation_rate,
	trx.process_id,
	1,
	@new_co_asset_id,
	0,
	0,
	0 
FROM	#new_trx_keys 	tmp,
		amtrxhdr	trx
WHERE	tmp.old_co_trx_id	= trx.co_trx_id


SELECT @result = @@error
IF @result <> 0
	RETURN @result

IF @debug_level >= 5
	SELECT 	* 
	FROM	amtrxhdr
	WHERE	co_asset_id = @new_co_asset_id
	

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
	tmp_trx.new_co_trx_id, 	 
	tmp_bk.new_co_asset_book_id, 	 
	apply_date, 			
	trx_type, 				
	GETDATE(), 			
	@user_id, 	
	effective_date,	
	0, 						
	0,						
	0, 						
	0,						
	percent_disposed, 			
	0,					
	"",						
	created_by_trx			
FROM	#new_trx_keys 	tmp_trx, #new_book_keys tmp_bk,
		amacthst 		ah
WHERE	ah.co_asset_book_id	= tmp_bk.old_co_asset_book_id
AND		ah.co_trx_id		= tmp_trx.old_co_trx_id

SELECT @result = @@error
IF @result <> 0 
	RETURN @result 

IF @debug_level >= 5
	SELECT 	* 
	FROM	#new_trx_keys 	tmp_trx,
			amacthst 		ah
	WHERE	ah.co_trx_id		= tmp_trx.new_co_trx_id


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
	tmp_trx.new_co_trx_id, 	 
	tmp_bk.new_co_asset_book_id, 	 
 account_type_id, 
 apply_date, 
 trx_type, 
 amount, 
 0,					
 0				
FROM	#new_trx_keys 	tmp_trx, #new_book_keys tmp_bk,
		amvalues 		v
WHERE	v.co_asset_book_id	= tmp_bk.old_co_asset_book_id
AND		v.co_trx_id			= tmp_trx.old_co_trx_id


SELECT @result = @@error
IF @result <> 0 
	RETURN @result 

IF @debug_level >= 5
	SELECT 	* 
	FROM	#new_trx_keys 	tmp_trx,
			amvalues 		ah
	WHERE	ah.co_trx_id		= tmp_trx.new_co_trx_id


INSERT INTO ammandpr
(
 co_asset_book_id, 
 fiscal_period_end, 
 last_modified_date, 
 modified_by, 
 posting_flag, 
 depr_expense
)
SELECT
	tmp.new_co_asset_book_id, 	 
 fiscal_period_end, 
 GETDATE(), 
 @user_id, 
 0,				
	depr_expense
FROM	#new_book_keys tmp,
		ammandpr	man
WHERE	man.co_asset_book_id	= tmp.old_co_asset_book_id

SELECT @result = @@error
IF @result <> 0 
	RETURN @result 

DROP TABLE #new_trx_keys
DROP TABLE #new_book_keys

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amrepbks.sp" + ", line " + STR( 500, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amReplicateBooks_sp] TO [public]
GO
