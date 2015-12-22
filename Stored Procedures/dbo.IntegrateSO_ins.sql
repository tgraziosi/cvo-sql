SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
                      
CREATE PROCEDURE [dbo].[IntegrateSO_ins] (@debug_level int = 0)                      
AS                      
                      
DECLARE @iError   NUMERIC                      
DECLARE @errors   VARCHAR(8000)                      
DECLARE @result   INT                      
DECLARE @hDoc    INTEGER                      
DECLARE @key_table   VARCHAR(30)                      
DECLARE @key_table2  VARCHAR(30)                      
DECLARE @ErrorInd  INTEGER                      
                      
declare @ext int                  
DECLARE @TEMPrequireddate  DATETIME                        
DECLARE @TEMPsonumber   VARCHAR(18)                        
DECLARE @TEMPusrfirstname  VARCHAR(18)                        
DECLARE @TEMPusrlastname  VARCHAR(18)                        
DECLARE @TEMPshipto   VARCHAR(50)                       
DECLARE @TEMPshiptoaddress1  VARCHAR(50)                        
DECLARE @TEMPshiptoaddress2  VARCHAR(50)                        
DECLARE @TEMPshiptoaddress3  VARCHAR(50)                       
DECLARE @TEMPshiptoaddress4  VARCHAR(50)                        
DECLARE @TEMPshiptoaddress5  VARCHAR(50)                        
DECLARE @TEMPshiptoaddress6  VARCHAR(50)                        
DECLARE @TEMPshiptocity  VARCHAR(40)                        
DECLARE @TEMPshiptostate  VARCHAR(50)                        
DECLARE @TEMPshiptozip   CHAR(10)                        
DECLARE @TEMPshiptocountry  VARCHAR(20)                        
DECLARE @TEMPordcountry  VARCHAR(20)                       
DECLARE @TEMPtransstatus  VARCHAR(20)                        
DECLARE @TEMPsoldto  VARCHAR(10)                      
DECLARE @TEMPsoldtoaddress1  VARCHAR(50)                        
DECLARE @TEMPsoldtoaddress2  VARCHAR(50)                        
DECLARE @TEMPsoldtoaddress3  VARCHAR(50)                        
DECLARE @TEMPsoldtoaddress4  VARCHAR(50)                        
DECLARE @TEMPsoldtoaddress5  VARCHAR(50)                        
DECLARE @TEMPsoldtoaddress6  VARCHAR(50)                       
DECLARE @TEMPcarrier  VARCHAR(20)                      
DECLARE @TEMPfob   VARCHAR(8)                      
DECLARE @TEMPterms  VARCHAR(8)                      
DECLARE @TEMPtax  VARCHAR(8)                      
DECLARE @TEMPpostingcode VARCHAR(8)                       
DECLARE @TEMPcurrency  VARCHAR(8)                       
DECLARE @TEMPsalesperson VARCHAR(8)                       
DECLARE @TEMPuserstatus  VARCHAR(8)                       
DECLARE @TEMPblanket  CHAR(1)                      
DECLARE @TEMPblanketfrom DATETIME                       
DECLARE @TEMPblanketto  DATETIME                       
DECLARE @TEMPblanketamount FLOAT                       
DECLARE @TEMPlocation  VARCHAR(10)                       
DECLARE @TEMPbackorder  CHAR(1)                       
DECLARE @TEMPcategory  VARCHAR(10)                       
DECLARE @TEMPsopriority  CHAR(1)                       
DECLARE @TEMPdisc  VARCHAR(13)                      
DECLARE @TEMPdeliverydt  DATETIME                       
DECLARE @TEMPshipdt  DATETIME                      
DECLARE @TEMPcanceldt  DATETIME                       
DECLARE @TEMPmessageid   VARCHAR(50)                       
DECLARE @TEMPnote  VARCHAR(255)                      
DECLARE @TEMPhold  VARCHAR(10)                      
DECLARE @TEMPshipinst  VARCHAR(255)                       
DECLARE @TEMPfowarder  VARCHAR(8)                       
DECLARE @TEMPfreight  VARCHAR(13)                      
DECLARE @TEMPfreightto  VARCHAR(8)                       
DECLARE @TEMPfreighttype VARCHAR(8)                       
DECLARE @TEMPuserdeffld1 VARCHAR(255)                       
DECLARE @TEMPuserdeffld2 VARCHAR(255)                       
DECLARE @TEMPuserdeffld3 VARCHAR(255)                       
DECLARE @TEMPuserdeffld4 VARCHAR(255)                       
DECLARE @TEMPuserdeffld5 FLOAT                       
DECLARE @TEMPuserdeffld6 FLOAT                       
DECLARE @TEMPuserdeffld7 FLOAT                       
DECLARE @TEMPuserdeffld8 FLOAT                
DECLARE @TEMPuserdeffld9 INTEGER                       
DECLARE @TEMPuserdeffld10 INTEGER                       
DECLARE @TEMPuserdeffld11 INTEGER                       
DECLARE @TEMPuserdeffld12 INTEGER                       
DECLARE @TEMPpoaction  SMALLINT                       
DECLARE @TEMPpay_code  VARCHAR(8)                      
                      
                      
DECLARE @TEMPsonumberdet  VARCHAR(18)                       
DECLARE @TEMPlinenumber  INTEGER              
DECLARE @TEMPpartno   VARCHAR(20)                       
DECLARE @TEMPtype  CHAR(1)                      
DECLARE @TEMPquantity   NUMERIC                       
DECLARE @TEMPunitofmeasure  VARCHAR(20)                       
DECLARE @TEMPloc   VARCHAR(10)                      
DECLARE @TEMPitemdescription VARCHAR(255)                       
DECLARE @TEMPdetailcomment  VARCHAR(255)               
DECLARE @TEMPcompany   VARCHAR(180)                      
DECLARE @TEMPaccount   VARCHAR(180)                       
DECLARE @TEMPcomm  VARCHAR(13)                       
DECLARE @TEMPtaxcode  VARCHAR(10)                      
DECLARE @TEMPcustomer  VARCHAR(20)                      
DECLARE @TEMPusercount  INT                      
DECLARE @TEMPcreatepo  SMALLINT                      
DECLARE @TEMPbackorderdet CHAR(1)                      
DECLARE @TEMPreference   VARCHAR(180)                      
DECLARE @TEMPlogin   VARCHAR(30)                       
DECLARE @TEMPsoaction   INT                       
DECLARE @TEMPprice   DECIMAL(20, 8)                       
DECLARE @TEMPfreightdet  DECIMAL(20,8)                      
DECLARE @TEMPwhoentered  VARCHAR(20)                       
DECLARE @TEMPitemnote  VARCHAR(255)                      
DECLARE @so_no   VARCHAR(18)                      
DECLARE @TEMPord_total  DECIMAL(13)                      
                      
                      
                      
                      
DECLARE @TEMPattention  VARCHAR(40)                       
DECLARE @TEMPphone  VARCHAR(20)                      
DECLARE @TEMPconsolidation SMALLINT                      
DECLARE @TEMPcustcode  VARCHAR(10)                      
DECLARE @TEMPautoship  CHAR(1)                      
DECLARE @TEMPmultipleship CHAR(1)                      
DECLARE @TEMPshipto_det  VARCHAR(10)                      
DECLARE @TEMPsold_to_city                       varchar  (40)                       
DECLARE @TEMPsold_to_state                      varchar  (40)                       
DECLARE @TEMPsold_to_zip                        varchar  (15)                      
DECLARE @TEMPsold_to_country_cd                 varchar  (3)                      
DECLARE @dummie   INTEGER                      
DECLARE @ACC   VARCHAR(20)                      
DECLARE @acct_masked  VARCHAR(255)                      
DECLARE @key   VARCHAR(255)                      
DECLARE @TEMPinternal_so_ind INTEGER                      
                      
                      
                      
