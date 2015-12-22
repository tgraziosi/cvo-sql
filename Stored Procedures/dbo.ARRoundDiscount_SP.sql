SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\PROCS\arrd.SPv - e7.2.2 : 1.2
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                


CREATE PROC [dbo].[ARRoundDiscount_SP]	@disc_prc_flag	smallint,
				@extended_amt	float,
				@discount	float,
				@return_row	smallint = 0,
				@discount_amt	float = 0.0 OUTPUT,
				@discount_prc	float = 0.0 OUTPUT
AS

DECLARE
	@rounding_factor	float,
	@precision		int

BEGIN
	
	SELECT	@discount_amt = @extended_amt * (@discount / 100.0),
			@discount_prc = @discount
	WHERE	@disc_prc_flag = 1

	
	SELECT	@discount_amt = @discount,
			@discount_prc = (@discount / @extended_amt) * 100.0
	WHERE	@disc_prc_flag = 0
	AND		@extended_amt != 0.0

	SELECT	@discount_amt = @discount,
			@discount_prc = 0.0
	WHERE	@disc_prc_flag = 0
	AND		@extended_amt = 0.0

	
	SELECT	@precision = glcurr_vw.curr_precision + 3 FROM glco,glcurr_vw
	WHERE	glco.home_currency = glcurr_vw.currency_code

	
	SELECT	@rounding_factor = 0.0
	SELECT	@rounding_factor = glcurr_vw.rounding_factor / 2.0
	FROM	glco, glcurr_vw
	WHERE	glco.home_currency = glcurr_vw.currency_code
	AND	substring(str(@discount_amt - floor(@discount_amt), 10, 10), @precision, 1) = '5'
	
	
	SELECT	@discount_amt = ROUND(@discount_amt + @rounding_factor, glcurr_vw.curr_precision)
	FROM	glco, glcurr_vw
	WHERE	glco.home_currency = glcurr_vw.currency_code
	IF( @return_row = 1 )
		SELECT	@discount_amt, @discount_prc
END


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[ARRoundDiscount_SP] TO [public]
GO
