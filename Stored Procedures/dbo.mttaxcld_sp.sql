SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[mttaxcld_sp]	@match_ctrl_num varchar(16), 
				@trx_type smallint, 
				@tax_type_code varchar(8), 
				@tax_code varchar(8), 
				@unit_price float,
				@tax_code_seq int, 
				@base_id int, 
				@ext_price float,
				@previous_tax float, 
				@qty_invoiced float, 
				@amt_gmd float, 
				@total_freight float, 
				@ins_mtinptax_flag smallint, 
				@total_tax float OUTPUT, 
				@inp_seq_id int OUTPUT, 
				@amt_included_tax float OUTPUT,
				@sequence_id	int = 0,
				@gbl_sequence_id	int OUTPUT	

AS
DECLARE  @amt_tax          float,      @prc_flag         smallint,   
         @prc_type         smallint,  
         @cents_code_flag  smallint,   @cents_code         varchar(8),
         @tax_based_type   smallint,   @tax_included_flag  smallint, 
         @modify_base_prc  float,      @base_range_flag    smallint,
         @base_range_type  smallint,   @base_taxed_type    smallint,
         @min_base_amt     float,      @max_base_amt       float,
         @tax_range_flag   smallint,   @tax_range_type     smallint,
         @min_tax_amt      float,      @max_tax_amt        float,
         @taxable_amt      float,      @prev_tax_type_code varchar(8),
         @cents            float,      @total_type_tax     float, 
         @total_tax2       float,      @temp_int           int,
         @temp_1           int, 
         @tax			   float,
         @cmp_result1          smallint,
         @cmp_result2         smallint,
         @freight_tax_flag	smallint,
	 @included_amt_taxable	float,
	@recoverable_flag	int,	@sales_tax_acct_code varchar(32),	
	@valid_taxdetail int							


SELECT 	@total_tax = 0.0, 
	@amt_included_tax = 0.0, 
	@freight_tax_flag = 0,
	@taxable_amt = 0.0,
	@valid_taxdetail = 1					




SELECT 	@amt_tax = amt_tax, 
	@prc_flag = prc_flag, 
	@prc_type = prc_type, 
	@cents_code_flag = cents_code_flag, 
   	@cents_code = cents_code, 
   	@tax_based_type = tax_based_type, 
   	@tax_included_flag = tax_included_flag, 
   	@modify_base_prc = modify_base_prc, 
   	@base_range_flag = base_range_flag,
   	@base_range_type = base_range_type, 
   	@base_taxed_type = base_taxed_type,
   	@min_base_amt = min_base_amt, 
   	@max_base_amt = max_base_amt,
   	@tax_range_flag = tax_range_flag, 
   	@tax_range_type = tax_range_type,
   	@min_tax_amt = min_tax_amt, 
   	@max_tax_amt = max_tax_amt,
	@recoverable_flag = recoverable_flag,					
	@sales_tax_acct_code	 = sales_tax_acct_code				
FROM	aptxtype
WHERE  tax_type_code = @tax_type_code




IF  ( @prc_flag = 0 )  OR ( @prc_flag IS NULL )  
BEGIN
   	IF @tax_based_type = 0     
   	BEGIN
   		IF (@amt_tax = 0.0)
   			SELECT @taxable_amt = 0.0
		ELSE   			
    		SELECT @taxable_amt = @ext_price
	END      

   	IF @tax_based_type = 1     
    	SELECT @taxable_amt = @qty_invoiced

   	IF @tax_based_type = 2                        
   	BEGIN
	    	SELECT @taxable_amt  =  @total_freight
	      	SELECT @freight_tax_flag = 1


	END      
END

