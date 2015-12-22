SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/   


CREATE PROCEDURE [dbo].[IntegratePurchaseOrder] (@InputXml TEXT)
AS

SELECT '$FIN_RESULTS$'
SELECT '<Description>Those are the error results</Description>'
SELECT '<ErrorList>' 

DECLARE @iError NUMERIC
DECLARE @hDoc INTEGER
DECLARE @key_table VARCHAR(30)
DECLARE @errors VARCHAR(8000)

DECLARE @TEMPcust_code varchar(10)
DECLARE @TEMPreq_ship_date	DATETIME
DECLARE @TEMPcust_po VARCHAR(20)
DECLARE @TEMPattention VARCHAR(40)
DECLARE @TEMPnote VARCHAR(255)
DECLARE @TEMPlocation VARCHAR(10)
DECLARE @TEMPsold_to_addr1 VARCHAR(40)
DECLARE @TEMPsold_to_addr2 VARCHAR(40)
DECLARE @TEMPsold_to_addr3 VARCHAR(40)
DECLARE @TEMPsold_to_addr4 VARCHAR(40)
DECLARE @TEMPsold_to_addr5 VARCHAR(40)
DECLARE @TEMPsold_to_addr6 VARCHAR(40)
DECLARE @TEMPvoid_ind INTEGER
DECLARE @TEMPcurrency VARCHAR(10)

DECLARE @TEMPline_no	INTEGER
DECLARE @TEMPpart_no	VARCHAR(30)
DECLARE @TEMPordered	DECIMAL(20,8)
DECLARE @TEMPunit_price NUMERIC
DECLARE @TEMPuom	CHAR(2)
DECLARE @TEMPgl_rev_acct	VARCHAR(32)
DECLARE @TEMPreference_code	VARCHAR(32)

DECLARE @type_item	char(1)

CREATE TABLE #TEMPSO
(
key_table INTEGER IDENTITY(1,1),
RequiredDate INTEGER,							PONumber VARCHAR(18),						
UsrFirstName VARCHAR(18),						UsrLastName VARCHAR(18),				
ShipFromHeader VARCHAR(50),						ShipToAddress1 VARCHAR(50),						
ShipToAddress2 VARCHAR(50),						ShipToAddress3 VARCHAR(50),					
ShipToAddress4 VARCHAR(50),						ShipToCity VARCHAR(40),					
ShipToState VARCHAR(50),						ShipToZip CHAR(10),
ShipToCountry VARCHAR(20),						OrderStatus VARCHAR(20),						
MessageID VARCHAR(50),							CurrencyCode VARCHAR(10),
HeaderComment VARCHAR(255),						LineNumber INTEGER,				
SupplierPartNum VARCHAR(20),					Quantity NUMERIC,
UnitOfMeasure VARCHAR(20),						UnitPrice NUMERIC,
ShipFromName VARCHAR(50),						DetailComment VARCHAR(255),						
Company VARCHAR(180),							Account VARCHAR(180),							
Reference VARCHAR(180),							Customer VARCHAR(30)
)

CREATE UNIQUE INDEX hist_index1
ON #TEMPSO (key_table)

CREATE UNIQUE INDEX hist_index2
ON #TEMPSO (PONumber, LineNumber, SupplierPartNum)


SET @iError = 0 
SET @errors = ''

EXEC @iError = sp_xml_preparedocument @hDoc OUTPUT, @InputXml

IF @iError <> 0 
BEGIN
	SELECT '<ErrorCode>' + CAST(@iError AS VARCHAR(10)) + '</ErrorCode>'
	SELECT '<ErrorInfo>Error trying to initialize the xml document</ErrorInfo>'
	
	GOTO EndProcedure
END

INSERT INTO #TEMPSO 
	SELECT 	[RequiredDate],
			[PONumber],
			[UsrFirstName],
			[UsrLastName],
			[ShipFromHeader],
			[ShipToAddress1],
			[ShipToAddress2],
			[ShipToAddress3],
			[ShipToAddress4],
			[ShipToCity],
			[ShipToState],
			[ShipToZip],
			[ShipToCountry],
			[OrderStatus],
			[MessageID],
			[CurrencyCode],
			[HeaderComment],
			[LineNumber],
			[SupplierPartNum],
			[Quantity],
			[UnitOfMeasure],
			[UnitPrice],
			[ShipFromName],
			[DetailComment],
			[Company],
			[Account],
			[Reference],
			[Customer]
	FROM OPENXML (@hDoc, '/Procurement.GetPurchaseOrdersDoc/PurchaseOrders', 2)
	WITH #TEMPSO

