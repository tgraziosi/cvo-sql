SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\PROCS\aptxinft.SPv - e7.2.2 : 1.4
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                









create procedure [dbo].[aptxinft_sp]
	@g_amt_freight float, @g_tax_code char(8),
	@incl_frt_deduct float OUTPUT
as
DECLARE	@tax_type_code char(8),
	@tax_based_type smallint,
	@amt_tax float,
	@prc_flag smallint

	SELECT @incl_frt_deduct = 0.0

	SELECT @tax_type_code = aptxtype.tax_type_code,
	 @tax_based_type = aptxtype.tax_based_type,
	 @amt_tax = aptxtype.amt_tax,	
	 @prc_flag = aptxtype.prc_flag
	FROM aptaxdet, aptxtype
	WHERE aptaxdet.tax_code = @g_tax_code
	AND aptxtype.tax_type_code = aptaxdet.tax_type_code

	IF (@@ROWCOUNT = 0)
		RETURN

	
	IF (@tax_based_type = 2)
	BEGIN
		
		IF ( @prc_flag = 1)
			SELECT @incl_frt_deduct = @incl_frt_deduct
				+ ( @g_amt_freight -
			( @g_amt_freight / ( 1.0 + ( @amt_tax / 100))))
		ELSE
			
			SELECT @incl_frt_deduct = @incl_frt_deduct
				 + @amt_tax
	END
	
	SELECT @incl_frt_deduct = (SIGN(@incl_frt_deduct) * ROUND(ABS(@incl_frt_deduct) + 0.0000001, 2))




GO
GRANT EXECUTE ON  [dbo].[aptxinft_sp] TO [public]
GO
