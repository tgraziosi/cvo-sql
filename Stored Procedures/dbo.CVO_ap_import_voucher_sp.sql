SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[CVO_ap_import_voucher_sp]        
     @debug_level  int    
        
AS        
  DECLARE @ret_status int, @hDoc int, @Error int, @str varchar(255)        
 SELECT @ret_status = 0, @hDoc = 0        
        
 -->>>==================Create Temp Tables=================        
        
CREATE TABLE #apinpchg (        
 trx_ctrl_num  varchar(16),        
 trx_type   smallint,        
 doc_ctrl_num  varchar(16),        
 apply_to_num  varchar(16),        
 user_trx_type_code varchar(8),        
 batch_code   varchar(16),        
 po_ctrl_num   varchar(16),        
 vend_order_num  varchar(20),        
 ticket_num   varchar(20),        
 date_applied  int,        
 date_aging   int,        
 date_due   int,        
 date_doc   int,        
 date_entered  int,        
 date_received  int,        
 date_required  int,        
 date_recurring  int,        
 date_discount  int,        
 posting_code  varchar(8),        
 vendor_code   varchar(12),        
 pay_to_code   varchar(8),        
 branch_code   varchar(8),        
 class_code   varchar(8),        
 approval_code  varchar(8),        
 comment_code  varchar(8),        
 fob_code   varchar(8),        
 terms_code   varchar(8),        
 tax_code   varchar(8),        
 recurring_code  varchar(8),        
 location_code  varchar(8),        
 payment_code  varchar(8),        
 times_accrued  smallint,        
 accrual_flag  smallint,        
 drop_ship_flag  smallint,        
 posted_flag   smallint,        
 hold_flag   smallint,        
 add_cost_flag  smallint,        
 approval_flag  smallint,        
 recurring_flag  smallint,        
 one_time_vend_flag smallint,        
 one_check_flag  smallint,        
 amt_gross   float,        
 amt_discount  float,        
 amt_tax    float,        
 amt_freight   float,        
 amt_misc   float,        
 amt_net    float,        
 amt_paid   float,        
 amt_due    float,        
 amt_restock   float,        
 amt_tax_included float,        
 frt_calc_tax  float,        
 doc_desc   varchar(40),        
 hold_desc   varchar(40),        
 user_id    smallint,        
 next_serial_id  smallint,        
 pay_to_addr1  varchar(40),        
 pay_to_addr2  varchar(40),        
 pay_to_addr3  varchar(40),        
 pay_to_addr4  varchar(40),        
 pay_to_addr5  varchar(40),        
 pay_to_addr6  varchar(40),        
 attention_name  varchar(40),        
 attention_phone  varchar(30),        
 intercompany_flag smallint,        
 company_code  varchar(8),        
 cms_flag   smallint,        
 process_group_num varchar(16),        
 nat_cur_code   varchar(8),        
 rate_type_home   varchar(8),        
 rate_type_oper  varchar(8),        
 rate_home    float,        
 rate_oper   float,        
 trx_state  smallint NULL,        
 mark_flag smallint  NULL,        
 net_original_amt float,        
 org_id    varchar(30),         
 tax_freight_no_recoverable float   -->>RCGT        
        
 )        
        
CREATE TABLE #apinpcdt (        
 trx_ctrl_num   varchar(16),        
 trx_type  smallint,        
 sequence_id  int,        
 location_code  varchar(8),        
 item_code  varchar(30),        
 bulk_flag  smallint,        
 qty_ordered  float,        
 qty_received  float,        
 qty_returned  float,        
 qty_prev_returned  float,        
 approval_code   varchar(8),        
 tax_code  varchar(8),        
 return_code  varchar(8),        
 code_1099  varchar(8),        
 po_ctrl_num  varchar(16),        
 unit_code  varchar(8),        
 unit_price  float,        
 amt_discount  float,        
 amt_freight  float,        
 amt_tax  float,        
 amt_misc  float,        
 amt_extended  float,        
 calc_tax  float,        
 date_entered  int,        
 gl_exp_acct  varchar(32),        
 new_gl_exp_acct  varchar(32),        
 rma_num  varchar(20),        
 line_desc  varchar(60),    
 serial_id  int,        
 company_id  smallint,        
 iv_post_flag  smallint,        
 po_orig_flag  smallint,        
 rec_company_code  varchar(8),        
 new_rec_company_code varchar(8),        
 reference_code   varchar(32),        
 new_reference_code  varchar(32),        
 trx_state   smallint NULL,        
 mark_flag  smallint NULL,        
 org_id  varchar(30),        
 amt_nonrecoverable_tax float,  -->>RCGT        
 amt_tax_det float   -->>RCGT        
 )        
        
        
        
-->>RCGT        
CREATE TABLE #apinptaxdtl        
(        
 trx_ctrl_num varchar (16),        
 sequence_id int,         
 trx_type int,        
 tax_sequence_id int,        
 detail_sequence_id int,        
 tax_type_code varchar(8),        
 amt_taxable float,        
 amt_gross   float,        
 amt_tax float,        
 amt_final_tax float,        
 recoverable_flag int,        
 account_code varchar(32)        
)        
-->>RCGT        
        
        
        
CREATE TABLE #ewerror        
(        
 module_id smallint,        
 err_code int,        
 info1 char(32),        
 info2 char(32),        
 infoint int,        
 infofloat float,        
 flag1 smallint,        
 trx_ctrl_num char(16),        
 sequence_id int,        
 source_ctrl_num char(16),        
 extra int        
)        
        
CREATE TABLE #bows_apinpchg_link (        
 doc_reference_id varchar(128),        
 trx_ctrl_num  varchar(16),        
 new_trx_ctrl_num varchar(16),        
 trx_ctrl_num_int int IDENTITY,        
 imported_flag  int DEFAULT 0        
)        
        
create table #bows_apinptax_link (        
 doc_reference_id varchar(128),        
 trx_ctrl_num  varchar(16),        
 trx_type  smallint,        
 tax_type_code  varchar(8),        
 amt_final_tax  float,        
 tax_calculated_mode int default 0,        
 db_action  int default 0        
)        
        
