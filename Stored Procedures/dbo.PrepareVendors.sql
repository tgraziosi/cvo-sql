SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--select * from ztemp_vendor                        
CREATE procedure [dbo].[PrepareVendors]                        
AS                        
                        
declare @vendor_code varchar(15),@terms_code varchar(10),@Country varchar(40),@lead int                        
                        
                        
DECLARE vendor_cursor CURSOR FOR                        
select vendor_code from ztemp_vendor                        
                        
OPEN vendor_cursor;                        
                        
                        
                        
FETCH NEXT FROM vendor_cursor                        
INTO @vendor_code;                        
                        
WHILE @@FETCH_STATUS = 0                        
BEGIN                        
                      
    
set @terms_code=(select terms_code from ztemp_vendor where vendor_code=@vendor_code)    
set @lead=(select lead_time from ztemp_vendor where vendor_code=@vendor_code)    
set @terms_code=    
( CASE    
 WHEN @terms_code is NULL THEN 'NET0'    
 ELSE 'A'    
 END    
)    
IF @terms_code='A'    
BEGIN    
set @terms_code=(    
CASE    
 WHEN @lead in (0,1,2,3,4) THEN 'NET0'    
 WHEN @lead in (5,6,7,8,9) THEN 'NET5'    
 WHEN @lead in (10,11,12,13,14) THEN 'NET10'    
 WHEN @lead < 30 THEN 'NET15'    
 WHEN @lead < 60 THEN 'NET30'     
 WHEN @lead < 90 THEN 'NET60'    
 WHEN @lead < 120 THEN 'NET90'    
 ELSE 'NET120'    
END    
)    
END     
    
--we need to do a case statement for all the values...    
            
set @Country=(select Country from ztemp_vendor where vendor_code=@vendor_code)                      
                        
update ztemp_vendor set                   
row_action=                   
( Case                         
  WHEN LEN(note) >= 0 THEN 1                         
  ELSE  0                        
    END                        
 )                        
,                --select * from ztemp_vendor        
vendor_short_name = SUBSTRING(vendor_name,1,10),                        
addr1=vendor_name,--(SUBSTRING((ISNULL(addr2,'')+','+ISNULL(addr3,'')+','+ISNULL(addr4,'')+','+ISNULL(addr5,'')+','+ISNULL(addr6,',')),1,40)),                  
addr5='',      
addr6='',      
address_type=0,                        
status_type=5,                        
tax_code='NOTAX',                        
terms_code=@terms_code, --ISNULL((Select terms_code from cvo_termsxref where tcode=@terms_code),'NET30'),        
fob_code='DEST',                    
posting_code='STD',                    
vend_class_code=(ISNULL(vend_class_code,'OTHER')),                        
branch_code='MAIN',                        
pay_to_hist_flag=0,                        
item_hist_flag=1,                        
credit_limit_flag=0,                        
credit_limit=0,                        
aging_limit_flag=0,                        
aging_limit=0,                        
restock_chg_flag=0,                        
restock_chg=0,                        
prc_flag=0,                        
flag_1099 =                         
 ( Case                         
  WHEN LEN(code_1099) >= 0 THEN 1                         
  ELSE  0                        
    END                        
 ),                        
amt_max_check=0,                    
lead_time=@lead, --ISNULL(lead_time,0),                        
one_check_flag=0,                        
dup_voucher_flag=0,                        
dup_amt_flag=0,                        
user_trx_type_code='STANDARD',                        
payment_code='CHECK',                        
limit_by_home=0,                        
rate_type_home='BUY',                        
rate_type_oper='BUY',                        
nat_cur_code='USD',                        
one_cur_vendor=0,                        
cash_acct_code='1020000000000',                        
city=addr4,                        
state=addr5,                        
postal_code=CASE
	WHEN LEN(addr6)=9 THEN substring(addr6,1,5)+'-'+substring(addr6,6,4)
	ELSE addr6
END,                  
addr4=CASE
	WHEN LEN(addr6)=9 THEN (SUBSTRING((ISNULL(addr4,'')+' '+ISNULL(addr5,'')+' '+ISNULL((substring(addr6,1,5)+'-'+substring(addr6,6,4)),'')),1,40))
	ELSE (SUBSTRING((ISNULL(addr4,'')+' '+ISNULL(addr5,'')+' '+ISNULL(addr6,'')),1,40))
END,      

country=ISNULL(country,'United States Of America'),          
freight_code ='BESTWAY',                      
country_code=ISNULL((select TOP(1) country_code from cvo_countryxref where cname like '%'+ RTRIM(LTRIM(@country))+'%'),'US'),                  
note=NULL,    
tax_id_num=code_1099                  
where vendor_code=@vendor_code                        
--print @vendor_code                        
                        
update ztemp_vendor set addr1=              
( Case                         
  WHEN LEN(addr1) = 5 THEN vendor_name                         
  ELSE  addr1              
    END                        
 ),    
code_1099=    
( Case    
  WHEN LEN(code_1099) >0 THEN 'MISC'    
  ELSE NULL    
  END    
)                        
where vendor_code=@vendor_code                         
                        
   FETCH NEXT FROM vendor_cursor                        
   INTO @vendor_code                        
END                        
                        
CLOSE vendor_cursor;                        
DEALLOCATE vendor_cursor;     
GO
GRANT EXECUTE ON  [dbo].[PrepareVendors] TO [public]
GO
