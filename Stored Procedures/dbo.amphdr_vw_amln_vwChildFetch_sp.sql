SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amphdr_vw_amln_vwChildFetch_sp]
(
	@rowsrequested		smallint = 1,
	@company_id			smCompanyID,		 	
	@trx_ctrl_num 		smControlNumber,		
	@sequence_id 		smCounter,				
	@line_id 			smCounter				
) 
AS

CREATE TABLE #temp 
(
	timestamp 				varbinary(8) 	null,
	company_id 				smallint 		null,
	trx_ctrl_num 			varchar(16) 	null,
	sequence_id 			int 			null,
	line_id 				int 			null,
	line_desc 				varchar(60) 	null,
	gl_exp_acct 			varchar(32) 	null,
	reference_code 			varchar(32) 	null,
	amt_extended 			float 			null,
	qty_received 			float 			null,
	co_asset_id 			int 			null,
	asset_ctrl_num 			char(16) 		null,
	line_description 		varchar(40) 	null,
	quantity 				int 			null,
	update_asset_quantity	tinyint			null,
	asset_amount 			float 			null,
	imm_exp_amount 			float 			null,
	imm_exp_acct 			varchar(32) 	null,
	imm_exp_ref_code 		varchar(32) 	null,
	create_item 			tinyint 		null,
	activity_type 			tinyint 		null,
	apply_date 				datetime 		null,
	asset_tag				char(32)		null,
	item_tag				char(32)		null,
	last_modified_date	 	datetime 		null,
	modified_by 			int 			null,
	org_id				varchar(30)		null
)

DECLARE 
	@rowsfound 			smallint,
	@MSKline_id 		smCounter,
	@MSKsequence_id 	int,
	@result				smErrorCode,
	@home_currency_code	smCurrencyCode,		
	@nat_currency_code	smCurrencyCode,		
	@rate_home			smCurrencyRate,		
	@rounding_factor	float,
	@curr_precision		smallint


EXEC @result = amGetCurrencyCode_sp 
				@company_id, 
				@home_currency_code OUTPUT 
IF @result <> 0
	RETURN @result


EXEC @result = amGetCurrencyPrecision_sp 
		@curr_precision OUTPUT,	
		@rounding_factor OUTPUT 	

IF @result <> 0
	RETURN @result


SELECT	@nat_currency_code 	= currency_code,
		@rate_home			= rate_home
FROM	apvohdr
WHERE	apvohdr.trx_ctrl_num	= @trx_ctrl_num

SELECT @rowsfound 		= 0
SELECT @MSKline_id 		= @line_id
SELECT @MSKsequence_id 	= @sequence_id

IF EXISTS (SELECT 	line_id 
			FROM 	amln_vw 
			WHERE	company_id 		= @company_id 
			AND		trx_ctrl_num 	= @trx_ctrl_num 
			AND		sequence_id 	= @MSKsequence_id 
			AND		line_id 		= @MSKline_id)
