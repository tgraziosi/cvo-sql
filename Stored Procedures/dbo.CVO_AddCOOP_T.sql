SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--select * from ztemp_customer                        
--select * from cvo_armaster_all                        
CREATE PROCEDURE [dbo].[CVO_AddCOOP_T]                        
AS                        
                        
declare @customer_code varchar(15)                                       
declare @shipto varchar(15)                        
--                        
declare @coop_eligible char(1),                        
@coop_dollars decimal(20,8),                        
@coop_cust_rate_flag char(1),                        
@coop_cust_rate int,                        
@rx_carrier varchar(8),                        
@bo_carrier varchar(8),                        
@add_patterns varchar(1),                    
@consol_ship_flag varchar(1),              
@allow int,            
@at int,      
@printcredits nvarchar(1),      
@chargebacks nvarchar(1)                        
--                        
                                                        
DECLARE customer_cursor CURSOR FOR                                                        
select customer_code,ship_to_code from armaster where address_type in (0,1)                                                    
--select customer_code,ship_to_code from cvo_shiptos

                                                        
OPEN customer_cursor;                                                        
                                                        
                                                        
                                                        
FETCH NEXT FROM customer_cursor                                                        
INTO @customer_code,@shipto;                                                        
                                                        
WHILE @@FETCH_STATUS = 0                                                        
BEGIN                                                        
                        
                        
--IF exists (select customer_code from ztemp_customer where customer_code=@customer_code and coop_eligible='Y')                        
--BEGIN                        
                        
set @coop_eligible=(select top(1) coop_eligible from ztemp_customer where customer_code=@customer_code)                        
set @coop_dollars=(select top(1) coop_dollars from ztemp_customer where customer_code=@customer_code)                        
set @coop_cust_rate_flag=(                        
CASE                        
 WHEN (select top(1) coop_cust_rate from ztemp_customer where customer_code=@customer_code)=6 THEN 'Y'                        
 ELSE 'N'                        
END                        
)                         
set @coop_cust_rate=(select top(1) coop_cust_rate from ztemp_customer where customer_code=@customer_code)                        
IF @shipto=''            
BEGIN            
set @rx_carrier=(select top(1) rx_carrier from ztemp_customer where customer_code=@customer_code)                        
set @bo_carrier=(select top(1) bo_carrier from ztemp_customer where customer_code=@customer_code)                        
set @rx_carrier=(select top(1) ship_via_code from cvo_shipviaxref where svia=@rx_carrier)                        
set @bo_carrier=(select top(1) ship_via_code from cvo_shipviaxref where svia=@bo_carrier)                        
set @at=0            
END            
ELSE            
BEGIN            
set @rx_carrier=(select top(1) addr6 from cvo_shiptos where customer_code=@customer_code and ship_to_code=@shipto)                        
--set @bo_carrier=(select top(1) ship_via_code from cvo_shiptos where customer_code=@customer_code and ship_to_code=@shipto)                        
set @bo_carrier=(select top(1) bo_carrier from ztemp_customer where customer_code=@customer_code)                        
set @bo_carrier=(select top(1) ship_via_code from cvo_shipviaxref where svia=@bo_carrier)                        
set @at=1            
END            
set @add_patterns=(select top(1) add_patterns from ztemp_customer where customer_code=@customer_code)             
set @allow=(select top(1) allow_substitutes from ztemp_customer where customer_code=@customer_code)      
set @consol_ship_flag=(select top(1) consol_ship_flag from ztemp_customer where customer_code=@customer_code)                      
set @printcredits=(select top(1) "print credits" from ztemp_customer2 where cust#=@customer_code)                     
set @printcredits=(      
CASE      
 WHEN @printcredits='Y' THEN 1      
 ELSE 0      
END)              
set @chargebacks=(select top(1) "charge back" from ztemp_customer2 where cust#=@customer_code)      
set @chargebacks=(      
 CASE      
 WHEN @chargebacks='Y' THEN 1      
 ELSE 0      
END)              
                        
                        
INSERT INTO [CVO].[dbo].[CVO_armaster_all]                        
           ([customer_code]                        
           ,[ship_to]                        
           ,[coop_eligible]                        
           ,[coop_threshold_flag]                        
           ,[coop_threshold_amount]                        
           ,[coop_dollars]                        
           ,[coop_notes]                        
           ,[coop_cust_rate_flag]                        
           ,[coop_cust_rate]                        
           ,[coop_dollars_prev_year]                        
           ,[coop_dollars_previous]                        
           ,[rx_carrier]                        
           ,[bo_carrier]                        
           ,[add_cases]                        
           ,[add_patterns]                        
           ,[max_dollars]                        
           ,[metal_plastic]                        
           ,[suns_opticals]                        
           ,[address_type]                        
           ,[consol_ship_flag]                        
           ,[coop_redeemed]                        
           ,[allow_substitutes]                        
           ,[patterns_foo]                        
           ,[commissionable]                        
           ,[commission]      
   ,[cvo_print_cm]      
   ,[cvo_chargebacks])                        
     VALUES                    
           (@customer_Code                        
           ,@shipto                        
           ,@coop_eligible                        
           ,NULL                        
           ,NULL                        
           ,@coop_dollars                        
           ,NULL                        
           ,@coop_cust_rate_flag                        
           ,@coop_cust_rate                        
           ,NULL                        
           ,NULL                        
           ,@rx_carrier                        
           ,@bo_carrier                        
           ,'Y'                        
           ,@add_patterns                        
           ,0                        
           ,NULL                        
           ,NULL                        
       ,@at                        
           ,@consol_ship_flag  --fzambada                    
           ,NULL                        
           ,ISNULL(@allow,0)                        
           ,NULL                        
           ,NULL                        
           ,NULL      
   ,@printcredits      
   ,@chargebacks)                        
                  
                  
                  
--select @customer_code                  
--select @shipto                  
                        
                  
--END                        
                        
                       
                        
                        
                        
  FETCH NEXT FROM customer_cursor                                         
   INTO @customer_code,@shipto                                                        
END                                                        
                                                        
CLOSE customer_cursor;                                                        
DEALLOCATE customer_cursor; 
GO
GRANT EXECUTE ON  [dbo].[CVO_AddCOOP_T] TO [public]
GO
