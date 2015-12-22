SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2008 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2008 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                





CREATE PROCEDURE [dbo].[apupdatetaxdetails_sp] 		@control_number		varchar(16),
						@trx_type		smallint,
						@currency_code		varchar(8)
						   
AS
	DECLARE @detail_sequence_id INTEGER
	DECLARE	@sequence_id	INTEGER
BEGIN		
	
	IF (@trx_type= 4091)
	BEGIN


		SELECT @sequence_id = 0, @detail_sequence_id=1
		UPDATE #apinptaxdtl3500
		SET account_code = d.gl_exp_acct,
		    sequence_id = @sequence_id,
		    @sequence_id = CASE WHEN detail_sequence_id <> 
                    @detail_sequence_id THEN 1 ELSE  @sequence_id +1 END,
		    @detail_sequence_id = detail_sequence_id
		FROM #apinptaxdtl3500 t, #apinpcdt3500 d
		WHERE t.trx_ctrl_num =d.trx_ctrl_num
		  AND t.trx_type = d.trx_type
		  AND t.detail_sequence_id  = d.sequence_id


                

	       DELETE  apinptaxdtl
	       WHERE trx_ctrl_num = @control_number 
		     AND trx_type = @trx_type

	       INSERT INTO apinptaxdtl (trx_ctrl_num,   sequence_id,	trx_type,    
					tax_sequence_id ,	detail_sequence_id, tax_type_code, 
					amt_taxable,  	amt_gross, 	amt_tax, 	amt_final_tax,                              
					recoverable_flag,	account_code        )
	       SELECT 			trx_ctrl_num,   sequence_id,	trx_type,    
					tax_sequence_id ,	detail_sequence_id, tax_type_code, 
					amt_taxable,  	amt_gross, 	amt_tax, 	amt_final_tax,                              
					recoverable_flag,	account_code    FROM #apinptaxdtl3500

               UPDATE #apinptax3500
                SET amt_final_tax = d.amt_tax_det 
	        FROM #apinptax3500 t, #apinpcdt3500 d
		WHERE t.trx_ctrl_num =d.trx_ctrl_num
		  AND t.trx_type = d.trx_type
		  AND t.sequence_id  = d.sequence_id
				
               DELETE  apinptax
	       WHERE trx_ctrl_num = @control_number 
		     AND trx_type = @trx_type

               INSERT INTO apinptax (trx_ctrl_num,   trx_type, sequence_id,	    
			tax_type_code, 	amt_taxable,  	amt_gross, 	amt_tax, 	amt_final_tax )
	       SELECT 	trx_ctrl_num,   trx_type, sequence_id,	    
			tax_type_code, 	amt_taxable,  	amt_gross, 	amt_tax, 	amt_final_tax                              
                       FROM #apinptax3500          				

					
	END

	IF (@trx_type= 4092)
	BEGIN


		SELECT @sequence_id = 0, @detail_sequence_id=1
		UPDATE #apinptaxdtl3560
		SET account_code = d.gl_exp_acct,
		    sequence_id = @sequence_id,
		    @sequence_id = CASE WHEN detail_sequence_id <> 
                    @detail_sequence_id THEN 1 ELSE  @sequence_id +1 END,
		    @detail_sequence_id = detail_sequence_id
		FROM #apinptaxdtl3560 t, #apinpcdt3560 d
		WHERE t.trx_ctrl_num =d.trx_ctrl_num
		  AND t.trx_type = d.trx_type
		  AND t.detail_sequence_id  = d.sequence_id


                

	       DELETE  apinptaxdtl
	       WHERE trx_ctrl_num = @control_number 
		     AND trx_type = @trx_type

	       INSERT INTO apinptaxdtl (trx_ctrl_num,   sequence_id,	trx_type,    
					tax_sequence_id ,	detail_sequence_id, tax_type_code, 
					amt_taxable,  	amt_gross, 	amt_tax, 	amt_final_tax,                              
					recoverable_flag,	account_code        )
	       SELECT 			trx_ctrl_num,   sequence_id,	trx_type,    
					tax_sequence_id ,	detail_sequence_id, tax_type_code, 
					amt_taxable,  	amt_gross, 	amt_tax, 	amt_final_tax,                              
					recoverable_flag,	account_code    FROM #apinptaxdtl3560

               UPDATE #apinptax3560
                SET amt_final_tax = d.amt_tax_det 
	        FROM #apinptax3560 t, #apinpcdt3560 d
		WHERE t.trx_ctrl_num =d.trx_ctrl_num
		  AND t.trx_type = d.trx_type
		  AND t.sequence_id  = d.sequence_id
				
               DELETE  apinptax
	       WHERE trx_ctrl_num = @control_number 
		     AND trx_type = @trx_type

               INSERT INTO apinptax (trx_ctrl_num,   trx_type, sequence_id,	    
			tax_type_code, 	amt_taxable,  	amt_gross, 	amt_tax, 	amt_final_tax )
	       SELECT 	trx_ctrl_num,   trx_type, sequence_id,	    
			tax_type_code, 	amt_taxable,  	amt_gross, 	amt_tax, 	amt_final_tax                              
                       FROM #apinptax3560          				

					
	END

END

/**/                                              
GO
GRANT EXECUTE ON  [dbo].[apupdatetaxdetails_sp] TO [public]
GO
