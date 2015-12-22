SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
  
--select * from e_aropen                                                 
CREATE PROCEDURE [dbo].[CVO_LOADAR]                                                  
AS                                                  
                                                  
declare @row int                                                  
declare @OrderControlNum varchar(20)                                                  
declare @g datetime                                                  
declare @l datetime                                                  
declare @h datetime                                                  
declare @customer_code varchar(15)                                                  
declare @ship_code varchar(15)                                                  
declare @slp varchar(10)                                                  
declare @TerritoryCode varchar(10)                                                  
declare @terms varchar(12)                                                  
declare @desc varchar(30)                                                  
declare @unitprice float                                                  
declare @type varchar(2)                                                  
                                              
declare @invnum nvarchar(15)                                              
declare @amt_tax float                                              
declare @amt_freight float                                              
                          
                                                                                    
DECLARE ar_cursor CURSOR FOR                                                                                    
select row from e_aropen              
--where billcustomercode in ('500','10059','36005')                                                           
                                                                                    
OPEN ar_cursor;                                                                                    
                                                                                    
                                                                                    
                                                                                    
FETCH NEXT FROM ar_cursor                                                                                    
INTO @row;                                                                                    
                                                                                    
WHILE @@FETCH_STATUS = 0                                                                                    
BEGIN                                                     
                                                  
                                                  
set @type=(select type from e_aropen where row=@row)                                  
set @desc=(                                  
CASE                                  
 WHEN @type='I' THEN 'Converted Invoice'                                  
 WHEN @type='A' THEN 'Converted Adjustment'                                  
 ELSE 'Converted Credit'                                  
END)                                  
set @type=(                                  
CASE                                  
 WHEN @type in ('I','A') THEN 'I'                                  
 ELSE 'C'                                  
END)                                                 
set @OrderControlNum=(select invoicenumber from e_aropen where row=@row)                                                  
set @g=(select invoicedate from e_aropen where row=@row)                                                  
set @l=(select duedate from e_aropen where row=@row)                                                  
set @h=(select statementdate from e_aropen where row=@row)                                                  
set @customer_code=(select billcustomercode from e_aropen where row=@row)                                                  
set @customer_code=RIGHT(REPLICATE('0', 10) + CONVERT(VARCHAR, @customer_code), 6)                                               
set @ship_code=''--(select soldshiptocode from e_aropen where row=@row)                                                  
set @slp=(select slp from e_aropen where row=@row)                                                
set @TerritoryCode=(select top(1) CAST(territory_code AS varchar) from cvo_territoryxref where SCODE=@slp)                                                
set @slp=(select top(1) salesperson_code from cvo_salespersonxref where SCODE=@slp)                                                  
set @terms=(select top(1) terms from e_aropen where row=@row)                                                  
set @terms=ISNULL((select top(1) terms_code from cvo_termsxref where tcode=@terms),'NET30')                                                  
--set @desc='Converted Invoice'--(CONVERT(Varchar, @g)+' '+@OrderControlNum)                                                  
set @unitprice=(select baldue from e_aropen where row=@row)                                          
set @unitprice=ABS(@unitprice)                                                  
      
set @l=(                  
CASE                  
 WHEN @h='' and @g>convert(varchar,(month(@g)))+'/25/'+convert(varchar,year(@g))       
THEN convert(varchar,(month(@g)+1))+'/25/'+convert(varchar,year(@g))      
 WHEN @h='' and @g<=convert(varchar,(month(@g)))+'/25/'+convert(varchar,year(@g))       
THEN convert(varchar,(month(@g)))+'/25/'+convert(varchar,year(@g))      
 ELSE @l      
END)                                               
      
      
      
