SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--select * from cvo_soload                                                              
CREATE procedure [dbo].[cvo_loadSO]                                                                                                
AS                                                                                                
                                                                                                
declare @sonumber varchar(15), @line int, @so_no int                                                              
declare @customer_code varchar(12), @ship_to varchar(12), @carrier varchar(12), @req_date datetime                                                              
,@fob varchar(10), @terms varchar(10),@tax varchar(10),@slp varchar(10),@bo varchar(1),@note varchar(255)                                                              
,@att varchar(25),@phone numeric                                                              
        
declare @cdate datetime                                                              
declare @dnote varchar(255)                                           
declare @shipinst varchar(255)                                                         
                                                              
declare @stat varchar(1)                                                
declare @dnote2 varchar(255)                                                              
declare @part varchar(25)                                                              
declare @qty float                                                              
declare @price decimal(20,8)                                                              
declare @cat varchar(10)                                                          
declare @hold varchar(10)                                                              
declare @ext nvarchar(5)                                                       
declare @idesc nvarchar(255)                                                             
declare @lprice decimal(20,8)                          
declare @po nvarchar(15)                  
declare @sonumber2 nvarchar(20)                    
                                                        
declare @sold_to nvarchar(15)            
DECLARE so_cursor CURSOR FOR                                                                                                
select distinct order# from cvo_soload                                                              
where order# is not null                                                                                              
                                                                                                
OPEN so_cursor;                                                                                                
                                                                                                
                                                                                                
                                                                                                
FETCH NEXT FROM so_cursor                                                                                                
INTO @sonumber;                                                                                                
                                                                                                
WHILE @@FETCH_STATUS = 0                                                                                                
BEGIN                                                                                                
/*CODE*/                                                              
                                                              
