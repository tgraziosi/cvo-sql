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

CREATE PROCEDURE [dbo].[IntegrateTransferRequest] (@InputXml TEXT)
AS


SELECT '$FIN_RESULTS$'
SELECT '<Description>Those are the error results</Description>'
SELECT '<ErrorList>' 

DECLARE @iError NUMERIC
DECLARE @hDoc INTEGER
DECLARE @key_table VARCHAR(30)
DECLARE @errors VARCHAR(8000)

DECLARE @TEMPreq_ship_date	DATETIME
DECLARE @TEMPcust_po VARCHAR(20)
DECLARE @TEMPlocationto VARCHAR(10)
DECLARE @TEMPlocationfrom VARCHAR(10)

DECLARE @TEMPline_no	INTEGER
DECLARE @TEMPpart_no	VARCHAR(30)
DECLARE @TEMPordered	DECIMAL(20,8)
DECLARE @TEMPuom	CHAR(2)
DECLARE @TEMPsupplier	VARCHAR(12)


CREATE TABLE #TEMPPO
(
key_table INTEGER IDENTITY(1,1),
RequiredDate INTEGER,							PONumber VARCHAR(18),						
ShipFromName VARCHAR(50),						ShipToName VARCHAR(50),
CurrencyCode VARCHAR(10),						LineNumber INTEGER,				
SupplierPartNum VARCHAR(20),					Quantity NUMERIC,
UnitOfMeasure VARCHAR(20),						Company VARCHAR(180),	
Account VARCHAR(180),							Reference VARCHAR(180),
SupplierNumber VARCHAR(30)
)

CREATE UNIQUE INDEX hist_index1
ON #TEMPPO (key_table)

CREATE UNIQUE INDEX hist_index2
ON #TEMPPO (PONumber, LineNumber, SupplierPartNum)


SET @iError = 0 
SET @errors = ''

EXEC @iError = sp_xml_preparedocument @hDoc OUTPUT, @InputXml

IF @iError <> 0 
BEGIN
	SELECT '<ErrorCode>' + CAST(@iError AS VARCHAR(10)) + '</ErrorCode>'
	SELECT '<ErrorInfo>Error trying to initialize the xml document</ErrorInfo>'
	
	GOTO EndProcedure
END

INSERT INTO #TEMPPO 
	SELECT 	[RequiredDate],
			[PONumber],
			[ShipFromName],
			[ShipToName],
			[CurrencyCode],
			[LineNumber],
			[SupplierPartNum],
			[Quantity],
			[UnitOfMeasure],
			[Company],
			[Account],
			[Reference],
			[SupplierNumber]
	FROM OPENXML (@hDoc, '/Procurement.GetTransferRequestDoc/TransferRequest', 2)
	WITH #TEMPPO

/*---VALIDATE INFORMATION--------------------------------------------------------------------------------------------------------*/

SELECT DISTINCT @TEMPcust_po = TEMP.PONumber,
		@TEMPlocationfrom = TEMP.ShipFromName,
		@TEMPlocationto = TEMP.ShipToName,
		@TEMPreq_ship_date = CASE ISNULL(TEMP.RequiredDate,0) WHEN 0 THEN GETDATE() ELSE (SELECT dateadd(day, TEMP.RequiredDate - 693596,'01/01/1900')) END
FROM #TEMPPO TEMP

EXEC adm_ep_ins_xfr_validate  @proc_po_no = @TEMPcust_po,
								@from_loc = @TEMPlocationfrom,
								@to_loc = @TEMPlocationto,
								@req_ship_date = @TEMPreq_ship_date,
								@error_description = @errors OUTPUT	

IF @errors <> '' 
BEGIN
	SELECT '<ErrorCode>Error from purchase order: ' + @TEMPcust_po + '</ErrorCode>'
	SELECT '<ErrorInfo>Those are the error getting from the purchase order ' + @TEMPcust_po + '</ErrorInfo>'
	SELECT @errors
	GOTO EndProcedure 
END


