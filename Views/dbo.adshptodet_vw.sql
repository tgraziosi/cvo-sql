SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[adshptodet_vw] as 
SELECT 	
  customer_code,
  ship_to_code, 
  ship_to_name, 
  ship_to_short_name,
  addr1,             
  addr2,             
  addr3,             
  addr4,             
  addr5,             
  addr6,             
  addr_sort1,        
  addr_sort2,        
  addr_sort3,        
  status_type,       
  attention_name,    
  attention_phone,   
  contact_name,      
  contact_phone,     
  tlx_twx,           
  phone_1,           
  phone_2,           
  tax_code,          
  terms_code,        
  fob_code,          
  freight_code,      
  posting_code,      
  location_code,     
  alt_location_code, 
  dest_zone_code,    
  territory_code,    
  salesperson_code,  
  note,              
  address_type,      
  rate_type_home,    
  rate_type_oper,    
  nat_cur_code,      
  one_cur_cust,      
  added_by_user_name,
  added_by_date,     
  modified_by_user_name,
  modified_by_date,     
  city,                 
  state,                
  postal_code,          
  country,              
  remit_code,           
  forwarder_code,       
  freight_to_code,      
  route_code,           
  route_no,             
  url,                  
  special_instr,        
  guid,                 
  price_level,          
  ship_via_code 	
FROM adm_shipto_all

GO
GRANT REFERENCES ON  [dbo].[adshptodet_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[adshptodet_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[adshptodet_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[adshptodet_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[adshptodet_vw] TO [public]
GO
