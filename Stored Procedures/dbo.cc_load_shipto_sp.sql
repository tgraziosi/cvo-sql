SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE 	[dbo].[cc_load_shipto_sp] @doc_ctrl_num varchar(16)

AS

	SELECT 	h.ship_to_code,
		ship_to_name,
		ship_addr1,
		ship_addr2,
		ship_addr3,
		ship_addr4,
		ship_addr5,
		ship_addr6
	FROM 	artrxxtr x, artrx h, arshipto s
	WHERE	x.trx_ctrl_num = h.trx_ctrl_num 
	AND	h.doc_ctrl_num = @doc_ctrl_num
	AND	h.customer_code = s.customer_code
	AND	h.ship_to_code = s.ship_to_code


GO
GRANT EXECUTE ON  [dbo].[cc_load_shipto_sp] TO [public]
GO
