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


CREATE PROCEDURE [dbo].[gltc_doc_tax_det_sp]
	@trx_ctrl_num	varchar(20)
AS
BEGIN

	DECLARE @posted_flag int
	DECLARE @trx_type int
	DECLARE @doc_ctrl_num varchar(20)
	select @posted_flag =  posted_flag, @trx_type = trx_type, @doc_ctrl_num = doc_ctrl_num  from gltcrecon where trx_ctrl_num = @trx_ctrl_num

		if (@posted_flag = 0 AND  (@trx_type = 2031 OR @trx_type = 2032))
			insert #doctaxdet 
			select trx.tax_type_code, tax.tax_type_desc, 
					trx.amt_gross, trx.amt_taxable, trx.amt_tax	
				from arinptax trx, artxtype tax 
				where trx.trx_ctrl_num = @trx_ctrl_num
					AND trx.tax_type_code = tax.tax_type_code
	
		else if (@posted_flag = 1 AND (@trx_type = 2031 OR @trx_type = 2032))
			insert #doctaxdet 
			select trx.tax_type_code, tax.tax_type_desc, 
					trx.amt_gross, trx.amt_taxable, trx.amt_tax	
				from artrxtax trx, artxtype tax
				where trx.tax_type_code = tax.tax_type_code 
					AND trx.doc_ctrl_num = @doc_ctrl_num
	
		else if (@posted_flag = 1 AND (@trx_type = 4091 OR @trx_type = 4092))
			insert #doctaxdet 
			select trx.tax_type_code, tax.tax_type_desc, 
					trx.amt_gross, trx.amt_taxable, trx.amt_tax	
				from aptrxtax trx, aptxtype tax
				where trx.trx_ctrl_num = @trx_ctrl_num
					AND trx.tax_type_code = tax.tax_type_code
	
		else if (@posted_flag = 0 AND (@trx_type = 4091 OR @trx_type = 4092))
			insert #doctaxdet 
			select trx.tax_type_code, tax.tax_type_desc, 
					trx.amt_gross, trx.amt_taxable, trx.amt_tax	
				from apinptax trx, aptxtype tax
				where trx.trx_ctrl_num = @trx_ctrl_num
					AND trx.tax_type_code = tax.tax_type_code
				
END
/**/                                              

GO
GRANT EXECUTE ON  [dbo].[gltc_doc_tax_det_sp] TO [public]
GO