DECLARE @err_section   CHAR(30)                      
                      
SET @err_section = 'IntegrateSO_ins.sp'                      
IF ( @debug_level > 0 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/IntegrateSO_ins.sp' + ', line ' + STR( 124, 5 ) + ' -- ENTRY: '                      
CREATE TABLE #ewerror                      
(                      
 module_id smallint,                      
 err_code  int,                      
 info char(255),                      
 source char (20),                      
 sequence_id int                      
)                      
                      
CREATE TABLE #arcrchk                      
(                       
  customer_code  varchar(8),                      
  check_credit_limit  smallint,                      
  credit_limit  float,                      
  limit_by_home  smallint                      
)                      
CREATE UNIQUE INDEX #arcrchk_ind_0 ON #arcrchk (customer_code)                      
                      
                      
                      
SET @iError = 0                       
SET @errors = ''                      
                      
                      
IF ( @debug_level > 0 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/IntegrateSO_ins.sp' + ', line ' + STR( 124, 5 ) + ' -- Fill temp tables: '                      
                      
--             
--INSERT INTO CVO_TempSO                       
-- SELECT   [RequiredDate],                      
--   [SONumber],                      
--   [CustCode],                      
--   [UsrFirstName],                      
--   [UsrLastName],                      
--   [ShipTo],                      
--   [ShipToAddress1],                      
--   [ShipToAddress2],                      
--   [ShipToAddress3],                      
--   [ShipToAddress4],                      
--   [ShipToAddress5],                      
--   [ShipToAddress6],                      
--   [ShipToCity],                      
--   [ShipToState],                      
--   [ShipToZip],                      
--   [OrdCountry],                      
--   [TransStatus],                      
--   [SoldTo],                      
--   [SoldToAddress1],                      
--   [SoldToAddress2],                      
--   [SoldToAddress3],                      
--   [SoldToAddress4],                      
--   [SoldToAddress5],                      
--   [SoldToAddress6],                      
--   [Carrier],                      
--   [Fob],                      
--   [Terms],                      
--   [Tax],                      
--   [PostingCode],                      
--   [Currency],                      
--   [SalesPerson],                      
--   [UserStatus],                      
--   ISNULL([Blanket], 'N'),                      
--   [BlanketFrom],                      
--   [BlanketTo],                      
--   [BlanketAmount],                      
--   [Location],                      
--   [BackOrder],                      
--   [Category],                      
--   [SOPriority],                     
--   [Disc],                      
--   [DeliveryDt],                      
--   [ShipDt],                      
--   [CancelDt],                      
--   [MessageID],                      
--   [Note],                      
--   [Hold],                      
--   [ShipInst],                      
--   [Fowarder],                      
--   [Freight],                      
--   [FreightTo],                      
--   [FreightType],                      
--   [Consolidate],                      
--   [UserDefFld1],                      
--   [UserDefFld2],                      
--   [UserDefFld3],                        
--   [UserDefFld4],                      
--   [UserDefFld5],                      
--   [UserDefFld6],                      
--   [UserDefFld7],                      
--   [UserDefFld8],                      
--   [UserDefFld9],                      
--   [UserDefFld10],                      
--   [UserDefFld11],                      
--   [UserDefFld12],                      
--   [Poaction],                      
--   [Attention],                      
--   [Phone],                      
--                      
--   [AutoShip],                       
--   [MultipleShip],                        
--                      
--   [SoldToCity],                      
--   [SoldToState],                      
--   [SoldToZip],                      
--   [SoldToCountry],                      
--                      
--                      
--   [NewSO],                      
--   [InternalSoInd]                      
-- FROM OPENXML (@hDoc, '/BackOfficeIV.SalesOrder/SalesOrder/Header', 2)                      
-- WITH                      
-- (                      
-- key_table   INTEGER ,                       
-- RequiredDate   DATETIME 'req_ship_date',                       
-- SONumber   VARCHAR(18) 'order_no',                       
-- CustCode  VARCHAR(10) 'cust_code',                      
-- UsrFirstName   VARCHAR(18),                       
-- UsrLastName   VARCHAR(18),        
-- ShipTo    VARCHAR(50) 'ship_to',                       
-- ShipToAddress1   VARCHAR(50) 'ship_to_add_1',                       
-- ShipToAddress2   VARCHAR(50) 'ship_to_add_2',                       
-- ShipToAddress3   VARCHAR(50) 'ship_to_add_3',                      
-- ShipToAddress4   VARCHAR(50) 'ship_to_add_4',                       
-- ShipToAddress5   VARCHAR(50) 'ship_to_add_5',                       
-- ShipToAddress6   VARCHAR(50),                       
-- ShipToCity   VARCHAR(40) 'ship_to_city',                       
-- ShipToState   VARCHAR(50) 'ship_to_state',                       
-- ShipToZip   CHAR(10) 'ship_to_zip',                       
-- OrdCountry VARCHAR(20) 'ship_to_country',                      
-- TransStatus   VARCHAR(20),                       
-- SoldTo   VARCHAR(10) 'cust_code',                      
-- SoldToAddress1   VARCHAR(50) 'sold_to_addr1',                       
-- SoldToAddress2   VARCHAR(50) 'sold_to_addr2',                       
-- SoldToAddress3   VARCHAR(50) 'sold_to_addr3',                       
-- SoldToAddress4   VARCHAR(50) 'sold_to_addr4',                       
-- SoldToAddress5   VARCHAR(50) 'sold_to_addr5',                       
-- SoldToAddress6   VARCHAR(50) 'sold_to_addr6',                      
-- Carrier   VARCHAR(20) 'routing',                      
-- Fob    VARCHAR(8) 'fob',                      
-- Terms   VARCHAR(8) 'terms',                      
-- Tax   VARCHAR(8) 'tax_id',                      
-- PostingCode  VARCHAR(8) 'posting_code',                       
-- Currency  VARCHAR(8) 'curr_key',                      
-- SalesPerson  VARCHAR(8) 'salesperson',                      
-- UserStatus  VARCHAR(8) 'user_code',                      
-- Blanket   CHAR(1)  'blanket',                      
-- BlanketFrom  DATETIME 'from_date',                      
-- BlanketTo  DATETIME 'to_date',                      
-- BlanketAmount  FLOAT  'blanket_amt',                      
-- Location  VARCHAR(10) 'location',                      
-- BackOrder  CHAR(1)  'back_ord_flag',                      
-- Category  VARCHAR(10) 'user_category',                      
-- SOPriority  CHAR(1)  'so_priority_code',                      
-- Disc   VARCHAR(13) 'discount',                      
-- DeliveryDt  DATETIME,                      
-- ShipDt   DATETIME 'sch_ship_date',                      
-- CancelDt  DATETIME 'cancel_date',                      
-- MessageID   VARCHAR(50),                      
-- Note    VARCHAR(255) 'note',                      
-- Hold   VARCHAR(10) 'hold_reason',                      
-- ShipInst  VARCHAR(255) 'special_instr',                      
-- Fowarder  VARCHAR(8) 'forwarder_key',                      
-- Freight   VARCHAR(13) 'freight',                      
-- FreightTo  VARCHAR(8) 'freight_to',                      
-- FreightType  VARCHAR(8) 'freight_allow_type',                      
-- Consolidate  SMALLINT 'consolidate_flag',                      
-- UserDefFld1  VARCHAR(255) 'user_def_fld1',                      
-- UserDefFld2  VARCHAR(255) 'user_def_fld2',                      
-- UserDefFld3  VARCHAR(255) 'user_def_fld3',                      
-- UserDefFld4  VARCHAR(255) 'user_def_fld4',                      
-- UserDefFld5  FLOAT  'user_def_fld5',                      
-- UserDefFld6  FLOAT  'user_def_fld6',                      
-- UserDefFld7  FLOAT  'user_def_fld7',                      
-- UserDefFld8  FLOAT  'user_def_fld8',                      
-- UserDefFld9  INTEGER  'user_def_fld9',                      
-- UserDefFld10  INTEGER  'user_def_fld10',                      
-- UserDefFld11  INTEGER  'user_def_fld11',                      
-- UserDefFld12  INTEGER  'user_def_fld12',                      
-- Poaction  SMALLINT,                      
--                      
-- Attention  VARCHAR(40) 'attention',                      
-- Phone   VARCHAR(20) 'phone',                      
--                      
-- AutoShip  CHAR(1)  'autoship',                       
-- MultipleShip  CHAR(1)  'multiple_flag',                       
--                      
-- SoldToCity  VARCHAR(40) 'sold_to_city',                      
-- SoldToState  VARCHAR(40) 'sold_to_state',                      
-- SoldToZip  VARCHAR(15) 'sold_to_zip',                      
-- SoldToCountry   VARCHAR(3) 'sold_to_country_cd',                      
--                      
-- NewSO   VARCHAR(18),                      
-- InternalSoInd INTEGER  'internal_so_ind'                      
-- )                      
--                      
--                      
--                      
--                      
--                      
--                      
--              
--SET @result = @@error                      
--IF @result <> 0                       
--BEGIN                       
-- INSERT #ewerror (module_id,err_code, info, source, sequence_id) VALUES (18000, 10, @err_section + '', '', 0)                       
--END                       
--                      
--INSERT INTO CVO_TempSOD                       
-- SELECT   [SONumber],                       
--   [LineNumber],                      
--   [PartNo],                       
--   [Type],                       
--   [Quantity],                       
--   [UnitOfMeasure],                       
--   [Loc],                       
--   [ItemDescription],                      
--   [DetailComment],                       
--   [Company],                       
--   [Account],                       
--   [Comm],                          
--   [TaxCode],                         
--   [Customer],                         
--   [UserCount],                         
--   [CreatePO],                         
--   [BackOrder],         --   [Reference],                        
--   [Login],                       
--   [SOAction],                       
--   [Price],                       
--   [Freight],                      
--   [Poaction],                      
--                      
--   [ShipTo],                      
--                      
--   [Fob],                      
--   [Routing],                      
--   [Forwarder],                      
--   [ShipToRegion],                      
--   [DestZone],                      
--                      
--  [ItemNote]                      
-- FROM OPENXML (@hDoc, '/BackOfficeIV.SalesOrder/SalesOrder/Header/Items/Item', 2)                      
-- WITH                      
--(                      
-- key_table   INTEGER ,                       
-- SONumber   VARCHAR(18) 'order_no', --'cust_po',                       
-- LineNumber   INTEGER  'line_no',                      
-- PartNo    VARCHAR(20) 'part_no',                       
-- Type   CHAR(1)  'part_type',                      
-- Quantity   NUMERIC  'ordered',                       
-- UnitOfMeasure   VARCHAR(20) 'uom',                       
-- Loc    VARCHAR(50) 'location',                       
-- ItemDescription  VARCHAR(255) 'description',                       
-- DetailComment   VARCHAR(255),                       
-- Company   VARCHAR(180),                       
-- Account   VARCHAR(180) 'gl_rev_acct',                       
-- Comm   VARCHAR(13),                       
-- TaxCode   VARCHAR(10),                      
-- Customer  VARCHAR(20),                      
-- UserCount  INT,                      
-- CreatePO  SMALLINT,                      
-- BackOrder  CHAR(1),                       
-- Reference   VARCHAR(180) 'reference_code',                      
-- Login    VARCHAR(30),                       
-- SOAction   INT,                       
-- Price    DECIMAL(20, 8)  'price',                       
-- Freight   DECIMAL(20,8),                      
-- Poaction  SMALLINT,                      
--                      
-- ShipTo   VARCHAR(50) 'ship_to',                      
-- Fob   VARCHAR(10) 'fob',                      
-- Routing   VARCHAR(20) 'routing',                      
-- Forwarder  VARCHAR(10) 'forwarder_key',                      
-- ShipToRegion  VARCHAR(10) 'ship_to_region',                      
-- DestZone  VARCHAR(8) 'dest_zone_code',                      
--                      
-- ItemNote  VARCHAR(255) 'note'                      
--)                      
---- WITH CVO_TempSOD                      
--                      
--                      
--SET @result = @@error                      
--IF @result <> 0                       
--BEGIN                       
-- INSERT #ewerror (module_id,err_code, info, source, sequence_id) VALUES (18000, 20, @err_section + '', '', 0)                       
--END                       
--                      
--                      
--INSERT INTO CVO_TempSOPAY                       
--SELECT                       
-- order_no,                      
-- trx_desc,                      
-- date_doc,                      
-- payment_code,                      
-- amt_payment,                      
-- prompt1_inp,                      
-- prompt2_inp,                      
-- prompt3_inp,                      
-- prompt4_inp,                       
-- amt_disc_taken,                      
-- cash_acct_code,                      
-- doc_ctrl_num                      
--FROM OPENXML (@hDoc, '/BackOfficeIV.SalesOrder/SalesOrder/Header/Payment', 2)                      
--WITH CVO_TempSOPAY                      
--                      
--                      
--SET @result = @@error                      
--IF @result <> 0                       
--BEGIN                       
-- INSERT #ewerror (module_id,err_code, info, source, sequence_id) VALUES (18000, 50, @err_section + '', '', 0)                       
--END                       
--                      
--                      
--INSERT INTO CVO_TempSOCO                       
--SELECT DISTINCT                      
-- order_no,                      
-- display_line,                      
-- salesperson,                      
-- sales_comm,                      
-- percent_flag,                      
-- exclusive_flag,                      
-- split_flag,                      
-- note                      
--FROM OPENXML (@hDoc, '/BackOfficeIV.SalesOrder/SalesOrder/Header/Comissions/Comission', 2)                      
--WITH CVO_TempSOCO                      
--                      
--SET @result = @@error                      
--IF @result <> 0                       
--BEGIN                       
-- INSERT #ewerror (module_id,err_code, info, source, sequence_id) VALUES (18000, 60, @err_section + '', '', 0)                       
--END                       
--                    
--                      
--                      
                      
IF ( @debug_level > 0 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/adm_ins_SO_validate.sp' + ', line ' + STR( 124, 5 ) + ' -- Validate information: '                      
EXEC adm_ins_SO_validate                       
                      
IF ( @debug_level > 0 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/adm_ins_SO_dtl_validate.sp' + ', line ' + STR( 124, 5 ) + ' -- Validate information: '                      
EXEC adm_ins_SO_dtl_validate                       
                      
                      
                      
 SET @ErrorInd = 0                      
                      
                      
IF EXISTS (SELECT 1 FROM #ewerror ew INNER JOIN eboerrdef so ON ew.err_code = so.e_code WHERE so.e_level = 1 )                      
 SET @ErrorInd = 1                      
ELSE                      
 BEGIN                      
                      
                      
   SET @key_table = 0                      
   SET @iError = 0                      
                         
   SELECT @key_table = MIN(key_table)                      
   FROM CVO_TempSO                      
   WHERE key_table > @key_table                      
                         
   WHILE @key_table IS NOT NULL                      
   BEGIN                      
                      
                      
    SELECT DISTINCT                      
      @TEMPrequireddate    = TEMP.RequiredDate,              
      @TEMPsonumber     = TEMP.SONumber,         
      @TEMPcustcode    = TEMP.CustCode,                      
      @TEMPusrfirstname    = TEMP.UsrFirstName,                       
      @TEMPusrlastname    = TEMP.UsrLastName,                       
      @TEMPshipto     = ISNULL(TEMP.ShipTo,''),                       
      @TEMPshiptoaddress1    = ISNULL(TEMP.ShipToAddress1,''),                       
      @TEMPshiptoaddress2    = ISNULL(TEMP.ShipToAddress2,''),                       
      @TEMPshiptoaddress3    = ISNULL(TEMP.ShipToAddress3,''),                       
      @TEMPshiptoaddress4    = ISNULL(TEMP.ShipToAddress4,''),                       
      @TEMPshiptoaddress5    = ISNULL(TEMP.ShipToAddress5,''),                       
      @TEMPshiptoaddress6    = ISNULL(TEMP.ShipToAddress6,''),                       
      @TEMPshiptocity    = ISNULL(TEMP.OrdCountry,''),--ISNULL(TEMP.ShipToCity,                       
      @TEMPshiptostate    = ISNULL(TEMP.ShipToState,''),                       
      @TEMPshiptozip     = ISNULL(TEMP.ShipToZip,''),                       
      @TEMPordcountry    = NULL, --TEMP.OrdCountry,                       
      @TEMPtransstatus    = TEMP.TransStatus,                       
      @TEMPsoldto    = TEMP.SoldTo,                       
      @TEMPsoldtoaddress1    = TEMP.SoldToAddress1,                       
      @TEMPsoldtoaddress2    = TEMP.SoldToAddress2,                       
@TEMPsoldtoaddress3    = TEMP.SoldToAddress3,                       
      @TEMPsoldtoaddress4    = TEMP.SoldToAddress4,                       
      @TEMPsoldtoaddress5    = TEMP.SoldToAddress5,                       
      @TEMPsoldtoaddress6    = TEMP.SoldToAddress6,                       
      @TEMPcarrier    = TEMP.Carrier,                       
      @TEMPfob     = TEMP.Fob,                       
      @TEMPterms    = TEMP.Terms,                       
      @TEMPtax    = TEMP.Tax,                       
      @TEMPpostingcode   = TEMP.PostingCode,                       
      @TEMPcurrency    = TEMP.Currency,                       
      @TEMPsalesperson   = TEMP.SalesPerson,             
      @TEMPuserstatus    = TEMP.UserStatus,                       
      @TEMPblanket    = TEMP.Blanket,                       
      @TEMPblanketfrom   = TEMP.BlanketFrom,                       
      @TEMPblanketto = TEMP.BlanketTo,                       
      @TEMPblanketamount   = TEMP.BlanketAmount,                       
      @TEMPlocation    = TEMP.Location,                       
      @TEMPbackorder    = TEMP.BackOrder,                       
      @TEMPcategory    = TEMP.Category,                       
      @TEMPsopriority    = TEMP.SOPriority,                       
      @TEMPdisc    = TEMP.Disc,                       
      @TEMPdeliverydt    = TEMP.DeliveryDt,                       
      @TEMPshipdt    = TEMP.ShipDt,                       
      @TEMPcanceldt    = TEMP.CancelDt,                       
      @TEMPmessageid     = TEMP.MessageID,                       
      @TEMPnote    = TEMP.Note,                       
      @TEMPhold    = TEMP.Hold,                       
      @TEMPshipinst    = TEMP.ShipInst,                       
      @TEMPfowarder    = TEMP.Fowarder,                       
      @TEMPfreight    = TEMP.Freight,                       
      @TEMPfreightto    = TEMP.FreightTo,                       
      @TEMPfreighttype   = TEMP.FreightType,                      
      @TEMPconsolidation   =  TEMP.Consolidate,                      
      @TEMPuserdeffld1   = TEMP.UserDefFld1,                       
      @TEMPuserdeffld2   = TEMP.UserDefFld2,                       
      @TEMPuserdeffld3   = TEMP.UserDefFld3,                         
    @TEMPuserdeffld4   = TEMP.UserDefFld4,                       
      @TEMPuserdeffld5   = TEMP.UserDefFld5,                       
      @TEMPuserdeffld6   = TEMP.UserDefFld6,                       
      @TEMPuserdeffld7   = TEMP.UserDefFld7,                       
      @TEMPuserdeffld8   = TEMP.UserDefFld8,                       
      @TEMPuserdeffld9   = TEMP.UserDefFld9,                       
      @TEMPuserdeffld10   = TEMP.UserDefFld10,                       
      @TEMPuserdeffld11   = TEMP.UserDefFld11,                       
      @TEMPuserdeffld12   = TEMP.UserDefFld12,                       
      @TEMPpoaction    = TEMP.Poaction,                      
      @TEMPattention    = TEMP.Attention,                      
      @TEMPphone    =  TEMP.Phone,                      
      @TEMPautoship    = TEMP.AutoShip,                      
      @TEMPmultipleship   = TEMP.MultipleShip,                      
      @TEMPsold_to_city   = TEMP.SoldToCity,                       
      @TEMPsold_to_state   = TEMP.SoldToState,                       
      @TEMPsold_to_zip   = TEMP.SoldToZip,                       
      @TEMPsold_to_country_cd   = TEMP.SoldToCountry,                      
      @TEMPinternal_so_ind   = TEMP.InternalSoInd                      
    FROM CVO_TempSO TEMP                           
    WHERE key_table = @key_table                      
                      
                      
                      
    EXEC @iError = adm_ins_SO                  
      @order_no                           = @TEMPsonumber    ,                      
      @ship_to                            = @TEMPshipto    ,                      
      @req_ship_date               = @TEMPrequireddate,--@TEMPdeliverydt   ,                    --fzambada rev2  
      @sch_ship_date                      = @TEMPshipdt   ,                      
      @terms                              = @TEMPterms   ,                      
      @routing                            = @TEMPcarrier   ,                      
      @special_instr                      = @TEMPshipinst   ,                      
      @salesperson                        = @TEMPsalesperson  ,                      
      @tax_id                             = @TEMPtax   ,                      
      @fob                                = @TEMPfob    ,                      
      @freight                            = @TEMPfreight   ,                      
      @discount                           = @TEMPdisc   ,                      
      @cancel_date                        = @TEMPcanceldt   ,                      
      @ship_to_add_1                      = @TEMPshiptoaddress1   ,                      
      @ship_to_add_2   = @TEMPshiptoaddress2   ,                      
      @ship_to_add_3                      = @TEMPshiptoaddress3   ,                      
      @ship_to_add_4                      = @TEMPshiptoaddress4   ,                      
      @ship_to_add_5                      = @TEMPshiptoaddress5   ,                      
      @ship_to_city                       = @TEMPshiptocity   ,                      
      @ship_to_state                      = @TEMPshiptostate   ,                      
  @ship_to_zip                        = @TEMPshiptozip    ,                      
      @ship_to_country                    = @TEMPordcountry   ,                      
      @back_ord_flag                      = @TEMPbackorder   ,                      
      @note                               = @TEMPnote   ,                      
    @forwarder_key                      = @TEMPfowarder   ,                      
      @freight_to                         = @TEMPfreightto   ,                      
      @freight_allow_type                 = @TEMPfreighttype  ,                      
      @location                           = @TEMPlocation   ,                      
      @blanket                            = @TEMPblanket   ,                      
      @curr_key           = @TEMPcurrency   ,                      
      @posting_code                       = @TEMPpostingcode  ,                      
      @hold_reason                        = @TEMPhold   ,                      
      @so_priority_code                   = @TEMPsopriority   ,                      
      @blanket_amt                        = @TEMPblanketamount  ,                      
      @user_category                      = @TEMPcategory   ,                      
      @from_date                          = @TEMPblanketfrom  ,                      
      @cust_code    = @TEMPcustcode   ,                      
      @to_date                            = @TEMPblanketto   ,                      
      @sold_to_addr1                      = @TEMPsoldtoaddress1   ,                      
      @sold_to_addr2                      = @TEMPsoldtoaddress2   ,                      
      @sold_to_addr3                      = @TEMPsoldtoaddress3   ,                      
      @sold_to_addr4                     = @TEMPsoldtoaddress4   ,                      
      @sold_to_addr5                      = @TEMPsoldtoaddress5   ,                      
      @sold_to_addr6                      = @TEMPsoldtoaddress6   ,                      
      @user_code                          = @TEMPuserstatus   ,                      
      @user_def_fld1                      = @TEMPuserdeffld1  ,                      
      @user_def_fld2                      = @TEMPuserdeffld2  ,                      
      @user_def_fld3                      = @TEMPuserdeffld3  ,                      
      @user_def_fld4                      = @TEMPuserdeffld4  ,                      
      @user_def_fld5                      = @TEMPuserdeffld5  ,                      
      @user_def_fld6                      = @TEMPuserdeffld6  ,                      
      @user_def_fld7                      = @TEMPuserdeffld7  ,                      
      @user_def_fld8                      = @TEMPuserdeffld8  ,                      
      @user_def_fld9                      = @TEMPuserdeffld9  ,                      
      @user_def_fld10                     = @TEMPuserdeffld10  ,                      
      @user_def_fld11                     = @TEMPuserdeffld11  ,                      
      @user_def_fld12                     = @TEMPuserdeffld12  ,                      
      @sold_to                            = @TEMPsoldto   ,                        
      @attention    = @TEMPattention   ,                      
      @phone     = @TEMPphone   ,                       
      @consolidate_flag   = @TEMPconsolidation  ,                      
      @autoship    = @TEMPautoship   ,                      
      @multipleship = @TEMPmultipleship  ,                      
      @sold_to_city                        = @TEMPsold_to_city  ,                       
      @sold_to_state                       = @TEMPsold_to_state  ,                       
      @sold_to_zip = @TEMPsold_to_zip  ,                       
      @sold_to_country_cd                  = @TEMPsold_to_country_cd  ,          
@status = @TEMPtransstatus,  --fzambada add status                    
 @ext = 0,--@TEMPuserdeffld12,                     
      --@internal_so_ind      =   @TEMPinternal_so_ind,  --fzambada                    
      @so_no     = @so_no OUTPUT                      
                      
                      
                      
    IF @iError <> 0                      
    BEGIN                     
     INSERT #ewerror (module_id,err_code, info, source, sequence_id) VALUES (19000, 10, @err_section + '', '', 0)                       
    END                      
                      
    UPDATE CVO_TempSO                      
    SET NewSO = @so_no                      
    where SONumber = @TEMPsonumber                      
                          
    -------------------------------WHILE-------START---                      
    SET @key_table2 = 0                      
                          
    SELECT @key_table2 = MIN(key_table)                      
    FROM CVO_TempSOD                      
    WHERE key_table > @key_table2                      
                          
                      
                      
                      
    set @TEMPwhoentered = suser_name()                      
                      
    WHILE @key_table2 IS NOT NULL                      
    BEGIN                      
                 
    SELECT   @TEMPsonumberdet  = TEMP.SONumber,                       
@TEMPlinenumber   = TEMP.LineNumber,                      
      @TEMPpartno   = TEMP.PartNo,                       
      @TEMPtype   = TEMP.Type,                       
      @TEMPquantity   = TEMP.Quantity,                       
      @TEMPunitofmeasure  = TEMP.UnitOfMeasure,                       
     @TEMPloc   = TEMP.Loc,                       
      @TEMPitemdescription  = TEMP.ItemDescription,                      
      @TEMPdetailcomment  = TEMP.DetailComment,                       
      @TEMPcompany   = TEMP.Company,                      
      @TEMPaccount   = TEMP.Account,                       
      @TEMPcomm   = TEMP.Comm,                      
      @TEMPtaxcode   = TEMP.TaxCode,                      
      @TEMPcustomer   = TEMP.Customer,                      
      @TEMPusercount   = TEMP.UserCount,                      
      @TEMPcreatepo   = TEMP.CreatePO,                      
      @TEMPbackorderdet  = TEMP.BackOrder,                      
      @TEMPreference   = TEMP.Reference,                        
      @TEMPlogin   = TEMP.Login,                       
      @TEMPsoaction   = TEMP.SOAction,                       
      @TEMPprice   = TEMP.Price,                       
      @TEMPfreightdet   = TEMP.Freight,                      
      @TEMPpoaction   = TEMP.Poaction,                      
      @TEMPshipto_det   = TEMP.ShipTo,                      
      @TEMPitemnote   = TEMP.ItemNote                       
     FROM CVO_TempSOD TEMP                      
      INNER JOIN CVO_TempSO TEMP2 ON TEMP.SONumber = TEMP2.SONumber                             
     WHERE TEMP.key_table = @key_table2 AND TEMP2.NewSO = @so_no                      
                      
                      
     EXEC @iError = adm_ins_SO_dtl                      
      @cust_code     = @TEMPcustomer,                       
      @cust_po    = @TEMPsonumberdet,                      
      @line_no    = @TEMPlinenumber,                       
      @location    = @TEMPloc,                       
      @part_no    = @TEMPpartno,                       
      @ordered      = @TEMPquantity,                      
      @uom      = @TEMPunitofmeasure,                       
      @note     = @TEMPitemnote,                       
      @gl_rev_acct    = @TEMPaccount,                       
      @reference_code  = @TEMPreference,                      
      @price   = @TEMPprice,                       
      @Who_entered   = @TEMPwhoentered,                      
      @part_type  = @TEMPtype,                      
      @description  = @TEMPitemdescription,                      
      @ship_to  = @TEMPshipto_det,                      
      @listprice = @TEMPfreightdet		--fzambada rev2              
                      
                      
                      
    IF @iError <> 1                      
    BEGIN                      
     INSERT #ewerror (module_id,err_code, info, source, sequence_id) VALUES (19000, 10, @err_section + '', '', 0)                       
 END                      
                      
                      
     SELECT @key_table2 = MIN(key_table)                      
     FROM CVO_TempSOD                      
     WHERE key_table > @key_table2                      
                      
                      
    END                      
                      
    SELECT @key_table = MIN(key_table)                      
    FROM CVO_TempSO                      
    WHERE key_table > @key_table                      
                      
                      
                          
    EXEC adm_ins_SO_mutiship @so_no                      
                      
                          
    update orders                      
    set orders.status = 'R'                      
    from CVO_TempSO                       
    where CVO_TempSO.AutoShip <> 'N'                      
    and CVO_TempSO.NewSO = orders.order_no                      
    and orders.order_no = @so_no                      
    and CVO_TempSO.AutoShip IS NOT NULL                   
                      
                      
                          
    update ord_list                      
    set ord_list.status = 'R'                      
    from orders                       
where ord_list.order_no = orders.order_no                      
    and orders.status <> 'N'                      
    and orders.order_no = @so_no                      
                      
                      
   END                      
                      
 END                      
        
                      
                      
                      
                      
                      
   SET @key_table = 0                      
   SET @iError = 0                      
   SET @so_no = ''                      
                         
   SELECT  @key_table = MIN(key_table)                      
   FROM  CVO_TempSO                      
   WHERE  key_table > @key_table                      
                         
   select @so_no = NewSO FROM CVO_TempSO where key_table = @key_table                      
                      
   WHILE @key_table IS NOT NULL                      
   BEGIN                      
                         
     EXEC dbo.fs_calculate_oetax_wrap @ord = @so_no, @ext = @ext, @debug = 0, @batch_call = 1     --fzambada                  
     EXEC dbo.fs_updordtots @ordno = @so_no, @ordext = @ext                        
     update orders set total_amt_order=(select sum(ordered*price) from ord_list where order_no=@so_no), status=@TEMPtransstatus            
  where order_no=@so_no--fzambada            
            
              
    SELECT  @key_table = MIN(key_table)                      
    FROM  CVO_TempSO                      
    WHERE  key_table > @key_table                      
                      
    select @so_no = NewSO FROM CVO_TempSO where key_table = @key_table                      
                      
   END                       
                      
  IF EXISTS (SELECT 1 FROM #ewerror)                      
   set @ErrorInd = 1                      
                        
                        
  IF @ErrorInd = 1                      
  BEGIN                      
         SELECT '$FIN_RESULTS$'                      
         /*SELECT '<Description>' + ISNULL((SELECT e_ldesc FROM poerrdef WHERE e_code = 35057),'') + ' </Description>'*/                      
      SELECT '<Description>' + ISNULL((SELECT e_ldesc FROM eboerrdef WHERE e_code = 35057 and e_type = 'poerr'),'') + ' </Description>'                      
         SELECT '<ErrorList>'                        
         SELECT module_id, err_code,                       
      RTRIM(LTRIM(DEF.e_ldesc)) AS info,                       
      RTRIM(LTRIM(info)) AS SONumber,                       
      RTRIM(LTRIM(sequence_id)) AS LineNumber,                       
      ISNULL(RTRIM(LTRIM(ERRORS.source)),'') AS value                      
         FROM #ewerror AS ERRORS                      
     INNER JOIN eboerrdef DEF ON err_code = DEF.e_code and DEF.e_type = 'soerr'                      
         FOR XML AUTO, ELEMENTS                      
         SELECT '</ErrorList>'                      
  END                      
                      
                      
                      
                      
/**/ 
GO
GRANT EXECUTE ON  [dbo].[IntegrateSO_ins] TO [public]
GO
