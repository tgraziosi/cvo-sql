SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\PROCS\artxintl.SPv - e7.2.2 : 1.4
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                



CREATE PROC [dbo].[artxintl_sp]
	@incl_rev_deduct float, @g_trx_num char(32),
	@incl_rev_bal float = 0.0 OUTPUT
AS
DECLARE
	@incl_tax_total float

	SELECT @incl_tax_total = SUM(amt_final_tax)
	FROM arinptax, artxtype
	WHERE arinptax.tax_type_code = artxtype.tax_type_code
	AND artxtype.tax_included_flag = 1
	AND arinptax.trx_ctrl_num = @g_trx_num

	IF @incl_tax_total IS NULL
		SELECT @incl_rev_bal = 0.0
	ELSE
		SELECT @incl_rev_bal = @incl_tax_total - @incl_rev_deduct

RETURN



/**/                                              
GO
GRANT EXECUTE ON  [dbo].[artxintl_sp] TO [public]
GO
