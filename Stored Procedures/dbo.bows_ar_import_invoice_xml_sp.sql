SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
        
      
CREATE  PROC [dbo].[bows_ar_import_invoice_xml_sp]      
     @debug_level  int    
      
AS      
  DECLARE @ret_status int, @hDoc int, @Error int      
 SELECT @ret_status = 0, @hDoc = 0      
      
 -->>>==================Create Temp Tables=================      
      
CREATE TABLE #arinpchg      
(      
 link varchar(16) NULL,      
 trx_ctrl_num varchar(16) NULL,      
 doc_ctrl_num varchar(16) NULL,      
 doc_desc varchar(40) NULL,      
 apply_to_num varchar(16) NULL,      
 apply_trx_type smallint NULL,      
 order_ctrl_num varchar(16) NULL,      
 batch_code varchar(16) NULL,      
 trx_type smallint NULL,      
 date_entered int NULL,      
 date_applied int NULL,      
 date_doc int NULL,      
 date_shipped int NULL,      
 date_required int NULL,      
 date_due int NULL,      
 date_aging int NULL,      
 customer_code varchar(8),      
 ship_to_code varchar(8) NULL,      
 salesperson_code varchar(8) NULL,      
 territory_code varchar(8) NULL,      
 comment_code varchar(8) NULL,      
 fob_code varchar(8) NULL,      
 freight_code varchar(8) NULL,      
 terms_code varchar(8) NULL,      
 fin_chg_code varchar(8) NULL,      
 price_code varchar(8) NULL,      
 dest_zone_code varchar(8) NULL,      
 posting_code varchar(8) NULL,      
 recurring_flag smallint NULL,      
 recurring_code varchar(8) NULL,      
 tax_code varchar(8) NULL,      
 cust_po_num varchar(20) NULL,      
 total_weight float NULL,      
 amt_gross float NULL,      
 amt_freight float NULL,      
 amt_tax float NULL,      
 amt_tax_included float NULL,      
 amt_discount float NULL,      
 amt_net float NULL,      
 amt_paid float NULL,      
 amt_due float NULL,      
 amt_cost float NULL,      
 amt_profit float NULL,      
 next_serial_id smallint NULL,      
 printed_flag smallint NULL,      
 posted_flag smallint NULL,      
 hold_flag smallint NULL,      
 hold_desc varchar(40) NULL,      
 user_id smallint NULL,      
 customer_addr1 varchar(40) NULL,      
 customer_addr2 varchar(40) NULL,      
 customer_addr3 varchar(40) NULL,      
 customer_addr4 varchar(40) NULL,      
 customer_addr5 varchar(40) NULL,      
 customer_addr6 varchar(40) NULL,      
 ship_to_addr1 varchar(40) NULL,      
 ship_to_addr2 varchar(40) NULL,      
 ship_to_addr3 varchar(40) NULL,      
 ship_to_addr4 varchar(40) NULL,      
 ship_to_addr5 varchar(40) NULL,      
 ship_to_addr6 varchar(40) NULL,      
 attention_name varchar(40) NULL,      
 attention_phone varchar(30) NULL,      
 amt_rem_rev float NULL,      
 amt_rem_tax float NULL,      
 date_recurring int NULL,      
 location_code varchar(8) NULL,      
 process_group_num varchar(16) NULL,      
 trx_state smallint NULL,      
 mark_flag smallint NULL,      
 amt_discount_taken float NULL,      
 amt_write_off_given float NULL,      
 source_trx_ctrl_num varchar(16) NULL,      
 source_trx_type smallint NULL,      
 nat_cur_code varchar(8) NULL,      
 rate_type_home varchar(8) NULL,      
 rate_type_oper varchar(8) NULL,      
 rate_home float NULL,      
 rate_oper float NULL,      
 edit_list_flag smallint NULL,      
 ddid varchar(32) NULL,      
 writeoff_code varchar(8) NULL,      
 vat_prc float NULL,       
 org_id  varchar(30) NULL      
)      
      
CREATE INDEX #arinpchg_ind_0      
ON #arinpchg ( trx_ctrl_num, trx_type )      
CREATE INDEX #arinpchg_ind_1      
ON #arinpchg (batch_code)      
      
create table #arinpcdt      
(      
 link   varchar(16) NULL,      
 trx_ctrl_num   varchar(16) NULL,      
 doc_ctrl_num   varchar(16) NULL,      
 sequence_id   int NULL,      
 trx_type   smallint NULL,      
 location_code   varchar(8) NULL,      
 item_code   varchar(30) NULL,      
 bulk_flag   smallint NULL,      
 date_entered   int NULL,      
 line_desc   varchar(60) NULL,      
 qty_ordered   float NULL,      
 qty_shipped   float NULL,      
 unit_code   varchar(8) NULL,      
 unit_price   float,      
 unit_cost   float NULL,      
 weight    float NULL,      
 serial_id   int NULL,      
 tax_code   varchar(8) NULL,      
 gl_rev_acct   varchar(32) NULL,      
 disc_prc_flag   smallint NULL,      
 discount_amt   float NULL,      
 commission_flag smallint NULL,      
 rma_num  varchar(16) NULL,      
 return_code   varchar(8) NULL,      
 qty_returned   float NULL,      
 qty_prev_returned float NULL,      
 new_gl_rev_acct varchar(32) NULL,     
 iv_post_flag   smallint NULL,      
 oe_orig_flag   smallint NULL,      
 discount_prc  float NULL,      
 extended_price float NULL,      
 calc_tax  float NULL,      
 reference_code varchar(32) NULL,      
 trx_state  smallint NULL,      
 mark_flag  smallint NULL,      
 cust_po   VARCHAR(20) NULL,      
 org_id   VARCHAR(30) NULL      
)      
      