ELSE 
BEGIN  
   


	IF @prc_type = 0
	BEGIN
		IF @tax_based_type = 0       
		BEGIN
			IF (@tax_included_flag = 1)
			BEGIN	
				SELECT	@taxable_amt = @ext_price / (1 + (@amt_tax / 100.0))
				
				SELECT	@included_amt_taxable = @ext_price
			END
				
			ELSE
			BEGIN
				IF (@amt_tax = 0.0)
					SELECT @taxable_amt = 0.0
				ELSE					
					SELECT @taxable_amt = @ext_price
			END				
		END
		
		IF @tax_based_type = 2       
		BEGIN
			SELECT @taxable_amt = @total_freight
	      		SELECT @freight_tax_flag = 1

			


			SELECT @valid_taxdetail = 0

		END      
	END

	

   
   	IF @prc_type = 1      
		SELECT @taxable_amt = @previous_tax
   
   IF @prc_type = 2           
      SELECT @taxable_amt = @ext_price + @previous_tax

	

   
   	IF @base_range_flag = 1
   	BEGIN
    	


      	IF @base_range_type = 0       
      	BEGIN
        	EXEC @cmp_result1 = flcomp_sp @unit_price, @min_base_amt
         	EXEC @cmp_result2 = flcomp_sp @unit_price, @max_base_amt 
			IF ( @cmp_result1 <= 1 ) AND ( @cmp_result2 = 2 OR @cmp_result2 = 0 )
        	BEGIN
        		IF @base_taxed_type = 0        
	            	SELECT @taxable_amt = @taxable_amt * ( @modify_base_prc / 100.0 )
    	        ELSE                          
        	    BEGIN
            		SELECT @taxable_amt = ( @ext_price - 
               		(( @min_base_amt / @unit_price ) * @ext_price )) * 
               		( @modify_base_prc / 100.0 )
            	END
        	END
        	ELSE
	        	SELECT @taxable_amt = 0.0
      	END   

      	IF @base_range_type = 1       
      	BEGIN
        	EXEC @cmp_result1 = flcomp_sp @ext_price, @min_base_amt
         	EXEC @cmp_result2 = flcomp_sp @ext_price, @max_base_amt
	 	 	IF 	((@cmp_result1 = 0) OR (@cmp_result1 = 1)) AND 
	 	 		((@cmp_result2 = 0) OR (@cmp_result2 = -1))
         	BEGIN
            	IF @base_taxed_type = 0        
               		SELECT @taxable_amt = @taxable_amt * ( @modify_base_prc / 100.0 )
            	ELSE                          
            	BEGIN
               		SELECT @taxable_amt = ( @ext_price - 
               		( ( @min_base_amt / @ext_price ) * 
               		@ext_price ) ) * ( @modify_base_prc / 100.0 )
            	END
         	END
         	ELSE
            	SELECT @taxable_amt = 0.0
		END   

      	IF @base_range_type = 2       
      	BEGIN
        	EXEC @cmp_result1 = flcomp_sp @amt_gmd, @min_base_amt
         	EXEC @cmp_result2 = flcomp_sp @amt_gmd, @max_base_amt
	 	 	if ((@cmp_result1 = 0) OR (@cmp_result1 = 1)) 
	 	 		AND ((@cmp_result2 = 0) OR (@cmp_result2 = -1))
         	BEGIN
            	IF @base_taxed_type = 0        
               		SELECT @taxable_amt = @taxable_amt * 
               		( @modify_base_prc / 100.0 )
            	ELSE                          
            	BEGIN
               		SELECT @taxable_amt = ( @ext_price - 
               		( ( @min_base_amt / @amt_gmd ) * 
               		@ext_price ) ) * ( @modify_base_prc / 100.0 )
            	END
         	END
         	ELSE
            	SELECT @taxable_amt = 0.0

		


		SELECT @valid_taxdetail = 0
			
      	END
      
   END
   ELSE           
      SELECT @taxable_amt = @taxable_amt * ( @modify_base_prc / 100.0 )

END 

			





IF @cents_code_flag = 1
BEGIN
   SELECT @cents = ( @taxable_amt - FLOOR( @taxable_amt ) )
   SELECT @taxable_amt = FLOOR( @taxable_amt )
   
SELECT @total_tax = @taxable_amt * ( @amt_tax / 100.0 )

   SELECT @total_tax = @total_tax + tax_cents
   FROM apcendet
   WHERE ( cents_code = @cents_code ) AND ( @cents >= from_cent ) AND
      ( @cents <= to_cent )

	


	SELECT @valid_taxdetail = 0
END
ELSE          

	IF (@prc_flag = 1)
		


		SELECT @total_tax = @taxable_amt * (@amt_tax / 100.0) 
	ELSE
	BEGIN
		


		IF (@tax_based_type = 0)  
			SELECT @total_tax = @amt_tax 
		ELSE IF (@tax_based_type = 1) 
			SELECT @total_tax = @taxable_amt * @amt_tax		
	END		






