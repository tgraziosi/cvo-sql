SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2008 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2008 Epicor Software Corporation, 2008    
                  All Rights Reserved                    
*/                                                


















CREATE PROCEDURE [dbo].[mtdeldtl_sp] @match_ctrl_num varchar(16), @sequence_id int
AS
BEGIN

	DELETE #epmchdtl
	WHERE match_ctrl_num = @match_ctrl_num
		AND sequence_id = @sequence_id

	DELETE #mtinptaxdtl
	WHERE match_ctrl_num = @match_ctrl_num
		AND detail_sequence_id = @sequence_id

	DELETE #mtinptax
	WHERE tax_type_code NOT IN ( SELECT DISTINCT tax_type_code 
								 FROM #mtinptaxdtl )

	UPDATE a
	SET a.amt_taxable = ( SELECT sum( amt_taxable )
						  FROM #mtinptaxdtl 
						  WHERE match_ctrl_num = a.match_ctrl_num 
							AND tax_type_code = a.tax_type_code ),
		a.amt_gross = ( SELECT sum( amt_gross )
						FROM #mtinptaxdtl 
						WHERE match_ctrl_num = a.match_ctrl_num 
							AND tax_type_code = a.tax_type_code ),
		a.amt_tax = ( SELECT sum( amt_tax )
					  FROM #mtinptaxdtl 
					  WHERE match_ctrl_num = a.match_ctrl_num 
							AND tax_type_code = a.tax_type_code ),
		a.amt_final_tax = ( SELECT sum( amt_final_tax )
							FROM #mtinptaxdtl 
							WHERE match_ctrl_num = a.match_ctrl_num 
								AND tax_type_code = a.tax_type_code )	
	FROM #mtinptax a

END
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[mtdeldtl_sp] TO [public]
GO
