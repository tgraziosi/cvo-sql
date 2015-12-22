SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[cc_inv_det_sp]	@doc_ctrl_num	varchar(16) = NULL
AS

	DECLARE @trx varchar(16),
					@order_str varchar(16),
					@ord_no int,
					@ord_ext int,
					@sep_index smallint

	SELECT 	@trx = trx_ctrl_num, 
					@order_str = order_ctrl_num
	FROM artrx_all
	WHERE doc_ctrl_num = @doc_ctrl_num




























			SELECT 	'apply_trx_type' = CASE apply_trx_type WHEN 2031 THEN item_code ELSE 'ATF invoice'	END, 
							line_desc, 
							qty_shipped, 
							'unit price' = CASE apply_trx_type	WHEN 2031 THEN STR(unit_price,30,6) ELSE STR(amt_net,30,6) END, 
							'balance' = CASE apply_trx_type	WHEN 2031 THEN STR(unit_price * qty_shipped,30,6) ELSE STR(amt_net,30,6) END,
							nat_cur_code,
							d.org_id,
							order_ctrl_num,
							sequence_id,
							calc_tax,
							amt_tax,
							amt_freight
			FROM artrx h LEFT OUTER JOIN artrxcdt d ON (h.doc_ctrl_num = d.doc_ctrl_num)
			WHERE	h.doc_ctrl_num = @doc_ctrl_num	
			ORDER BY sequence_id
--		END

GO
GRANT EXECUTE ON  [dbo].[cc_inv_det_sp] TO [public]
GO
