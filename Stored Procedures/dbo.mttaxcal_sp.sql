SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                































































CREATE PROC [dbo].[mttaxcal_sp]	@match_ctrl_num varchar(16), 
				@trx_type smallint,
				@tax_code varchar(8), 
				@unit_price float, 
				@qty_invoiced float, 
				@total_freight float, 
				@ins_mtinptax_flag smallint,
				@total_line_tax float OUTPUT, 
				@inp_seq_id int OUTPUT, 
				@total_line_tax_included float OUTPUT ,
				@sequence_id		int = 0,
				@gbl_sequence_id	int = 0 OUTPUT
AS
DECLARE  @tax_code_seq      int,        
         @tax_type_code     varchar(8),    
         @amt_tax           float,
         @ext_price         float,         
         @base_id           int,
         @line_tax          float,         
         @line_included_tax float,
         @return_code	smallint,
         @amt_gmd		float,
         @previous_tax	float
         
SELECT @previous_tax = 0.0
SELECT @amt_gmd = 0.0	         
SELECT @ext_price = @unit_price * @qty_invoiced




         
IF ( ( @tax_code != '' ) AND ( @tax_code IS NOT NULL ) )
BEGIN

	


	SET ROWCOUNT 1
	SELECT	@tax_code_seq = sequence_id, 
   		@tax_type_code = tax_type_code,
		@base_id = base_id
	FROM	aptaxdet
	WHERE	tax_code = @tax_code
	ORDER BY tax_code, sequence_id
   
	WHILE ( @@ROWCOUNT > 0 )
	BEGIN
		

  
		EXEC @return_code = mttaxcld_sp 
					@match_ctrl_num, 
					@trx_type, 
					@tax_type_code, 
					@tax_code, 
					@unit_price, 
					@tax_code_seq, 
					@base_id, 
					@ext_price,
					@previous_tax,
					@qty_invoiced, 
					@amt_gmd, 
					@total_freight, 
					@ins_mtinptax_flag, 
					@line_tax OUTPUT, 
					@inp_seq_id OUTPUT, 
					@line_included_tax OUTPUT,
					@sequence_id,
					@gbl_sequence_id OUTPUT
					
	

		IF @return_code != 0  
			RETURN -1
	
		IF @line_tax IS NULL
			SELECT @line_tax = 0.0

		IF @line_included_tax IS NULL
			SELECT @line_tax = 0.0
                        
		SELECT @previous_tax = @line_tax	                        
		SELECT @total_line_tax = @total_line_tax + @line_tax
		SELECT @total_line_tax_included = @total_line_tax_included + @line_included_tax

		


		SET ROWCOUNT 1
		SELECT @tax_code_seq = sequence_id, 
			@tax_type_code = tax_type_code,
			@base_id = base_id
		FROM	aptaxdet
		WHERE	tax_code = @tax_code and sequence_id > @tax_code_seq
		ORDER BY tax_code, sequence_id
	END
END   

RETURN 0

GO
GRANT EXECUTE ON  [dbo].[mttaxcal_sp] TO [public]
GO