CREATE TABLE #bows_aperror        
(        
 DocumentReferenceID varchar(255)  NULL,        
 ControlNumber  varchar(16)  NULL,        
 SequenceID  int   NULL,        
 err_code   int   NOT NULL,        
 err_msg   char(256)  NULL,        
 err_parameter  char(64)  NULL        
)        
        
create table #bows_psaTrx (        
 ControlNumber  varchar(16) NOT NULL,        
 TransactionType  int,        
 SequenceID  int,        
 PostedFlag  int NOT NULL DEFAULT 0,        
 ProjectCode  varchar(20) NOT NULL,        
 RevisionNum  int NULL,        
 TaskUID   int NOT NULL,        
 ExpenseTypeCode  varchar(12),        
 ResourceID  varchar(15),        
 ExpenseID  int NULL,        
 PrepaidFlag  int NOT NULL DEFAULT 0,        
 Origin   int NOT NULL DEFAULT 0,        
 ClosedFlag  int NOT NULL DEFAULT 0,        
 ProjectSiteURN  varchar(128) NULL,        
 InterCompanyFlag int NOT NULL DEFAULT 0,        
 ProjectName  varchar(60),  --rev 7        
 OpportunityCode  varchar(20),  --rev 7        
 doc_reference_id varchar(128),        
 db_action  int default 0        
)        
        
CREATE TABLE #bows_doc_notes(        
 trx_ctrl_num  varchar(16),        
 trx_type  smallint,        
 sequence_id  int null,        
 link   varchar(255) null,        
 note   varchar(255),        
 show_line_mode  int DEFAULT 0,        
 note_sequence  int IDENTITY (1,1),        
 position_mode  int DEFAULT 0,        
 mark_flag  int DEFAULT 0        
)        
--        
-- -->> XML representation tables        
-- CREATE TABLE VoucherHeader(        
--  [DocumentReferenceID] varchar(128),        
--  [DocumentType]  varchar(1),        
--  [DocumentControlNumber] varchar(16),        
--  [POControlNumber] varchar(16),        
--  [VendorOrderNumber] varchar(20),        
--  [TicketNumber]  varchar(20),        
--  [DateDocument]  varchar(19),--rev 6        
--  [DateApplied]  varchar(19),--rev 6        
--  [DateAging]  varchar(19),--rev 6        
--  [DateDue]  varchar(19),--rev 6        
--  [DateEntered]  varchar(19),--rev 6        
--  [DateReceived]  varchar(19),--rev 6        
--  [DateRequired]  varchar(19),--rev 6        
--  [DateDiscount]  varchar(19),--rev 6        
--  [PostingCode]  varchar(8),        
--  [VendorCode]  varchar(12),        
--  [BranchCode]  varchar(8),        
--  [ClassCode]  varchar(8),        
--  [CommentCode]  varchar(8),        
--  [FobCode]  varchar(8),        
--  [TermsCode]  varchar(8),        
--  [PaymentCode]  varchar(8),        
--  [TaxCode]  varchar(8),        
--  [HoldFlag]  smallint,        
--  [HoldDescription] varchar(40),        
--  [ApprovalFlag]  smallint,        
--  [RecurringFlag]  smallint,        
--  [RecurringCode]  varchar(8),        
--  [AmountFreight]  float,        
--  [AmountMisc]  float,        
--  [AmountDiscount]  float, --rev 8        
--  [DocDescription] varchar(40),        
--  [PayToCode]  varchar(8),        
--  [PayToAddress1]  varchar(40),        
--  [PayToAddress2]  varchar(40),        
--  [PayToAddress3]  varchar(40),        
--  [PayToAddress4]  varchar(40),        
--  [PayToAddress5]  varchar(40),        
--  [PayToAddress6]  varchar(40),        
--  [AttentionName]  varchar(40),        
--  [AttentionPhone] varchar(30),        
--  [TransactionCurrency] varchar(8),        
--  [HomeRateType]  varchar(8),        
--  [OperationalRateType] varchar(8),        
--  [HomeRate]  float,        
--  [OperationalRate] float,        
--  [HomeRateOperator]  varchar(1),        
--  [OperationalRateOperator] varchar(1),        
--  [CalculateTaxMode] smallint,        
--  [ApplyToControlNumber] varchar(16),        
--  [BackOfficeInterCompanyFlag] smallint,        
--  [OrganizationID]   varchar(15),        
--  [ApprovalCode]   varchar(8)        
-- )        
--        
-- CREATE TABLE VoucherDetail(        
--  [DocumentReferenceID] varchar(128),        
--  [SequenceID]  int,        
--  [QtyOrdered]  float,        
--  [QtyReceived]  float,        
--  [QtyReturned]  float,        
--  [UnitPrice]  float,        
--  [TaxCode]  varchar(8),        
--  [ReturnCode]  varchar(8),        
--  [POControlNumber] varchar(16),        
--  [AmountDiscount] float,        
--  [AmountFreight]  float,        
--  [AmountTax]  float,        
--  [AmountMisc]  float,        
--  [AmountExtended] float,        
--  [GLExpenseAccount] varchar(32),        
--  [LineDescription] varchar(60),        
--  [UOM]   varchar(8),        
--  [ItemCode]  varchar(30),        
--  [GLReferenceCode]  varchar(32),        
--  [ApprovalCode]  varchar(8),        
--  [LocationCode]  varchar(8),        
--        
--  [ProjectCode]  varchar(20),        
--  [RevisionNum]  int,        
--  [TaskUID]  int,        
--  [ExpenseTypeCode] varchar(12),        
--  [ResourceID]  varchar(15),        
--  [ExpenseID]  int,        
--  [PrepaidFlag]  int,        
--  [Origin]  int,        
--  [ClosedFlag]  int,        
--  [InterCompanyTransactionFlag] int,        
--  [ProjectSiteURN] varchar(128),        
--  [CompanyID] smallint,        
--  [RecCompanyCode] varchar(8),        
--  [OrganizationID] varchar(15)        
-- )        
--        
-- CREATE TABLE VoucherTax(        
--  [DocumentReferenceID]  varchar(128),        
--  [TaxTypeCode]   varchar(8),        
--  [BaseAmount]   float,        
--  [CalculatedTaxAmount]  float,        
--  [FinalTaxAmount]  float,        
--  [RecoverableFlag]  float,        
--  [APFooterGLTaxChartofAccount]   varchar(32),        
--  [SequenceID]   int,        
--  [DetailSequenceID]  int,        
--  [TaxIncludedFlag]  smallint,        
--  [TaxAmount]   float        
-- )        
--        
-- CREATE TABLE VoucherNotes(        
--  [DocumentReferenceID]  varchar(128),        
--  [SequenceID]   int,        
--  [Link]    varchar(255),        
--  [Note]    varchar(255),        
--  [ShowLineMode]   int        
-- )        
        
 /*        
 * Begin Rev 1        
 */        
 --Begin Rev 5        
 CREATE TABLE #txdetail (        
  control_number  varchar(16),        
  reference_number int,        
  tax_type_code  varchar(8),        
  amt_taxable   float        
 )        
         
 CREATE TABLE #txinfo_id (        
  id_col   numeric identity,         
  control_number varchar(16),         
  sequence_id  int,         
  tax_type_code varchar(8),         
  currency_code varchar(8)         
 )        
 --End Rev 5        
        
 --<<<==================Populate XML Representation Tables=================        
        
 -->>populate xml representation tables        
