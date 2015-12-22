SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[mtdmptmp_sp] @tmp_mch_ctrl_num varchar(16)
AS      

BEGIN TRANSACTION 

	DELETE epmchdtl 
	WHERE match_ctrl_num = @tmp_mch_ctrl_num
	IF  @@error != 0                
	BEGIN
	 	ROLLBACK TRANSACTION
	   	RETURN -1
	END  
                                                

	INSERT INTO epmchdtl
		(timestamp,                                           
		match_dtl_key,
		match_ctrl_num,
		sequence_id,
		po_ctrl_num,
		po_sequence_id,
		receipt_ctrl_num,
		receipt_dtl_key,
		account_code,
		reference_code,
		company_id,
		qty_received,
		qty_invoiced,
		qty_prev_invoiced,
		amt_prev_invoiced,
		unit_price,
		invoice_unit_price,
		tolerance_hold_flag,
		match_posted_flag,
		tax_code,
		amt_tax,
		amt_tax_included,
		calc_tax,
		receipt_sequence_id, 
		amt_tax_exp, 
		amt_discount, 
		amt_freight, 
		amt_misc)                    
	SELECT NULL,
		match_dtl_key,
		match_ctrl_num,
		sequence_id,
		po_ctrl_num,
		po_sequence_id,
		receipt_ctrl_num,
		receipt_dtl_key,
		account_code,
		reference_code,
		company_id,
		qty_received,
		qty_invoiced,
		qty_prev_invoiced,
		amt_prev_invoiced,
		unit_price,
		invoice_unit_price,
		tolerance_hold_flag,
		0,			
		tax_code,
		amt_tax,
		amt_tax_included,
		calc_tax,
		receipt_sequence_id, 
		amt_tax_exp, 
		amt_discount, 
		amt_freight, 
		amt_misc 
	FROM  #epmchdtl 
	WHERE match_ctrl_num = @tmp_mch_ctrl_num 
	IF  @@error != 0                
	BEGIN
	 	ROLLBACK TRANSACTION
	   	RETURN -1
	END 


COMMIT TRANSACTION
RETURN 0

GO
GRANT EXECUTE ON  [dbo].[mtdmptmp_sp] TO [public]
GO
