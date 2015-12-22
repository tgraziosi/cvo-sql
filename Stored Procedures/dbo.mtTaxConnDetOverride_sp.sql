SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2008 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2008 Epicor Software Corporation, 2008    
                  All Rights Reserved                    
*/                                                














CREATE PROCEDURE [dbo].[mtTaxConnDetOverride_sp]
			@match_ctrl_num varchar(16), 
			@sequence_id    int
as
declare @sum_amt_final_tax decimal(20,8),
		@sum_amt_tax decimal(20,8)
		
select	@sum_amt_final_tax = sum(amt_final_tax),
		@sum_amt_tax = sum(amt_tax)
from #mtinptaxdtl 
where match_ctrl_num = @match_ctrl_num
and detail_sequence_id = @sequence_id

if @sum_amt_tax>0
BEGIN
	UPDATE #mtinptaxdtl
	SET amt_final_tax = (amt_tax / @sum_amt_tax) * @sum_amt_final_tax
	WHERE match_ctrl_num = @match_ctrl_num
	 and detail_sequence_id = @sequence_id
END
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[mtTaxConnDetOverride_sp] TO [public]
GO
