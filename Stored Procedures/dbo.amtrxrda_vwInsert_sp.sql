SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amtrxrda_vwInsert_sp] 
( 
	@company_id                     smCompanyID, 
	@trx_ctrl_num                   smControlNumber, 
	@co_trx_id                      smSurrogateKey, 
	@trx_type                       smTrxType, 
	@last_modified_date             smISODate, 
	@modified_by                    smUserID, 
	@apply_date                     smISODate, 
	@from_code						smCriteriaCode,
	@to_code						smCriteriaCode,
	@group_code						smGroupCode,
	@from_org_id					varchar(30),		
	@to_org_id						varchar(30)			 
) as 

DECLARE @error 				int, 
		@home_currency_code smCurrencyCode

SELECT 	@home_currency_code = home_currency
FROM	glco

BEGIN TRANSACTION

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
		org_id
	)
	VALUES 
	( 
		@company_id,
		@trx_ctrl_num,
		'',
		@co_trx_id,
		@trx_type,
		0,
		NULL,	
		@last_modified_date,
		@modified_by,
		@apply_date,
		0,
		null,
		0,
		'',
		'',
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
		1,
		0,
		0,
		0,
		0,
		''
	)
	SELECT @error = @@error

	IF @error <> 0
	BEGIN
		ROLLBACK TRANSACTION
		RETURN @error
	END

	
	SELECT 	@co_trx_id 		= co_trx_id
	FROM	amtrxhdr
	WHERE	trx_ctrl_num 	= @trx_ctrl_num
	AND		company_id		= @company_id

	
	IF @from_code IS NULL
	SELECT @from_code = ''

	IF @to_code IS NULL
	SELECT @to_code = ''
	
	INSERT INTO amdprcrt 
	( 
		co_trx_id,
		field_type,
		from_code,
		to_code 
	)
	VALUES 
	( 	@co_trx_id,
		7,
		@from_code,
		@to_code 
	)

	IF @error <> 0
	BEGIN
		ROLLBACK TRANSACTION
		RETURN @error
	END

	IF @group_code IS NULL
	SELECT @group_code = ''


	INSERT INTO amdprcrt 
	( 
		co_trx_id,
		field_type,
		from_code,
		to_code 
	)
	VALUES 
	( 	@co_trx_id,
		19,
		@group_code,
		'' 
	)

	SELECT @error = @@error 
	IF @error <> 0 
	BEGIN 
		ROLLBACK TRANSACTION 
		RETURN @error
	END 




	INSERT INTO amdprcrt 
	( 
		co_trx_id,
		field_type,
		from_code,
		to_code 
	)
	VALUES 
	( 	@co_trx_id,
		20,
		isnull(@from_org_id, ''),
		isnull(@to_org_id, '') 
	)

	SELECT @error = @@error 
	IF @error <> 0 
	BEGIN 
		ROLLBACK TRANSACTION 
		RETURN @error
	END

	
COMMIT TRANSACTION

RETURN @@error 
GO
GRANT EXECUTE ON  [dbo].[amtrxrda_vwInsert_sp] TO [public]
GO
