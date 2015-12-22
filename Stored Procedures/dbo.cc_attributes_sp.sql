SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROCEDURE [dbo].[cc_attributes_sp] 
	@cust_code varchar(9) = '',
	@inv_num varchar(16),
	@direction tinyint = 0 

AS









	IF ( SELECT trx_type FROM artrx WHERE doc_ctrl_num = @inv_num ) = 2031
		SELECT 	'Transaction Num.' = d.trx_ctrl_num, 
						'Location' = d.location_code, 
						'Part Number' = d.item_code, 
						'Entry Date' = CASE WHEN d.date_entered > 639906 THEN CONVERT(datetime, DATEADD(dd, d.date_entered - 639906, '1/1/1753'), 107) ELSE ' ' END, 
						'Line Description' = d.line_desc,
		 'Qty' = d.qty_shipped,
						'Tax Code' = d.tax_code,
						'GL Account' = d.gl_rev_acct,
	 'Discount %' = d.discount_prc,
						'Discount' = d.discount_amt,
						'Extended Price' = d.extended_price,
						'Tax' = d.calc_tax,
						'Reference Code' = d.reference_code
		FROM 	artrxcdt d, artrx h
		WHERE customer_code = @cust_code
		AND 	d.doc_ctrl_num = @inv_num
		AND	d.trx_ctrl_num = h.trx_ctrl_num
	

	IF ( SELECT trx_type FROM artrx WHERE doc_ctrl_num = @inv_num ) = 2021
		SELECT 	'Transaction Num.' = d.trx_ctrl_num, 
						'Revenue Account' = d.rev_acct_code, 
						'Apply Amount' = d.apply_amt,
						'Reference Code' = d.reference_code
		FROM 	artrx h, artrxrev d
		WHERE customer_code = @cust_code
		AND 	h.doc_ctrl_num = @inv_num
		AND	d.trx_ctrl_num = h.trx_ctrl_num

	IF ( SELECT trx_type FROM artrx WHERE doc_ctrl_num = @inv_num ) = 2111
		SELECT 	'Transaction Num.' = d.trx_ctrl_num, 
						'Apply Date' = CASE WHEN d.date_applied > 639906 THEN CONVERT(datetime, DATEADD(dd, d.date_applied - 639906, '1/1/1753'),107) ELSE ' ' END, 
						'Write Off' = amt_wr_off,
						'Line Description' = d.line_desc,
						'Journal Num' = d.gl_trx_id, 
						'Customer Code' = d.customer_code
		FROM 	artrxpdt d, artrx h
		WHERE d.customer_code = @cust_code
		AND 	d.doc_ctrl_num = @inv_num
		AND	d.trx_ctrl_num = h.trx_ctrl_num


GO
GRANT EXECUTE ON  [dbo].[cc_attributes_sp] TO [public]
GO
