SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2002 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2002 Epicor Software Corporation, 2002    
                  All Rights Reserved                    
*/                                                


CREATE VIEW [dbo].[ibgentax_vw] AS
	SELECT 
		CONVERT(varchar(36), tax.id) id,
		CONVERT(varchar(32), hdr.trx_ctrl_num) trx_ctrl_num,
		sequence_id,
		CONVERT(varchar(16), tax_type_code) tax_type_code,
		amt_gross,
		amt_taxable,
		amt_tax,
		CONVERT(varchar(16), nat_cur_code) nat_cur_code,
		balance_oper,
		rate_oper,
		CONVERT(varchar(16), oper_currency) oper_currency,
		CONVERT(varchar(16), rate_type_oper) rate_type_oper,
		balance_home,
		rate_home,
		CONVERT(varchar(16), home_currency) home_currency,
		CONVERT(varchar(16), rate_type_home) rate_type_home
		
	FROM ibtax tax
		INNER JOIN ibhdr hdr
		ON tax.id = hdr.id
GO
GRANT REFERENCES ON  [dbo].[ibgentax_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[ibgentax_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[ibgentax_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[ibgentax_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[ibgentax_vw] TO [public]
GO
