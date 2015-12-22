SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

                                           
/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                                                          


CREATE PROC [dbo].[get_company_xml_sp]   
AS

			SELECT company_id as CompanyId, company_name AS CompanyName, db_name as CompanyDB FROM CVO_Control..smcomp


GO
GRANT EXECUTE ON  [dbo].[get_company_xml_sp] TO [public]
GO
