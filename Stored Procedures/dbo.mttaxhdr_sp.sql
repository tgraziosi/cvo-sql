SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


 

CREATE PROC [dbo].[mttaxhdr_sp] 
 
AS 
DECLARE
	@total_amt_tax		float,
	@total_tax_included		float 

 
	SELECT @total_amt_tax = SUM(amt_final_tax)
	FROM
		#mtinptax
 
	SELECT @total_tax_included = SUM(amt_final_tax)
	FROM
		#mtinptax m, aptxtype a
	WHERE
		m.tax_type_code = a.tax_type_code
	AND	a.tax_included_flag = 1 
 
 
SELECT @total_amt_tax, @total_tax_included
GO
GRANT EXECUTE ON  [dbo].[mttaxhdr_sp] TO [public]
GO