IF ( @tax_range_flag = 1 ) AND ( @tax_range_type = 1 )
BEGIN
   EXEC @cmp_result1 = flcomp_sp @total_tax,  @max_tax_amt
   if ( @cmp_result1 = 1 )
       SELECT @total_tax = @max_tax_amt

   EXEC @cmp_result1 = flcomp_sp @total_tax,  @min_tax_amt
   if ( @cmp_result1 = -1 )
      SELECT @total_tax = @min_tax_amt

	


	SELECT @valid_taxdetail = 0

END





SELECT @total_tax2 = @total_tax

IF ( @tax_range_flag = 1 ) AND ( @tax_range_type = 0 )
BEGIN
   SELECT @total_type_tax = SUM( amt_final_tax )
   FROM #mtinptax
   WHERE ( match_ctrl_num = @match_ctrl_num ) AND ( tax_type_code = @tax_type_code )

   IF ( @total_type_tax IS NULL)
      SELECT @total_type_tax = 0.0
   
   SELECT @tax =  @total_type_tax + @total_tax
   EXEC @cmp_result1 = flcomp_sp @tax, @min_tax_amt
   if ( @cmp_result1 = -1 )
      SELECT @total_tax = ( @min_tax_amt - @total_type_tax )

   EXEC @cmp_result1 = flcomp_sp @tax, @max_tax_amt
   if ( @cmp_result1 = 1 )
      SELECT @total_tax = ( @max_tax_amt - @total_type_tax )
END





IF @tax_included_flag = 1 
BEGIN
   SELECT @amt_included_tax = @amt_included_tax + @total_tax
   SELECT @ext_price = @ext_price - @amt_included_tax 
END                                    




                                    
IF (@freight_tax_flag = 1)
BEGIN
	DELETE
		#mtinptax
	WHERE	
		match_ctrl_num = @match_ctrl_num AND
		trx_type       = @trx_type AND
		tax_type_code  = @tax_type_code
		
END   

IF @prc_type = 0 AND @tax_based_type = 0 AND @tax_included_flag = 1
BEGIN
	SELECT	@ext_price = @included_amt_taxable
	SELECT	@taxable_amt = @included_amt_taxable
END



IF @ins_mtinptax_flag = 1
BEGIN

	


	
	



	UPDATE	#mtinptax 
	SET	amt_taxable 	= amt_taxable + @taxable_amt,
		amt_gross 	= amt_gross + @ext_price,         
		amt_tax     	= amt_tax + @total_tax2,         
		amt_final_tax 	= amt_final_tax + @total_tax        
	WHERE	match_ctrl_num 	= @match_ctrl_num AND
		trx_type       	= @trx_type AND
		tax_type_code  	= @tax_type_code

	IF (@@ROWCOUNT = 0)
	BEGIN
	
		SELECT @inp_seq_id = @inp_seq_id + 1
		
		INSERT INTO #mtinptax(	timestamp,	match_ctrl_num,		trx_type,	sequence_id,	
					tax_type_code,	amt_taxable,		amt_gross, 	amt_tax,	
					amt_final_tax )       
		VALUES ( 		NULL, 		@match_ctrl_num,	@trx_type, 	@inp_seq_id, 
					@tax_type_code,	@taxable_amt,		@ext_price, 	@total_tax2, 
			   		@total_tax )
	
		IF @@error != 0  
			RETURN -1 

	END		

	


	
	IF (@valid_taxdetail = 1)
	BEGIN
		
		


		SELECT 	@gbl_sequence_id = @gbl_sequence_id + 1
			
		INSERT #mtinptaxdtl (	match_ctrl_num, 	sequence_id,		trx_type,	tax_sequence_id,	detail_sequence_id,
					tax_type_code,		amt_taxable,		amt_gross,	amt_tax,		amt_final_tax,
					recoverable_flag,	account_code	)
		SELECT			@match_ctrl_num, 	@gbl_sequence_id,	@trx_type, 	@sequence_id	, 	@sequence_id,
					@tax_type_code, 	@taxable_amt,  		@ext_price, 	@total_tax2,   		@total_tax,
					@recoverable_flag,	 
									account_code
								 


		FROM	#epmchdtl  
		WHERE	match_ctrl_num 	= @match_ctrl_num
		AND	sequence_id 	= @sequence_id		
				
		IF @@error != 0  
			RETURN -1 
			
	END


END 

RETURN 0	
GO
GRANT EXECUTE ON  [dbo].[mttaxcld_sp] TO [public]
GO
