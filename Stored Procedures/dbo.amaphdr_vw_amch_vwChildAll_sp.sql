SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amaphdr_vw_amch_vwChildAll_sp]
(
	@company_id			smallint,		
	@trx_ctrl_num		varchar(16)		
) 
AS

SELECT
		timestamp,
		company_id,
		trx_ctrl_num,
		sequence_id,
		line_id					= ISNULL(line_id, 1),
		line_desc,
		gl_exp_acct,
		reference_code,
		amt_charged,
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
		apply_date 				= CONVERT(char(8),apply_date, 112),
		asset_tag,
		item_tag,
		last_modified_date 		= CONVERT(char(8),last_modified_date, 112),
		modified_by,
		org_id
FROM 	amch_vw
WHERE	company_id		= @company_id
AND 	trx_ctrl_num	= @trx_ctrl_num
ORDER BY company_id, trx_ctrl_num, ABS(sequence_id), line_id

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amaphdr_vw_amch_vwChildAll_sp] TO [public]
GO