SET @key_table = 0

SELECT	@key_table = MIN(key_table)
FROM	#TEMPPO
WHERE	key_table > @key_table

WHILE @key_table IS NOT NULL
BEGIN
	SET @errors = ''

	SELECT 	@TEMPcust_po = TEMP.PONumber,
			@TEMPline_no = TEMP.LineNumber,
			@TEMPpart_no = TEMP.SupplierPartNum,
			@TEMPordered = TEMP.Quantity,
			@TEMPuom = TEMP.UnitOfMeasure,
			@TEMPsupplier = TEMP.SupplierNumber
	FROM #TEMPPO TEMP
	WHERE key_table = @key_table 

	EXEC adm_ep_ins_xfr_line_validate  @proc_po_no = @TEMPcust_po,
										@line_no = @TEMPline_no,
										@vendor_cd = @TEMPsupplier,
										@part_no = @TEMPpart_no,
										@ordered = @TEMPordered,
										@uom = @TEMPuom,
										@error_description = @errors OUTPUT	

	IF @errors <> '' 
	BEGIN
		SELECT '<ErrorCode>Error from part number: ' + @TEMPpart_no + '</ErrorCode>'
		SELECT '<ErrorInfo>Those are the error getting from validating the ' + @TEMPpart_no + ' part number information</ErrorInfo>'
		SELECT @errors

		SET @iError = 1
	END

	SELECT	@key_table = MIN(key_table)
	FROM	#TEMPPO
	WHERE	key_table > @key_table

END

IF @iError = 1
BEGIN
	GOTO EndProcedure
END

/*-------------------------------------------------------------------------------------------------------------------------------*/

SELECT DISTINCT @TEMPcust_po = TEMP.PONumber,
		@TEMPlocationfrom = TEMP.ShipFromName,
		@TEMPlocationto = TEMP.ShipToName,
		@TEMPreq_ship_date = CASE ISNULL(TEMP.RequiredDate,0) WHEN 0 THEN GETDATE() ELSE (SELECT dateadd(day, TEMP.RequiredDate - 693596,'01/01/1900')) END
FROM #TEMPPO TEMP

EXEC @iError = adm_ep_ins_xfr  @proc_po_no = @TEMPcust_po,
								@from_loc = @TEMPlocationfrom,
								@to_loc = @TEMPlocationto,
								@req_ship_date = @TEMPreq_ship_date

IF @iError <> 1
BEGIN
	RAISERROR('There was an error when trying to insert the order header',16,1)
END

/*-------------------------------WHILE-------START---*/
SET @key_table = 0

SELECT	@key_table = MIN(key_table)
FROM	#TEMPPO
WHERE	key_table > @key_table

WHILE @key_table IS NOT NULL
BEGIN
	
	SELECT 	@TEMPcust_po = TEMP.PONumber,
			@TEMPline_no = TEMP.LineNumber,
			@TEMPpart_no = TEMP.SupplierPartNum,
			@TEMPordered = TEMP.Quantity,
			@TEMPuom = TEMP.UnitOfMeasure,
			@TEMPsupplier = TEMP.SupplierNumber
	FROM #TEMPPO TEMP
	WHERE key_table = @key_table 

	EXEC @iError = adm_ep_ins_xfr_line  @proc_po_no = @TEMPcust_po,
										@line_no = @TEMPline_no,
										@vendor_cd = @TEMPsupplier,
										@part_no = @TEMPpart_no,
										@ordered = @TEMPordered,
										@uom = @TEMPuom


	IF @iError <> 1
	BEGIN
		RAISERROR('There was an error when trying to insert the order detail',16,1)
	END

	SELECT	@key_table = MIN(key_table)
	FROM	#TEMPPO
	WHERE	key_table > @key_table

END

/*-------------------------------WHILE-------END---*/

DROP TABLE #TEMPPO

EndProcedure:

SELECT '</ErrorList>'

GO
GRANT EXECUTE ON  [dbo].[IntegrateTransferRequest] TO [public]
GO