/*---VALIDATE INFORMATION------------------------------------------------------------*/

SELECT DISTINCT @TEMPcust_po = TEMP.PONumber,
		@TEMPcust_code = TEMP.Customer,
		@TEMPreq_ship_date = CASE ISNULL(TEMP.RequiredDate,0) WHEN 0 THEN GETDATE() ELSE (SELECT dateadd(day, TEMP.RequiredDate - 693596,'01/01/1900')) END,
		@TEMPattention = TEMP.UsrFirstName + ' ' + TEMP.UsrLastName, 
		@TEMPnote = TEMP.HeaderComment,
		@TEMPcurrency = TEMP.CurrencyCode,
		@TEMPlocation = TEMP.ShipFromHeader,
		@TEMPsold_to_addr1 = TEMP.ShipToAddress1, 
		@TEMPsold_to_addr2 = TEMP.ShipToAddress2, 
		@TEMPsold_to_addr3 = TEMP.ShipToAddress3, 
		@TEMPsold_to_addr4 = TEMP.ShipToAddress4, 
		@TEMPsold_to_addr5	= TEMP.ShipToCity + ',' + TEMP.ShipToState + ',' +  TEMP.ShipToZip, 
		@TEMPsold_to_addr6 = TEMP.ShipToCountry, 
		@TEMPvoid_ind = CASE TEMP.OrderStatus WHEN 'PO Cancellation' THEN 1 ELSE 0 END
FROM #TEMPSO TEMP

EXEC adm_ep_ins_po_validate @proc_po_no = @TEMPcust_po,
							@vendor_no = @TEMPcust_code,
							@ship_to_no = @TEMPlocation,
							@curr_key =  @TEMPcurrency,
							@error_description = @errors OUTPUT	

IF @errors <> '' 
BEGIN
	SELECT '<ErrorCode>Error from purchase order: ' + @TEMPcust_po + '</ErrorCode>'
	SELECT '<ErrorInfo>Those are the error getting from the purchase order ' + @TEMPcust_po + '</ErrorInfo>'
	SELECT @errors
	GOTO EndProcedure 
END

SET @key_table = 0
SET @iError = 0

SELECT	@key_table = MIN(key_table)
FROM	#TEMPSO
WHERE	key_table > @key_table

WHILE @key_table IS NOT NULL
BEGIN
	SET @errors = ''

	SELECT 	@TEMPcust_code = TEMP.Customer,
			@TEMPcust_po = TEMP.PONumber,
			@TEMPline_no = TEMP.LineNumber,
			@TEMPlocation = TEMP.ShipFromName,
			@TEMPpart_no = TEMP.SupplierPartNum,
			@TEMPordered = TEMP.Quantity,
			@TEMPuom = TEMP.UnitOfMeasure,
			@TEMPunit_price = TEMP.UnitPrice,
			@TEMPnote = TEMP.DetailComment,
			@TEMPgl_rev_acct = TEMP.Account,
			@TEMPreference_code = TEMP.Reference
	FROM #TEMPSO TEMP
	WHERE key_table = @key_table 

	EXEC adm_ep_ins_po_line_validate   @proc_po_no = @TEMPcust_po,			
										@part_no = @TEMPpart_no,					
										@location = @TEMPlocation,				
										@unit_measure = @TEMPuom,			
										@qty_ordered = @TEMPordered,			
										@curr_cost = @TEMPunit_price,
										@error_description = @errors OUTPUT	

	IF @errors <> '' 
	BEGIN
		SELECT '<ErrorCode>Error from part number: ' + @TEMPpart_no + '</ErrorCode>'
		SELECT '<ErrorInfo>Those are the error getting from validating the ' + @TEMPpart_no + ' part number information</ErrorInfo>'
		SELECT @errors

		SET @iError = 1
	END

	SELECT	@key_table = MIN(key_table)
	FROM	#TEMPSO
	WHERE	key_table > @key_table

END

IF @iError = 1
BEGIN
	GOTO EndProcedure
END

/*-----------------------------------------------------------------------------------*/