set @customer_code=(select top(1) "cust #" from cvo_soload where order#=@sonumber)                                                              
set @ship_to=ISNULL((select top(1) "Ship to" from cvo_soload where order#=@sonumber),'')                                                              
set @customer_code=RIGHT(REPLICATE('0', 10) + CONVERT(VARCHAR,@customer_code), 6)  --fzambada                                 
set @ship_to=(                                                              
CASE                                                              
 WHEN @ship_to='D' THEN ''--NULL                             
 WHEN @ship_to='I' THEN ''        
 ELSE @ship_to                                                              
END)                                    
set @sold_to=(            
CASE            
 WHEN @ship_to like 'G%' THEN @customer_code--@ship_to            
 --ELSE NULL            
 ELSE @customer_code          
END)    --fzambada rev4                  
--go live      
--set @ship_to=(      
--CASE       
-- WHEN @ship_to like 'G%' THEN ''      
-- ELSE @ship_to      
--END)      
--end go live      
                         
set @carrier=(select top(1) "Ship Via" from cvo_soload where order#=@sonumber)                                                              
set @carrier=(select top (1) ship_via_code from cvo_shipviaxref where svia=@carrier)                                                              
set @so_no=(select last_no from next_order_num)+1                                                              
set @fob=ISNULL((select top(1) fob_code from armaster_all where customer_code=@customer_code),'DEST')                                                              
set @terms=ISNULL((select top(1) "Payment Terms" from cvo_soload where order#=@sonumber),1)                                                        
set @tax=(select top(1) tax_code from armaster_all where customer_code=@customer_code)                              
set @terms=ISNULL((select top(1) terms_code from cvo_termsxref where TCODE=@terms),'NET30')                                                              
set @slp=(select top(1) "SLP #" from cvo_soload where order#=@sonumber)                                                              
set @req_date=(select top(1) "Request Ship" from cvo_soload where order#=@sonumber)                                                              
set @cdate=(select top(1) "Order Date" from cvo_soload where order#=@sonumber)                                                              
set @slp=(select top(1) salesperson_code from cvo_salespersonxref where SCODE=@slp)              
set @bo=(select top(1) "BO Allowed" from cvo_soload where order#=@sonumber)                                                              
set @bo=(                                                             
CASE                                                              
 WHEN @bo='Y' THEN 1                                                              
 ELSE 2                                                              
END)                               
set @po=(select top(1) "PO #" from cvo_soload where order#=@sonumber)                                                   
set @ext=(select TOP(1) "BOSeq" from cvo_soload where order#=@sonumber)                                                        
set @note=(select TOP (1) "remarks" from cvo_soload where order#=@sonumber)                                                              
set @shipinst=ISNULL((select top(1) "message 1" from cvo_soload where order#=@sonumber),'')                                      
set @att=(select top(1) "ST Contact" from cvo_soload where order#=@sonumber)                                                              
set @phone=ISNULL((select contact_phone from armaster_all where customer_code=@customer_code and ship_to_code=@ship_to)                                                              ,0)
set @cat=(select TOP (1) "Order Type" from cvo_soload where order#=@sonumber)                                                          
set @cat=(select "Epicor Code" from cvo_xrefcategory where "megasys code"=@cat)                                                              
set @hold=(select top (1) "HOLD Type" from cvo_soload where order#=@sonumber)                                                              
set @hold=(                                                          
CASE                                 
 WHEN @hold is null THEN NULL                                                          
 ELSE ISNULL((select hold_code from adm_oehold where hold_code=@hold),'EL')                                                            
END)                                                
set @stat=(                                                          
CASE                                                
 WHEN @hold is NULL THEN 'N'                                                
 ELSE 'A'                
END)                                             
set @sonumber2=@sonumber+'-'+@ext  --fzambada rev3                               
                                                
INSERT INTO [CVO].[dbo].[CVO_TempSO]                                                              
([RequiredDate],[SONumber],[CustCode],[UsrFirstName],[UsrLastName]                                                              
,[ShipTo],[ShipToAddress1],[ShipToAddress2],[ShipToAddress3],[ShipToAddress4]                                                              
,[ShipToAddress5],[ShipToAddress6],[ShipToCity],[ShipToState],[ShipToZip]                                                              
,[OrdCountry],[TransStatus],[SoldTo],[SoldToAddress1],[SoldToAddress2]                                                              
,[SoldToAddress3],[SoldToAddress4],[SoldToAddress5],[SoldToAddress6],[Carrier]                                                              
,[Fob],[Terms],[Tax],[PostingCode],[Currency]                                                              
,[SalesPerson],[UserStatus],[Blanket],[BlanketFrom],[BlanketTo]                                                              
,[BlanketAmount],[Location],[BackOrder],[Category],[SOPriority]                                                              
,[Disc],[DeliveryDt],[ShipDt],[CancelDt],[MessageID]                               
,[Note],[Hold],[ShipInst],[Fowarder],[Freight]                                                              
,[FreightTo],[FreightType],[Consolidate],[UserDefFld1],[UserDefFld2]                                                              
,[UserDefFld3],[UserDefFld4],[UserDefFld5],[UserDefFld6],[UserDefFld7]                                                              
,[UserDefFld8],[UserDefFld9],[UserDefFld10],[UserDefFld11],[UserDefFld12]                                                              
,[Poaction],[Attention],[Phone],[AutoShip],[MultipleShip]                                                              
,[SoldToCity],[SoldToState],[SoldToZip],[SoldToCountry],[NewSO]                                                              
,[InternalSoInd])--,[key_table])                                                              
     VALUES                                           
           (@req_date,@so_no,@customer_code,NULL,NULL                                                              
           --,NULL,NULL,NULL,NULL,NULL            
   ,@ship_to,NULL,NULL,NULL,NULL                                  --fzambada rev4            
   ,NULL,NULL,NULL,NULL,NULL                                                              
   --,NULL,'N',@customer_code,NULL,NULL                                                              
--,NULL,@stat,@customer_code,NULL,NULL                              
,NULL,@stat,@sold_to,NULL,NULL --fzambada rev4                             
   ,NULL,NULL,NULL,NULL,@carrier                                                              
           ,@fob                                                              
           ,@terms --<Terms, varchar(8),>                                                              
           ,@tax --<Tax, varchar(8),>                                                              
           ,'STD' --<PostingCode, varchar(8),>                                                     
           ,'USD' --<Currency, varchar(8),>                                 
           ,@slp --<SalesPerson, varchar(8),>                                                              
           ,NULL --<UserStatus, varchar(8),>                                                              
           ,'N' --<Blanket, char(1),>                                    
           ,NULL  --<BlanketFrom, datetime,>                                                              
           ,NULL --<BlanketTo, datetime,>                                                              
           ,NULL --<BlanketAmount, float,>                                                              
   ,'001' --<Location, varchar(10),>                                                              
           ,@bo --<BackOrder, char(1),>                                                              
   ,@cat --<Category, varchar(10),>                                                              
           ,NULL --<SOPriority, char(1),>                                                              
           ,NULL --<Disc, varchar(13),>                                                              
           ,NULL --<DeliveryDt, datetime,>                                                              
           ,NULL --<ShipDt, datetime,>                                                              
           --,NULL --<CancelDt, datetime,>                                                              
,@cdate --<CancelDt, datetime,>                                                     --fzambada rev6         
           ,NULL --<MessageID, varchar(50),>                                                                         
,@Note --<Note, varchar(255),>                                                              
           ,@hold  --<Hold, varchar(10),>                                                              
           ,@shipinst --<ShipInst, varchar(255),>                                                              
           ,NULL --<Fowarder, varchar(8),>                                                      
           ,0 --<Freight, varchar(13),>                                                              
           ,NULL --<FreightTo, varchar(8),>                        
           ,NULL--<FreightType, varchar(8),>                                                              
           ,0 --<Consolidate, smallint,>                                                    
           ,@po--<UserDefFld1, varchar(255),>                                                              
           ,NULL--<UserDefFld2, varchar(255),>                              
           ,NULL --<UserDefFld3, varchar(255),>                                                              
           ,@sonumber2 --<UserDefFld4, varchar(255),>                                                           
           ,NULL--<UserDefFld5, float,>                                                             
           ,NULL--<UserDefFld6, float,>                                                              
           ,NULL--<UserDefFld7, float,>                                                              
           ,NULL--<UserDefFld8, float,>                                                              
           ,NULL--<UserDefFld9, int,>                     
           ,NULL--<UserDefFld10, int,>                                                              
           ,NULL--<UserDefFld11, int,>                                                              
           ,@ext--<UserDefFld12, int,>                                                              
           ,NULL--<Poaction, smallint,>                                                              
           ,@att --<Attention, varchar(40),>                                                    
           ,ISNULL(@Phone,0) --<Phone, varchar(20),>     
           ,NULL--<AutoShip, char(1),>                                                              
         ,NULL--<MultipleShip, char(1),>                               
           ,NULL--<SoldToCity, varchar(40),>                                                              
           ,NULL--<SoldToState, varchar(40),>                                                          
           ,NULL--<SoldToZip, varchar(15),>                             
           ,NULL--<SoldToCountry, varchar(3),>                                                              
           ,NULL--<NewSO, varchar(18),>                                                              
           ,0) --<InternalSoInd, int,>                                                    
   --,1)  --fzambada key table                                                              
                                                    
                                                              
-----Segundo Cursor                                                              
                                                              
DECLARE line_cursor CURSOR FOR                                             
select "Order Line #" from cvo_soload                                                              
where order# = @sonumber                   
and "item code" not like '!%' and "item code" not like 'ZZZ'  --fzambada rev3                  
order by "Order Line #"                                                                                    
                                                                
OPEN line_cursor;                                                                                                
                         
                                                                                            
                                                                                                
FETCH NEXT FROM line_cursor                                                                                                
INTO @line;                     
                                                                      
WHILE @@FETCH_STATUS = 0                                                                                                
BEGIN                                                                                                
/*Code*/                                                              
                                                              
set @part=(select "Item Code" from cvo_soload where order#=@sonumber and "order line #"=@line)                                                              
--set @part=(                        
--CASE                        
-- WHEN @part like '!%' THEN 'M'                        
-- WHEN @part='ZZZ' THEN 'M'                        
-- ELSE @part                        
--END)                        
set @qty=(select "Qty Ord" from cvo_soload where order#=@sonumber and "order line #"=@line)                                                               
set @price=ISNULL((select "Sell Price" from cvo_soload where order#=@sonumber and "order line #"=@line) ,0)                                                              
set @lprice=ISNULL((select "List Price" from cvo_soload where order#=@sonumber and "order line #"=@line) ,0)                                                              
set @dnote=(select "patient name" from cvo_soload where order#=@sonumber and "order line #"=@line)                                                              
set @dnote=ISNULL(@dnote,'')+' '                                  
set @dnote2=(select "tray number" from cvo_soload where order#=@sonumber and "order line #"=@line)                                                              
set @dnote=@dnote+ISNULL(@dnote2,'')                                                              
set @idesc=(select top(1) description from inv_master where part_no=@part)                                                                                                                   
                                                              
                                                              
INSERT INTO [CVO].[dbo].[CVO_TempSOD]                                                              
           ([SONumber]                                                              
           ,[LineNumber]                            
           ,[PartNo]                                                              
           ,[Type]                                                              
           ,[Quantity]                                                              
           ,[UnitOfMeasure]                                                              
           ,[Loc]                                        
 ,[ItemDescription]                            
           ,[DetailComment]                                                              
           ,[Company]                                                              
           ,[Account]                                                              
           ,[Comm]                                                              
           ,[TaxCode]                                             
  ,[Customer]                                                              
           ,[UserCount]                                                
           ,[CreatePO]                                                              
    ,[BackOrder]                                                              
           ,[Reference]                                                              
           ,[Login]                                                              
           ,[SOAction]                                
           ,[Price]                                                              
           ,[Freight]                                                              
           ,[Poaction]                                                              
       ,[ShipTo]                                                              
           ,[Fob]                                                              
           ,[Routing]                                                              
           ,[Forwarder]                                                              
           ,[ShipToRegion]                                                              
,[DestZone]                         
           ,[ItemNote])                                                  
     VALUES                                                              
           (@so_no                                                              
           ,@line                                                              
           ,@part                                                              
           ,'P' --<Type, char(1),>                                                              
           ,@qty  --<Quantity, numeric(18,0),>                                                              
           ,'EA' --<UnitOfMeasure, varchar(20),>                                     
           ,'001' --<Loc, varchar(50),>                       
           ,@idesc --<ItemDescription, varchar(255),>                                                              
           ,NULL --<DetailComment, varchar(255),>                                                              
           ,'CVO' --<Company, varchar(180),>                                                              
           ,'4000000000000' --<Account, varchar(180),>                                   
           ,NULL --<Comm, varchar(13),>                                                              
           ,@tax --<TaxCode, varchar(10),>                                      
           ,@customer_code  --<Customer, varchar(20),>                                                              
           ,NULL --<UserCount, int,>                               
           ,0  --<CreatePO, smallint,>                                                              
           ,0  --<BackOrder, char(1),>                                                
           ,NULL --<Reference, varchar(180),>                                       
           ,NULL --<Login, varchar(30),>                                                              
           ,NULL  --<SOAction, int,>                
           ,@price  --<Price, decimal(20,8),>                                                              
           ,@lprice --<Freight, decimal(20,8),>                                                              
           ,NULL --<Poaction, smallint,>                                                              
           ,NULL --<ShipTo, varchar(50),>                                                              
           ,@fob --<Fob, varchar(10),>                                                              
,@carrier --<Routing, varchar(20),>                                                              
           ,NULL --<Forwarder, varchar(10),>                                                              
           ,NULL --<ShipToRegion, varchar(10),>                                                              
           ,NULL --<DestZone, varchar(8),>                                                              
           ,@Dnote) --<ItemNote, varchar(255),>)                                                              
                                                              
                              
                                                              
                                                  
                                                              
  FETCH NEXT FROM line_cursor                                                                                                
   INTO @line                                                              
END                                                                                                
                                                                                    
CLOSE line_cursor;                                                                                                
DEALLOCATE line_cursor;               
                                                              
                                                              
--- fin segundo cursor                                                              
                                                              
                                                       
                                                              
exec integrateso_ins  7                                                          
                                                              
truncate table [CVO_TempSO]                                                              
truncate table [CVO_TempSOD]                                                    
          
                
update orders_all set sold_to='' where User_Def_Fld4=@sonumber                            
                            
--delete from cvo_soload where order#=@sonumber                                                              
                                                                   
  FETCH NEXT FROM so_cursor                                                                                                
   INTO @sonumber                                                              
END                                                                                                
                      
                            
CLOSE so_cursor;                                                                                                
DEALLOCATE so_cursor; 
GO
GRANT EXECUTE ON  [dbo].[cvo_loadSO] TO [public]
GO
