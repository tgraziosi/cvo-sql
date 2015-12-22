SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\PROCS\appoxtax.SPv - e7.2.2 : 1.6
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                























CREATE PROCEDURE [dbo].[appoxtax_sp]
	@trx_ctrl_num varchar(16), 	@trx_type smallint,
	@sequence_id smallint,		@tax_type_code varchar(8), 	
	@amt_taxable float, 		@amt_gross float, 	
	@amt_tax float, 		@amt_final_tax float,
	@error_flag smallint OUTPUT
as

	SELECT @error_flag = 0

	
	
	IF NOT EXISTS(SELECT trx_ctrl_num
	 FROM apinpchg
	 WHERE trx_ctrl_num = @trx_ctrl_num)
	 BEGIN
		SELECT @error_flag = -1
		RETURN
	 END
	
	IF (@sequence_id = 0)
	 SELECT @sequence_id = MAX(sequence_id) + 1
	 FROM apinptax
	 WHERE trx_ctrl_num = @trx_ctrl_num
	ELSE
	BEGIN
	 IF EXISTS (SELECT sequence_id FROM apinptax
	 WHERE trx_ctrl_num = @trx_ctrl_num
	 AND sequence_id = @sequence_id)
	 BEGIN
		SELECT @error_flag = -2
		RETURN
	 END
	END
	
	IF NOT(@trx_type = 4091) AND NOT(@trx_type = 4092)
	 BEGIN
	 	SELECT @error_flag = -3
		RETURN
	 END
	
	IF NOT EXISTS (SELECT tax_type_code FROM aptxtype
	 WHERE tax_type_code = @tax_type_code)
	 BEGIN
		SELECT @error_flag = -4
	 	RETURN
	 END

	
	IF ((@amt_taxable) < (0.0) - 0.0000001) OR ((@amt_gross) < (0.0) - 0.0000001) OR
	 ((@amt_tax) < (0.0) - 0.0000001) OR ((@amt_final_tax) < (0.0) - 0.0000001)
	 BEGIN
		SELECT @error_flag = -5
		RETURN
	 END
		
	
	INSERT INTO apinptax VALUES
	(
		NULL,			@trx_ctrl_num,
		@trx_type,		@sequence_id,		
		@tax_type_code,		@amt_taxable,		
		@amt_gross,		@amt_tax,		
		@amt_final_tax		
	)
	IF(@@ROWCOUNT = 0)
		SELECT @error_flag = -6





GO
GRANT EXECUTE ON  [dbo].[appoxtax_sp] TO [public]
GO
