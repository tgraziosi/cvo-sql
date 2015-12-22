SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2006 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2006 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                





CREATE PROCEDURE [dbo].[aprecalsumtaxdetail_sp] 	@control_number		varchar(16),
						@trx_type		smallint,
						@currency_code		varchar(8),
                                                @detail_sec_id          int
						   
AS
	DECLARE	@amt_tax	dec(20,8)
	DECLARE	@amt_tax_final	dec(20,8)
	DECLARE	@amt_tax_norec	dec(20,8)
	DECLARE @amt_tax_recover dec(20,8)
BEGIN		
	
	
	IF (@trx_type= 4091)
	BEGIN

	       SELECT @amt_tax_recover = sum(amt_final_tax)                              
		FROM #apinptaxdtl3500
		WHERE ISNULL(recoverable_flag, 0) = 1
                AND detail_sequence_id = @detail_sec_id 
               
                SELECT @amt_tax_norec = sum(amt_final_tax) 
                FROM #apinptaxdtl3500
		WHERE ISNULL(recoverable_flag, 0) = 0 
		AND detail_sequence_id = @detail_sec_id

	       SELECT @amt_tax = sum(amt_tax)                              
		FROM #apinptaxdtl3500
                WHERE detail_sequence_id = @detail_sec_id
		
               SELECT @amt_tax_final = sum(amt_final_tax) 
                FROM #apinptaxdtl3500
                WHERE detail_sequence_id = @detail_sec_id
                
               /*SELECT  @amt_tax_norec = @amt_tax - @amt_tax_final*/
                
		
          SELECT @amt_tax, @amt_tax_final , @amt_tax_recover , @amt_tax_norec 

	END
	
	IF (@trx_type= 4092)
	BEGIN
	
		       SELECT @amt_tax_recover = sum(amt_final_tax)                              
			FROM #apinptaxdtl3560
			WHERE ISNULL(recoverable_flag, 0) = 1
	                AND detail_sequence_id = @detail_sec_id 
	               
	                SELECT @amt_tax_norec = sum(amt_final_tax) 
	                FROM #apinptaxdtl3560
			WHERE ISNULL(recoverable_flag, 0) = 0 
			AND detail_sequence_id = @detail_sec_id
	
		       SELECT @amt_tax = sum(amt_tax)                              
			FROM #apinptaxdtl3560
	                WHERE detail_sequence_id = @detail_sec_id
			
	               SELECT @amt_tax_final = sum(amt_final_tax) 
	                FROM #apinptaxdtl3560
	                WHERE detail_sequence_id = @detail_sec_id
	                
	               /*SELECT  @amt_tax_norec = @amt_tax - @amt_tax_final*/
	                
			
	          SELECT @amt_tax, @amt_tax_final , @amt_tax_recover , @amt_tax_norec 
	
	END

       
END
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[aprecalsumtaxdetail_sp] TO [public]
GO