-- EXEC @ret_status=sp_xml_preparedocument @hDoc OUTPUT, @VoucherXml        
-- IF @ret_status<>0 BEGIN IF @debug_level>0 SELECT 'ERROR IN PREPARING XML DOCUMENT' SELECT @ret_status = 10 INSERT #bows_aperror(err_code,err_msg) SELECT -(10), 'ERROR IN PREPARING XML DOCUMENT' GOTO lbERROR_RETURN END        
--        
-- -->>populate VoucherHeader        
-- INSERT INTO VoucherHeader SELECT         
--  [DocumentReferenceID],        
--  [DocumentType],        
--  [DocumentControlNumber],        
--  [POControlNumber],        
--  [VendorOrderNumber],        
--  [TicketNumber],        
--  [DateDocument],        
--  [DateApplied],        
--  [DateAging],        
--  [DateDue],        
--  [DateEntered],        
--  [DateReceived],        
--  [DateRequired],        
--  [DateDiscount],        
--  [PostingCode],       
--  [VendorCode],        
--  [BranchCode],        
--  [ClassCode],        
--  [CommentCode],        
--  [FobCode],        
--  [TermsCode],        
--  [PaymentCode],        
--  [TaxCode],        
--  [HoldFlag],        
--  [HoldDescription],        
--  [ApprovalFlag],        
--  [RecurringFlag],        
--  [RecurringCode],        
--  [AmountFreight],        
--  [AmountMisc],        
--  [AmountDiscount], --rev 8        
--  [DocDescription],        
--  [PayToCode],        
--  [PayToAddress1],        
--  [PayToAddress2],        
--  [PayToAddress3],        
--  [PayToAddress4],        
--  [PayToAddress5],        
--  [PayToAddress6],        
--  [AttentionName],        
--  [AttentionPhone],        
--  [TransactionCurrency],        
--  [HomeRateType],        
--  [OperationalRateType],        
--  [HomeRate],        
--  [OperationalRate],        
--  [HomeRateOperator],        
--  [OperationalRateOperator],        
--  [CalculateTaxMode],        
--  [ApplyToControlNumber],        
--  [BackOfficeInterCompanyFlag],        
--  [OrganizationID],        
--  [ApprovalCode]        
-- FROM OPENXML (@hDoc, '/CreateVoucherDoc/Voucher',2)        
-- WITH VoucherHeader        
-- SELECT @Error=@@ERROR IF @Error<>0 BEGIN IF @debug_level>0 SELECT 'SQL Error during populating representation tables: VoucherHeader' SELECT @ret_status = 11 INSERT #bows_aperror(err_code,err_msg,err_parameter) SELECT -(11), 'SQL Error during populati 
 
 
   
