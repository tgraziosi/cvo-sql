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


CREATE PROC [dbo].[get_supplier_org_xml_sp] @from varchar(20), @to varchar(20), @action int
AS

	IF @from = "" BEGIN
		SET @from = NULL
	END
	IF @to = "" BEGIN
		SET @to = NULL
	END

		IF @action = 1 BEGIN
				select vendor_name as address_name,	vendor_code,
						addr1, addr2, addr3, addr4,
						city, state, postal_code, country_code as country,
						phone_1, url, 
						contact_name, contact_phone, contact_email, 
						attention_name, attention_phone, attention_email,
						terms_code,tlx_twx
				 from apvend where  proc_vend_flag = 1 AND (vendor_code LIKE @from OR vendor_code LIKE @to)
		END
		ELSE IF @action = 2 BEGIN
				select vendor_name as address_name,	vendor_code,
						addr1, addr2, addr3, addr4,
						city, state, postal_code, country_code as country, 
						phone_1, url, 
						contact_name, contact_phone, contact_email, 
						attention_name, attention_phone, attention_email,
						terms_code,tlx_twx
				 from apvend where  proc_vend_flag = 1 AND (vendor_code BETWEEN isnull(@from, (select min(vendor_code) from apmaster))
									and  isnull(@to, (select max(vendor_code) from apmaster)))
		END
		ELSE IF @action = 3 BEGIN
				select vendor_name as address_name,	vendor_code,
								addr1, addr2, addr3, addr4,
								city, state, postal_code, country_code as country,
								phone_1, url, 
								contact_name, contact_phone, contact_email, 
								attention_name, attention_phone, attention_email,
								terms_code,tlx_twx
						 from apvend INNER JOIN #SuppliersXML ON vendor_code = id
						 	WHERE apvend.proc_vend_flag = 1
		END


GO
GRANT EXECUTE ON  [dbo].[get_supplier_org_xml_sp] TO [public]
GO