CREATE INDEX arinpcdt_ind_0      
 ON #arinpcdt ( trx_ctrl_num, trx_type, sequence_id )      
      
CREATE TABLE #arinpcom      
(      
 trx_ctrl_num varchar(16),      
 trx_type smallint,      
 sequence_id int,      
 salesperson_code varchar(8),      
 amt_commission float,      
 percent_flag smallint,      
 exclusive_flag smallint,      
 split_flag smallint,      
 trx_state smallint NULL,      
 mark_flag smallint NULL      
 )      
      
CREATE UNIQUE INDEX arinpcom_ind_0      
ON #arinpcom ( trx_ctrl_num, trx_type, sequence_id )      
      
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
      
CREATE TABLE #bows_arerror      
(      
 ControlNumber  varchar(16) NULL,      
 SequenceID  int default 0,      
 err_code   int NULL,      
 err_msg   char(256) NULL,      
 err_parameter  char(64) NULL      
)      
      
CREATE TABLE #bows_arinpchg_link (      
 doc_reference_id varchar(128),      
 trx_ctrl_num  varchar(16),      
 trx_ctrl_num_int int IDENTITY      
)      
      
create table #bows_arinptax_link (      
 doc_reference_id varchar(128),      
 trx_ctrl_num  varchar(16),      
 trx_type  smallint,      
 tax_type_code  varchar(8),      
 amt_final_tax  float,      
 tax_calculated_mode int default 0,      
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
-- CREATE TABLE CVO_INVHeader(      
--  [DocumentReferenceID] varchar(128),      
--  [DocumentType]  varchar(1),      
--  [DocDescription] varchar(40),      
--  [ApplyToControlNum] varchar(16),      
--  [OrderControlNum] varchar(16),      
--  [DateEntered]  varchar(19), --rev 4      
--  [DateApply]  varchar(19), --rev 4      
--  [DateDocument]  varchar(19), --rev 4      
--  [DateShipped]  varchar(19), --rev 4      
--  [DateRequired]  varchar(19), --rev 4      
--  [DateDue]  varchar(19), --rev 4      
--  [DateAging]  varchar(19), --rev 4      
--  [CustomerCode]  varchar(8),      
--  [ShipToCode]  varchar(8),      
--  [SalesPersonCode] varchar(8),      
--  [TerritoryCode]  varchar(8),      
--  [CommentCode]  varchar(8),      
--  [FobCode]  varchar(8),      
--  [FreightCode]  varchar(8),      
--  [TermsCode]  varchar(8),      
--  [FinChargeCode]  varchar(8),      
--  [PriceCode]  varchar(8),      
--  [DestZoneCode]  varchar(8),      
--  [PostingCode]  varchar(8),      
--  [RecurringFlag]  smallint,      
--  [RecurringCode]  varchar(8),      
--  [CustomerPO]  varchar(20),      
--  [TaxCode]  varchar(8),      
--  [TotalWeight]  float,      
--  [AmountFreight]  float,      
--  [HoldFlag]  smallint,      
--  [HoldDescription] varchar(40),      
--  [CustomerAddress1] varchar(40),      
--  [CustomerAddress2] varchar(40),      
--  [CustomerAddress3] varchar(40),      
--  [CustomerAddress4] varchar(40),      
--  [CustomerAddress5] varchar(40),      
--  [CustomerAddress6] varchar(40),      
--  [ShipToAddress1] varchar(40),      
--  [ShipToAddress2] varchar(40),      
--  [ShipToAddress3] varchar(40),      
--  [ShipToAddress4] varchar(40),      
--  [ShipToAddress5] varchar(40),      
--  [ShipToAddress6] varchar(40),      
--  [AttentionName]  varchar(40),      
--  [AttentionPhone] varchar(30),      
--  [SourceControlNumber] varchar(16),      
--  [TransactionalCurrency] varchar(8),      
--  [HomeRateType]  varchar(8),      
--  [OperationalRateType] varchar(8),      
--  [HomeRate]  float,      
--  [OperationalRate] float,     
--  [HomeRateOperator] varchar(1),      
--  [OperationalRateOperator] varchar(1),      
--  [TaxCalculatedMode] smallint,      
--  [PrintedFlag]  smallint,      
--  [OrganizationID] varchar(30)      
-- )      
--      
-- CREATE TABLE CVO_INVDetail(      
--  [DocumentReferenceID] varchar(128),      
--  [SequenceID]  int,      
--  [Location]  varchar(8),      
--  [ItemCode]  varchar(30),      
--  [DateEntered]  varchar(19), --rev 4      
--  [LineDescription] varchar(60),      
--  [QtyOrdered]  float,      
--  [QtyShipped]  float,      
--  [SalesUOMCode]  varchar(8),      
--  [UnitPrice]  float,      
--  [Weight]  float,      
--  [TaxCode]  varchar(8),      
--  [GLRevAccount]  varchar(32),      
--  [DiscPrcFlag]  smallint,      
--  [AmountDiscount] float,      
--  [ReturnCode]  varchar(8),      
--  [QtyReturned]  float,      
--  [DiscPrc]  float,      
--  [ExtendedPrice]  float,      
--  [GLReferenceCode] varchar(32),      
--  [OEFlag]  int,      
--  [CustomerPO]  varchar(20),      
--  [OrganizationID] varchar(30)      
-- )      
--      
-- CREATE TABLE CVO_INVTax(      
--  [DocumentReferenceID]  varchar(128),      
--  [TaxTypeCode]   varchar(8),      
--  [TaxAmount]   float,      
--  [TaxIncludedFlag]  smallint      
-- )      
--      
-- CREATE TABLE CVO_INVCommission(      
--  [DocumentReferenceID]  varchar(128),      
--  [SequenceID]   int,      
--  [SalesPersonCode]  varchar(8),      
--  [CommissionAmount]  float,      
--  [PercentFlag]   smallint,      
--  [ExclusiveFlag]   smallint,      
--  [SplitFlag]   smallint      
-- )      
--      
-- CREATE TABLE CVO_INVNotes(      
--  [DocumentReferenceID]  varchar(128),      
--  [SequenceID]   int,      
--  [Link]    varchar(255),      
--  [Note]    varchar(255),      
--  [ShowLineMode]   int      
-- )      
--      
 /*      
 * Begin Rev 1      
 */      
 --<<<==================Populate XML Representation Tables=================      
      
 -->>populate xml representation tables      
