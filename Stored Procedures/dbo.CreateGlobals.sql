SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[CreateGlobals]    
AS                      
                                        
declare @row int    
    
                      
DECLARE row_cursor CURSOR FOR                                        
select row from cvo_globalsload                                        
                                        
OPEN row_cursor;                                        
                                       
                                        
                                        
FETCH NEXT FROM row_cursor                                        
INTO @row;                                        
                                        
WHILE @@FETCH_STATUS = 0                                        
BEGIN                                   
    
    
declare @customer_code varchar(8), @ship_to_short_name varchar(10),    
@ship_to_name varchar(40), @addr1 varchar(40),@addr2 varchar(40),@addr3 varchar(40),@addr4 varchar(40),    
@city varchar(40), @state varchar(40),@postal_code nvarchar(15),@country varchar(40),@date_opened int,    
@date datetime,@contact_phone numeric,@ship_via_code varchar(15)    
    
    
set @customer_code=(select top(1) ID from cvo_globalsload where row=@row)    
IF @customer_code not in (select customer_code from armaster_all where customer_code=@customer_code)    
BEGIN    
set @ship_via_code=(select top(1) svia from cvo_globalsload where row=@row)    
set @ship_to_short_name=SUBSTRING((select top(1) NAME from cvo_globalsload where row=@row),1,10)    
set @ship_to_name=ISNULL((select top(1) NAME from cvo_globalsload where row=@row),'')    
set @addr1=ISNULL((select top(1) NAME from cvo_globalsload where row=@row),'')    
set @addr2=ISNULL((select top(1) addr1 from cvo_globalsload where row=@row),'')    
set @addr3=ISNULL((select top(1) addr2 from cvo_globalsload where row=@row),'')    
set @addr4=ISNULL((select top(1) F7 from cvo_globalsload where row=@row),'')    
set @city=ISNULL((select top(1) city from cvo_globalsload where row=@row),'')    
set @state=ISNULL((select top(1) ST from cvo_globalsload where row=@row),'')    
set @postal_code=ISNULL((select top(1) ZIP from cvo_globalsload where row=@row),0)    
set @date_opened=(select datediff(dd, '1/1/1753', GETDATE()) + 639906)    
set @date=(select getdate())    
set @contact_phone=(select top(1) tel from cvo_globalsload where row=@row)    
set @ship_via_code=ISNULL((select top(1) ship_via_code from cvo_shipviaxref where svia=@ship_via_code),'UPS1D')    
    
INSERT armaster_all (     
customer_code,address_name,short_name,    
addr1,addr2,addr3,addr4,address_type,status_type,    
print_stmt_flag,trade_disc_percent,invoice_copies,    
iv_substitution,ship_to_history,check_credit_limit,    
credit_limit,check_aging_limit,aging_limit_bracket,    
bal_fwd_flag,ship_complete_flag,db_date,late_chg_type,    
valid_payer_flag,valid_soldto_flag,valid_shipto_flag,    
across_na_flag,date_opened,added_by_user_name,added_by_date,    
limit_by_home,one_cur_cust,city,state,postal_code,    
route_no,price_level,ship_via_code,consolidated_invoices,    
delivery_days,extended_name,check_extendedname_flag,    
writeoff_code,contact_phone)     
VALUES (      
@customer_code,@ship_to_name,  @ship_to_short_name,    
@addr1,  @addr2,@addr3,@addr4,9,  1,    
0,0,0,    
0,0,0,    
0,0,0,    
0,0,0,0,    
0,0,0,    
0,@date_opened,'elabarbera',@date,    
0,0,@city,@state,@postal_code,    
0,1,@ship_via_code,1,    
0,@addr1,0,    
'BADDEBT',@contact_phone)     
END    
    
                    
  FETCH NEXT FROM row_cursor                                        
   INTO @row                                        
END    
                                        
CLOSE row_cursor;                                        
DEALLOCATE row_cursor;     
GO
GRANT EXECUTE ON  [dbo].[CreateGlobals] TO [public]
GO
