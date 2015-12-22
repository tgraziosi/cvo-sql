SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

	
	
	
/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2008 Epicor Software Corporation, 2008    
                  All Rights Reserved                    
*/   



CREATE	PROC [dbo].[input_pl_xml_sp] (@xmlDoc ntext)   
AS

			
			--XML TABLE
			CREATE TABLE #PLXML(
				KeyLineValue	int IDENTITY(1,1) NOT NULL,	
				LineNumber		int,				QtyAccepted				float,
				Location		varchar(50),		
				PONumber		varchar(18),		CCNumber				varchar(180),
				CurrencyCode	varchar(8),			EnterpriseActFreightAmt float,
				SupplierPartNum varchar(30),		UnitOfMeasure			varchar(8),
				AccountCode		varchar(32),		UnitPrice				float,
				ExtendedPrice	float,				EnterpriseUnitPrice		float,
				SupplierNumber	varchar(20),		SupplierName			varchar(40),
				LoginName		varchar(20),		OrderID					INT,
				ReferenceCode	varchar(32),		ShortDscrptn			varchar(2048),
				CompanyCode		varchar(30),		MultyCompany			INT,
				ValidForMatch	INT
			)

			--XML TABLE
			CREATE TABLE #PLCompany(
				KeyValue	int IDENTITY(1,1) NOT NULL,	
				CompanyCode	varchar(20)
			)

			--error handler 
			CREATE TABLE #ErrorXML
			(
				Code			varchar(15),
				ErrorInfo       varchar(30)
			)
			
			--insertedTransactions 
			CREATE TABLE #insertedTransactions
			(
				PONumber	varchar(18),
				status		int
			)



			DECLARE	@ErrorDescription	varchar(30)
			SET @ErrorDescription = 'PROCESS COMPLETE'
			
			DECLARE @ret_status int, @hDoc int, @multycompany int, @keyValueCompany  int, 
			@current_db_name varchar(20), @companyCode varchar(20), @db_name varchar(20)

			EXEC @ret_status = sp_xml_preparedocument @hDoc OUTPUT, @xmlDoc  
			INSERT INTO #PLXML(
				LineNumber,			QtyAccepted,
				Location,			
				PONumber,			CCNumber,
				CurrencyCode,		EnterpriseActFreightAmt ,
				SupplierPartNum,	UnitOfMeasure,
				AccountCode,		UnitPrice,
				ExtendedPrice,		EnterpriseUnitPrice,
				SupplierNumber,		SupplierName,
				LoginName,			OrderID,
				ReferenceCode,		ShortDscrptn,
				CompanyCode,		MultyCompany,
				ValidForMatch)
			SELECT
				LineNumber,			QtyAccepted,
				Location,			
				PONumber,			CCNumber,
				CurrencyCode,		EnterpriseActFreightAmt ,
				SupplierPartNum,	UnitOfMeasure,
				AccountCode,		UnitPrice,
				ExtendedPrice,		EnterpriseUnitPrice,
				SupplierNumber,		SupplierName,
				LoginName,			OrderID,
				ReferenceCode,		ShortDscrptn,
				CompanyCode,		MultyCompany,
				ValidForMatch
			FROM OPENXML(@hDoc, '/Procurement.GetPLInvoicesDoc/PLInvoice',2)
			WITH #PLXML
			--error handler 
			IF @@ERROR <> 0 BEGIN
					SET @ErrorDescription = 'ERROR ON PL LINES XML'
			END
			---------------	
				SELECT TOP 1 @multycompany = MultyCompany FROM #PLXML
				IF @multycompany = 0 BEGIN
					INSERT INTO #PLCompany (CompanyCode)
						SELECT DISTINCT CompanyCode FROM #PLXML 
					
					SELECT	@keyValueCompany = 0

					
					SELECT  @keyValueCompany = MIN(KeyValue) 
					FROM  #PLCompany WHERE KeyValue > @keyValueCompany
					--here begins the process for every PO
					WHILE @keyValueCompany IS NOT NULL
					BEGIN
					
						SELECT 	@companyCode = CompanyCode 
						FROM	#PLCompany
						WHERE	KeyValue	= @keyValueCompany
						
						 --Getting Company DB Information
						SELECT @db_name = db_name 
						FROM CVO_Control..smcomp WHERE company_id = @companyCode
						declare @str varchar(50)
						SET @str = @db_name + "..input_plmulticomp_xml_sp '" + @companyCode + "'"	
						EXEC (@str)

						SELECT  @keyValueCompany = MIN(KeyValue) 
						FROM  #PLCompany WHERE KeyValue > @keyValueCompany
					END
				END
				ELSE BEGIN
						SET @str = 'input_plinterorg_xml'
						EXEC (@str)

				END
				SELECT PONumber,Status FROM #insertedTransactions
				

GO
GRANT EXECUTE ON  [dbo].[input_pl_xml_sp] TO [public]
GO