BEGIN
	WHILE @MSKline_id IS NOT NULL AND @rowsfound < @rowsrequested
 	BEGIN

		INSERT INTO #temp 
		(
			timestamp,
			company_id,
			trx_ctrl_num,
			sequence_id,
			line_id,
			line_desc,
			gl_exp_acct,
			reference_code,
			amt_extended,
			qty_received,
			co_asset_id,
			asset_ctrl_num,
			line_description,
			quantity,
			update_asset_quantity,
			asset_amount,
			imm_exp_amount,
			imm_exp_acct,
			imm_exp_ref_code,
			create_item,
			activity_type,
			apply_date,
			asset_tag,
			item_tag,
			last_modified_date,
			modified_by,
			org_id			 
		)
		SELECT 
			ln.timestamp,
			ln.company_id,
			ln.trx_ctrl_num,
			ln.sequence_id,
			ln.line_id,
			ln.line_desc,
			ln.gl_exp_acct,
			ln.reference_code,
			ROUND((ln.amt_extended - (ln.calc_tax * tax.tax_included_flag) + ln.amt_tax + ln.amt_misc + ln.amt_freight - ln.amt_discount + ln.amt_nonrecoverable_tax), @curr_precision),
			ln.qty_received,
			ln.co_asset_id,
			ln.asset_ctrl_num,
			ln.line_description,
			ln.quantity,
			ln.update_asset_quantity,
			ln.asset_amount,
			ln.imm_exp_amount,
			ln.imm_exp_acct,
			ln.imm_exp_ref_code,
			ln.create_item,
			ln.activity_type,
			ln.apply_date,
			ln.asset_tag,
			ln.item_tag,
			ln.last_modified_date,
			ln.modified_by,
			ln.org_id			 
		FROM 	amln_vw ln,
				aptax tax 
		WHERE	ln.company_id 		= @company_id 
		AND		ln.trx_ctrl_num 	= @trx_ctrl_num 
		AND		ln.sequence_id 		= @MSKsequence_id 
		AND		ln.line_id 			= @MSKline_id
		AND		ln.tax_code			= tax.tax_code

		SELECT @rowsfound = @rowsfound + @@rowcount
		
		
		SELECT 	@MSKline_id 	= MIN(line_id) 
		FROM 	amln_vw 
		WHERE	company_id 		= @company_id 
		AND		trx_ctrl_num 	= @trx_ctrl_num 
		AND		sequence_id 	= @MSKsequence_id 
		AND		line_id 		> @MSKline_id
	END

	SELECT 	@MSKsequence_id = MIN(sequence_id) 
	FROM 	amln_vw 
	WHERE	company_id 		= @company_id 
	AND		trx_ctrl_num 	= @trx_ctrl_num 
	AND		sequence_id 	> @MSKsequence_id

	WHILE @MSKsequence_id IS NOT NULL AND @rowsfound < @rowsrequested
	BEGIN
		SELECT 	@MSKline_id 	= MIN(line_id) 
		FROM 	amln_vw
		WHERE	company_id 		= @company_id 
		AND		trx_ctrl_num 	= @trx_ctrl_num 
		AND		sequence_id 	= @MSKsequence_id

		WHILE @MSKline_id IS NOT NULL AND @rowsfound < @rowsrequested
 		BEGIN

			INSERT INTO #temp 
			(
				timestamp,
				company_id,
				trx_ctrl_num,
				sequence_id,
				line_id,
				line_desc,
				gl_exp_acct,
				reference_code,
				amt_extended,
				qty_received,
				co_asset_id,
				asset_ctrl_num,
				line_description,
				quantity,
				update_asset_quantity,
				asset_amount,
				imm_exp_amount,
				imm_exp_acct,
				imm_exp_ref_code,
				create_item,
				activity_type,
				apply_date,
				asset_tag,
				item_tag,
				last_modified_date,
				modified_by,
				org_id			 
			)
			SELECT 
				ln.timestamp,
				ln.company_id,
				ln.trx_ctrl_num,
				ln.sequence_id,
				ln.line_id,
				ln.line_desc,
				ln.gl_exp_acct,
				ln.reference_code,
				ROUND((ln.amt_extended - (ln.calc_tax * tax.tax_included_flag) + ln.amt_tax + ln.amt_misc + ln.amt_freight - ln.amt_discount + ln.amt_nonrecoverable_tax), @curr_precision),
				ln.qty_received,
				ln.co_asset_id,
				ln.asset_ctrl_num,
				ln.line_description,
				ln.quantity,
				ln.update_asset_quantity,
				ln.asset_amount,
				ln.imm_exp_amount,
				ln.imm_exp_acct,
				ln.imm_exp_ref_code,
				ln.create_item,
				ln.activity_type,
				ln.apply_date,
				ln.asset_tag,
				ln.item_tag,
				ln.last_modified_date,
				ln.modified_by,
				ln.org_id			 
			FROM 	amln_vw ln,
					aptax tax
			WHERE	company_id 		= @company_id 
			AND		trx_ctrl_num 	= @trx_ctrl_num 
			AND		sequence_id 	= @MSKsequence_id 
			AND		line_id 		= @MSKline_id
			AND		ln.tax_code		= tax.tax_code

			SELECT @rowsfound = @rowsfound + @@rowcount

			

			SELECT 	@MSKline_id 	= MIN(line_id) 
			FROM 	amln_vw 
			WHERE	company_id 		= @company_id 
			AND		trx_ctrl_num 	= @trx_ctrl_num 
			AND		sequence_id 	= @MSKsequence_id 
			AND		line_id 		> @MSKline_id
		END
		
		
		SELECT @MSKsequence_id 	= MIN(sequence_id) 
		FROM 	amln_vw 
		WHERE	company_id 		= @company_id 
		AND		trx_ctrl_num 	= @trx_ctrl_num 
		AND		sequence_id 	> @MSKsequence_id
	END
