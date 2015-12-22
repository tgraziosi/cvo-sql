SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--exec cvo_loadSO_Hist
--select * from cvo_sohist (nolock)                                                          
CREATE procedure [dbo].[cvo_loadSO_Hist]                                                                                            
AS                                                                                            
                                                                                            
declare @sonumber varchar(15), @line int, @so_no int                                                          
declare @customer_code varchar(12), @ship_to varchar(12), @carrier varchar(12), @req_date datetime                                                          
,@fob varchar(10), @terms varchar(10),@tax varchar(10),@slp varchar(10),@bo varchar(1),@note varchar(255)                                                          
,@att varchar(25),@phone numeric                                ,@dateent datetime,@inv varchar(15),                          
@cpo nvarchar(20),@ot nvarchar(25),@frt float,@ns float,@list float,@qtyship float,                
@cost float                
,@comm float                          
                                                          
declare @dnote varchar(255)                                       
declare @shipinst varchar(255)                                                     
                                                          
declare @stat varchar(1)                                            
declare @dnote2 varchar(255)                                                          
declare @part varchar(25)                                                          
declare @qty float                                                          
declare @price nvarchar(25)--(20,8)                                                          
declare @cat varchar(10)                                                      
declare @hold varchar(10)                                                          
declare @ext nvarchar(2)                                                   
declare @idesc nvarchar(255)                                                         
declare @sonumber2 nvarchar(15)                          
declare @type nvarchar(3)                    
declare @soint int --fzambada rev4        
declare @promo nvarchar(15),@level nvarchar(10)            
                                               
set @soint=(select max(order_no) from cvo_orders_all_hist)                                                                                                                                                      
                 
DECLARE so_cursor CURSOR FOR                                                                                            
select distinct "order # + BOSEQ" from cvo_sohist (nolock)                                                          
where "order # + BOSEQ" is not NULL and "order # + BOSEQ" <>''                       
--and "order # + BOSEQ" = 'JC881000'                 
                                                                                            
OPEN so_cursor;                                                                                            
                                                                                            
                                                                                            
                                                                                            
FETCH NEXT FROM so_cursor                                                                                            
INTO @sonumber;                                                                                            
                                                                                            
WHILE @@FETCH_STATUS = 0                                                                                            
BEGIN                                                                                            
/*CODE*/                
            
set @soint=@soint+1                                                      
                    
