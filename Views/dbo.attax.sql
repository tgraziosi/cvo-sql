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


CREATE VIEW [dbo].[attax]
AS
	SELECT a.tax_code, a.tax_desc, a.tax_included_flag, a.override_flag, a.module_flag, a.tax_connect_flag, 
		a.external_tax_code, a.imported_flag
	FROM aptax a, aptxtype b, aptaxdet c 
	WHERE a.tax_connect_flag = 0 
	AND a.tax_code = c.tax_code 
	AND b.tax_type_code = c.tax_type_code 
	AND b.prc_flag = 0 
	AND b.tax_included_flag = 0 
	AND b.amt_tax = 0.0
	AND ( SELECT COUNT(1) FROM aptaxdet WHERE tax_code = a.tax_code ) = 1
/**/                                              
GO
GRANT REFERENCES ON  [dbo].[attax] TO [public]
GO
GRANT SELECT ON  [dbo].[attax] TO [public]
GO
GRANT INSERT ON  [dbo].[attax] TO [public]
GO
GRANT DELETE ON  [dbo].[attax] TO [public]
GO
GRANT UPDATE ON  [dbo].[attax] TO [public]
GO
