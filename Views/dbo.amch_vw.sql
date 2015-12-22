SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[amch_vw] 
AS 

SELECT 
	am.timestamp,
	chrg.company_id,
	chrg.trx_ctrl_num,
	chrg.sequence_id,
	am.line_id,
	chrg.line_desc,
	chrg.gl_exp_acct,
	chrg.reference_code,
	chrg.amt_charged,
	qty_received		= 1,
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
	am.org_id
FROM   	amapchrg chrg LEFT OUTER JOIN	amapdet am 	ON chrg.trx_ctrl_num = am.trx_ctrl_num
							--AND chrg.sequence_id = am.sequence_id







GO
GRANT REFERENCES ON  [dbo].[amch_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[amch_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[amch_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[amch_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[amch_vw] TO [public]
GO
