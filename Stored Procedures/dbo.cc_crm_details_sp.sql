SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

-- EXEC cc_crm_details_sp 'CRM0028590'

CREATE PROCEDURE [dbo].[cc_crm_details_sp]
	 @doc_ctrl_num varchar(16)
AS
	SELECT
		IsNull(item_code,' '), 
		IsNull(line_desc,' '), 
		STR(qty_returned,30,2), 
		STR(unit_price,30,2), 
		STR(unit_price * qty_returned,30,2) 
		nat_cur_code,
		artrx.org_id,
		'', 
		'', 
		sequence_id
	FROM 	artrxcdt, artrx 
	WHERE 	artrxcdt.doc_ctrl_num = @doc_ctrl_num
	AND 	artrx.trx_ctrl_num = artrxcdt.trx_ctrl_num
	ORDER BY sequence_id


GO
GRANT EXECUTE ON  [dbo].[cc_crm_details_sp] TO [public]
GO
