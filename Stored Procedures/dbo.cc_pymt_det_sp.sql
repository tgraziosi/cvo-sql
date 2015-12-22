SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROCEDURE [dbo].[cc_pymt_det_sp]
	@doc_ctrl_num varchar(16) = NULL,
	@customer_code varchar(8)

AS
	SELECT 	d.sub_apply_num, 
		STR(d.amt_applied,30,6), 
		nat_cur_code 	
	FROM 	artrxpdt d, artrxage
	WHERE 	d.doc_ctrl_num = @doc_ctrl_num
	AND 	d.trx_type = 2111
	AND 	d.payer_cust_code = @customer_code
	AND 	d.trx_ctrl_num = artrxage.trx_ctrl_num
	AND 	d.apply_to_num = artrxage.apply_to_num
	ORDER BY sequence_id

GO
GRANT EXECUTE ON  [dbo].[cc_pymt_det_sp] TO [public]
GO