END

IF @home_currency_code != @nat_currency_code
BEGIN
	SELECT
		timestamp,
		company_id,
		trx_ctrl_num,
		sequence_id,
		line_id					= ISNULL(line_id, 1),
		line_desc,
		gl_exp_acct,
		reference_code,
		amt_extended			= ROUND(amt_extended * ( SIGN(1 + SIGN(@rate_home))*(@rate_home) + (SIGN(ABS(SIGN(ROUND(@rate_home,6))))/(@rate_home + SIGN(1 - ABS(SIGN(ROUND(@rate_home,6)))))) * SIGN(SIGN(@rate_home) - 1) ), @curr_precision),
		qty_received,
		co_asset_id,
		asset_ctrl_num,
		line_description 		= ISNULL(line_description, line_desc),
		quantity				= ISNULL(quantity, qty_received),
		update_asset_quantity	= ISNULL(update_asset_quantity, 1),
		asset_amount			= ISNULL(asset_amount, 0.0),
		imm_exp_amount			= ISNULL(imm_exp_amount, 0.0),
		imm_exp_acct,
		imm_exp_ref_code,
		create_item				= ISNULL(create_item, 1),
		activity_type			= ISNULL(activity_type, 10),
		apply_date 				= CONVERT(char(8), apply_date, 112),
		asset_tag,
		item_tag,
		last_modified_date 		= CONVERT(char(8), last_modified_date, 112),
		modified_by,
		org_id
	FROM #temp 
	ORDER BY company_id, trx_ctrl_num, sequence_id, line_id
END
ELSE
BEGIN
	SELECT
		timestamp,
		company_id,
		trx_ctrl_num,
		sequence_id,
		line_id					= ISNULL(line_id, 1),
		line_desc,
		gl_exp_acct,
		reference_code,
		amt_extended,
		qty_received,
		co_asset_id,
		asset_ctrl_num,
		line_description 		= ISNULL(line_description, line_desc),
		quantity				= ISNULL(quantity, qty_received),
		update_asset_quantity	= ISNULL(update_asset_quantity, 1),
		asset_amount			= ISNULL(asset_amount, 0.0),
		imm_exp_amount			= ISNULL(imm_exp_amount, 0.0),
		imm_exp_acct,
		imm_exp_ref_code,
		create_item				= ISNULL(create_item, 1),
		activity_type			= ISNULL(activity_type, 10),
		apply_date 				= CONVERT(char(8), apply_date, 112),
		asset_tag,
		item_tag,
		last_modified_date 		= CONVERT(char(8), last_modified_date, 112),
		modified_by,
		org_id
	FROM #temp 
	ORDER BY company_id, trx_ctrl_num, sequence_id, line_id
END

DROP TABLE #temp

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amphdr_vw_amln_vwChildFetch_sp] TO [public]
GO
