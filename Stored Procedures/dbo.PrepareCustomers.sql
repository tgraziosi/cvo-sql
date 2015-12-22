SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--select postal_code,* from ztemp_customer                                                            
CREATE procedure [dbo].[PrepareCustomers]                                                                            
AS                                                                            
                                                                            
declare @customer_code varchar(15), @country varchar(15),@territory_code varchar(15),@terms_code varchar(15),                                                        
@svia varchar(15), @date varchar(15),@type varchar(50),@fcc varchar(15)                                                           
                                      
declare @cc varchar(15)                                                                            
DECLARE customer_cursor CURSOR FOR                                                                            
select customer_code from ztemp_customer                                                                            
                                                                            
OPEN customer_cursor;                                                                            
                                                                            
                                                                            
                                                                            
FETCH NEXT FROM customer_cursor                                                                            
INTO @customer_code;                                                                            
                                                                            
WHILE @@FETCH_STATUS = 0                                                                            
BEGIN                                                                            
                                                            
set @Country=(select top(1) Country from ztemp_customer where customer_code=@customer_code)                                                            
set @territory_code=(select top(1) territory_code from ztemp_customer where customer_code=@customer_code)                                                            
set @terms_code=(select top(1) terms_code from ztemp_customer where customer_code=@customer_code)                                                          
set @svia=(select top(1) ship_via_code from ztemp_customer where customer_code=@customer_code)                                                          
set @date=(select top(1) date_opened from ztemp_customer where customer_code=@customer_code)                                                             
set @cc=(select top(1) customer_code from ztemp_customer where customer_code=@customer_code)                                      
set @cc=RIGHT(REPLICATE('0', 10) + CONVERT(VARCHAR, @cc), 6)                                      
set @type=(select top(1) addr_sort1 from ztemp_customer where customer_code=@customer_code)                                
set @fcc=(select top(1) fin_chg_code from ztemp_customer where customer_code=@customer_code)                
                                                            
update ztemp_customer set                                       
customer_code=@cc,                                      
row_action=                                                             
(                                                            
 CASE                                                            
 WHEN ftp like 'Y%' THEN 1                                                            
 ELSE 0                                                            
 END                                                            
),                                                            
addr1=customer_name,                                                
addr3=ISNULL(addr3,''),                    
--addr4=SUBSTRING((ISNULL(city,'')+', '+ISNULL(state,'')+' '+ISNULL(addr6,'')),1,40),                  --Rev1 change addr4 for add3                                     
addr_sort1=ISNULL((select top(1) "Epicor Code" from cvo_xrefcusttype where type=@type),'Customer'),                                
addr_sort3='POB',                                              
address_type=0,                       
status_type=1,                                                            
tax_code=                                                        
(                                                            
 CASE                                                            
 WHEN LEN(tax_code) >0 THEN 'AVATAX'                                               
 ELSE 'NOTAX'                                                            
 END                                                            
),                                                            
posting_code='STD',                                                
terms_code=ISNULL((Select top(1) terms_code from cvo_termsxref where tcode=@terms_code),'NET30'),                                                                    
territory_code=(select top(1) territory_code from cvo_territoryxref where Scode=@territory_Code),                                                        
salesperson_code=(select top(1) Salesperson_code from cvo_salespersonxref where Scode=@territory_Code),                                                        
ship_via_code=(select top(1) ship_via_code from cvo_shipviaxref where svia=@svia),                                                        
--fin_chg_code='LATE',                                                            
fin_chg_code=(                
 CASE                
 WHEN @fcc IS NULL THEN NULL                
 ELSE 'LATE'                
 END                
),                
payment_code='CHECK',                                             
print_stmt_flag=1,                                                            
stmt_cycle_code='STMT25',                                    
invoice_copies=1,                                                            
ship_to_history=0,                                                            
check_credit_limit=                                                            
(                                                            
 CASE                                                            
 WHEN credit_limit = 0 THEN 0                                                            
 ELSE 1                                                            
 END                                                            
),                                                            
check_aging_limit=0,                                                            
aging_limit_bracket=1,                                                            
bal_fwd_flag=0,                                                            
ship_complete_flag=                                                            
(                                          
 CASE                                                            
 WHEN addr_sort2 = 'N' THEN 2                                                            
 ELSE 0     --fzambada backorder                                                            
END                                                            
),                                                            
special_instr='',                                                            
late_chg_type=0,                                                            
valid_payer_flag=                                  
(                                  
 CASE                                  
 WHEN added_by_user_name is null THEN 1                                  
 ELSE 0                                  
 END                                  
),                                                            
valid_soldto_flag=1,                                                            
valid_shipto_flag=                            
(                                                            
 CASE                                                            
 WHEN special_instr = 'Y' THEN 0                                                 
 ELSE 1                                                            
 END                                                            
),                            
                                                    
payer_soldto_rel_code='REPORT',                                                      
date_opened=(select datediff(dd, '1/1/1753', @date) + 639906),                                                            
rate_type_home='BUY',                                                            
rate_type_oper='BUY',                                          
limit_by_home=0,                                                    
fob_code='DEST',                                                            
nat_cur_code='USD',                
one_cur_cust=0,                                                            
added_by_user_name='elabarbera',                                                            
added_by_date=(select getdate()),                
postal_code=addr6,      
--(              
--CASE              
-- WHEN LEN(addr6)=9 THEN SUBSTRING(addr6,1,5)+'-'+SUBSTRING(addr6,6,4)        --rev3 Liz added logic to the source creation      
-- ELSE addr6              
--END              
--),        
addr4=SUBSTRING((ISNULL(city,'')+', '+ISNULL(state,'')+' '+ISNULL(addr6,'')),1,40),                  --Rev1 change addr4 for add3                                                                                            
country=ISNULL(country,'United States of America'),                                                            
price_level=1,                
ftp=url,     
country_code=ISNULL((select TOP(1) country_code from cvo_countryxref where cname like '%'+ RTRIM(LTRIM(@country))+'%'),'US'),                                                            
writeoff_code='BADDEBT',                                                            
consolidated_invoices=0,                  
allow_substitutes=(                  
CASE                  
 WHEN allow_substitutes = 'N'THEN 0                  
 ELSE 1                  
END),            
location_code='001'                                                   
where customer_code=@customer_code                                                                            
                                                                        
                                                            
                                                            
  FETCH NEXT FROM customer_cursor                                                                            
   INTO @customer_code                                                                            
END                                                                            
                      
                                                            
update ztemp_customer set url='',addr6='',addr_sort2=''                                                             
                                                                      
CLOSE customer_cursor;                                                                            
DEALLOCATE customer_cursor; 
GO
GRANT EXECUTE ON  [dbo].[PrepareCustomers] TO [public]
GO