--      
--ng representation tables: VoucherHeader', @Error GOTO lbERROR_RETURN END        
--         
-- -->>populate VoucherDetail        
-- INSERT INTO VoucherDetail SELECT         
--  [DocumentReferenceID],        
--  [SequenceID],        
--  [QtyOrdered],        
--  [QtyReceived],        
--  [QtyReturned],        
--  [UnitPrice],        
--  [TaxCode],        
--  [ReturnCode],        
--  [POControlNumber],        
--  [AmountDiscount],        
--  [AmountFreight],        
--  [AmountTax],        
--  [AmountMisc],        
--  [AmountExtended],        
--  [GLExpenseAccount],        
--  [LineDescription],        
--  [UOM],        
--  [ItemCode],        
--  [GLReferenceCode],        
--  [ApprovalCode],        
--  [LocationCode],        
--  [ProjectCode],        
--  [RevisionNum],        
--  [TaskUID],        
--  [ExpenseTypeCode],   
--  [ResourceID],        
--  [ExpenseID],        
--  [PrepaidFlag],        
--  [Origin],        
--  [ClosedFlag],        
--  [InterCompanyTransactionFlag],        
--  [ProjectSiteURN],        
--  [CompanyID],        
--  [RecCompanyCode],        
--  [OrganizationID]        
-- FROM OPENXML (@hDoc, '/CreateVoucherDoc/Voucher/VoucherDetail',2)        
-- WITH VoucherDetail        
-- SELECT @Error=@@ERROR IF @Error<>0 BEGIN IF @debug_level>0 SELECT 'SQL Error during populating representation tables: VoucherDetail' SELECT @ret_status = 12 INSERT #bows_aperror(err_code,err_msg,err_parameter) SELECT -(12), 'SQL Error during populati 
 
  
--      
--ng representation tables: VoucherDetail', @Error GOTO lbERROR_RETURN END        
--        
-- -->>populate VoucherTax        
-- INSERT INTO VoucherTax SELECT         
--  [DocumentReferenceID],        
--  [TaxTypeCode],        
--  [BaseAmount],        
--  [CalculatedTaxAmount],        
--  [FinalTaxAmount],        
--  [RecoverableFlag],        
--  [APFooterGLTaxChartofAccount],        
--  [SequenceID],        
--  [DetailSequenceID],        
--  [TaxIncludedFlag],        
--  [TaxAmount]        
-- FROM OPENXML (@hDoc, '/CreateVoucherDoc/Voucher/VoucherTaxType',2)        
-- WITH VoucherTax        
-- SELECT @Error=@@ERROR IF @Error<>0 BEGIN IF @debug_level>0 SELECT 'SQL Error during populating representation tables: VoucherTax' SELECT @ret_status = 13 INSERT #bows_aperror(err_code,err_msg,err_parameter) SELECT -(13), 'SQL Error during populating   

  
--      
--representation tables: VoucherTax', @Error GOTO lbERROR_RETURN END        
--        
-- -->>populate VoucherNotes (from header)        
-- INSERT INTO VoucherNotes SELECT        
--  [DocumentReferenceID],        
--  NULL,  --SequenceID        
--  [Link],        
--  [Note],        
--  ISNULL([ShowLineMode],0)        
-- FROM OPENXML (@hDoc, '/CreateVoucherDoc/Voucher/VoucherNotes',2)        
-- WITH VoucherNotes        
-- ORDER BY [DocumentReferenceID]        
-- SELECT @Error=@@ERROR IF @Error<>0 BEGIN IF @debug_level>0 SELECT 'SQL Error during populating representation tables: #VoucherXmlNotes' SELECT @ret_status = 14 INSERT #bows_aperror(err_code,err_msg,err_parameter) SELECT -(14), 'SQL Error during populatin    
--      
--g representation tables: #VoucherXmlNotes', @Error GOTO lbERROR_RETURN END        
--        
-- -->>populate VoucherNotes (from detail)        
-- INSERT INTO VoucherNotes SELECT        
--  [DocumentReferenceID],        
--  [SequenceID],        
--  [Link],        
--  [Note],        
--  ISNULL([ShowLineMode],1)        
-- FROM OPENXML (@hDoc, '/CreateVoucherDoc/Voucher/VoucherDetail/VoucherDetailNotes',2)        
-- WITH VoucherNotes        
-- ORDER BY [DocumentReferenceID],[SequenceID]        
-- SELECT @Error=@@ERROR IF @Error<>0 BEGIN IF @debug_level>0 SELECT 'SQL Error during populating representation tables: #VoucherXmlNotes' SELECT @ret_status = 15 INSERT #bows_aperror(err_code,err_msg,err_parameter) SELECT -(15), 'SQL Error during populatin    
--      
--g representation tables: #VoucherXmlNotes', @Error GOTO lbERROR_RETURN END        
--        
-- --release XML document        
-- IF @hDoc<>0 EXEC sp_xml_removedocument @hDoc        
--         
 /*        
 * End Rev 1        
 */        
         
 --<<<==================Populate Temp Tables=================        
        
 -->>validate no duplicates in header        
 SELECT @str=[DocumentReferenceID]        
 FROM VoucherHeader  --Rev 1        
 GROUP BY [DocumentReferenceID]        
 HAVING (Count([DocumentReferenceID])>1) AND (NOT [DocumentReferenceID] IS NULL)        
 IF @@rowcount>0 BEGIN IF @debug_level>0 SELECT 'Duplicate DocumentReferenceID in header' SELECT @ret_status = 20 INSERT #bows_aperror(err_code,err_msg) SELECT -(20), 'Duplicate DocumentReferenceID in header' GOTO lbERROR_RETURN END        
        
 -->>validate rate and operators        
 SELECT 1        
 FROM VoucherHeader  --Rev 1        
 WHERE  ((ISNULL([HomeRateOperator],'')='/') AND (ISNULL(HomeRate,1.0)=0.0))        
 OR ((ISNULL([OperationalRateOperator],'')='/') AND (ISNULL(OperationalRate,1.0)=0.0))        
 IF @@rowcount>0 BEGIN IF @debug_level>0 SELECT 'Invalid zero rate for division' SELECT @ret_status = 30 INSERT #bows_aperror(err_code,err_msg) SELECT -(30), 'Invalid zero rate for division' GOTO lbERROR_RETURN END        
        
 -->>prepare link temp table        
 INSERT INTO #bows_apinpchg_link(        
  doc_reference_id        
 )        
 SELECT        
  [DocumentReferenceID]        
 FROM VoucherHeader  --Rev 1        
 SELECT @Error=@@ERROR IF @Error<>0 BEGIN IF @debug_level>0 SELECT 'SQL Error during preparing link data' SELECT @ret_status = 40 INSERT #bows_aperror(err_code,err_msg,err_parameter) SELECT -(40), 'SQL Error during preparing link data', @Error GOTO lbERROR_RETURN END        
        
 -->> set string control number        
 UPDATE  #bows_apinpchg_link        
  SET  trx_ctrl_num = 'VIMP$'+Convert(varchar(16),trx_ctrl_num_int),        
  new_trx_ctrl_num = 'VIMP$'+Convert(varchar(16),trx_ctrl_num_int)        
 SELECT @Error=@@ERROR IF @Error<>0 BEGIN IF @debug_level>0 SELECT 'SQL Error during setting of link control' SELECT @ret_status = 50 INSERT #bows_aperror(err_code,err_msg,err_parameter) SELECT -(50), 'SQL Error during setting of link control', @Error GOTO lbERROR_RETURN END        
         
 -->> validate if interbranch processing is enabled        
 DECLARE @ib_flag int, @org_id varchar(30)        
 SELECT @ib_flag = ib_flag FROM glco        
 SELECT @org_id = organization_id FROM Organization WHERE outline_num = '1'        
        
 -->>prepare header temp table        
 INSERT INTO #apinpchg(        
  trx_ctrl_num,        
  trx_type,        
  doc_ctrl_num,        
  apply_to_num,        
  user_trx_type_code,        
  batch_code,        
  po_ctrl_num,        
  vend_order_num,        
  ticket_num,        
  date_applied,        
  date_aging,        
  date_due,        
  date_doc,        
  date_entered,        
  date_received,        
  date_required,        
  date_recurring,        
  date_discount,        
  posting_code,        
  vendor_code,        
  pay_to_code,        
  branch_code,        
