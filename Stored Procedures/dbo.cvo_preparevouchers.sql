SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--select * from cvo_voucherload                  
CREATE PROCEDURE [dbo].[cvo_preparevouchers]                  
AS                  
                  
declare @row int                  
                  
                  
declare @docctrl int                  
declare @pocontrol varchar(20)                  
declare @dateentered datetime                  
declare @dateapplied datetime, @datedocument datetime,@daterequired datetime, @dateaging datetime,                  
@vendorcode varchar(10), @class varchar(10)                  
declare @unitprice float                  
declare @user_trx_type_code varchar(16)            
declare @type varchar(1)    
declare @curr varchar(3)    
                                                    
DECLARE voucher_cursor CURSOR FOR                                                    
select row from cvo_voucherload                                                    
                                                    
OPEN voucher_cursor;                                                    
                                                    
                                                    
                                                    
FETCH NEXT FROM voucher_cursor                                                    
INTO @row;                                                    
                                                    
WHILE @@FETCH_STATUS = 0                                                    
BEGIN                                         
                  
--set @docctrl=(select invoice from cvo_voucherload where row=@row)                  
set @pocontrol=(select invoice from cvo_voucherload where row=@row)                  
set @dateaging=(select due_date from cvo_voucherload where row=@row)                  
set @vendorcode=(select vendor from cvo_voucherload where row=@row)                  
set @class=ISNULL((select vendor_type from cvo_voucherload where row=@row),'OTHER')                  
set @unitprice=(select balance from cvo_voucherload where row=@row)                  
set @user_trx_type_code=(select Vtype from cvo_voucherload where row=@row)            
set @dateentered=(select cdate from cvo_voucherload where row=@row)            
set @type=(select type from cvo_voucherload where row=@row)    
IF @type='C'    
BEGIN    
set @unitprice=@unitprice*-1    
END    
set @curr=(select top(1) nat_cur_code from apmaster_all where vendor_code=@vendorcode)    
                  
insert into voucherheader (documentreferenceID,documenttype,documentcontrolnumber,pocontrolnumber,dateentered,                  
dateapplied,datedocument,daterequired,dateaging,vendorcode,transactioncurrency,homerate,homeratetype,                  
operationalrate,operationalratetype,backofficeintercompanyflag,organizationid,paytocode,classcode,user_trx_type_code,
datedue)                  
values                  
(@row,'V',@pocontrol,@pocontrol,@dateentered,@dateaging,@dateentered,@dateaging,                  
@dateaging,@vendorcode,@Curr,1,'BUY',1,'BUY',0,'CVO',NULL,@class,@user_trx_type_code,@dateaging)                  
                  
                  
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
where doc_ctrl_num in (select invoice from cvo_voucherload)                        
      
update apinpcdt set po_orig_flag=0, item_code='' where line_desc='Converted Invoice'      
                                   
CLOSE voucher_cursor;                                                    
DEALLOCATE voucher_cursor; 
GO
GRANT EXECUTE ON  [dbo].[cvo_preparevouchers] TO [public]
GO
