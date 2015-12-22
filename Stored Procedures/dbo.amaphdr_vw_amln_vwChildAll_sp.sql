SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amaphdr_vw_amln_vwChildAll_sp]
(
	@company_id			smallint,		
	@trx_ctrl_num		varchar(16)		
) 
AS

DECLARE	
	@result				smErrorCode,
	@home_currency_code	smCurrencyCode,		
	@nat_currency_code	smCurrencyCode,		
	@rate_home			smCurrencyRate,		
	@rounding_factor	float,
	@curr_precision		smallint




EXEC @result = amGetCurrencyCode_sp 
				@company_id, 
				@home_currency_code   OUTPUT  
IF @result <> 0
	RETURN @result




EXEC @result = amGetCurrencyPrecision_sp 
		@curr_precision    OUTPUT,	
		@rounding_factor   OUTPUT 	

IF @result <> 0
	RETURN @result




SELECT	@nat_currency_code 	= currency_code,
		@rate_home			= rate_home
FROM	apvohdr
WHERE	apvohdr.trx_ctrl_num	= @trx_ctrl_num

IF @home_currency_code != @nat_currency_code
BEGIN
	SELECT
			ln.timestamp,
			ln.company_id,
			ln.trx_ctrl_num,
			ln.sequence_id,
			line_id					= ISNULL(ln.line_id, 1),
			ln.line_desc,
			ln.gl_exp_acct,
			ln.reference_code,
			amt_extended			= ROUND((ln.amt_extended - (ln.calc_tax * tax.tax_included_flag) + ln.amt_tax + ln.amt_misc + ln.amt_freight - ln.amt_discount + ln.amt_nonrecoverable_tax) * ( SIGN(1 + SIGN(@rate_home))*(@rate_home) + (SIGN(ABS(SIGN(ROUND(@rate_home,6))))/(@rate_home + SIGN(1 - ABS(SIGN(ROUND(@rate_home,6)))))) * SIGN(SIGN(@rate_home) - 1) ), @curr_precision),
			ln.qty_received,
			ln.co_asset_id,
			ln.asset_ctrl_num,
			line_description 		= ISNULL(ln.line_description, line_desc),
			quantity				= ISNULL(ln.quantity, qty_received),
			update_asset_quantity	= ISNULL(ln.update_asset_quantity, 1),
			asset_amount			= ISNULL(ln.asset_amount, 0.0),
			imm_exp_amount			= ISNULL(ln.imm_exp_amount, 0.0),
			ln.imm_exp_acct,
			ln.imm_exp_ref_code,
			create_item				= ISNULL(ln.create_item, 1),
			activity_type			= ISNULL(ln.activity_type, 10),
			apply_date 				= CONVERT(char(8), ln.apply_date, 112),
			ln.asset_tag,
			ln.item_tag,
			last_modified_date 		= CONVERT(char(8), ln.last_modified_date, 112),
			ln.modified_by,
			ln.org_id
	FROM 	amln_vw	ln,
			aptax 	tax
	WHERE	ln.company_id	= @company_id
	AND 	ln.trx_ctrl_num	= @trx_ctrl_num
	AND		ln.tax_code		= tax.tax_code
	ORDER BY  ln.company_id, ln.trx_ctrl_num, ln.sequence_id, ln.line_id
END
ELSE
BEGIN
	SELECT
			ln.timestamp,
			ln.company_id,
			ln.trx_ctrl_num,
			ln.sequence_id,
			line_id					= ISNULL(ln.line_id, 1),
			ln.line_desc,
			ln.gl_exp_acct,
			reference_code,
			amt_extended			= ROUND(ln.amt_extended  - (ln.calc_tax * tax.tax_included_flag) + ln.amt_tax + ln.amt_misc + ln.amt_freight - ln.amt_discount + ln.amt_nonrecoverable_tax, @curr_precision),
			ln.qty_received,
			ln.co_asset_id,
			ln.asset_ctrl_num,
			line_description 		= ISNULL(ln.line_description, line_desc),
			quantity				= ISNULL(ln.quantity, qty_received),
			update_asset_quantity	= ISNULL(ln.update_asset_quantity, 1),
			asset_amount			= ISNULL(ln.asset_amount, 0.0),
			imm_exp_amount			= ISNULL(ln.imm_exp_amount, 0.0),
			ln.imm_exp_acct,
			ln.imm_exp_ref_code,
			create_item				= ISNULL(ln.create_item, 1),
			activity_type			= ISNULL(ln.activity_type, 10),
			apply_date 				= CONVERT(char(8), ln.apply_date, 112),
			ln.asset_tag,
			ln.item_tag,
			last_modified_date 		= CONVERT(char(8), ln.last_modified_date, 112),
			ln.modified_by,
			ln.org_id
	FROM 	amln_vw	ln,
			aptax 	tax
	WHERE	ln.company_id		= @company_id
	AND 	ln.trx_ctrl_num		= @trx_ctrl_num
	AND		ln.tax_code			= tax.tax_code
	ORDER BY  ln.company_id, ln.trx_ctrl_num, ln.sequence_id, ln.line_id
END

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amaphdr_vw_amln_vwChildAll_sp] TO [public]
GO
