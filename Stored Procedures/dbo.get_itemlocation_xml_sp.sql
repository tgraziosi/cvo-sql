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


	CREATE PROC [dbo].[get_itemlocation_xml_sp]   
	AS
			SELECT DISTINCT I.part_no, L.location, V.vend_sku, V.vendor_no 
				FROM vendor_sku V RIGHT OUTER JOIN 
					(inv_list L INNER JOIN inv_master I ON L.part_no = I.part_no	
									AND I.eprocurement_flag = 1 and I.status != 'R')
							 ON V.sku_no = L.part_no
	
GO
GRANT EXECUTE ON  [dbo].[get_itemlocation_xml_sp] TO [public]
GO
