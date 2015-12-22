SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_unposted_det_sp] 	@trx_ctrl_num 	varchar(16), 
				 															@trx_type int
AS
	SET NOCOUNT ON		

	
		
	IF @trx_type IN (2021, 2031, 2998, 2032)
		SELECT 	trx_ctrl_num,
			'',
			location_code,
			item_code,
			line_desc,			qty_ordered,
			qty_shipped,
			unit_code,
			STR(extended_price,30,6), 
			return_code,
			qty_returned,
			trx_type,
			org_id
		FROM 	arinpcdt
		WHERE	trx_ctrl_num = @trx_ctrl_num 
		ORDER BY trx_ctrl_num, sequence_id
	ELSE
		SELECT 	trx_ctrl_num,
			apply_to_num,
			'',
			'',
			line_desc,			0,
			0,
			'',
			STR(amt_applied,30,6), 
			'',
			0,
			trx_type,
			org_id
		FROM 	arinppdt
		WHERE	trx_ctrl_num = @trx_ctrl_num 
		ORDER BY trx_ctrl_num, sequence_id

	
	SET NOCOUNT OFF
GO
GRANT EXECUTE ON  [dbo].[cc_unposted_det_sp] TO [public]
GO
