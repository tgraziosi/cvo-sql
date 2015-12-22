SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[appoxdet_sp]
AS
DECLARE 	
	@today int,
	@result int

	SELECT @result = 0

	EXEC appdate_sp @today OUTPUT

	



	

	INSERT #apinpcdt(
		trx_ctrl_num,		
		trx_type,		
		sequence_id,		 
		location_code,		
		item_code,		
		bulk_flag,		
		qty_ordered,		
		qty_received,		
		qty_returned,		
		qty_prev_returned,	
		approval_code,		
		tax_code,		
		return_code,		
		code_1099,		
		po_ctrl_num,		
		unit_code,		
		unit_price,		
		amt_discount,		
		amt_freight,		
		amt_tax,		
		amt_misc,		
		amt_extended,		
		calc_tax,		
		date_entered,		
		gl_exp_acct,		
		new_gl_exp_acct,	
		rma_num,		
		line_desc,		
		serial_id,		
		company_id,		
		iv_post_flag,		
		po_orig_flag,		
		rec_company_code,	
		new_rec_company_code,	
		reference_code,		
		new_reference_code,	
		org_id,
		amt_nonrecoverable_tax,
		amt_tax_det
	)
	SELECT	DISTINCT a.trx_ctrl_num,	
		4091,
		b.sequence_id,
		a.location_code,
		e.item_code,
		0,
		b.qty_received,
		b.qty_invoiced,
		0,
		0,
		a.approval_code,
		b.tax_code,
		'',
		d.code_1099,
		b.po_ctrl_num,
		e.unit_code,
		b.invoice_unit_price,
		b.amt_discount,		
		b.amt_freight,		
		b.amt_tax_exp,		
		b.amt_misc,			
		(b.invoice_unit_price * b.qty_invoiced),
		b.calc_tax,
		@today,
		b.account_code,	
		b.account_code,	
		'',
		e.item_desc,
		0,
		b.company_id,
		0,
		-b.sequence_id,
		c.company_code,
		c.company_code,
		reference_code = CASE ISNULL(e.reference_code, '')
					WHEN '' THEN ' '
					ELSE e.reference_code
				END,
		new_reference_code = CASE ISNULL(e.reference_code, '')
					WHEN '' THEN ' '
					ELSE e.reference_code
				END,
		gl.organization_id,
		b.amt_tax_included,		
		b.amt_tax				  		
	FROM #apinpchg a, epmchdtl b, glcomp_vw c, apvend d, epinvdtl e, glchart gl  
	WHERE a.match_ctrl_num = b.match_ctrl_num
	AND b.company_id = c.company_id
	AND a.vendor_code = d.vendor_code
	AND b.receipt_ctrl_num = e.receipt_ctrl_num 
	AND b.receipt_dtl_key = e.receipt_detail_key AND b.po_sequence_id = e.po_sequence_id		
	AND b.account_code = e.account_code		
	AND isnull(b.reference_code, '') = isnull(e.reference_code, '')
	AND gl.account_code = b.account_code

	

	IF ( @@ROWCOUNT = 0 )
	BEGIN
		SELECT @result = 100
	END

RETURN @result
GO
GRANT EXECUTE ON  [dbo].[appoxdet_sp] TO [public]
GO