set @l=(                                
CASE                                
 WHEN @h='' THEN DATEADD(day,(select days_due from arterms where terms_code=@terms),@l)                                
 ELSE @l                                
END)        
--fix dates    
set @l=(                  
CASE                  
 WHEN @l>convert(varchar,(month(@l)))+'/25/'+convert(varchar,year(@l))       
THEN convert(varchar,(month(@l)+1))+'/25/'+convert(varchar,year(@l))      
 WHEN @l<=convert(varchar,(month(@l)))+'/25/'+convert(varchar,year(@l))       
THEN convert(varchar,(month(@l)))+'/25/'+convert(varchar,year(@l))      
 ELSE @l      
END)                                               
--end fix dates    
    
                             
--set @h=(                                
--CASE                                
-- WHEN @h='' THEN @g                                
-- ELSE @h                                
--END)                  
--set @l=(                  
--CASE                  
-- WHEN @l>convert(varchar,(month(@l)))+'/25/'+convert(varchar,year(@l))                  
--THEN convert(varchar,(month(@l)+1))+'/25/'+convert(varchar,year(@l))                  
-- ELSE convert(varchar,month(@l))+'/25/'+convert(varchar,year(@l))                  
--END)                                               
set @amt_tax=(select tax from e_aropen where row=@row)                              
set @amt_tax=ABS(@amt_tax)                                              
set @amt_freight=ISNULL((select freight from e_aropen where row=@row),0)                                              
set @amt_freight=ABS(@amt_freight)                                          
                          
                                                  
--truncate table cvo_invheader                                                  
--truncate table cvo_invdetail                                                  
                                                  
INSERT INTO [CVO].[dbo].[CVO_INVHeader]                                                  
           ([DocumentReferenceID],[DocumentType],[OrderControlNum],[DateEntered],[DateApply]                     
                                ,[DateDocument],[DateShipped],[DateRequired],[DateDue],[DateAging]           
           ,[CustomerCode],[ShipToCode],[SalesPersonCode],[TerritoryCode],[CommentCode]                                                  
           ,[FobCode],[FreightCode],[TermsCode],[FinChargeCode],[PriceCode]                                                  
   ,[DestZoneCode],[PostingCode],[RecurringFlag],[RecurringCode],[CustomerPO]                                                  
           ,[TaxCode],[TotalWeight],[AmountFreight],[HoldFlag],[HoldDescription]                                                  
           ,[CustomerAddress1],[CustomerAddress2],[CustomerAddress3],[CustomerAddress4],[CustomerAddress5]                                                  
       ,[CustomerAddress6],[ShipToAddress1],[ShipToAddress2],[ShipToAddress3],[ShipToAddress4]                                                  
           ,[ShipToAddress5],[ShipToAddress6],[AttentionName],[AttentionPhone],[SourceControlNumber]                                                
           ,[TransactionalCurrency],[HomeRateType],[OperationalRateType],[HomeRate],[OperationalRate]                                                  
           ,[HomeRateOperator],[OperationalRateOperator],[TaxCalculatedMode],[PrintedFlag],[OrganizationID])                                                  
     VALUES                                                  
           (@row,@type,@OrderControlNum,@g,@g                                                  
   ,@g,@g,@g,@l,@l                                                  
           ,@customer_code,@ship_code,@slp,@TerritoryCode,NULL                                   
           ,'DEST',NULL,@terms,NULL,NULL                                                  
           ,NULL,'STD',0,NULL,''                                                  
           ,'NOTAX',NULL,NULL,0,NULL                                                  
           ,NULL,NULL,NULL,NULL,NULL                                                  
   ,NULL,NULL,NULL,NULL,NULL                                                  
   ,NULL,NULL,NULL,NULL,@OrderControlNum                                                  
           ,'USD',NULL,NULL,NULL,NULL                                                  
   ,NULL,NULL,1,1,'CVO')                                                  
                         
                                                  
INSERT INTO [CVO].[dbo].[CVO_INVDetail]                                                  
           ([DocumentReferenceID],[SequenceID],[Location],[ItemCode],[DateEntered]                   
           ,[LineDescription],[QtyOrdered],[QtyShipped],[SalesUOMCode],[UnitPrice]                                                  
           ,[Weight],[TaxCode],[GLRevAccount],[DiscPrcFlag],[AmountDiscount]                                                  
   ,[ReturnCode],[QtyReturned],[DiscPrc],[ExtendedPrice],[GLReferenceCode]                                                  
           ,[OEFlag],[CustomerPO],[OrganizationID])                                                  
     VALUES                                                  
           (@row,1,'','',@g                                                  
           ,@desc,1,1,'EA',@unitprice                                                  
           ,NULL,'NOTAX','9999000000000',0,0                         
 ,NULL,0,0,NULL,NULL                                                  
           ,NULL,@OrderControlNum,'CVO')                                                  
                                                  
                                                
