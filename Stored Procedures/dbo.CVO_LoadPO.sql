SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--select * from ztemp_po order by PO                    
CREATE PROCEDURE [dbo].[CVO_LoadPO]                    
AS                    
                    
declare @po int                    
declare @po_code int    --Col A                    
declare @line int                    
declare @vendor_code varchar(15), --Col E                    
@date_of_order datetime,   --Col D                    
@date_order_due datetime,   --Col K                    
@part_no varchar(20),    --Col B                    
@qty_ordered float,    --Col N                    
@qty_received float,    --Col O                    
@ext_cost money,     --Col Q                    
@date int,              
@reldate datetime,            
@note varchar(255)                ,    
@curr nvarchar(4)    

truncate table [CVO_TempPO_PRE]
                    
DECLARE po_cursor CURSOR FOR                                                    
select po,line from ztemp_po                                                    
                                                    
OPEN po_cursor;                                                    
                    
                                                    
                                                    
                                                    
FETCH NEXT FROM po_cursor                                                    
INTO @po_code,@line;                                                    
                                                    
WHILE @@FETCH_STATUS = 0                                                    
BEGIN                    
---------------------                    
--Prepare Data                    
---------------------                    
                    
set @vendor_code=(select vendor from ztemp_po where PO=@PO_CODE and LINE=@line)                    
set @date_of_order=(select POCREATEDATE from ztemp_po where PO=@PO_CODE and LINE=@line)                    
set @date_order_due=(select reqdate from ztemp_po where PO=@PO_CODE and LINE=@line)                  
set @part_no=(select ITEMCODE from ztemp_po where PO=@PO_CODE and LINE=@line)                    
set @qty_ordered=(select QTYORD from ztemp_po where PO=@PO_CODE and LINE=@line)                    
set @qty_received=(select TOTREC from ztemp_po where PO=@PO_CODE and LINE=@line)                    
set @ext_cost=ISNULL((select UNITCOST from ztemp_po where PO=@PO_CODE and LINE=@line)                  ,0)  
set @reldate=(select reqdate from ztemp_po where PO=@PO_CODE and LINE=@line)                 
set @date=(select datediff(dd, '1/1/1753', @date_of_order) + 639906)                    
set @note=(select "whse remarks" from ztemp_po where PO=@PO_CODE and LINE=@line)                    
set @curr=ISNULL((select top(1) nat_cur_code from apmaster_all where vendor_code=@vendor_code),'USD')    
--Insert Lines                    
                    
INSERT INTO [CVO].[dbo].[CVO_TempPO_PRE]                    
           ([RequiredDate]                    
           ,[PONumber]                    
           ,[UsrFirstName]                    
           ,[UsrLastName]                    
           ,[ShipFromHeader]                    
           ,[ShipToAddress1]                    
           ,[ShipToAddress2]                    
           ,[ShipToAddress3]                    
           ,[ShipToAddress4]                    
           ,[ShipToCity]                    
           ,[ShipToState]                    
           ,[ShipToZip]                    
           ,[ShipToCountry]                    
           ,[OrderStatus]                    
           ,[MessageID]                    
           ,[CurrencyCode]                    
           ,[HeaderComment]                    
           ,[LineNumber]                    
           ,[SupplierPartNum]                    
           ,[Quantity]                    
           ,[UnitOfMeasure]                    
           ,[UnitPrice]                    
           ,[ShipFromName]                    
           ,[DetailComment]                    
           ,[Company]                
           ,[Account]                    
           ,[Reference]                    
           ,[Customer]              
   ,[reldate])                       VALUES                    
           (@date                    
           ,@PO_CODE                    
           ,NULL                    
           ,NULL                    
           ,'001','','','','','','',''                    
           ,'US'                    
           ,'OPEN'         
           ,NULL                    
           ,@curr                    
           ,@note                    
           ,@line                    
           ,@part_no                    
  ,@qty_ordered                    
           ,'EA'                    
           ,@ext_cost                    
           ,'001'                    
           ,'Detail'                    
           ,'CVO'                    
         ,'BC Men'                    
           ,NULL                    
           ,@vendor_code              
   ,@reldate)                    
                    
--End Insert Lines                    
                    
                    
                    
                    
                              
                    
--------------------------------                                    
  FETCH NEXT FROM po_cursor                                                    
   INTO @po_code,@line                                                    
END                                                    
                                                    
CLOSE po_cursor;                              
DEALLOCATE po_cursor;                     
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
--*******************************************                    
/*                    
declare @date int                    
                    
set @date=(select datediff(dd, '1/1/1753', GETDATE()) + 639906)                    
                    
--select * from CVO_TempPO_PRE                    
--truncate table CVO_TempPO_PRE                    
                    
INSERT INTO [CVO].[dbo].[CVO_TempPO_PRE]                    
           ([RequiredDate]                    
           ,[PONumber]                    
           ,[UsrFirstName]                    
           ,[UsrLastName]                    
           ,[ShipFromHeader]                    
           ,[ShipToAddress1]                    
           ,[ShipToAddress2]                    
           ,[ShipToAddress3]                    
           ,[ShipToAddress4]                    
           ,[ShipToCity]                    
           ,[ShipToState]                    
           ,[ShipToZip]                    
           ,[ShipToCountry]                    
           ,[OrderStatus]                    
           ,[MessageID]                    
           ,[CurrencyCode]                    
           ,[HeaderComment]                    
           ,[LineNumber]                    
           ,[SupplierPartNum]                    
           ,[Quantity]                    
           ,[UnitOfMeasure]                    
           ,[UnitPrice]                    
           ,[ShipFromName]                    
           ,[DetailComment]                    
           ,[Company]                    
           ,[Account]                    
           ,[Reference]                    
           ,[Customer])                    
     VALUES                    
           (@date                    
           ,'938109'                    
           ,NULL                    
           ,NULL                    
           ,'001','','','','','Hauppauge','NY','90210'                    
           ,'US'                    
    ,'OPEN'                    
           ,NULL                    
           ,'USD'                    
           ,'Header'                    
           ,0                    
           ,'BC666BLA5916' --BC666BLA5916    BC800                    
           ,3                    
           ,'EA'                    
           ,10                    
           ,'001'                    
        ,'Detail'                    
           ,'CVO'                    
           ,'BC Men'                    
           ,NULL                    
           ,'21STCE')                    
                    
                    
--exec CVO_PurchaseOrder                    
                    
*/
GO
GRANT EXECUTE ON  [dbo].[CVO_LoadPO] TO [public]
GO