-- EXEC @ret_status=sp_xml_preparedocument @hDoc OUTPUT, @InputXml      
-- IF @ret_status<>0 BEGIN      
--  INSERT #bows_arerror(err_code, err_msg) SELECT 10, 'ERROR IN PREPARING XML DOCUMENT' GOTO lbERROR_RETURN      
-- END      
----       
---- -->>populate CVO_INVHeader      
-- INSERT INTO CVO_INVHeader SELECT      
--  [DocumentReferenceID],      
--  [DocumentType],      
--  [DocDescription],      
--  [ApplyToControlNum],      
--  [OrderControlNum],      
--  [DateEntered],      
--  [DateApply],      
--  [DateDocument],      
--  [DateShipped],      
--  [DateRequired],      
--  [DateDue],      
--  [DateAging],      
--  [CustomerCode],      
--  [ShipToCode],      
--  [SalesPersonCode],      
--  [TerritoryCode],      
--  [CommentCode],      
--  [FobCode],      
--  [FreightCode],      
--  [TermsCode],      
--  [FinChargeCode],      
--  [PriceCode],      
--  [DestZoneCode],      
--  [PostingCode],      
--  [RecurringFlag],      
--  [RecurringCode],      
--  [CustomerPO],      
--  [TaxCode],      
--  [TotalWeight],      
--  [AmountFreight],      
--  [HoldFlag],      
--  [HoldDescription],      
--  [CustomerAddress1],      
--  [CustomerAddress2],      
--  [CustomerAddress3],      
--  [CustomerAddress4],      
--  [CustomerAddress5],      
--  [CustomerAddress6],      
--  [ShipToAddress1],      
--  [ShipToAddress2],      
--  [ShipToAddress3],      
--  [ShipToAddress4],      
--  [ShipToAddress5],      
--  [ShipToAddress6],      
--  [AttentionName],      
--  [AttentionPhone],      
--  [SourceControlNumber],      
--  [TransactionalCurrency],      
--  [HomeRateType],      
--  [OperationalRateType],      
--  [HomeRate],      
--  [OperationalRate],      
--  [HomeRateOperator],      
--  [OperationalRateOperator],      
--  [TaxCalculatedMode],      
--  [PrintedFlag],      
--  [OrganizationID]      
-- FROM OPENXML (@hDoc, '/CreateInvoiceDoc/Invoice',2)      
-- WITH CVO_INVHeader      
-- SELECT @Error=@@ERROR      
-- IF @Error<>0 BEGIN      
--  INSERT #bows_arerror(err_code, err_msg) SELECT 11, 'SQL Error during populating representation tables: CVO_INVHeader' GOTO lbERROR_RETURN      
-- END      
--       
-- -->>populate CVO_INVDetail      
-- INSERT INTO CVO_INVDetail SELECT      
--  [DocumentReferenceID],      
--  [SequenceID],      
--  [Location],      
--  [ItemCode],      
--  [DateEntered],      
--  [LineDescription],      
--  [QtyOrdered],      
--  [QtyShipped],      
--  [SalesUOMCode],      
--  [UnitPrice],      
--  [Weight],      
--  [TaxCode],      
--  [GLRevAccount],      
--  [DiscPrcFlag],      
--  [AmountDiscount],      
--  [ReturnCode],      
--  [QtyReturned],      
--  [DiscPrc],      
--  [ExtendedPrice],      
--  [GLReferenceCode],      
--  [OEFlag],      
--  [CustomerPO],      
--  [OrganizationID]      
-- FROM OPENXML (@hDoc, '/CreateInvoiceDoc/Invoice/InvoiceDetail',2)      
-- WITH CVO_INVDetail      
-- SELECT @Error=@@ERROR      
-- IF @Error<>0 BEGIN      
--  INSERT #bows_arerror(err_code, err_msg) SELECT 12, 'Error during populating representation tables: CVO_INVDetail' GOTO lbERROR_RETURN      
-- END      
--       
-- -->>populate CVO_INVTax      
-- INSERT INTO CVO_INVTax SELECT      
--  [DocumentReferenceID],      
--  [TaxTypeCode],      
--  [TaxAmount],      
--  [TaxIncludedFlag]      
-- FROM OPENXML (@hDoc, '/CreateInvoiceDoc/Invoice/InvoiceTaxType',2)      
-- WITH CVO_INVTax      
-- SELECT @Error=@@ERROR      
-- IF @Error<>0 BEGIN      
--  INSERT #bows_arerror(err_code, err_msg) SELECT 13, 'Error during populating representation tables: CVO_INVTax' GOTO lbERROR_RETURN      
-- END      
--       
-- -->>populate CVO_INVCommission      
-- INSERT INTO CVO_INVCommission SELECT      
--  [DocumentReferenceID],      
--  [SequenceID],      
--  [SalesPersonCode],      
--  [CommissionAmount],      
--  [PercentFlag],      
--  [ExclusiveFlag],      
--  [SplitFlag]       
-- FROM OPENXML (@hDoc, '/CreateInvoiceDoc/Invoice/InvoiceCommission',2)      
-- WITH CVO_INVCommission      
-- SELECT @Error=@@ERROR      
-- IF @Error<>0 BEGIN      
--  INSERT #bows_arerror(err_code, err_msg) SELECT 14, 'Error during populating representation tables: CVO_INVCommission' GOTO lbERROR_RETURN      
-- END      
--       
-- -->>populate CVO_INVNotes (from header)      
-- INSERT INTO CVO_INVNotes SELECT      
--  [DocumentReferenceID],      
--  [SequenceID],      
--  [Link],      
--  [Note],      
--  ISNULL([ShowLineMode],0)      
-- FROM OPENXML (@hDoc, '/CreateInvoiceDoc/Invoice/InvoiceNotes',2)      
-- WITH CVO_INVNotes      
-- ORDER BY [DocumentReferenceID]      
-- SELECT @Error=@@ERROR      
-- IF @Error<>0 BEGIN      
--  INSERT #bows_arerror(err_code, err_msg) SELECT 15, 'SQL Error during populating representation tables: CVO_INVNotes' GOTO lbERROR_RETURN      
-- END      
--       
-- -->>populate CVO_INVNotes (from detail)      
-- INSERT INTO CVO_INVNotes SELECT      
--  [DocumentReferenceID],      
--  [SequenceID],      
--  [Link],      
--  [Note],      
--  ISNULL([ShowLineMode],1)      
-- FROM OPENXML (@hDoc, '/CreateInvoiceDoc/Invoice/InvoiceDetail/InvoiceDetailNotes',2)      
-- WITH CVO_INVNotes      
-- ORDER BY [DocumentReferenceID],[SequenceID]      
-- SELECT @Error=@@ERROR      
-- IF @Error<>0 BEGIN      
--  INSERT #bows_arerror(err_code, err_msg) SELECT 16, 'SQL Error during populating representation tables: CVO_INVNotes' GOTO lbERROR_RETURN      
-- END      
--       
-- --release XML document      
-- IF @hDoc<>0 EXEC sp_xml_removedocument @hDoc      
--       
 /*      
 * End Rev 1      
 */      
       
 --<<<==================Populate Temp Tables=================      
      
 -->>validate no duplicates in header      
 SELECT [DocumentReferenceID]      
 FROM CVO_INVHeader   --Rev 1      
 GROUP BY [DocumentReferenceID]      
 HAVING (Count([DocumentReferenceID])>1) AND (NOT [DocumentReferenceID] IS NULL)      
 IF @@rowcount>0 BEGIN      
  INSERT #bows_arerror(err_code, err_msg) SELECT 20, 'Duplicate header record' GOTO lbERROR_RETURN      
 END      
      
 -->>prepare link temp table      
 INSERT INTO #bows_arinpchg_link(      
  doc_reference_id      
 )      
 SELECT      
  [DocumentReferenceID]      
 FROM CVO_INVHeader   --Rev 1      
 SELECT @Error=@@ERROR      
 IF @Error<>0 BEGIN      
  INSERT #bows_arerror(err_code, err_msg) SELECT 30, 'SQL Error preparing link data' GOTO lbERROR_RETURN      
 END      
       
 -->> set string control number      
 UPDATE  #bows_arinpchg_link      
  SET  trx_ctrl_num = 'INVIMP$'+Convert(varchar(16),trx_ctrl_num_int)      
      
 -->> validate if interbranch processing is enabled      
 DECLARE @ib_flag int, @org_id varchar(30)      
 SELECT @ib_flag = ib_flag FROM glco      
 SELECT @org_id = organization_id FROM Organization WHERE outline_num = '1' --rev 3      
      
 -->>prepare header temp table      
 INSERT INTO #arinpchg (      
  link,      
  trx_ctrl_num,      
  doc_ctrl_num,      
  doc_desc,      
  apply_to_num,      
  apply_trx_type,      
  order_ctrl_num,      
  batch_code,      
  trx_type,      
  date_entered,      
  date_applied,      
  date_doc,      
  date_shipped,      
  date_required,      
  date_due,      
  date_aging,      
  customer_code,      
  ship_to_code,      
  salesperson_code,      
  territory_code,      
  comment_code,      
  fob_code,      
  freight_code,      
  terms_code,      
  fin_chg_code,      
  price_code,      
  dest_zone_code,      
  posting_code,      
  recurring_flag,      
  recurring_code,      
  tax_code,      
  cust_po_num,      
  total_weight,      
  amt_gross,      
  amt_freight,      
  amt_tax,      
  amt_tax_included,      
  amt_discount,      
  amt_net,      
  amt_paid,      
  amt_due,      
  amt_cost,      
  amt_profit,      
  next_serial_id,      
  printed_flag,      
  posted_flag,      
  hold_flag,      
  hold_desc,      
  [user_id],      
  customer_addr1,      
  customer_addr2,      
  customer_addr3,      
  customer_addr4,      
  customer_addr5,      
  customer_addr6,      
  ship_to_addr1,      
  ship_to_addr2,      
  ship_to_addr3,      
  ship_to_addr4,      
  ship_to_addr5,      
  ship_to_addr6,      
  attention_name,      
  attention_phone,      
  amt_rem_rev,      
  amt_rem_tax,      
  date_recurring,      
  location_code,      
  process_group_num,      
  trx_state,      
  mark_flag,      
  amt_discount_taken,      
  amt_write_off_given,      
  source_trx_ctrl_num,      
  source_trx_type,      
  nat_cur_code,      
  rate_type_home,      
  rate_type_oper,      
  rate_home,      
  rate_oper,      
  edit_list_flag,      
  ddid,      
  org_id      
 )      
 SELECT      
  ISNULL((SELECT trx_ctrl_num FROM #bows_arinpchg_link WHERE #bows_arinpchg_link.doc_reference_id=[DocumentReferenceID]),[DocumentReferenceID]),      
  ISNULL((SELECT trx_ctrl_num FROM #bows_arinpchg_link WHERE #bows_arinpchg_link.doc_reference_id=[DocumentReferenceID]),[DocumentReferenceID]),      
  '',   -- doc_ctrl_num (assigned during printing)      
  ISNULL([DocDescription],''),      
  ISNULL([ApplyToControlNum],''),      
  CASE WHEN (([DocumentType]='C') AND (NOT ISNULL([ApplyToControlNum],'')='')) THEN 2031 ELSE 0 END, -- apply_trx_type      
  ISNULL([OrderControlNum],''),      
  '',   -- batch_code      
  CASE [DocumentType] WHEN 'C' THEN 2032 ELSE 2031 END, -- trx_type      
  (SELECT datediff(dd, '1/1/80', CONVERT(datetime,CONVERT(varchar(19),ISNULL([DateEntered],[DateDocument]))))+722815), --rev 4: changed length from 23 to 19 in varchar      
  (SELECT datediff(dd, '1/1/80', CONVERT(datetime,CONVERT(varchar(19),ISNULL([DateApply],[DateDocument]))))+722815), --rev 4      
  (SELECT datediff(dd, '1/1/80', CONVERT(datetime,CONVERT(varchar(19),[DateDocument])))+722815),    --rev 4      
  (SELECT datediff(dd, '1/1/80', CONVERT(datetime,CONVERT(varchar(19),ISNULL([DateShipped],[DateDocument]))))+722815), --rev 4      
  (SELECT datediff(dd, '1/1/80', CONVERT(datetime,CONVERT(varchar(19),ISNULL([DateRequired],[DateDocument]))))+722815), --rev 4      
  --(SELECT datediff(dd, '1/1/80', CONVERT(datetime,CONVERT(varchar(19),ISNULL([DateDue],[DateDocument]))))+722815), --rev 4      
(SELECT datediff(dd, '1/1/80', CONVERT(datetime,CONVERT(varchar(19),ISNULL([DateAging],[DateDocument]))))+722815), --rev 4      --fzambada
  (SELECT datediff(dd, '1/1/80', CONVERT(datetime,CONVERT(varchar(19),ISNULL([DateAging],[DateDocument]))))+722815), --rev 4      
  [CustomerCode],      
  ISNULL([ShipToCode],''),-- ship_to_code      
  [SalesPersonCode], --ISNULL([SalesPersonCode],''), --rev 5      
  [TerritoryCode], -- territory_code      
  [CommentCode],      
  [FobCode],      
  [FreightCode],      
  [TermsCode],      
  [FinChargeCode], -- fin_chg_code (null will pick up cust. default)      
  [PriceCode],  -- price_code (null will pick up cust. default)      
  [DestZoneCode],  -- dest_zone_code      
  [PostingCode],      
  CASE [DocumentType] WHEN 'C' THEN 1 ELSE ISNULL([RecurringFlag],0) END,      
  ISNULL([RecurringCode],''),      
  [TaxCode],      
  ISNULL([CustomerPO],''),      
  ISNULL([TotalWeight],0.0),      
  0.0,   -- amt_gross      
  ISNULL([AmountFreight],0.0),      
  0.0,   -- amt_tax      
  0.0,   -- amt_tax_included      
  0.0,   -- amt_discount (we are not handling discounts)      
  0.0,   -- amt_net      
  0.0,   -- amt_paid      
  0.0,   -- amt_due      
  0.0,   -- amt_cost      
  0.0,   -- amt_profit      
  0,   -- next_serial_id      
  ISNULL([PrintedFlag],0),      
  0,   -- posted_flag      
  ISNULL([HoldFlag],0),      
  ISNULL([HoldDescription],''),      
  1,   -- user_id      
  [CustomerAddress1],      
  [CustomerAddress2],      
  [CustomerAddress3],      
  [CustomerAddress4],      
  [CustomerAddress5],      
  [CustomerAddress6],      
  [ShipToAddress1],      
  [ShipToAddress2],      
  [ShipToAddress3],      
  [ShipToAddress4],      
  [ShipToAddress5],    [ShipToAddress6],      
  [AttentionName], --ISNULL([AttentionName],''), --rev 5      
  [AttentionPhone], --ISNULL([AttentionPhone],''), rev 5      
  0.0,   -- amt_rem_rev      
  0.0,   -- amt_rem_tax      
  0,   -- date_recurring      
  '',   -- location_code      
  null,   -- process_group_num      
  null,   -- trx_state      
  null,   -- mark_flag      
  0.0,   -- amt_discount_taken      
  0.0,   -- amt_write_off_given      
  [SourceControlNumber], --ISNULL([SourceControlNumber],''), -- source_trx_ctrl_num --rev 5      
  null, --0,   -- source trx type --rev 5      
  [TransactionalCurrency],      
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
  '',--0,   -- edit_list_flag --rev 5      
  0 , --null,   --ddid --rev 5      
  CASE @ib_flag WHEN 1 THEN ISNULL([OrganizationID],@org_id) ELSE @org_id END      
 FROM CVO_INVHeader   --Rev 1      
 SELECT @Error=@@ERROR      
 IF @Error<>0 BEGIN      
  INSERT #bows_arerror(err_code, err_msg) SELECT 40, 'SQL Error preparing header' GOTO lbERROR_RETURN      
 END      
      
 -->>validate no duplicates in details      
 SELECT [SequenceID]+[DocumentReferenceID]      
 FROM CVO_INVDetail   --Rev 1      
 GROUP BY [DocumentReferenceID],[SequenceID]      
 HAVING Count([SequenceID])>1      
 IF @@rowcount>0 BEGIN      
  INSERT #bows_arerror(err_code, err_msg) SELECT 50, 'Duplicate SequenceID' GOTO lbERROR_RETURN      
 END      
      
 -->>prepare details temp table      
 INSERT #arinpcdt(      
  link,      
  trx_ctrl_num,      
  doc_ctrl_num,      
  sequence_id,      
  trx_type,      
  location_code,      
  item_code,      
  bulk_flag,      
  date_entered,      
  line_desc,      
  qty_ordered,      
 qty_shipped,      
  unit_code,      
  unit_price,      
  unit_cost,      
  weight,      
  serial_id,      
  tax_code,      
  gl_rev_acct,      
  disc_prc_flag,      
  discount_amt,      
  commission_flag,      
  rma_num,      
  return_code,      
  qty_returned,      
  qty_prev_returned,      
  new_gl_rev_acct,      
  iv_post_flag,      
  oe_orig_flag,      
  discount_prc,      
  extended_price,      
  calc_tax,      
  reference_code,      
  trx_state,      
  mark_flag,      
  cust_po,      
  org_id      
 )      
 SELECT      
  ISNULL((SELECT trx_ctrl_num FROM #bows_arinpchg_link WHERE #bows_arinpchg_link.doc_reference_id=[DocumentReferenceID]),[DocumentReferenceID]),      
  ISNULL((SELECT trx_ctrl_num FROM #bows_arinpchg_link WHERE #bows_arinpchg_link.doc_reference_id=[DocumentReferenceID]),[DocumentReferenceID]),      
  '',   -- doc_ctrl_num (assigned during printing)      
  [SequenceID],      
  ISNULL((SELECT a.trx_type FROM #arinpchg a, #bows_arinpchg_link b WHERE a.trx_ctrl_num=b.trx_ctrl_num and b.doc_reference_id=[DocumentReferenceID]),2031),      
  CASE WHEN (ISNULL([ItemCode],'')<>'') AND (ISNULL([Location],'')='') THEN 'EXTERNAL'      
   ELSE ISNULL([Location],'') END,      
  [ItemCode],  -- item_code      
  0,   -- bulk_flag      
  (SELECT datediff(dd, '1/1/80', CONVERT(datetime,CONVERT(varchar(19),[DateEntered])))+722815), --rev 4      
  [LineDescription],      
  ISNULL([QtyOrdered],ISNULL([QtyShipped],1.0)),      
  ISNULL([QtyShipped],ISNULL([QtyOrdered],1.0)),      
  [SalesUOMCode],  -- unit_code      
  CASE ISNULL([UnitPrice],0.0) WHEN 0.0 THEN ISNULL([ExtendedPrice],0) ELSE [UnitPrice] END,      
  0.0,   -- unit_cost      
  ISNULL([Weight],0.0),      
  0,   -- serial_id      
  [TaxCode],      
  [GLRevAccount],      
  ISNULL([DiscPrcFlag],0),      
  ISNULL([AmountDiscount],0.0),      
  0,   -- commission_flag      
  '',   -- rma_num      
  ISNULL([ReturnCode],''),      
  ISNULL([QtyReturned],0.0),      
  0.0,   -- qty_prev_returned      
  '',   -- new_gl_rev_acct      
  1,--0,   -- iv_post_flag, --rev 5      
  ISNULL([OEFlag],0), -- oe_orig_flag,      
  ISNULL([DiscPrc],0.0),      
  [ExtendedPrice], -- if null it will be calculated      
  0.0,   -- calc_tax      
  ISNULL([GLReferenceCode],''),      
  0,   -- trx_state,      
  0,   -- mark_flag      
  ISNULL([CustomerPO],''),      
  CASE @ib_flag WHEN 1 THEN ISNULL([OrganizationID],@org_id) ELSE @org_id END      
 FROM CVO_INVDetail   --Rev 1      
 SELECT @Error=@@ERROR      
 IF @Error<>0 BEGIN      
  INSERT #bows_arerror(err_code, err_msg) SELECT 60, 'Error preparing detail' GOTO lbERROR_RETURN      
 END      
      
 -->>prepare tax temp table      
 INSERT INTO #bows_arinptax_link (      
  doc_reference_id,      
  trx_ctrl_num,      
  trx_type,      
  tax_type_code,      
  amt_final_tax      
 )      
 SELECT      
  [DocumentReferenceID],      
  ISNULL((SELECT trx_ctrl_num FROM #bows_arinpchg_link WHERE #bows_arinpchg_link.doc_reference_id=[DocumentReferenceID]),[DocumentReferenceID]),      
  ISNULL((SELECT a.trx_type FROM #arinpchg a, #bows_arinpchg_link b WHERE a.trx_ctrl_num=b.trx_ctrl_num and b.doc_reference_id=[DocumentReferenceID]),2031),      
  [TaxTypeCode],      
  [TaxAmount]      
 FROM CVO_INVTax   --Rev 1      
 IF @Error<>0 BEGIN      
  INSERT #bows_arerror(err_code, err_msg) SELECT 90, 'Error preparing detail' GOTO lbERROR_RETURN      
 END      
      
 -->>fetch tax calculate mode      
 UPDATE #bows_arinptax_link      
 SET tax_calculated_mode = ISNULL([TaxCalculatedMode],0)      
 FROM  CVO_INVHeader a, #bows_arinptax_link b, #bows_arinpchg_link c   --Rev 1      
 WHERE a.[DocumentReferenceID] = c.doc_reference_id      
 AND b.trx_ctrl_num = c.trx_ctrl_num      
 SELECT @Error=@@ERROR      
 IF @Error<>0 BEGIN      
  INSERT #bows_arerror(err_code, err_msg) SELECT 91, 'SQL Error fetching tax calculated mode' GOTO lbERROR_RETURN      
 END      
      
 -->>prepare commission temp table      
 INSERT #arinpcom(      
  trx_ctrl_num,      
  trx_type,      
  sequence_id,      
  salesperson_code,      
  amt_commission,      
  percent_flag,      
  exclusive_flag,      
  split_flag      
 )      
 SELECT      
  ISNULL((SELECT trx_ctrl_num FROM #bows_arinpchg_link WHERE #bows_arinpchg_link.doc_reference_id=[DocumentReferenceID]),[DocumentReferenceID]),      
  ISNULL((SELECT a.trx_type FROM #arinpchg a, #bows_arinpchg_link b WHERE a.trx_ctrl_num=b.trx_ctrl_num and b.doc_reference_id=[DocumentReferenceID]),2031),      
  [SequenceID],      
  [SalesPersonCode],      
  ISNULL([CommissionAmount],0.0),      
  CASE ISNULL([SplitFlag],0) WHEN 1 THEN 0 ELSE ISNULL([PercentFlag],0) END,      
  CASE ISNULL([SplitFlag],0) WHEN 1 THEN 0 ELSE ISNULL([ExclusiveFlag],0) END,      
  ISNULL([SplitFlag],0)      
 FROM CVO_INVCommission   --Rev 1      
 SELECT @Error=@@ERROR      
 IF @Error<>0 BEGIN      
  INSERT #bows_arerror(err_code, err_msg) SELECT 75, 'Error preparing commission' GOTO lbERROR_RETURN      
 END      
      
 /*      
 *Begin Rev 1      
 *Fill together header and detail notes from representation table      
 */      
 -->>prepare notes temp table      
 INSERT INTO #bows_doc_notes (      
  trx_ctrl_num,      
  trx_type,      
  sequence_id,      
  link,      
  note,      
  show_line_mode      
 )      
 SELECT      
  ISNULL((SELECT trx_ctrl_num FROM #bows_arinpchg_link WHERE #bows_arinpchg_link.doc_reference_id=[DocumentReferenceID]),[DocumentReferenceID]),      
  ISNULL((SELECT a.trx_type FROM #arinpchg a, #bows_arinpchg_link b WHERE a.trx_ctrl_num=b.trx_ctrl_num and b.doc_reference_id=[DocumentReferenceID]),2031),      
  NULL,      
  ISNULL([Link],''),      
  ISNULL([Note],''),      
  [ShowLineMode]      
 FROM CVO_INVNotes      
 ORDER BY [DocumentReferenceID],[SequenceID]      
 SELECT @Error=@@ERROR      
 IF @Error<>0 BEGIN     
  INSERT #bows_arerror(err_code, err_msg) SELECT 76, 'SQL Error during preparing invoice notes' GOTO lbERROR_RETURN      
 END      
 /*      
 *End Rev 1      
 */      
      
 IF @debug_level>5 BEGIN      
  SELECT '#arinpchg data from XML'      
  select * from #arinpchg      
  SELECT '#arinpcdt data from XML'      
  select * from #arinpcdt      
  SELECT '#bows_arinptax_link data from XML'      
  select * from #bows_arinptax_link      
  SELECT '#arinpcom data from XML'      
  select * from #arinpcom      
  SELECT 'BOWS_DOC_NOTES data from XML'      
  select * from #bows_doc_notes      
 END      
      
 -->> Call AR import stored procedure      
 EXEC @ret_status = bows_ARINImportBatch_SP @debug_level=@debug_level      
 IF (@ret_status<>0) AND (NOT EXISTS(SELECT 1 FROM #ewerror)) BEGIN      
  INSERT #bows_arerror(err_code, err_msg) SELECT 100, 'Error import stored proc' GOTO lbERROR_RETURN      
 END      
      
 IF EXISTS(SELECT 1 FROM #ewerror) BEGIN      
  INSERT  #bows_arerror(ControlNumber,SequenceID,err_code,      
   err_msg,      
   err_parameter)      
  SELECT  trx_ctrl_num, sequence_id,err_code,      
   ISNULL((SELECT b.err_desc FROM aredterr b WHERE b.e_code=#ewerror.err_code),'') +      
   RTRIM(' ' + RTRIM(ISNULL(info1,'')+' ') + RTRIM(ISNULL(info2,''))),      
   null      
  FROM #ewerror      
 END      
      
lbERROR_RETURN:      
      
 --Form Resulting XML      
 SELECT '$FIN_RESULTS$' --Keyword for the result parser      
      
 IF EXISTS(SELECT 1 FROM #bows_arerror)      
  SELECT @ret_status=CASE @ret_status WHEN 0 THEN -1 ELSE @ret_status END      
      
 SELECT '<Status>' + convert(varchar, @ret_status) + '</Status>'      
      
 SELECT '<InvoiceList>'      
 SELECT      
  RTRIM(a.trx_ctrl_num) as ControlNumber,      
  RTRIM(doc_reference_id) as DocumentReferenceID,      
  CASE WHEN RTRIM(a.doc_ctrl_num)='' THEN NULL ELSE a.doc_ctrl_num END as DocumentNumber,      
  CASE WHEN RTRIM(a.batch_code)='' THEN NULL ELSE a.batch_code END as BatchNumber      
 FROM #bows_arinpchg_link as Invoice, arinpchg a      
 WHERE Invoice.trx_ctrl_num = a.trx_ctrl_num      
 FOR XML AUTO, ELEMENTS      
 SELECT '</InvoiceList>'      
      
 IF EXISTS(SELECT 1 FROM #bows_arerror) BEGIN      
  SELECT '<ErrorList>'      
  SELECT      
   err_code  as  ErrorCode,      
   RTRIM(err_msg)  as ErrorDescription,      
   RTRIM(err_parameter) as ErrorParameter,      
   CASE SequenceID WHEN 0 THEN NULL ELSE SequenceID END as SequenceID,      
   (SELECT doc_reference_id FROM #bows_arinpchg_link WHERE trx_ctrl_num=Error.ControlNumber) as DocumentReferenceID      
  FROM #bows_arerror as Error      
  FOR XML AUTO, ELEMENTS      
  SELECT '</ErrorList>'      
 END      
        
 DROP TABLE #arinpchg      
 DROP TABLE #arinpcdt      
 DROP TABLE #arinpcom      
 DROP TABLE #ewerror      
 DROP TABLE #bows_arinpchg_link      
 DROP TABLE #bows_arinptax_link      
 DROP TABLE #bows_arerror      
 DROP TABLE #bows_doc_notes      
      
 RETURN @ret_status 
GO
GRANT EXECUTE ON  [dbo].[bows_ar_import_invoice_xml_sp] TO [public]
GO