class_code,        
  approval_code,        
  comment_code,        
  fob_code,        
  terms_code,        
  tax_code,        
  recurring_code,        
  location_code,        
  payment_code,        
  times_accrued,        
  accrual_flag,        
  drop_ship_flag,        
  posted_flag,        
  hold_flag,        
  add_cost_flag,        
  approval_flag,        
  recurring_flag,        
  one_time_vend_flag,        
  one_check_flag,        
  amt_gross,        
  amt_discount,        
  amt_tax,        
  amt_freight,        
  amt_misc,        
  amt_net,        
  amt_paid,        
  amt_due,        
  amt_restock,        
  amt_tax_included,        
  frt_calc_tax,        
  doc_desc,        
  hold_desc,        
  [user_id],        
  next_serial_id,        
  pay_to_addr1,        
  pay_to_addr2,        
  pay_to_addr3,        
  pay_to_addr4,        
  pay_to_addr5,        
  pay_to_addr6,        
  attention_name,        
  attention_phone,        
  intercompany_flag,        
  company_code,        
  cms_flag,        
  process_group_num,        
  nat_cur_code,        
  rate_type_home,        
  rate_type_oper,        
  rate_home,        
  rate_oper,        
  trx_state,        
  mark_flag,        
  net_original_amt,        
  org_id        
 )        
 SELECT        
  ISNULL((SELECT trx_ctrl_num FROM #bows_apinpchg_link WHERE #bows_apinpchg_link.doc_reference_id=[DocumentReferenceID]),[DocumentReferenceID]),        
  CASE [DocumentType] WHEN 'D' THEN 4092 ELSE 4091 END, -- trx_type        
 [DocumentControlNumber],        
  ISNULL([ApplyToControlNumber],''),        
  CASE [user_trx_type_code] WHEN 'AM' THEN 'AMEX' ELSE 'STANDARD' END,   -- user_trx_type_code        
  '',   -- batch_code        
  ISNULL([POControlNumber],''),        
  ISNULL([VendorOrderNumber],''),        
  ISNULL([TicketNumber],''),        
  (SELECT datediff(dd, '1/1/80', CONVERT(datetime,ISNULL([DateApplied],[DateDocument])))+722815),        
  (SELECT datediff(dd, '1/1/80', CONVERT(datetime,ISNULL([DateAging],[DateDocument])))+722815),        
  CASE WHEN [DateDue] IS NULL THEN 0        
   ELSE datediff(dd, '1/1/80', CONVERT(datetime,[DateDue]))+722815        
  END,        
  (SELECT datediff(dd, '1/1/80', CONVERT(datetime,[DateDocument]))+722815),        
  (SELECT datediff(dd, '1/1/80', CONVERT(datetime,ISNULL([DateEntered],[DateDocument])))+722815),        
  (SELECT datediff(dd, '1/1/80', CONVERT(datetime,ISNULL([DateReceived],[DateDocument])))+722815),        
  (SELECT datediff(dd, '1/1/80', CONVERT(datetime,ISNULL([DateRequired],[DateDocument])))+722815),        
  0,   -- date_recurring        
  CASE WHEN [DateDiscount] IS NULL THEN 0        
   ELSE datediff(dd, '1/1/80', CONVERT(datetime,[DateDiscount]))+722815        
  END,        
  ISNULL([PostingCode],''),        
  [VendorCode],        
  ISNULL([PayToCode],''),  --fzambada        
  [BranchCode],        
  [ClassCode],          ISNULL([ApprovalCode],''), -- approval_code        
  [CommentCode],        
  [FobCode],        
  [TermsCode],        
  [TaxCode],        
  [RecurringCode],        
  '',   -- location_code        
  [PaymentCode],        
  0,   -- times_accrued        
  0,   -- accrual_flag        
  0,    -- drop_ship_flag        
  0,   -- posted_flag        
  ISNULL([HoldFlag],13),        
  0,   -- add_cost_flag        
  ISNULL([ApprovalFlag],0),        
  ISNULL([RecurringFlag],0),        
  0,   -- one_time_vend_flag        
  0,    -- one_check_flag        
  0.0,   -- amt_gross (will be calculated)        
  ------------------amts        
  ISNULL([AmountDiscount],0.0),   -- amt_discount (we are not handling discounts and kelly neither :)) --rev 8        
  0.0,   -- amt_tax        
  ISNULL([AmountFreight],0.0),        
  ISNULL([AmountMisc],0.0),        
  0.0,   -- amt_net        
  0.0,   -- amt_paid        
  0.0,   -- amt_due        
  0.0,   -- amt_restock        
  0.0,   -- amt_tax_included        
  0.0,   -- frt_calc_tax        
  [DocDescription],        
  [HoldDescription],        
  null,   -- user_id        
  null,   -- next_serial_id        
  [PayToAddress1],        
  [PayToAddress2],        
  [PayToAddress3],        
  [PayToAddress4],        
  [PayToAddress5],        
  [PayToAddress6],        
  [AttentionName],        
  [AttentionPhone],        
  ISNULL([BackOfficeInterCompanyFlag],0),        
  null,   -- company_code        
  null,   -- cms_flag        
  null,   -- process_group_num        
  [TransactionCurrency],        
  [HomeRateType],        
  [OperationalRateType],        
  CASE ISNULL([HomeRateOperator],'*')        
   WHEN '/' THEN -ISNULL([HomeRate],1.0)        
   ELSE ISNULL([HomeRate],1.0)        
  END,        
  CASE ISNULL([OperationalRateOperator],'*')        
   WHEN '/' THEN -ISNULL([OperationalRate],1.0)        
   ELSE ISNULL([OperationalRate],1.0)        
  END,        
  null,   -- trx_state        
  null,    -- mark_flag        
  0.0,    -- net_original_amt        
  CASE @ib_flag WHEN 1 THEN ISNULL([OrganizationID],@org_id) ELSE @org_id END        
 FROM VoucherHeader   --Rev 1        
 SELECT @Error=@@ERROR IF @Error<>0 BEGIN IF @debug_level>0 SELECT 'SQL Error during preparing header data' SELECT @ret_status = 60 INSERT #bows_aperror(err_code,err_msg,err_parameter) SELECT -(60), 'SQL Error during preparing header data', @Error GOTO lbERROR_RETURN END        
        
 -->>validate no duplicates in detail        
 SELECT @str=[DocumentReferenceID] + ':' + convert(varchar,[SequenceID])        
 FROM VoucherDetail   --Rev 1         
 GROUP BY [DocumentReferenceID],[SequenceID]        
 HAVING Count([SequenceID])>1        
 IF @@rowcount>0 BEGIN IF @debug_level>0 SELECT 'Duplicate sequence id in details.ReferenceID/Sequence=' + @str SELECT @ret_status = 70 INSERT #bows_aperror(err_code,err_msg) SELECT -(70), 'Duplicate sequence id in details.ReferenceID/Sequence=' + @str GOTO lbERROR_RETURN END        
        
 -->>validate no orphan voucher details        
 SELECT @str=[DocumentReferenceID]        
 FROM VoucherDetail   --Rev 1        
 WHERE [DocumentReferenceID] NOT IN (SELECT doc_reference_id FROM #bows_apinpchg_link)        
 IF @@rowcount>0 BEGIN IF @debug_level>0 SELECT 'Orphan voucher details detected. ReferenceID=' + @str SELECT @ret_status = 72 INSERT #bows_aperror(err_code,err_msg) SELECT -(72), 'Orphan voucher details detected. ReferenceID=' + @str GOTO lbERROR_RETURN 

  
    
      
END        
        
 -->>prepare details temp table        
 INSERT INTO #apinpcdt(        
  trx_ctrl_num,        
  trx_type,        
  sequence_id,        
  location_code,        
  item_code,        
  bulk_flag,        
  qty_ordered,        
  qty_received,        
  qty_returned,        
  qty_prev_returned,        
  approval_code,        
  tax_code,        
  return_code,        
  code_1099,        
  po_ctrl_num,        
  unit_code,        
  unit_price,        
  amt_discount,        
  amt_freight,        
  amt_tax,        
  amt_misc,        
  amt_extended,        
  calc_tax,        
  date_entered,        
  gl_exp_acct,        
  new_gl_exp_acct,        
  rma_num,        
  line_desc,        
  serial_id,        
  company_id,        
  iv_post_flag,        
  po_orig_flag,        
  rec_company_code,        
  new_rec_company_code,        
  reference_code,        
  new_reference_code,        
  org_id        
 )        
 SELECT        
  ISNULL((SELECT trx_ctrl_num FROM #bows_apinpchg_link WHERE #bows_apinpchg_link.doc_reference_id=[DocumentReferenceID]),[DocumentReferenceID]),        
  ISNULL((SELECT a.trx_type FROM #apinpchg a, #bows_apinpchg_link b WHERE a.trx_ctrl_num=b.trx_ctrl_num and b.doc_reference_id=[DocumentReferenceID]),4091),        
  [SequenceID],        
  CASE WHEN (ISNULL([ItemCode],'')<>'') AND (ISNULL([LocationCode],'')='') THEN 'EXTERNAL'        
   ELSE ISNULL([LocationCode],'') END,        
  NULL,--[ItemCode],  -- item_code        
  null,   -- bulk_flag        
  ISNULL([QtyOrdered],0.0),        
  ISNULL([QtyReceived],1.0),        
  ISNULL([QtyReturned],0.0),        
  0.0,   -- qty_prev_returned        
  ISNULL([ApprovalCode],''),        
  [TaxCode],        
  [ReturnCode],        
  null,   -- code_1099        
  [POControlNumber],        
  [UOM],   -- unit_code        
  ISNULL([UnitPrice],0.0),        
  ISNULL([AmountDiscount],0.0),        
  ISNULL([AmountFreight],0.0),        
  ISNULL([AmountTax],0.0),        
  ISNULL([AmountMisc],0.0),        
  ISNULL([AmountExtended], (ISNULL([QtyReceived],1.0)*ISNULL([UnitPrice],0.0)) ), -- amt_extended        
  0.0,   -- calc_tax        
  null,   -- date_entered        
  [GLExpenseAccount],        
  null,   -- new_gl_exp_acct        
  '',   -- rma_num        
  [LineDescription],        
  0,   -- serial_id        
  [CompanyID],        
  null,   -- iv_post_flag        
  0, --null,   -- po_orig_flag        
  [RecCompanyCode],         
  null,   -- new_rec_company_code        
  [GLReferenceCode],        
  null,   -- new_reference_code        
  CASE @ib_flag WHEN 1 THEN ISNULL([OrganizationID],@org_id) ELSE @org_id END        
 FROM VoucherDetail   --Rev 1        
 SELECT @Error=@@ERROR IF @Error<>0 BEGIN IF @debug_level>0 SELECT 'SQL Error during preparing detail data' SELECT @ret_status = 80 INSERT #bows_aperror(err_code,err_msg,err_parameter) SELECT -(80), 'SQL Error during preparing detail data', @Error GOTO lbERROR_RETURN END        
        
        
 -->>Prepare tax details temp table -->> RCGT        
 INSERT INTO #apinptaxdtl        
 (        
  trx_ctrl_num,        
  sequence_id,         
  trx_type,        
  tax_sequence_id,        
  detail_sequence_id,        
  tax_type_code,        
  amt_taxable,        
  amt_gross,        
  amt_tax,        
  amt_final_tax,        
  recoverable_flag,        
  account_code        
 )        
 SELECT         
  ISNULL((SELECT trx_ctrl_num FROM #bows_apinpchg_link WHERE #bows_apinpchg_link.doc_reference_id=[DocumentReferenceID]),[DocumentReferenceID]),        
  [SequenceID],        
  ISNULL((SELECT a.trx_type FROM #apinpchg a, #bows_apinpchg_link b WHERE a.trx_ctrl_num=b.trx_ctrl_num and b.doc_reference_id=[DocumentReferenceID]),4091),        
  [DetailSequenceID],        
  [DetailSequenceID],        
  [TaxTypeCode],        
  [BaseAmount],        
  [BaseAmount],           
  [CalculatedTaxAmount],        
  [FinalTaxAmount],        
  [RecoverableFlag],        
  [APFooterGLTaxChartofAccount]        
 FROM  VoucherTax        
 SELECT @Error=@@ERROR IF @Error<>0 BEGIN IF @debug_level>0 SELECT 'SQL Error during preparing tax data' SELECT @ret_status = 80 INSERT #bows_aperror(err_code,err_msg,err_parameter) SELECT -(80), 'SQL Error during preparing tax data', @Error GOTO lbERROR_RETURN END        
        
        
 -->> The amt_gross should be the = to the line unit price. -->>RCGT        
 UPDATE  #apinptaxdtl        
 SET amt_gross = #apinpcdt.unit_price        
 FROM #apinpcdt        
 WHERE   #apinpcdt.trx_ctrl_num = #apinptaxdtl.trx_ctrl_num and        
  #apinpcdt.sequence_id = #apinptaxdtl.detail_sequence_id        
        
        
        
 -->>prepare tax temp table        
 INSERT INTO #bows_apinptax_link (        
  doc_reference_id,        
  trx_ctrl_num,        
  trx_type,        
  tax_type_code,        
  amt_final_tax        
 )        
 SELECT        
  [DocumentReferenceID],        
  ISNULL((SELECT trx_ctrl_num FROM #bows_apinpchg_link WHERE #bows_apinpchg_link.doc_reference_id=[DocumentReferenceID]),[DocumentReferenceID]),        
  ISNULL((SELECT a.trx_type FROM #apinpchg a, #bows_apinpchg_link b WHERE a.trx_ctrl_num=b.trx_ctrl_num and b.doc_reference_id=[DocumentReferenceID]),4091),        
  [TaxTypeCode],        
  [TaxAmount]        
 FROM VoucherTax   --Rev 1        
 SELECT @Error=@@ERROR IF @Error<>0 BEGIN IF @debug_level>0 SELECT 'SQL Error during preparing tax data' SELECT @ret_status = 90 INSERT #bows_aperror(err_code,err_msg,err_parameter) SELECT -(90), 'SQL Error during preparing tax data', @Error GOTO lbERROR_RETURN END        
        
 -->>fetch tax calculate mode        
 UPDATE #bows_apinptax_link        
-- SET tax_calculated_mode = CASE ISNULL([CalculateTaxMode],1) WHEN 1 THEN 0 ELSE 1 END        
 SET tax_calculated_mode = CASE ISNULL([CalculateTaxMode],0) WHEN 0 THEN 0 ELSE 1 END        
 FROM VoucherHeader a, #bows_apinptax_link b, #bows_apinpchg_link c   --Rev 1        
 WHERE a.[DocumentReferenceID] = c.doc_reference_id        
 AND b.trx_ctrl_num = c.trx_ctrl_num        
 SELECT @Error=@@ERROR IF @Error<>0 BEGIN IF @debug_level>0 SELECT 'SQL Error during fetching tax calculate mode' SELECT @ret_status = 100 INSERT #bows_aperror(err_code,err_msg,err_parameter) SELECT -(100), 'SQL Error during fetching tax calculate mode', 

  
    
      
@Error GOTO lbERROR_RETURN END        
        
 -->>prepare project temp table        
 INSERT INTO #bows_psaTrx (        
  ControlNumber,        
  TransactionType,        
  SequenceID,        
  PostedFlag,        
  ProjectCode,        
  RevisionNum,        
  TaskUID,        
  ExpenseTypeCode,        
  ResourceID,        
  ExpenseID,        
  PrepaidFlag,        
  Origin,        
  ClosedFlag,        
  ProjectSiteURN,        
  InterCompanyFlag,        
  doc_reference_id,        
  db_action        
 )        
 SELECT        
  ISNULL((SELECT trx_ctrl_num FROM #bows_apinpchg_link WHERE #bows_apinpchg_link.doc_reference_id=[DocumentReferenceID]),[DocumentReferenceID]),        
  ISNULL((SELECT a.trx_type FROM #apinpchg a, #bows_apinpchg_link b WHERE a.trx_ctrl_num=b.trx_ctrl_num and b.doc_reference_id=[DocumentReferenceID]),4091),        
  [SequenceID],        
  0, -- PostedFlag        
  [ProjectCode],        
  [RevisionNum],        
  [TaskUID],        
  [ExpenseTypeCode],        
  [ResourceID],        
  [ExpenseID],        
  --[PrepaidFlag],        
ISNULL ([PrepaidFlag],0), --Fzambada Integration      
  ISNULL([Origin],1),        
  ISNULL([ClosedFlag],0),        
  ISNULL([ProjectSiteURN],''),        
  ISNULL([InterCompanyTransactionFlag],0),        
  [DocumentReferenceID],        
  0        
 FROM VoucherDetail   --Rev 1        
 WHERE NOT [ProjectCode] IS NULL        
 SELECT @Error=@@ERROR IF @Error<>0 BEGIN IF @debug_level>0 SELECT 'SQL Error during preparing project data' SELECT @ret_status = 110 INSERT #bows_aperror(err_code,err_msg,err_parameter) SELECT -(110), 'SQL Error during preparing project data', @Error GOTO lbERROR_RETURN END        
        
 /*        
 *Begin Rev 1        
 *Fill together header and detail notes from representation table        
 */        
 -->>prepare notes temp table (including header and detail)        
 INSERT INTO #bows_doc_notes (        
  trx_ctrl_num,        
  trx_type,        
  sequence_id,        
  link,        
  note,        
  show_line_mode        
 )        
 SELECT        
  ISNULL((SELECT trx_ctrl_num FROM #bows_apinpchg_link WHERE #bows_apinpchg_link.doc_reference_id=[DocumentReferenceID]),[DocumentReferenceID]),        
  ISNULL((SELECT a.trx_type FROM #apinpchg a, #bows_apinpchg_link b WHERE a.trx_ctrl_num=b.trx_ctrl_num and b.doc_reference_id=[DocumentReferenceID]),4091),        
  [SequenceID],        
  ISNULL([Link],''),        
  ISNULL([Note],''),        
  [ShowLineMode]        
 FROM VoucherNotes        
 ORDER BY [DocumentReferenceID],[SequenceID]        
 SELECT @Error=@@ERROR IF @Error<>0 BEGIN IF @debug_level>0 SELECT 'SQL Error during preparing detail notes' SELECT @ret_status = 130 INSERT #bows_aperror(err_code,err_msg,err_parameter) SELECT -(130), 'SQL Error during preparing detail notes', @Error GOTO lbERROR_RETURN END        
 /*        
 *End Rev 1        
 */         
        
 IF @debug_level>5 BEGIN        
  SELECT 'APINPCHG data from XML'        
  select * from #apinpchg        
  SELECT 'APINPCDT data from XML'        
  select * from #apinpcdt        
  SELECT 'BOWS_APINPTAX data from XML'        
  select * from #bows_apinptax_link        
  SELECT 'BOWS_PSATRX data from XML'        
  select * from #bows_psaTrx        
  SELECT 'BOWS_DOC_NOTES data from XML'        
  select * from #bows_doc_notes        
 END        
        
 -->> Call AP import stored procedure        
 DECLARE @result_process_ctrl_num varchar(16)        
 SELECT @ret_status = -1        
 EXEC @ret_status = bows_APImportVouch_SP        
    @debug_level=@debug_level        
        
 IF (@ret_status<>0) OR (@@error<>0) OR EXISTS(SELECT 1 FROM #ewerror) BEGIN        
  IF @debug_level>0 SELECT 'ERROR IN IMPORTING PROCEDURE'        
        
  IF ISNULL(@ret_status,0)=0 SET @ret_status = -1        
  INSERT  #bows_aperror(        
   ControlNumber, SequenceID, err_code,        
   err_msg,        
   err_parameter)        
  SELECT  trx_ctrl_num, sequence_id, err_code,        
   ISNULL((SELECT b.err_desc FROM apedterr b WHERE b.err_code=#ewerror.err_code),'') +        
   RTRIM(' ' + RTRIM(ISNULL(info1,'')+' ') + RTRIM(ISNULL(info2,''))),        
   null        
  FROM #ewerror        
  IF (@ret_status<>0) AND (NOT EXISTS(SELECT 1 FROM #bows_aperror)) BEGIN 
   INSERT  #bows_aperror(err_code,err_msg,err_parameter)        
   SELECT  -1,'ERROR IN IMPORTING PROCEDURE',null        
  END        
  GOTO lbERROR_RETURN        
END        
        
lbERROR_RETURN:        
        
 --Form Resulting XML        
 SELECT '$FIN_RESULTS$' --Keyword for the result parser        
        
 IF EXISTS(SELECT 1 FROM #bows_aperror)        
  SELECT @ret_status=CASE @ret_status WHEN 0 THEN -1 ELSE @ret_status END        
        
 SELECT '<Status>' + convert(varchar, @ret_status) + '</Status>'        
        
 IF EXISTS(SELECT 1 FROM #bows_aperror) BEGIN        
  SELECT '<ErrorList>'        
  SELECT        
   err_code  as  ErrorCode,        
   RTRIM(err_msg)  as ErrorDescription,        
   RTRIM(err_parameter) as ErrorParameter,        
   CASE WHEN ISNULL(SequenceID,0)<1 THEN NULL ELSE SequenceID END as SequenceID,        
   (SELECT doc_reference_id FROM #bows_apinpchg_link WHERE new_trx_ctrl_num=Error.ControlNumber) as DocumentReferenceID        
  FROM #bows_aperror as Error        
  FOR XML AUTO, ELEMENTS        
  SELECT '</ErrorList>'        
 END        
        
  SELECT '<VoucherList>'        
  SELECT        
   RTRIM(a.trx_ctrl_num) as ControlNumber,        
   RTRIM(doc_reference_id) as DocumentReferenceID,        
   CASE WHEN RTRIM(a.batch_code)='' THEN NULL ELSE a.batch_code END as BatchNumber        
  FROM #bows_apinpchg_link as Voucher, apinpchg a        
  WHERE Voucher.new_trx_ctrl_num = a.trx_ctrl_num        
  AND Voucher.imported_flag = 1        
  FOR XML AUTO, ELEMENTS        
  SELECT '</VoucherList>'        
        
-- DROP TABLE VoucherHeader        
-- DROP TABLE VoucherDetail        
-- DROP TABLE VoucherTax        
-- DROP TABLE VoucherNotes        
 DROP TABLE #apinpchg        
 DROP TABLE #apinpcdt        
 DROP TABLE #ewerror        
 DROP TABLE #bows_apinpchg_link        
 DROP TABLE #bows_apinptax_link        
 DROP TABLE #bows_aperror        
 DROP TABLE #bows_psaTrx        
 DROP TABLE #bows_doc_notes        
      
      
 RETURN @ret_status 

GO
GRANT EXECUTE ON  [dbo].[CVO_ap_import_voucher_sp] TO [public]
GO
