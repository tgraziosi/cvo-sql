SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


                
CREATE PROC [dbo].[mtdmptax_sp] @tmp_mch_ctrl_num varchar(16)
AS      

BEGIN TRANSACTION 

	DELETE	mtinptax
	WHERE	match_ctrl_num = @tmp_mch_ctrl_num 
	IF  @@error != 0                
	BEGIN
	 	ROLLBACK TRANSACTION
	   	RETURN -1
	END 

                                                

	INSERT INTO mtinptax
	   (timestamp,
	    match_ctrl_num,
	    trx_type,
	    sequence_id,
	    tax_type_code,
	    amt_taxable,
	    amt_gross,
	    amt_tax,
	    amt_final_tax )       
	SELECT	NULL,
		match_ctrl_num, 
		trx_type, 
		sequence_id,       
		tax_type_code, 
		amt_taxable, 
		amt_gross, 
		amt_tax,
		amt_final_tax
	FROM	#mtinptax
	WHERE	match_ctrl_num = @tmp_mch_ctrl_num

	IF  @@error != 0                
	BEGIN
	 	ROLLBACK TRANSACTION
	   	RETURN -1
	END


	DELETE	mtinptaxdtl
	WHERE	match_ctrl_num = @tmp_mch_ctrl_num 
	IF  @@error != 0                
	BEGIN
	 	ROLLBACK TRANSACTION
	   	RETURN -1
	END 

	



	INSERT INTO mtinptaxdtl (match_ctrl_num, 	sequence_id,		trx_type,	tax_sequence_id,	detail_sequence_id,
				tax_type_code,		amt_taxable,		amt_gross,	amt_tax,		amt_final_tax,
				recoverable_flag,	account_code	)
	SELECT match_ctrl_num, 	sequence_id,		trx_type,	tax_sequence_id,	detail_sequence_id,
				tax_type_code,		amt_taxable,		amt_gross,	amt_tax,		amt_final_tax,
				recoverable_flag,	account_code	
	FROM	#mtinptaxdtl
	WHERE	match_ctrl_num = @tmp_mch_ctrl_num 


	IF  @@error != 0                
	BEGIN
	 	ROLLBACK TRANSACTION
	   	RETURN -1
	END
















	COMMIT TRANSACTION
	RETURN 0


GO
GRANT EXECUTE ON  [dbo].[mtdmptax_sp] TO [public]
GO
