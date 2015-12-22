SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[amln_vw] 
AS 

SELECT 
	am.timestamp,
	am.company_id,
	ap.trx_ctrl_num,
	ap.sequence_id,
	am.line_id,
	ap.line_desc,
	ap.gl_exp_acct,
	ap.reference_code,
	ap.tax_code,
	ap.amt_extended,
	ap.amt_discount,
	ap.amt_freight,
	ap.amt_tax,
	ap.amt_misc,
	ap.calc_tax,
	ap.qty_received,
        ap.amt_nonrecoverable_tax,
	am.co_asset_id,
	am.asset_ctrl_num,
	am.line_description,
	am.quantity,
	am.update_asset_quantity,
	am.asset_amount,
	am.imm_exp_amount,
	am.imm_exp_acct,
	am.imm_exp_ref_code,
	am.create_item,
	am.activity_type,
	am.apply_date,
	am.asset_tag,
	am.item_tag,
	am.last_modified_date,
	am.modified_by,
	ap.org_id
FROM   	apvodet ap INNER JOIN amapdet am 	ON ap.trx_ctrl_num = am.trx_ctrl_num
						AND ap.sequence_id = am.sequence_id
GO
GRANT REFERENCES ON  [dbo].[amln_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[amln_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[amln_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[amln_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[amln_vw] TO [public]
GO
