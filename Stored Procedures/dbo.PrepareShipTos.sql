SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
              
--select * from cvo_shiptos                                      
CREATE procedure [dbo].[PrepareShipTos]                                                      
AS                                    
                      
--delete from cvo_shiptos where customer_code not in(select customer_code from arcust)                                        
                                                      
declare @customer_code varchar(15)                                   
declare @customer_code2 varchar(15)         
declare @shipto varchar(15)      
declare @slp varchar(15)      
declare @terr varchar(15)      
declare @svia varchar(15)  
declare @rxvia varchar(15)  
                                                     
DECLARE shipto_cursor CURSOR FOR                                                      
select customer_code,ship_to_code from cvo_shiptos                                                      
                                                      
OPEN shipto_cursor;                                                      
                                                      
                                                      
                                                      
FETCH NEXT FROM shipto_cursor                                                      
INTO @customer_code,@shipto;                                                      
                                                      
WHILE @@FETCH_STATUS = 0                                                      
BEGIN                                                 
          
set @customer_code2=(RIGHT(REPLICATE('0', 10) + CONVERT(VARCHAR, @customer_code), 6))          
set @terr=(select salesperson_code from cvo_shiptos where customer_code=@customer_code and ship_to_code=@shipto)      
set @slp=(select salesperson_code from cvo_shiptos where customer_code=@customer_code and ship_to_code=@shipto)      
set @svia=(select ship_via_code from cvo_shiptos where customer_code=@customer_code and ship_to_code=@shipto)      
set @rxvia=(select addr6 from cvo_shiptos where customer_code=@customer_code and ship_to_code=@shipto)      
                      
update cvo_shiptos set                        
customer_code=@customer_code2          ,                
ship_to_code=ISNULL(ship_to_code,1),          
addr3=ISNULL(addr2,''),          
addr4=ISNULL(addr4,''),          
addr5=ISNULL(addr5,''),          
--addr6=ISNULL(addr6,''),            
addr6=(select top(1) ship_via_code from cvo_shipviaxref where svia=@rxvia),  
addr2=addr1,            
addr1=address_name,            
addr_sort3='POB',                  
short_name=SUBSTRING((address_name),1,10),                                                             
tax_code=(select top(1) tax_code from arcust where customer_code=@customer_code2) ,                                      
posting_code='STD',                      
terms_code=ISNULL((select top(1) terms_code from arcust where customer_code=@customer_code2),'NET30'),                                      
territory_code=(select top(1) territory_code from cvo_territoryxref where SCODE=@terr),--(select top(1) territory_code from arcust where customer_code=@customer_code2) ,                                               
salesperson_code=(select top(1) salesperson_code from cvo_salespersonxref where SCODE=@slp),--(select top(1) salesperson_code from arcust where customer_code=@customer_code2) ,                                                 
ship_via_code=(select top(1) ship_via_code from cvo_shipviaxref where svia=@svia),                                                 
payment_code='CHECK',                                           
ship_complete_flag=(select top(1) ship_complete_flag from arcust where customer_code=@customer_code2) ,                                                 
special_instr='',                                      
valid_payer_flag=1,                                      
valid_soldto_flag=1,                                    
valid_shipto_flag=(select top(1) valid_shipto_flag from arcust where customer_code=@customer_code2) ,                                      
payer_soldto_rel_code='REPORT',                               
date_opened=(select top(1) date_opened from arcust where customer_code=@customer_code2) ,                                      
added_by_user_name=(select top(1) added_by_user_name from arcust where customer_code=@customer_code2),          
postal_code=ISNULL((
CASE
	WHEN LEN(postal_code)=9 THEN substring(postal_code,1,5)+'-'+substring(postal_code,6,4)
	ELSE postal_code
END
),0),--ISNULL(postal_code,0)         ,          
addr_sort2=ISNULL(addr_sort2,'')          
where customer_code=@customer_code and ship_to_code=@shipto             
                                                      
                                      
  FETCH NEXT FROM shipto_cursor                                                      
   INTO @customer_code,@shipto                                                      
END                                     
              
delete from cvo_shiptos where customer_code not in(select customer_code from arcust)                                        
                                 
                                                      
CLOSE shipto_cursor;                                                      
DEALLOCATE shipto_cursor; 
GO
GRANT EXECUTE ON  [dbo].[PrepareShipTos] TO [public]
GO