set @type=(                    
CASE                    
 WHEN @sonumber like 'A%' THEN 'C'                    
 ELSE 'I'                    
END)                                                           
set @customer_code=(select top(1) "customer code" from cvo_sohist (nolock) where "order # + BOSEQ"=@sonumber)                                  
set @customer_code=RIGHT(REPLICATE('0', 10) + CONVERT(VARCHAR,@customer_code), 6)  --fzambada                                              
set @ship_to=(select top(1) "Ship ID" from cvo_sohist (nolock) where "order # + BOSEQ"=@sonumber)                                            
set @ship_to=(                                                          
CASE                                                
 WHEN @ship_to='D' THEN NULL                                                          
 ELSE @ship_to                                                          
END)                            
set @inv=(select top(1) "Invoice #" from cvo_sohist (nolock) where "order # + BOSEQ"=@sonumber)                                
set @dateent=(select top(1) "ORDER Date" from cvo_sohist (nolock) where "order # + BOSEQ"=@sonumber)                            
set @cpo=(select top(1) "Customer PO" from cvo_sohist (nolock) where "order # + BOSEQ"=@sonumber)                                            
set @ot=(select top(1) "Order Taker" from cvo_sohist (nolock) where "order # + BOSEQ"=@sonumber)                          
set @carrier=(select top(1) "SVia" from cvo_sohist (nolock) where "order # + BOSEQ"=@sonumber)                                                          
set @carrier=(select top (1) ship_via_code from cvo_shipviaxref where svia=@carrier)                                                          
set @so_no=(select last_no from next_order_num)+1                                                          
set @fob='DEST'--ISNULL((select top(1) fob_code from armaster_all where customer_code=@customer_code),'DEST')                                                          
set @terms=ISNULL((select top(1) "Terms" from cvo_sohist (nolock) where "order # + BOSEQ"=@sonumber),1)                                                    
set @tax=(select top(1) "tax code" from cvo_sohist (nolock) where "order # + BOSEQ"=@sonumber)                                                          
set @tax=(                          
CASE                          
 WHEN LEN(@tax)>0 THEN 'AVATAX'                          
 ELSE 'NOTAX'                          
END)                          
set @terms=(select top(1) terms_code from cvo_termsxref where TCODE=@terms)                                                          
set @slp=(select top(1) "SLP" from cvo_sohist (nolock) where "order # + BOSEQ"=@sonumber)                                                          
set @req_date=(select top(1) "Reg date" from cvo_sohist (nolock) where "order # + BOSEQ"=@sonumber)                                                          
--set @bo=(select top(1) "BO Allowed" from cvo_soload where order#=@sonumber)                                                          
--set @bo=(                                                         
--CASE                                                          
-- WHEN @bo='Y' THEN 1                                                          
-- ELSE 3                                                          
--END)                                                       
set @frt=(select top(1) "FRT" from cvo_sohist (nolock) where "order # + BOSEQ"=@sonumber)                                                          
set @frt=(                          
CASE                          
 WHEN @frt>0 THEN @frt                          
 ELSE 0                          
END)                          
set @ns=(select top(1) "NET SALES" from cvo_sohist (nolock) where "order # + BOSEQ"=@sonumber)                                                       
--set @ext=substring(@sonumber,7,2)--(select TOP(1) "BOSeq" from cvo_soload where order#=@sonumber)    --rev 6          
--set @sonumber2=substring(@sonumber,1,6)        
set @ext=(          
CASE WHEN @type='I' THEN substring(@sonumber,7,2)          
 ELSE substring(@sonumber,9,2)          
END)          
set @sonumber2=(          
CASE          
 WHEN @type='I' THEN substring(@sonumber,1,6)          
 ELSE substring(@sonumber,1,8)          
END)          
--fzambada rev6          
set @note=''--(select TOP (1) "remarks" from cvo_soload where order#=@sonumber)                         
set @shipinst=ISNULL((select top(1) "inv remarks" from cvo_sohist (nolock) where "order # + BOSEQ"=@sonumber),'')                                  
set @att=(select top(1) "CALLER" from cvo_sohist (nolock) where "order # + BOSEQ"=@sonumber)                                                          
set @phone=0--(select contact_phone from armaster_all where customer_code=@customer_code and ship_to_code=@ship_to)             
  
set @cat=(select TOP (1) "OrderType" from cvo_sohist (nolock) where "order # + BOSEQ"=@sonumber)                                                      
set @cat=(select "Epicor Code" from cvo_xrefcategory where "megasys code"=@cat)                                                          
        
set @promo= (select top(1) "epicor promo_id" from cvo_programsxref where         
"Epicor order type" = @cat--(select TOP (1) "OrderType" from cvo_sohist (nolock) where "order # + BOSEQ"=@sonumber)        
and SKU in (select "SKU" from cvo_sohist (nolock) where "order # + BOSEQ"=@sonumber))        
        
set @level= (select top(1) "epicor promo_level" from cvo_programsxref where         
"Epicor order type" = @cat--(select TOP (1) "OrderType" from cvo_sohist (nolock) where "order # + BOSEQ"=@sonumber)        
and SKU in (select "SKU" from cvo_sohist (nolock) where "order # + BOSEQ"=@sonumber))        
        
        
set @hold=''--(select top (1) "HOLD Type" from cvo_soload where order#=@sonumber)                        
set @list=ABS((select top(1) "list" from cvo_sohist (nolock) where "order # + BOSEQ"=@sonumber)       )                    
--set @hold=(                                                      
--CASE                                                      
-- WHEN @hold is null THEN NULL                                                   
-- ELSE ISNULL((select hold_code from adm_oehold where hold_code=@hold),'EL')                                                          
--END)                                            
--set @stat=(                                                      
--CASE                                            
-- WHEN @hold is NULL THEN 'N'                                            
-- ELSE 'A'                                            
--END)                                   
                      
IF not exists (select 1 from cvo_orders_all_hist (nolock) where order_no=@soint)--@sonumber2)                      
BEGIN                       
    
                                 
INSERT INTO [CVO].[dbo].[CVO_orders_all_hist]                                        
([order_no]         ,[ext]           ,[cust_code]           ,[ship_to]           ,[req_ship_date]                          
           ,[sch_ship_date]           ,[date_shipped]           ,[date_entered]           ,[cust_po]           ,[who_entered]                          
           ,[status]           ,[attention]           ,[phone]           ,[terms]           ,[routing]                          
           ,[special_instr]           ,[invoice_date]           ,[total_invoice]           ,[total_amt_order]           ,[salesperson]                          
           ,[tax_id]           ,[tax_perc]           ,[invoice_no]           ,[fob]          ,[freight]                          
           ,[printed]           ,[discount]           ,[label_no]           ,[cancel_date]           ,[new]                          
,User_Def_Fld4,user_category,type,User_def_fld3,User_def_fld9)                          
     VALUES          (                          
--@sonumber2,@ext,@customer_code,@ship_to,@req_date,                          
@soint,ISNULL(@ext,0),@customer_code,@ship_to,@req_date,                          
@req_date,@req_date,@dateent,@cpo,@ot,                          
'T',@att,'',@terms,@carrier,                          
@shipinst,@req_date,isnull(@list,0),ISNULL(@ns,0),@slp,  @tax,0,@inv,@fob,@frt,                          
1,(ISNULL(@list,0)-ISNULL(@ns,0)),'','',''           ,@sonumber2,                        
@cat,@type,@promo,@level --<UserDefFld4, varchar(255),>                                                       
           )                                               
       
-----Segundo Cursor                                                          
                           
DECLARE line_cursor CURSOR FOR                                                                                            
select distinct "Line" from cvo_sohist (nolock)                                                          
where "order # + BOSEQ"=@sonumber                          
order by "Line"                                                                                
                                                            
OPEN line_cursor;                                                                                            
                                                                                                                                                              
                                                                                            
FETCH NEXT FROM line_cursor                                                                                            
INTO @line;                                                                                            
                                                                  
WHILE @@FETCH_STATUS = 0                    
BEGIN                                                                                            
/*Code*/                                                          
                                                        
set @part=(select top(1) "SKU" from cvo_sohist (nolock) where "order # + BOSEQ"=@sonumber and "line"=@line)                                                          
set @qty=ABS((select top (1) "Qty Ord" from cvo_sohist (nolock) where "order # + BOSEQ"=@sonumber and "line"=@line))                               
set @qtyship=ABS((select top (1) "Qty Invoiced" from cvo_sohist (nolock) where "order # + BOSEQ"=@sonumber and "line"=@line))                    
set @price=(select top(1) "Sale Price" from cvo_sohist (nolock) where "order # + BOSEQ"=@sonumber and "line"=@line)                                                          
--set @price=(                          
--CASE                          
-- WHEN @price='' THEN 0                          
-- WHEN @price is null THEN 0                          
-- ELSE @price                          
--END)                          
--set @dnote=(select "patient name" from cvo_soload where order#=@sonumber and "order line #"=@line)                                                          
--set @dnote=ISNULL(@dnote,'')+' '                                                          
--set @dnote2=(select "tray number" from cvo_soload where order#=@sonumber and "order line #"=@line)                                                          
--set @dnote=@dnote+ISNULL(@dnote2,'')                                                          
set @idesc=(select top(1) "DESC" from cvo_sohist (nolock) where "order # + BOSEQ"=@sonumber and "line"=@line)                                                         
set @cost=(select top(1) "LIST PRICE" from cvo_sohist (nolock) where "order # + BOSEQ"=@sonumber and "line"=@line)   --fzambada rev4                
set @comm=(select top(1) "SLS CMSN" from   cvo_sohist where "order # + BOSEQ"=@sonumber and "line"=@line)                       
set @cost=(                          
CASE                           
 WHEN @cost='' THEN 0                      
 WHEN @cost is null THEN 0         
 ELSE @cost                          
END)                          
set @comm=(                          
CASE                          
 WHEN @comm='' THEN 0                          
 WHEN @comm is null THEN 0                          
 ELSE @comm                          
END)                          
                                INSERT INTO [CVO].[dbo].[cvo_ord_list_hist]                          
           ([order_no]           ,[order_ext]           ,[line_no]           ,[location]           ,[part_no]                          
           ,[description]           ,[time_entered]           ,[ordered]           ,[shipped]           ,[price]                          
           ,[status]           ,[cost]           ,[who_entered]           ,[sales_comm]           ,[uom]                          
           ,[printed]           ,[organization_id])                          
VALUES(                          
--@sonumber2,@ext,@line,'001',@part,                          
@soint,@ext,@line,'001',@part,                          
@idesc,@dateent,@qty,@qtyship,@price,                          
'T',ISNULL(@cost,0),@ot,@comm,'EA',                          
1,'CVO')                                        
         
                                                      
  FETCH NEXT FROM line_cursor                                                                                            
   INTO @line                                                        
END                                                                                            
                                                                                
CLOSE line_cursor;                                                                                            
DEALLOCATE line_cursor;                                                           
                                                          
END                      
                                              
--- fin segundo cursorg                                                          
                      select @sonumber                       
                      
--delete from cvo_sohist where "order # + BOSEQ"=@sonumber                                   
                                        
  FETCH NEXT FROM so_cursor                                                                                            
   INTO @sonumber                                                          
END                                                                                            
                                       
CLOSE so_cursor;                                                                                            
DEALLOCATE so_cursor; 
GO
GRANT EXECUTE ON  [dbo].[cvo_loadSO_Hist] TO [public]
GO
