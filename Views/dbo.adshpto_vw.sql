SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[adshpto_vw] as 
SELECT 	
  customer_code,
  ship_to_code, 
  ship_to_name,               
  tax_code,          
  terms_code,        
  fob_code,          
  freight_code,   
  location_code,      
  dest_zone_code,    
  territory_code 	
FROM adm_shipto_all

GO
GRANT REFERENCES ON  [dbo].[adshpto_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[adshpto_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[adshpto_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[adshpto_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[adshpto_vw] TO [public]
GO
