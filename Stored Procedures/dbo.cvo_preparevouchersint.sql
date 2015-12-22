SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--select * from cvo_voucherloadint                      
CREATE PROCEDURE [dbo].[cvo_preparevouchersint]                      
AS                      
                      
declare @row int                      
                      
declare @rate float    
declare @docctrl int                      
declare @pocontrol varchar(20)                      
declare @dateentered datetime                      
declare @dateapplied datetime, @datedocument datetime,@daterequired datetime, @dateaging datetime,                      
@vendorcode varchar(10), @class varchar(10)                      
declare @unitprice float                      
declare @user_trx_type_code varchar(16)                
declare @type varchar(1)        
declare @curr varchar(3)        
declare @pc varchar(10)    
                                                        
DECLARE voucher_cursor CURSOR FOR                                                        
select row from cvo_voucherloadint                                                        
                                                        
OPEN voucher_cursor;                                                        
                                                        
                                                        
                                                        
FETCH NEXT FROM voucher_cursor                                                        
INTO @row;                                                        
                                                        
WHILE @@FETCH_STATUS = 0                                                        
BEGIN                                             
                      
--set @docctrl=(select invoice from cvo_voucherloadint where row=@row)                      
set @pocontrol=(select "Inv/Cr Memo" from cvo_voucherloadint where row=@row)                      
set @dateaging=(select "due date" from cvo_voucherloadint where row=@row)                      
set @vendorcode=(select vendor from cvo_voucherloadint where row=@row)                      
set @class=ISNULL((select type from cvo_voucherloadint where row=@row),'OTHER')                      
set @unitprice=(select (balance*"CONV RATE") from cvo_voucherloadint where row=@row)                      
set @user_trx_type_code='AP'--(select Vtype from cvo_voucherloadint where row=@row)                
set @dateentered=getdate()--(select cdate from cvo_voucherloadint where row=@row)                
set @type=(select type from cvo_voucherloadint where row=@row)        
IF @type='C'        
BEGIN        
set @unitprice=@unitprice*-1        
END        
set @curr=(select curency from cvo_voucherloadint where row=@row)        
set @curr=(CASE    
   WHEN @curr='EU' THEN 'EUR'    
   WHEN @curr='JY' THEN 'YEN'    
   ELSE 'Error'    
END)    
set @pc='STD'  
--(CASE    
--   WHEN @curr='EUR' THEN 'STD-EUR'    
--   WHEN @curr='YEN' THEN 'STD-YEN'    
--   ELSE 'Error'    
--END)    
    
    
    
set @rate=(select "conv rate" from cvo_voucherloadint where row=@row)        
        
                      
insert into voucherheader (documentreferenceID,documenttype,documentcontrolnumber,pocontrolnumber,dateentered,                      
dateapplied,datedocument,daterequired,dateaging,vendorcode,transactioncurrency,homerate,homeratetype,                      
operationalrate,operationalratetype,backofficeintercompanyflag,organizationid,paytocode,classcode,user_trx_type_code)                      
values                      
(@row,'V',@pocontrol,@pocontrol,@dateentered,@dateaging,@dateentered,@dateaging,                      
@dateaging,@vendorcode,@Curr,@Rate,'BUY',1,'BUY',0,'CVO',NULL,@class,@user_trx_type_code)                      
                      
                      
select * from voucherdetail                      
insert into voucherdetail (documentreferenceid,sequenceid,qtyordered,qtyreceived,unitprice,pocontrolnumber,glexpenseaccount,                      
taskuid,expenseid,linedescription,itemcode)                      
values                      
(@row,1,1,1,@unitprice,@pocontrol,'9999000000000',0,0,'Converted Invoice','')                      
                      
exec CVO_ap_import_voucher_sp 0                      
              
truncate table voucherheader                      
truncate table voucherdetail                      
                      
  FETCH NEXT FROM voucher_cursor                                                        
   INTO @row                                                        
END                                              
                  
                  
update apinpchg set pay_to_city='',pay_to_state='',pay_to_postal_code='',pay_to_country_code=''          
where doc_ctrl_num in (select "Inv/Cr Memo" from cvo_voucherloadint)                            
          
update apinpcdt set po_orig_flag=0, item_code='' where line_desc='Converted Invoice'          
                                       
CLOSE voucher_cursor;                                                        
DEALLOCATE voucher_cursor; 
GO
GRANT EXECUTE ON  [dbo].[cvo_preparevouchersint] TO [public]
GO