exec bows_ar_import_invoice_xml_sp 0                                 
                                              
--set @invnum=(select top (1) doc_ctrl_num from arinpchg order by doc_ctrl_num asc)                                              
                                  
set @invnum=(select top (1) doc_ctrl_num from arinpchg where Order_Ctrl_Num=@OrderControlNum)                                              
                                         
                                              
update arinpchg set amt_tax=@amt_tax,amt_freight=@amt_freight where Order_Ctrl_Num=@OrderControlNum                                               
--update arinpchg set amt_net=(amt_net+@amt_tax+@amt_freight) where Order_Ctrl_Num=@OrderControlNum   --fz rev3               
--update arinpchg set amt_due=amt_net where order_ctrl_num=@ordercontrolnum and trx_ctrl_num not like 'CM%'  --fz rev3                            
                      
update arinpchg set amt_net=(amt_net-@amt_tax-@amt_freight) where Order_Ctrl_Num=@OrderControlNum   --fz rev4                            
update arinpchg set amt_gross=(amt_net) where Order_Ctrl_Num=@OrderControlNum   --fz rev4                            
update arinpchg set amt_due=amt_net where order_ctrl_num=@ordercontrolnum and trx_ctrl_num not like 'CM%'  --fz rev4                      
update arinpcdt set unit_price=(unit_price - @amt_tax - @amt_freight),extended_price=(extended_price - @amt_tax - @amt_freight) where doc_ctrl_num = @invnum                      
                      
--select * from arinpcdt                            
                      
                              
declare @l2 int                              
set @l2=(select datediff(dd, '1/1/1753', @l) + 639906)                              
                                      
/*Fix Invoice Numbers*/                                      
declare @exten nvarchar(10)                                      
set @exten = (select count(*) from arinpchg (nolock) where doc_ctrl_num like @ordercontrolnum+'%')                                      
set @exten = @exten+1                                      
--IF @ordercontrolnum like 'CB%' or @ordercontrolnum like 'FC%'                        
--BEGIN                        
set @OrderControlNum=@OrderControlNum+'-'+@exten                                      
--END                        
update arinpchg set doc_ctrl_num = @OrderControlNum, Order_Ctrl_Num='', doc_desc=@desc, date_due=@l2 where doc_ctrl_num = @invnum                                      
update arinpcdt set doc_ctrl_num = @OrderControlNum where doc_ctrl_num = @invnum                                    
update arinpage set doc_ctrl_num = @OrderControlNum, date_due=@l2 where doc_ctrl_num = @invnum                                    
--end rev3                                    
                                  
IF @type='C'                                  
BEGIN                                  
update arinpcdt set qty_ordered=0 ,qty_shipped=0 where doc_ctrl_num = @OrderControlNum                                      
END                                              
                                                
                                              
truncate table cvo_invheader                                                  
truncate table cvo_invdetail                                                  
                                          
                                                  
  FETCH NEXT FROM ar_cursor                                                                                    
   INTO @row                                                                                    
END                                               
                            
--rev4                            
                  
update arinpage                            
   set amt_due= t1.amt_due                            
  from arinpage t2                            
inner                            
  join arinpchg t1                            
    on t2.trx_ctrl_num = t1.trx_ctrl_num                            
--end rev4                                      
--rev 5 "fix tax"                          
update arinptax                           
   set amt_tax= t3.amt_tax, amt_final_tax=t3.amt_tax                            
  from arinptax t4                            
inner                            
  join arinpchg t3   
    on t4.trx_ctrl_num = t3.trx_ctrl_num                          
--end rev5                          
                                                     
                                                                                    
CLOSE ar_cursor;                                                                                    
DEALLOCATE ar_cursor; 
GO
GRANT EXECUTE ON  [dbo].[CVO_LOADAR] TO [public]
GO
