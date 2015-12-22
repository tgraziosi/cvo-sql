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



CREATE PROC [dbo].[input_plmulticomp_xml_sp] (@companyCode varchar(20))   
AS

				DECLARE	@ErrorDescription	varchar(30)
				SET @ErrorDescription = 'PROCESS COMPLETE'
			
				--XML TABLE
				CREATE TABLE #PLHeaderXML(
					KeyValue	int IDENTITY(1,1) NOT NULL,	
					Location		varchar(50),		CCNumber		varchar(120),	
					CurrencyCode	varchar(8),			
					SupplierNumber	varchar(20),
					SupplierName	varchar(50),		OrderID					INT,
					PONumber		varchar(18)
				)
				
				INSERT INTO #PLHeaderXML ( OrderID, SupplierNumber, Location, CurrencyCode, CCNumber, PONumber)
					select distinct OrderID, SupplierNumber, Location, CurrencyCode, CCNumber, PONumber 
						FROM #PLXML WHERE CompanyCode = @companyCode 
					
				--error handler 
				IF @@ERROR <> 0 BEGIN
						SET @ErrorDescription = 'ERROR ON PL HEADER XML'
				END
				---------------	

				DECLARE 
				@doc_receipt_num		varchar(16),		@doc_invoice_num	varchar(16),
				@first_receive			varchar(16),		@second_receive		varchar(16),
				@first_invoice			varchar(16),		@doc_receipt_mask	varchar(16),
				@doc_invoice_mask		varchar(16),		@total_mtch_trx		int,
				@total_mtch_trx_dtl		int,				@beginning_mtch_trx int,
				@beginning_receive_trx	int,				@ending_mtch_trx	int,
				@gregorian_date			int,				@Location			varchar(30),
				@random_item			float,				@max_item_num		int,
				@min_item_num			int,				@vendor_code		varchar(12),
				@count_trx_dtl			int,				@currency_code		varchar(8),
				@amt_net				float,				@error_flag			smallint,
				@account_code			varchar(32),		
				@count_receive_trx		int,				
				@count_invoice_trx		int,				@receive_all		int,
				@invoiced_full			smallint,			@source_module		varchar(3),
				@invoice_date			int,				@tax_code			varchar(8),
				@tax_percent			float,				@import_date		int,
				@freight				float,				@freight_count		int,
				@company_id				INT,				@company_name		varchar(20),
				@keyValue				INT,				@keyLineValue		INT	,
				@OrderID				INT,				@CCNumber			VARCHAR(180),
				@CurrencyCode			varchar(8),
				@AccountCode			varchar(32),		@SupplierPartNum	varchar(20),
				@LoginName				varchar(20),		@QtyAccepted		FLOAT,
				@ERROR 					INT,				@PONumber			varchar(18),
				@ReferenceCode			varchar(32),		@UnitPrice			FLOAT,
				@UnitOfMeasure			varchar(8),			@ShortDscrptn		varchar(2048),
				@ValidForMatch 			INT	,				@LineNumber				INT
				
				--Data for proccesing
				SELECT @total_mtch_trx = count(1) FROM #PLHeaderXML
				--Header Information 
				SET @invoiced_full = 0
				SET @source_module = 'PRC' 	---> 'ADM' 	/ 'PRC'

				SELECT @ValidForMatch = ValidForMatch FROM #PLXML

				
				--Getting Company Information
				SELECT @company_name = company_name, @company_id = company_id FROM glco 

				SET @receive_all = '1'			---If you want to receive all the items of the invoice or just a part 1-Yes 0-No
				--Generate multiple invoices (2 for each receive) to one invoice or make the relation fo 1 to 1


			--initialazing values for the header cycle 
			SELECT	@keyValue = 1
			SELECT  @keyValue = MIN(KeyValue) FROM  #PLHeaderXML WHERE KeyValue >= @keyValue
			--here begins the process for every PO
			WHILE @keyValue IS NOT NULL
			BEGIN
					--Getting Header Information
					Select	@OrderID = OrderID,			@vendor_code = SupplierNumber, 
							@CCNumber = CCNumber,		@CurrencyCode = CurrencyCode,
							@Location = Location,		@PONumber = PONumber 
					FROM #PLHeaderXML WHERE KeyValue = @keyValue 
					
					CREATE TABLE #TEMPCCnum
					(
						TempPO_num varchar(18),
						TempCC_num varchar(40)
					)
					
					EXEC EncDecCC @PONumber, @CCNumber
					
					SELECT @CCNumber = TempCC_num FROM #TEMPCCnum
					/*mask for CC*/
						DECLARE @CCBEGIN	as varchar(10), 
						@CCEND		as varchar(10),
						@CCMASK		as varchar(16),
						@CCLEN as int,
						@CCLENVAR as int
						SET @CCLEN = LEN(@CCNumber)
						IF @CCLEN = 16 BEGIN
											SET @CCNumber = SUBSTRING(@CCNumber,0,3) + '##-####-####-' + SUBSTRING(@CCNumber,13,4)
						END
						ELSE BEGIN
											SET @CCMASK = ''
											SET	@CCBEGIN =  SUBSTRING(@CCNumber,0,3)
											SET @CCEND =  SUBSTRING(@CCNumber,@CCLEN - 3,4)
											SET @CCLENVAR = @CCLEN - 6
											WHILE (SELECT 1 WHERE ((@CCLENVAR) > 0)) = 1
											  BEGIN 
												SET @CCMASK = @CCMASK + '#'
												SET @CCLENVAR = @CCLENVAR - 1

											END
											SET @CCNumber = @CCBEGIN + @CCMASK + @CCEND
						END
					/*mask for cc*/
					
					DROP TABLE #TEMPCCnum
					
					SELECT @tax_code = tax_code FROM apmaster WHERE vendor_code = @vendor_code
					--Gettin total lines number
					SELECT @total_mtch_trx_dtl = count(1) FROM #PLXML WHERE #PLXML.OrderID = @OrderID 


					--Data Automatic Generated
					EXEC ARGetNextControl_SP 3400, @doc_receipt_mask OUTPUT, @doc_receipt_num OUTPUT
					SET @gregorian_date = (SELECT datediff(day, '01/01/1900', getdate()) + 693596)
					SET @import_date = (SELECT datediff(day, '01/01/1900', getdate()) + 693596)
					SET @invoice_date = (SELECT datediff(day, '01/01/1900', getdate()) + 693596)

					EXEC fmtctlnm_sp @beginning_mtch_trx, @doc_invoice_mask, @doc_invoice_num OUTPUT, @error_flag OUTPUT

					/*--------------------------------------Insert Receive Header--------------------------------------*/
					INSERT epinvhdr (
							receipt_ctrl_num,			po_ctrl_num,			date_accepted,			company_id,
							company_name,				ref_name,				vendor_code,			credit_card_num,
							validated_flag,				hold_flag,				invoiced_full_flag,		nat_cur_code,
							rate_type_home,				rate_type_oper,			rate_home,				rate_oper,
							comment)
					VALUES
							(@doc_receipt_mask,			@PONumber,				@gregorian_date,		@company_id,
							 @company_name,				'',						@vendor_code,			@CCNumber,
							@ValidForMatch,				0,						@invoiced_full,			@CurrencyCode,
							'',							'',						1,						1,
							'')
					IF @@ERROR <> 0 BEGIN
						SET @ErrorDescription =  'INSERT RECIVE HEADER ERROR'
					END
					
					
					--initialazing values for the lines cycle 
					SELECT	@keyLineValue = 1, @count_trx_dtl = 0
					SELECT  @keyLineValue = MIN(KeyLineValue) FROM  #PLXML WHERE OrderID = @OrderID AND KeyLineValue >= @keyLineValue AND CompanyCode = @companyCode 
					WHILE @keyLineValue IS NOT NULL
					BEGIN
							--getting line information
							select	@SupplierPartNum = SupplierPartNum, @LoginName = LoginName, @account_code = AccountCode,
									@ReferenceCode = ReferenceCode, @QtyAccepted = QtyAccepted, @freight = EnterpriseActFreightAmt,
									@UnitPrice = UnitPrice, @ShortDscrptn = ShortDscrptn, @UnitOfMeasure = UnitOfMeasure ,
									@LineNumber = LineNumber 
								FROM #PLXML WHERE KeyLineValue = @keyLineValue AND CompanyCode = @companyCode 

							SET @count_trx_dtl = @count_trx_dtl + 1
								IF @ReferenceCode = 'NOREF' BEGIN
									SET @ReferenceCode = ''
								END
								--Insert Receive Detail for intems that not exists on backoffice 
								INSERT epinvdtl (
									receipt_detail_key,			receipt_ctrl_num,			sequence_id,			po_sequence_id,
									company_id,					company_name,				item_code,				item_desc,
									unit_price,					unit_code,					qty_received,			qty_invoiced,
									amt_invoiced,				account_code,				reference_code,			po_closed_flag,
									invoiced_full_flag,			accept_name,				acceptance_comment,		tax_code)
								SELECT 
									NEWID(),					@doc_receipt_mask,			@count_trx_dtl,			@LineNumber,
									@company_id,				@company_name,				@SupplierPartNum,		@ShortDscrptn,
									@UnitPrice,					@UnitOfMeasure,				@QtyAccepted,			0,
									@UnitPrice * @QtyAccepted,	@account_code,				@ReferenceCode,			0,
									0,							@LoginName,					'',						@tax_code								
								IF @@ERROR <> 0 BEGIN
									SET @ErrorDescription = 'INSERT RECIVE DETAIL ERROR'
								END
						SELECT  @keyLineValue = MIN(KeyLineValue) FROM  #PLXML WHERE OrderID = @OrderID AND KeyLineValue > @keyLineValue AND CompanyCode = @companyCode 	
					END
				
				INSERT #insertedTransactions (PONumber,	status)   						/* insert a tabla de resultados */
				SELECT po_ctrl_num, 	0 from epinvhdr where po_ctrl_num = @PONumber 	/* insert a tabla de resultados */
				
				SELECT  @keyValue = MIN(KeyValue) FROM  #PLHeaderXML WHERE KeyValue > @keyValue
							
			END

	
	drop table #PLHeaderXML

GO
GRANT EXECUTE ON  [dbo].[input_plmulticomp_xml_sp] TO [public]
GO
