SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2006 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2006 Epicor Software Corporation, 2006    
                  All Rights Reserved                    
*/                                  

CREATE PROCEDURE [dbo].[gltc_invoice_det_sp]
	@trx_ctrl_num	varchar(20)
AS
BEGIN

if exists (select * from sysobjects where id = object_id('#gltcdocdet'))
   DROP TABLE #gltcdocdet


	DECLARE @posted_flag int
	select @posted_flag = posted_flag from gltcrecon where trx_ctrl_num = @trx_ctrl_num

			if (@posted_flag = 1)
				insert #gltcdocdet
					select trx_ctrl_num, sequence_id, location_code, item_code, unit_code, 
					tax_code, reference_code, discount_prc, discount_amt, extended_price, unit_price, 
					line_desc, gl_rev_acct, qty_shipped, qty_ordered, weight 
					from artrxcdt where trx_ctrl_num = @trx_ctrl_num
			else if (@posted_flag = 0)
				insert #gltcdocdet
					select trx_ctrl_num, sequence_id, location_code, item_code, unit_code, 
					tax_code, reference_code, discount_prc, discount_amt, extended_price, unit_price, 
					line_desc, gl_rev_acct, qty_shipped, qty_ordered, weight 
					from arinpcdt where trx_ctrl_num = @trx_ctrl_num
END
/**/                                              

GO
GRANT EXECUTE ON  [dbo].[gltc_invoice_det_sp] TO [public]
GO