SELECT DISTINCT @TEMPcust_po = TEMP.PONumber,
		@TEMPcust_code = TEMP.Customer,
		@TEMPreq_ship_date = CASE ISNULL(TEMP.RequiredDate,0) WHEN 0 THEN GETDATE() ELSE (SELECT dateadd(day, TEMP.RequiredDate - 693596,'01/01/1900')) END,
		@TEMPattention = TEMP.UsrFirstName + ' ' + TEMP.UsrLastName, 
		@TEMPnote = TEMP.HeaderComment,
		@TEMPcurrency = TEMP.CurrencyCode,
		@TEMPlocation = TEMP.ShipFromHeader,
		@TEMPsold_to_addr1 = TEMP.ShipToAddress1, 
		@TEMPsold_to_addr2 = TEMP.ShipToAddress2, 
		@TEMPsold_to_addr3 = TEMP.ShipToAddress3, 
		@TEMPsold_to_addr4 = TEMP.ShipToAddress4, 
		@TEMPsold_to_addr5	= TEMP.ShipToCity + ',' + TEMP.ShipToState + ',' +  TEMP.ShipToZip, 
		@TEMPsold_to_addr6 = TEMP.ShipToCountry, 
		@TEMPvoid_ind = CASE TEMP.OrderStatus WHEN 'PO Cancellation' THEN 1 ELSE 0 END
FROM #TEMPSO TEMP

EXEC @iError = adm_ep_ins_po					@proc_po_no = @TEMPcust_po,
								@vendor_no = @TEMPcust_code,
								@ship_to_no = @TEMPlocation,
								@curr_key =  @TEMPcurrency
					
IF @iError <> 1 
BEGIN
	RAISERROR('There was an error when trying to insert the order header',16,1)
END

/*-------------------------------WHILE-------START---*/
SET @key_table = 0

SELECT	@key_table = MIN(key_table)
FROM	#TEMPSO
WHERE	key_table > @key_table

WHILE @key_table IS NOT NULL
BEGIN
	SELECT 	@TEMPcust_code = TEMP.Customer,
			@TEMPcust_po = TEMP.PONumber,
			@TEMPline_no = TEMP.LineNumber,
			@TEMPlocation = TEMP.ShipFromName,
			@TEMPpart_no = TEMP.SupplierPartNum,
			@TEMPordered = TEMP.Quantity,
			@TEMPuom = TEMP.UnitOfMeasure,
			@TEMPunit_price = TEMP.UnitPrice,
			@TEMPnote = TEMP.DetailComment,
			@TEMPgl_rev_acct = TEMP.Account,
			@TEMPreference_code = TEMP.Reference
	FROM #TEMPSO TEMP
	WHERE key_table = @key_table 

	SET @type_item = 'P'

	IF NOT EXISTS (select 1  from inventory (nolock) where part_no = @TEMPpart_no and location = @TEMPlocation and void = 'N') AND
	   NOT EXISTS (select 1 from vendor_sku (nolock) where vend_sku = @TEMPpart_no and vendor_no = @TEMPcust_code)
		SET @type_item = 'M'

	EXEC @iError = adm_ep_ins_po_line   @proc_po_no = @TEMPcust_po,			
											@part_no = @TEMPpart_no,					
											@location = @TEMPlocation,				
											@unit_measure = @TEMPuom,			
											@qty_ordered = @TEMPordered,			
											@curr_cost = @TEMPunit_price,
											@type = @type_item,
											@description = @TEMPnote

	IF @iError <> 1
	BEGIN
		RAISERROR('There was an error when trying to insert the order detail',16,1)
	END
/*
	EXEC adm_ep_ins_po_rel @proc_po_no = @TEMPcust_po,
							@po_line = @TEMPline_no
							@release_date = @TEMPreq_ship_date
							@quantity = @TEMPordered

	IF @ret_status <> 0 
	BEGIN
		ROLLBACK TRANSACTION

		SET @iError = @@ERROR
	END
*/
	SELECT	@key_table = MIN(key_table)
	FROM	#TEMPSO
	WHERE	key_table > @key_table

END

/*-------------------------------WHILE-------END---*/

DROP TABLE #TEMPSO

EndProcedure:

SELECT '</ErrorList>'

GO
GRANT EXECUTE ON  [dbo].[IntegratePurchaseOrder] TO [public]
GO
