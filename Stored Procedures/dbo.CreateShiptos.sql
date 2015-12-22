SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[CreateShiptos]                                                      
AS                                    
                                                      
declare @row int                  
                                      
DECLARE row_cursor CURSOR FOR                                                      
select row from cvo_shiptos                                                      
                                                      
OPEN row_cursor;                                                      
                                                      
                                                      
                                                      
FETCH NEXT FROM row_cursor                                                      
INTO @row;                                                      
                                                      
WHILE @@FETCH_STATUS = 0                                                      
BEGIN                                                 
                  
                  
declare @customer_code varchar(8), @ship_to_code varchar(8),@ship_to_short_name varchar(10),                  
@ship_to_name varchar(40), @addr1 varchar(40),@addr2 varchar(40),@addr4 varchar(40),@addr_sort3 varchar(40),                  
@contact_name varchar(40), @contact_phone varchar(20), @tlx_twx varchar(30),@tax_code varchar(8),                  
@terms_code varchar(8), @posting_code varchar(8), @territory_code varchar(8),@salesperson_code varchar(8),                  
@nat_cur_code varchar(8), @one_cur_cust smallint, @added_by_user_name varchar(40), @added_by_date datetime,                  
@city varchar(40), @state varchar(40),@country varchar(40), @country_code varchar(3),@writeoff_code varchar(8)            
,@addr_sort1 varchar(40),@addr3 varchar(40),@postal_code varchar(10)            ,@svc varchar(15)    
                  
                  
                  
set @customer_code=(select customer_code from cvo_shiptos where row=@row)                  
                  
                  
IF @customer_code in (select customer_code from arcust where customer_code=@customer_code)                  
BEGIN                  
set @ship_to_code=ISNULL((select ship_to_code from cvo_shiptos where row=@row)  ,1)                
set @ship_to_short_name=(select short_name from cvo_shiptos where row=@row)                  
set @ship_to_name=(select address_name from cvo_shiptos where row=@row)                  
set @addr1=(select addr1 from cvo_shiptos where row=@row)        
set @addr2=(select addr2 from cvo_shiptos where row=@row)                  
set @addr3=(select addr3 from cvo_shiptos where row=@row)                  
set @addr4=(select addr4 from cvo_shiptos where row=@row)            
set @addr_sort1=(select top(1) addr_sort1 from armaster_all where customer_code=@customer_code)                  
set @addr_sort3=(select addr_sort3 from cvo_shiptos where row=@row)                  
set @contact_name=(select contact_name from cvo_shiptos where row=@row)                  
set @contact_phone=ISNULL((select contact_phone from cvo_shiptos where row=@row)  ,0)                
set @tlx_twx=(select tlx_twx from cvo_shiptos where row=@row)                  
set @tax_code=(select tax_code from cvo_shiptos where row=@row)                  
set @terms_code=(select terms_code from cvo_shiptos where row=@row)                  
set @posting_code=(select posting_code from cvo_shiptos where row=@row)                  
set @territory_code=(select territory_code from cvo_shiptos where row=@row)                  
set @salesperson_code=(select salesperson_code from cvo_shiptos where row=@row)                  
set @added_by_user_name=(select added_by_user_name from cvo_shiptos where row=@row)                  
set @one_cur_cust=(select one_cur_cust from arcust where customer_code=@customer_code)                  
set @added_by_user_name=(select added_by_user_name from cvo_shiptos where row=@row)                  
set @added_by_date=(select added_by_date from arcust where customer_code=@customer_code)                  
set @city=(select city from cvo_shiptos where row=@row)                  
set @state=(select state from cvo_shiptos where row=@row)                  
set @country=(select country from cvo_shiptos where row=@row)                  
set @country_code=ISNULL((select country_code from arcust where customer_code=@customer_code),'US')                
set @writeoff_code=(select writeoff_code from arcust where customer_code=@customer_code)                  
set @postal_code=(select postal_Code from cvo_shiptos where row=@row)            
set @addr4=(@city+', '+@state+' '+@postal_code)        
set @svc=(select ship_via_code from cvo_shiptos where row=@row)        
                  
INSERT arshipto (                   
customer_code,ship_to_code,ship_to_name,ship_to_short_name,                  
addr1,addr2,addr3,addr4,addr_sort1,addr_sort3,status_type,                  
contact_name,contact_phone,tlx_twx,tax_code,terms_code,posting_code,                  
territory_code,salesperson_code,address_type,nat_cur_code,one_cur_cust,                  
added_by_user_name,added_by_date,                  
city,state,country,country_code,writeoff_code,                
addr5,addr6,                
extended_name,check_extendedname_flag,postal_code,ship_via_code                  
) VALUES (                    
@customer_code,  @ship_to_code,  @ship_to_name,  ISNULL(@ship_to_short_name,''),                 
ISNULL(@addr1,''),  ISNULL(@addr2,''),ISNULL(@addr3,''),  ISNULL(@addr4,''),@addr_sort1,  ISNULL(@addr_sort3,''),  1,                  
 @contact_name,  @contact_phone,  @tlx_twx,  @tax_code,  @terms_code,  @posting_code,                  
 @territory_code,  @salesperson_code,  1,  'USD',  @one_cur_cust,                  
  @added_by_user_name,  @added_by_date,                  
  @city,  @state,  @country,@country_code, @writeoff_code,                
'','',                
@ship_to_name,0,ISNULL(@postal_Code,0),@svc)                   
  
INSERT INTO adm_arcontacts ( customer_code, ship_to_code, contact_no, contact_code, contact_name, contact_phone, contact_email,contact_fax )   
VALUES ( @customer_code, @ship_to_code, 1, 'Main', ISNULL(@contact_name,''), ISNULL(@contact_phone,''), '',@tlx_twx )  
  
                
END                  
                  
                  
                  
                                                    
                                      
  FETCH NEXT FROM row_cursor                                                      
   INTO @row                                                      
END                                     
        
update armaster_all set valid_payer_flag=0 where address_type=1                         
                                                      
CLOSE row_cursor;                                                      
DEALLOCATE row_cursor; 
GO
GRANT EXECUTE ON  [dbo].[CreateShiptos] TO [public]
GO
