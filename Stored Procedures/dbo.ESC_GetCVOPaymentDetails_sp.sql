SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 -- v1.0 CB 22/07/2013 - Issue #927 - Buying Group Switching  
 -- v1.1 CB 13/09/2013 - Issue with orphaned arinppyt records with -1 posted flag causing data not to be picked up  
 -- v1.2 CB 17/09/2013 - Issue #927 - Buying Group Switching - RB orders set to and from BGs  
 -- v1.3 CB 26/09/2013 - Issue #927 - Buying Group Switching - Exclude from child records that link to parents 
 -- v1.4 CB 05/12/2013 - Fix issue with missing data and performance 
 -- v1.5 CB 08/01/2014 - Fix issue with void payments being picked up
 -- v1.6 CB 10/01/2014 - Fix issue with invoices that are written off still showing
 -- v1.7 CB 28/01/2014 - Fix issue with items showing pre joining a bg
 -- v1.8 CB 28/01/2014 - Fix issue with items showing pre joining a bg
 -- v1.9 CB 18/03/2014 - Fix duplicates
 -- v2.0 CB 26/03/2014 - Fix delete statement
 -- v2.1 CB 16/04/2014 - Fix delete statement
 -- v2.2 CB 28/05/2014 - Fix issue with RB credits being removed
 -- v2.3 CB 28/05/2014 - Fix issue when child leaves and rejoins a buying group
 -- v3.0 CB 10/06/2014 - ReWrite of BG data
 -- v3.1 CB 20/06/2014 - Fix to v3.0
/*
declare @pytresult varchar(100)  
 exec ESC_GetCVOPaymentDetails_sp 'BG1','BG1','sa',735259,'',0,0,0,@pytresult OUT
select @pytresult

select * from esc_cashappdet where custcode = 'BG1'

delete from esc_cashappdet where custcode = 'BG1'

*/

CREATE procedure [dbo].[ESC_GetCVOPaymentDetails_sp] @ParentRec  varchar(40),  
             @PayerCust  varchar(8),     
             @UserName  varchar(30),     
             @StmntDate  int,       
             @PytNum   varchar(16),     
             @PytDate  int,     
             @PytAmt   float,     
             @ApplyCredits smallint,     
             @ErrMsg   varchar(100) OUTPUT      
AS      
BEGIN    
 -- GEP 2/21/2012 changed credits statement comparison to date due.      
      
 SET NOCOUNT ON      
      
 DECLARE @ErrFlag  smallint,     
   @ErrLog   smallint,      
   @PytAmtEntered float,      
   @PRecID   varchar(40),     
   @PSeq   int,     
   @PTrx   varchar(16),     
   @PDoc   varchar(16),     
   @PBal   Dec(20,2),     
   @PDate   int,      
   @IRecID   varchar(40),     
   @ISeq   int,     
   @IDoc   varchar(16),     
   @IBal   Dec(20,2),     
   @IDate   int,      
   @PytAmtApp  dec(20,2),      
   @InvAmtApp  dec(20,2),      
   @CustCode  varchar(8),    
   @RemBal   float,    
   @RecCount  int,    
   @IsParent  int -- v1.3          
    
    
 SELECT @PytAmtEntered = @PytAmt      
       
 SELECT @ErrLog = CASE value_str WHEN 'Y' THEN 1 ELSE 0 END      
 FROM config (NOLOCK)     
 WHERE flag = 'CVOCASHAPP'      
      
 SELECT @ErrLog = ISNULL(@ErrLog,0)      
        
 IF (@StmntDate = 0)    
  SELECT @StmntDate = 722815 + DATEDIFF(dd,'1/1/80',GETDATE())      
        
 CREATE TABLE #ESC_CashAppDet (      
  ParentRecID  varchar(40),      
  PayerCustCode varchar(8),      
  CustCode  varchar(8),      
  UserName  varchar(30),      
  SeqID   int identity(1,1),      
  TrxNum   varchar(16),      
  DocNum   varchar(16),      
  DocType   varchar(3),      
  DocDate   int,      
  DocDue   int,      
  DocAmt   float,      
  DocBal   float,      
  AmtApplied  float,      
  IncludeInPyt smallint)      
      
 CREATE TABLE #ESC_CashAppInvDet (      
  ParentRecID varchar(40),      
  SeqID  int ,      
  PytTrx  varchar(16),      
  PytDoc  varchar(16),      
  PytApp  float,      
  InvDoc  varchar(16),      
  ApplyType smallint)      
      
 CREATE TABLE #arvpay (      
  customer_code   varchar(8),      
  customer_name varchar(40),      
  bal_fwd_flag smallint,      
  seq_id   smallint)      
      
    
 IF (@ErrLog = 1)    
 BEGIN       
  INSERT INTO ESC_CashAppAudit      
  SELECT GETDATE(),        -- ProcessDate  datetime,      
    @UserName,        -- UserName  varchar(30),      
    @ParentRec,        -- ParentRecID  varchar(40),      
    'Payment Processing',     -- ProcessHdr  varchar(40),      
    10,          -- ProcessStepID int,      
    'Entering Payment Process',    -- ProcessStepName  varchar(40),      
    '',          -- ProcessValue varchar(100),      
    ''          -- ProcessResult varchar(100)      
 END      
      
 -- Fist check the Valid Payer and get the children customer codes      
      
 IF (@ErrLog = 1)      
 BEGIN       
  INSERT INTO ESC_CashAppAudit      
  SELECT GETDATE(),        -- ProcessDate  datetime,      
    @UserName,        -- UserName  varchar(30),      
    @ParentRec,        -- ParentRecID  varchar(40),      
    'Payment Processing',     -- ProcessHdr  varchar(40),      
    20,          -- ProcessStepID int,      
    'Getting Child Customers',    -- ProcessStepName  varchar(40),      
    '',          -- ProcessValue varchar(100),      
    ''          -- ProcessResult varchar(100)      
 END      
          
 -- v1.4 Start   
 CREATE INDEX #ESC_CashAppDet_ind0 ON #ESC_CashAppDet(trxnum)  
 -- v1.4 End  
  
 -- WORKING TABLE
 IF OBJECT_ID('tempdb..#bg_data') IS NOT NULL
	DROP TABLE #bg_data

 CREATE TABLE #bg_data (
		doc_ctrl_num	varchar(16),
		order_ctrl_num	varchar(16),
		customer_code	varchar(10),
		doc_date_int	int,
		doc_date		varchar(10),
		parent			varchar(10))

	-- Call BG Data Proc
 EXEC cvo_bg_get_document_data_sp @ParentRec
   
 CREATE INDEX #bg_data_ind22 ON #bg_data (customer_code, doc_ctrl_num)

 INSERT	#arvpay
 SELECT	DISTINCT a.customer_code, a.customer_name, a.bal_fwd_flag, 0
 FROM	arcust a (NOLOCK)
 JOIN	#bg_data b
 ON		a.customer_code = b.customer_code	

 CREATE INDEX #arvpay_ind0 ON #arvpay(customer_code)   

 IF (@ErrLog = 1)      
 BEGIN       
  INSERT INTO ESC_CashAppAudit      
  SELECT GETDATE(),        -- ProcessDate  datetime,      
    @UserName,        -- UserName  varchar(30),      
    @ParentRec,        -- ParentRecID  varchar(40),      
    'Payment Processing',     -- ProcessHdr  varchar(40),      
    30,          -- ProcessStepID int,      
    'Number of Customers Found',   -- ProcessStepName  varchar(40),      
    '',          -- ProcessValue varchar(100),      
    convert(varchar,count(*) )    -- ProcessResult varchar(100)      
  FROM #arvpay      
 END      
  
 -- v1.4 Start  
 SELECT a.*   
 INTO #artrx_all  
 FROM artrx_all a (NOLOCK)  
 JOIN #arvpay b   
 ON  a.customer_code = b.customer_code  

 -- v3.1 Start
	DELETE	a
	FROM	#artrx_all a
	JOIN	#bg_data b
	ON		a.doc_ctrl_num = b.doc_ctrl_num
	WHERE	b.parent <> @ParentRec

	DELETE	a
	FROM	#artrx_all a
	LEFT JOIN #bg_data b
	ON		a.doc_ctrl_num = b.doc_ctrl_num
	WHERE	b.doc_ctrl_num IS NULL
 -- v3.1 End
      
 IF EXISTS( SELECT * FROM #arvpay)      
 BEGIN      
  -- v1.4 Start  
  -- Get all the credits and debits for the payer customer from history.      
  INSERT INTO #ESC_CashAppDet      
   (ParentRecID, PayerCustCode, CustCode, UserName, TrxNum, DocNum, DocType, DocDate, DocDue, DocAmt, DocBal, AmtApplied, IncludeInPyt )      
  SELECT @PayerCust,         -- ParentRecID  varchar(40),      
    @PayerCust,           -- PayerCustCode varchar(8),      
    a.customer_code,          -- CustCode  varchar(8),      
    @UserName,           -- UserName  varchar(30),      
    a.trx_ctrl_num,          -- TrxNum   varchar(16),     
    a.doc_ctrl_num,          -- DocNum   varchar(16),      
    CASE a.trx_type      
     WHEN 2021 THEN 'INV'      
     WHEN 2031 THEN 'INV'      
     WHEN 2111 THEN 'PYT'      
     ELSE ''      
    END,            -- DocType   varchar(3),      
    CASE a.trx_type      
     WHEN 2021 THEN a.date_due      
     WHEN 2031 THEN a.date_due      
     WHEN 2111 THEN a.date_doc      
    END,           -- DocDate   int,      
    a.date_due,      
    CASE trx_type      
     WHEN 2021 THEN a.amt_net      
     WHEN 2031 THEN a.amt_net      
     WHEN 2111 THEN a.amt_net * -1      
     ELSE 0      
    END,            -- DocAmt   float,      
    CASE a.trx_type      
     WHEN 2021 THEN a.amt_net - a.amt_paid_to_date      
     WHEN 2031 THEN a.amt_net - a.amt_paid_to_date      
     WHEN 2111 THEN a.amt_on_acct * -1      
     ELSE 0      
    END,            -- DocBal   float,      
    0,             -- AmtApplied  float,      
    0             -- IncludeInPyt  smallint,          
  FROM #artrx_all a (NOLOCK)     
  JOIN #arvpay b   
  ON   a.customer_code = b.customer_code  
  LEFT JOIN ESC_CashAppDet c (NOLOCK)  
  ON a.trx_ctrl_num = c.TrxNum  
  WHERE ((a.paid_flag = 0 AND a.trx_type IN (2031,2021) AND a.date_due <= @StmntDate))      
  AND  a.trx_type IN (2021,2031)      
  AND  c.trxnum IS NULL      
  ORDER BY a.trx_type DESC, a.doc_ctrl_num ASC      
      
  INSERT INTO #ESC_CashAppDet      
   (ParentRecID, PayerCustCode, CustCode, UserName, TrxNum, DocNum, DocType, DocDate, DocDue, DocAmt, DocBal, AmtApplied, IncludeInPyt )      
  SELECT @PayerCust,         -- ParentRecID  varchar(40),      
    @PayerCust,           -- PayerCustCode varchar(8),      
    a.customer_code,          -- CustCode  varchar(8),      
    @UserName,           -- UserName  varchar(30),      
    a.trx_ctrl_num,          -- TrxNum   varchar(16),      
    a.doc_ctrl_num,          -- DocNum   varchar(16),      
    CASE a.trx_type      
     WHEN 2021 THEN 'INV'      
     WHEN 2031 THEN 'INV'      
     WHEN 2111 THEN 'PYT'      
     ELSE ''      
    END,            -- DocType   varchar(3),      
    CASE a.trx_type      
     WHEN 2021 THEN a.date_due      
     WHEN 2031 THEN a.date_due      
     WHEN 2111 THEN a.date_doc      
    END,           -- DocDate   int,      
    a.date_due,      
    CASE trx_type      
     WHEN 2021 THEN a.amt_net      
     WHEN 2031 THEN a.amt_net      
     WHEN 2111 THEN a.amt_net * -1      
     ELSE 0      
    END,            -- DocAmt   float,      
    CASE a.trx_type      
     WHEN 2021 THEN a.amt_net - a.amt_paid_to_date      
     WHEN 2031 THEN a.amt_net - a.amt_paid_to_date      
     WHEN 2111 THEN a.amt_on_acct * -1      
     ELSE 0      
    END,            -- DocBal   float,      
    0,             -- AmtApplied  float,      
    0             -- IncludeInPyt  smallint,          
  FROM #artrx_all a (NOLOCK)     
  JOIN #arvpay b   
  ON   a.customer_code = b.customer_code  
  LEFT JOIN ESC_CashAppDet c (NOLOCK)  
  ON a.trx_ctrl_num = c.TrxNum  
  WHERE (a.trx_type = 2111 AND a.payment_type IN (1,3) AND a.amt_on_acct > 0.001     
    AND CASE       
      WHEN a.date_due > 0 THEN a.date_due      
      ELSE a.date_doc      
     END <= @StmntDate )      
  AND  a.trx_type IN (2111)      
  AND  c.trxnum IS NULL   
  AND  a.void_flag = 0 -- v1.5   
  ORDER BY a.trx_type DESC, a.doc_ctrl_num ASC      
  
  -- v1.9 Start
 CREATE TABLE #ESC_CashAppDet2 (        
  ParentRecID  varchar(40),        
  PayerCustCode varchar(8),        
  CustCode  varchar(8),        
  UserName  varchar(30),        
  TrxNum   varchar(16),        
  DocNum   varchar(16),        
  DocType   varchar(3),        
  DocDate   int,        
  DocDue   int,        
  DocAmt   float,        
  DocBal   float,        
  AmtApplied  float,        
  IncludeInPyt smallint)	

  INSERT #ESC_CashAppDet2
  SELECT DISTINCT ParentRecID, PayerCustCode, CustCode, UserName, TrxNum, DocNum, DocType, DocDate, 
		DocDue, DocAmt, DocBal, AmtApplied, IncludeInPyt
  FROM  #ESC_CashAppDet 

  DELETE #ESC_CashAppDet

  INSERT #ESC_CashAppDet (ParentRecID, PayerCustCode, CustCode, UserName, TrxNum, DocNum, DocType, DocDate, 
		DocDue, DocAmt, DocBal, AmtApplied, IncludeInPyt)
  SELECT ParentRecID, PayerCustCode, CustCode, UserName, TrxNum, DocNum, DocType, DocDate, 
		DocDue, DocAmt, DocBal, AmtApplied, IncludeInPyt
  FROM  #ESC_CashAppDet2

  DROP TABLE #ESC_CashAppDet2
  DROP TABLE #bg_data
 -- v1.9 End
  
  
  IF (@ErrLog = 1)    
  BEGIN       
   INSERT INTO ESC_CashAppAudit      
   SELECT GETDATE(),        -- ProcessDate  datetime,      
     @UserName,        -- UserName  varchar(30),      
     @ParentRec,        -- ParentRecID  varchar(40),      
     'Payment Processing',     -- ProcessHdr  varchar(40),      
     40,          -- ProcessStepID int,      
     'Number of Records Found',    -- ProcessStepName  varchar(40),      
     '',          -- ProcessValue varchar(100),det      
     convert(varchar,count(*))    -- ProcessResult varchar(100)      
   FROM #ESC_CashAppDet      
  END      
      
  DELETE det      
  FROM #ESC_CashAppDet det, arinppyt_all uph      
  WHERE det.CustCode = uph.customer_code      
  AND  det.DocNum = uph.doc_ctrl_num      
  AND  det.DocType = 'PYT'    
  AND  uph.posted_flag <> -1 -- v1.1      
      
  IF (@ErrLog = 1)      
  BEGIN       
   INSERT INTO ESC_CashAppAudit      
   SELECT GETDATE(),        -- ProcessDate  datetime,      
     @UserName,        -- UserName  varchar(30),      
     @ParentRec,        -- ParentRecID  varchar(40),      
     'Payment Processing',     -- ProcessHdr  varchar(40),      
     41,          -- ProcessStepID int,      
     'Number of Records after Cleanup',  -- ProcessStepName  varchar(40),      
     '',          -- ProcessValue varchar(100),det      
     convert(varchar,count(*))    -- ProcessResult varchar(100)      
   FROM #ESC_CashAppDet      
  END      
      
  IF NOT EXISTS (SELECT 1 FROM #ESC_CashAppDet)      
  BEGIN      
   SELECT @ErrMsg = 'No Records Found!'      
   RETURN      
  END      
        
  IF (@ApplyCredits = 1)      
  BEGIN      
      
  -- Need to apply the settlements first. Every credit listed in the details needs to go to Settlements.      
  -- Apply the oldest credits to the oldest invoices. No other logic applies at this point      
        
  -- If any payments exist with a balance to be applied loop      
   DECLARE GetSettlements CURSOR      
   FOR      
   SELECT TrxNum      
   FROM #ESC_CashAppDet       
   WHERE DocType = 'PYT'       
   AND  DocBal < 0      
   ORDER BY SeqID      
       
   OPEN GetSettlements      
       
   FETCH NEXT FROM GetSettlements      
   INTO @PTrx      
       
   WHILE (@@FETCH_STATUS = 0)    
   BEGIN      
         
    -- Once the Trx is known lets get the remaining info      
    SELECT @PRecID = ParentRecID,       
      @PSeq = SeqID,       
      @PDoc = DocNum,       
      @PBal = DocBal,      
      @CustCode = CustCode      
    FROM #ESC_CashAppDet      
    WHERE TrxNum = @PTrx      
       
    IF (@ErrLog = 1)    
    BEGIN       
     INSERT INTO ESC_CashAppAudit      
     SELECT GETDATE(),        -- ProcessDate  datetime,      
       @UserName,        -- UserName  varchar(30),      
       @ParentRec,        -- ParentRecID  varchar(40),      
       'Settlement Processing',    -- ProcessHdr  varchar(40),      
       50,          -- ProcessStepID int,      
       'Payment Balance',      -- ProcessStepName  varchar(40),      
       @PTrx+ '-- $'+ convert(varchar,@PBal), -- ProcessValue varchar(100),      
       'Payment with balance has been found ' -- ProcessResult varchar(100)      
    END      
             
    WHILE (ABS(@PBal) > 0.001)    
    BEGIN      
     -- Now we need to find the next oldest invoice      
     SELECT @ISeq = ISNULL(MIN(SeqID),0)       
     FROM #ESC_CashAppDet      
     WHERE DocType = 'INV'      
     AND  CONVERT(dec(20,2),DocBal - ABS(AmtApplied)) > 0      
          
     -- if no invoices found exit the loop      
     IF (@ISeq = 0)    
      BREAK      
       
     -- Once the invoice is known lets get the remaining invoice info      
     SELECT @IRecID = ParentRecID,       
       @IDoc = DocNum,       
       @IBal = DocBal + AmtApplied      
     FROM #ESC_CashAppDet      
     WHERE SeqID = @ISeq      
     AND  DocType = 'INV'      
       
       
     IF (@ErrLog = 1)      
     BEGIN       
      INSERT INTO ESC_CashAppAudit      
      SELECT GETDATE(),          -- ProcessDate  datetime,      
        @UserName,          -- UserName  varchar(30),      
        @ParentRec,          -- ParentRecID  varchar(40),      
        'Settlement Processing',      -- ProcessHdr  varchar(40),      
        60,            -- ProcessStepID int,      
        'Invoice Found',        -- ProcessStepName  varchar(40),      
        @IDoc+'$'+convert(varchar,@Ibal),    -- ProcessValue varchar(100),      
        'Invoice with balance found'            -- ProcessResult varchar(100)      
     END      
             
     -- If Invoice Balance is less than payment balance apply all of the invoice balance to the payment      
     IF (@IBal < ABS(@PBal) AND @IBal <> 0 )      
     BEGIN      
      INSERT INTO #ESC_CashAppInvDet      
      SELECT @IRecID,      -- ParentRecID  varchar(40),      
        @ISeq,       -- SeqID   int ,      
        @PTrx,       -- PytTrx   varchar(16),      
       @PDoc,       -- PytDoc  varchar(16),      
        (@IBal*-1),      -- PytApp  float      
        @IDoc,       -- InvDoc  varchar(16)      
        1        -- ApplyType smallint      
         
      SELECT @PytAmtApp = ISNULL(SUM(PytApp),0)      
      FROM #ESC_CashAppInvDet      
      WHERE ParentRecID = @ParentRec      
      AND  ApplyType = 1      
      AND  PytTrx = @PTrx      
          
      SELECT @InvAmtApp = ISNULL(SUM(PytApp),0)      
      FROM #ESC_CashAppInvDet      
      WHERE ParentRecID = @ParentRec      
      AND  ApplyType = 1      
      AND  InvDoc = @IDoc      
       
      IF (@ErrLog = 1)    
      BEGIN       
       INSERT INTO ESC_CashAppAudit      
       SELECT GETDATE(),            -- ProcessDate  datetime,      
         @UserName,            -- UserName  varchar(30),      
         @ParentRec,            -- ParentRecID  varchar(40),      
         'Settlement Processing',        -- ProcessHdr  varchar(40),      
         61,              -- ProcessStepID int,      
         'Apply Payment',          -- ProcessStepName  varchar(40),      
         @IDoc+ ': $'+convert(varchar,@InvAmtApp),    -- ProcessValue varchar(100),      
         'Calculated Inv amt applied value'      -- ProcessResult varchar(100)      
      END      
       
      UPDATE #ESC_CashAppDet       
      SET  AmtApplied = ABS(@PytAmtApp),      
        IncludeInPyt = 1      
      WHERE DocType = 'PYT'       
      AND  TrxNum = @PTrx      
       
      UPDATE #ESC_CashAppDet       
      SET  AmtApplied = @InvAmtApp,      
        IncludeInPyt = 1      
      WHERE DocType = 'INV'       
      AND  DocNum = @IDoc      
       
      SELECT @PBal = @PBal + ABS(@IBal)      
      select @IBal = 0       
       
      IF (@ErrLog = 1)      
      BEGIN       
       INSERT INTO ESC_CashAppAudit      
       SELECT GETDATE(),            -- ProcessDate  datetime,      
         @UserName,            -- UserName  varchar(30),      
         @ParentRec,            -- ParentRecID  varchar(40),      
         'Settlement Processing',        -- ProcessHdr  varchar(40),      
         62,              -- ProcessStepID int,      
         'Apply Payment',          -- ProcessStepName  varchar(40),      
         @IDoc+ ': $'+convert(varchar,DocAmt+AmtApplied),  -- ProcessValue varchar(100),      
         'Inv Balance after payment applied'      -- ProcessResult varchar(100)      
       FROM #ESC_CashAppDet       
       WHERE DocType = 'INV'       
       AND  DocNum = @IDoc      
      END      
       
      IF (@ErrLog = 1)      
      BEGIN       
       INSERT INTO ESC_CashAppAudit      
       SELECT GETDATE(),        -- ProcessDate  datetime,      
         @UserName,        -- UserName  varchar(30),      
         @ParentRec,        -- ParentRecID  varchar(40),      
         'Settlement Processing',    -- ProcessHdr  varchar(40),      
         63,          -- ProcessStepID int,      
         'Payment Balance',      -- ProcessStepName  varchar(40),      
         @PTrx+ ': '+ convert(varchar,@PBal), -- ProcessValue varchar(100),      
         'Pyt Balance after payment applied'  -- ProcessResult varchar(100)      
      END      
     END      
     ELSE    
     BEGIN      
      -- If Invoice Balance is greater than or equal to the payment balance apply all of the payment balance to the invoice      
      IF (@IBal >= ABS(@PBal))      
      BEGIN      
       INSERT INTO #ESC_CashAppInvDet      
       SELECT @IRecID,     -- ParentRecID  varchar(40),      
         @ISeq,      -- SeqID   int ,      
         @Ptrx,      -- PytTrx   varchar(16),      
         @PDoc,      -- PytDoc  varchar(16),      
         @PBal,      -- AmtApplied  float,      
         @IDoc,      -- InvDoc   varchar(16)      
         1       -- ApplyType  smallint      
        
       SELECT @PytAmtApp = ISNULL(SUM(PytApp),0)      
       FROM #ESC_CashAppInvDet      
       WHERE ParentRecID = @ParentRec      
       AND  ApplyType = 1      
       AND  PytTrx = @PTrx      
           
       SELECT @InvAmtApp = ISNULL(SUM(PytApp),0)      
       FROM #ESC_CashAppInvDet      
       WHERE ParentRecID = @ParentRec      
       AND  ApplyType = 1      
       AND  InvDoc = @IDoc      
       
       IF (@ErrLog = 1)      
       BEGIN       
        INSERT INTO ESC_CashAppAudit      
        SELECT GETDATE(),            -- ProcessDate  datetime,      
          @UserName,            -- UserName  varchar(30),      
          @ParentRec,            -- ParentRecID  varchar(40),      
          'Settlement Processing',        -- ProcessHdr  varchar(40),      
          65,              -- ProcessStepID int,      
          'Apply Payment',          -- ProcessStepName  varchar(40),      
          @IDoc+ ': $'+convert(varchar,@InvAmtApp),    -- ProcessValue varchar(100),      
          'Calculated Inv amt applied value'      -- ProcessResult varchar(100)      
       END      
        
       UPDATE #ESC_CashAppDet       
       SET  AmtApplied = ABS(@PytAmtApp),      
         IncludeInPyt = 1      
       WHERE DocType = 'PYT'       
       AND  TrxNum = @PTrx      
        
       UPDATE #ESC_CashAppDet       
       SET  AmtApplied = @InvAmtApp,      
         IncludeInPyt = 1      
       WHERE DocType = 'INV'       
       AND  DocNum = @IDoc      
        
       IF (@ErrLog = 1)    
       BEGIN       
        INSERT INTO ESC_CashAppAudit      
        SELECT GETDATE(),                -- ProcessDate  datetime,      
          @UserName,                -- UserName  varchar(30),      
          @ParentRec,                -- ParentRecID  varchar(40),      
          'Settlement Processing',            -- ProcessHdr  varchar(40),      
          66,                  -- ProcessStepID int,      
          'Apply Payment',              -- ProcessStepName  varchar(40),      
          @IDoc +': $ ' + convert(varchar,@IBal),         -- ProcessValue varchar(100),      
          'Inv Balance greater than payment balance, applying payment balance' -- ProcessResult varchar(100)      
        END      
        
       IF (@ErrLog = 1)      
       BEGIN       
        INSERT INTO ESC_CashAppAudit      
        SELECT GETDATE(),                -- ProcessDate  datetime,      
          @UserName,                -- UserName  varchar(30),      
          @ParentRec,                -- ParentRecID  varchar(40),      
          'Settlement Processing',            -- ProcessHdr  varchar(40),      
          67,                  -- ProcessStepID int,      
          'Apply Payment',              -- ProcessStepName  varchar(40),      
          @IDoc +': $ ' + convert(varchar,(DocBal + AmtApplied)),      -- ProcessValue varchar(100),      
          'Inv Balance greater than payment balance, applying payment balance' -- ProcessResult varchar(100)      
        FROM #ESC_CashAppDet      
        WHERE DocNum = @IDoc      
        AND  DocType = 'INV'       
       END      
             
       SELECT @PBal = 0      
      END    
     END      
       
     IF (@ErrLog = 1)      
     BEGIN       
      INSERT INTO ESC_CashAppAudit      
      SELECT GETDATE(),               -- ProcessDate  datetime,      
        @UserName,               -- UserName  varchar(30),      
        @ParentRec,               -- ParentRecID  varchar(40),      
        'Settlement Processing',           -- ProcessHdr  varchar(40),      
        70,                 -- ProcessStepID int,      
        'Apply Payment',             -- ProcessStepName  varchar(40),      
        @PTrx+ ': $ '+ convert(varchar,@PBal),       -- ProcessValue varchar(100),      
        'Payment balance for loop back'           -- ProcessResult varchar(100)      
      FROM #ESC_CashAppDet      
      WHERE DocType = 'PYT'       
      AND  TrxNum = @PTrx      
     END      
           
     IF (ABS(@PBal) > 0)       
      CONTINUE      
     ELSE      
      BREAK      
       
    END      
      
    FETCH NEXT FROM GetSettlements      
    INTO @PTrx      
      
   END      
      
   CLOSE GetSettlements      
   DEALLOCATE GetSettlements       
      
   IF (@ErrLog = 1)      
   BEGIN       
INSERT INTO ESC_CashAppAudit      
    SELECT GETDATE(),       -- ProcessDate  datetime,      
      @UserName,       -- UserName  varchar(30),      
      @ParentRec,       -- ParentRecID  varchar(40),      
      'Settlement Processing',    -- ProcessHdr  varchar(40),      
      90,         -- ProcessStepID int,      
      'Settlement Complete',    -- ProcessStepName  varchar(40),      
      '',         -- ProcessValue varchar(100),      
      'All settlement records applied' -- ProcessResult varchar(100)      
   END          
        
   -- Update Balances      
   IF (@ErrLog = 1)      
   BEGIN       
    INSERT INTO ESC_CashAppAudit      
    SELECT GETDATE(),       -- ProcessDate  datetime,      
      @UserName,       -- UserName  varchar(30),      
      @ParentRec,       -- ParentRecID  varchar(40),      
      'Settlement Processing',   -- ProcessHdr  varchar(40),      
      100,        -- ProcessStepID int,      
      'Settlement Complete',    -- ProcessStepName  varchar(40),      
      '',         -- ProcessValue varchar(100),      
      'Updated #ESC_CashAppDet table'  -- ProcessResult varchar(100)      
   END      
  END      
  ELSE       
  BEGIN       
   IF (@ErrLog = 1)      
   BEGIN       
    INSERT INTO ESC_CashAppAudit      
    SELECT GETDATE(),         -- ProcessDate  datetime,      
      @UserName,         -- UserName  varchar(30),      
      @ParentRec,         -- ParentRecID  varchar(40),      
      'Settlement Processing',     -- ProcessHdr  varchar(40),      
      105,          -- ProcessStepID int,      
      'Settlement Complete',      -- ProcessStepName  varchar(40),      
      convert(varchar,@ApplyCredits),    -- ProcessValue varchar(100),      
      'User selected not to process credits'  -- ProcessResult varchar(100)      
   END      
  END      
      
       
  --************************************************************************************************************      
  -- Now apply the payment to the remaining invoices oldest first.      
      
  WHILE (ABS(@PytAmt) >= 0.01 and @PytNum <> '')      
  BEGIN      
       
   IF (@ErrLog = 1)      
   BEGIN       
    INSERT INTO ESC_CashAppAudit      
    SELECT GETDATE(),           -- ProcessDate  datetime,      
      @UserName,           -- UserName  varchar(30),      
      @ParentRec,           -- ParentRecID  varchar(40),      
      'Check Processing',         -- ProcessHdr  varchar(40),      
      110,            -- ProcessStepID int,      
      'Payment Process Loop ',       -- ProcessStepName  varchar(40),      
      'Payment: '+@PytNum+'in the amount of $'+       
      convert(varchar,@PytAmt),       -- ProcessValue varchar(100),      
      'Manual Payment entered by user'     -- ProcessResult varchar(100)      
   END      
      
   IF (@ErrLog = 1)      
   BEGIN       
    INSERT INTO ESC_CashAppAudit      
    SELECT GETDATE(),           -- ProcessDate  datetime,      
      @UserName,           -- UserName  varchar(30),      
      @ParentRec,           -- ParentRecID  varchar(40),      
      'Check Processing',         -- ProcessHdr  varchar(40),      
      112,            -- ProcessStepID int,      
      'Payment Process Loop ',       -- ProcessStepName  varchar(40),      
      'Payment : $'+ convert(varchar,@PytAmt),   -- ProcessValue varchar(100),      
      'Remaining balance of payment'      -- ProcessResult varchar(100)      
   END      
        
   -- Now we need to find the next oldest invoice      
   SELECT @ISeq = ISNULL(MIN(SeqID),0)      
   FROM #ESC_CashAppDet      
   WHERE DocType = 'INV'      
   AND  (DocBal + AmtApplied) >= 0.01      
      
   IF (@ErrLog = 1)      
   BEGIN       
    INSERT INTO ESC_CashAppAudit      
    SELECT GETDATE(),           -- ProcessDate  datetime,      
      @UserName,           -- UserName  varchar(30),      
      @ParentRec,           -- ParentRecID  varchar(40),      
      'Check Processing',         -- ProcessHdr  varchar(40),      
      113,            -- ProcessStepID int,      
      'Payment Process Loop ',       -- ProcessStepName  varchar(40),      
      'InvSeq : '+ convert(varchar,@ISeq),    -- ProcessValue varchar(100),      
      'Getting Next Invoice'        -- ProcessResult varchar(100)      
   END      
      
   IF (@ISeq = 0)       
    BREAK      
      
   -- Once the invoice is known lets get the remaining invoice info      
   SELECT @IRecID = ParentRecID,       
     @IDoc = DocNum,       
     @IBal = DocBal + AmtApplied      
   FROM #ESC_CashAppDet      
   WHERE SeqID = @ISeq      
   AND  DocType = 'INV'      
      
   IF (@ErrLog = 1)      
   BEGIN       
    INSERT INTO ESC_CashAppAudit      
    SELECT GETDATE(),              -- ProcessDate  datetime,      
      @UserName,              -- UserName  varchar(30),      
      @ParentRec,              -- ParentRecID  varchar(40),      
      'Check Processing',            -- ProcessHdr  varchar(40),      
      120,               -- ProcessStepID int,      
      'Payment Process Loop',           -- ProcessStepName  varchar(40),      
      @IDoc,               -- ProcessValue varchar(100),      
      'Invoice found with balance of: $'+ convert(varchar,@IBal)  -- ProcessResult varchar(100)      
   END      
   -- If Invoice Balance is less than payment balance apply all of the invoice balance to the payment      
      
   IF (@IBal < @PytAmt)      
   BEGIN      
    INSERT INTO #ESC_CashAppInvDet      
    SELECT @IRecID,     -- ParentRecID  varchar(40),      
      @ISeq,      -- SeqID   int ,      
      '',       -- PytDoc   varchar(16),      
      @PytNum,     -- PytApplied  varchar(16),      
      @IBal *-1,     -- AmtApplied  float      
      @IDoc,      -- InvDoc   varchar(16)      
      2       -- ApplyType  smallint      
      
    UPDATE #ESC_CashAppDet      
    SET  AmtApplied = AmtApplied + (@IBal * -1),      
      IncludeInPyt = 1      
    WHERE ParentRecID = @IRecID      
    AND  SeqID = @ISeq      
      
      
    IF (@ErrLog = 1)      
    BEGIN        
     INSERT INTO ESC_CashAppAudit      
     SELECT GETDATE(),           -- ProcessDate  datetime,      
       @UserName,           -- UserName  varchar(30),      
       @ParentRec,           -- ParentRecID  varchar(40),      
       'Check Processing',         -- ProcessHdr  varchar(40),      
       131,            -- ProcessStepID int,      
       'Payment Process Loop',        -- ProcessStepName  varchar(40),      
       @PytNum,           -- ProcessValue varchar(100),      
       'Applied Payment: $'+convert(varchar,@IBal) +       
       ' to Invoice: '+@IDoc '-- Invoice Paid in Full'  -- ProcessResult varchar(100)      
    END      
      
      
    SELECT @PytAmt = @PytAmt - @IBal      
        
   END      
   ELSE      
   BEGIN    
    -- If Invoice Balance is greater than or equal to the payment balance apply all of the payment balance to the invoice      
    IF (@IBal >= @PytAmt)      
    BEGIN      
     INSERT INTO #ESC_CashAppInvDet      
     SELECT @IRecID,     -- ParentRecID  varchar(40),      
       @ISeq,      -- SeqID   int ,      
       '',       -- PytTrx   varchar(16),      
       @PytNum,     -- PytDoc  varchar(16),      
       @PytAmt*-1,     -- AmtApplied  float      
       @IDoc,      -- InvDoc   varchar(16)      
       2       -- ApplyType  smallint      
      
     UPDATE #ESC_CashAppDet      
     SET  AmtApplied = AmtApplied - @PytAmt,      
       IncludeInPyt = 1      
     WHERE ParentRecID = @IRecID      
     AND  SeqID = @ISeq     
      
     IF (@ErrLog = 1)      
     BEGIN       
      INSERT INTO ESC_CashAppAudit      
      SELECT GETDATE(),             -- ProcessDate  datetime,      
        @UserName,             -- UserName  varchar(30),      
        @ParentRec,             -- ParentRecID  varchar(40),      
        'Check Processing',           -- ProcessHdr  varchar(40),      
        133,              -- ProcessStepID int,      
        'Payment Process Loop',          -- ProcessStepName  varchar(40),      
        @PytNum,             -- ProcessValue varchar(100),      
        'Payment Amount: $'+ convert(varchar,@PytAmt) +      
        ' to Invoice: ' + @IDoc +'--  Partially Paid'    -- ProcessResult varchar(100)        
     END      
         
     SELECT @PytAmt = 0      
      
    END    
   END      
      
   IF (@ErrLog = 1)      
   BEGIN       
    INSERT INTO ESC_CashAppAudit      
    SELECT GETDATE(),           -- ProcessDate  datetime,      
      @UserName,           -- UserName  varchar(30),      
      @ParentRec,           -- ParentRecID  varchar(40),      
      'Check Processing',         -- ProcessHdr  varchar(40),      
      135,            -- ProcessStepID int,      
      'Payment Process Loop',        -- ProcessStepName  varchar(40),      
      convert(varchar,@PytAmt),       -- ProcessValue varchar(100),      
      'Remaining payment balance'       -- ProcessResult varchar(100)      
   END      
        
   IF (ABS(@PytAmt) > 0)       
    CONTINUE      
   ELSE      
    BREAK      
        
  END      
      
  IF (@ErrLog = 1)      
  BEGIN         
   INSERT INTO ESC_CashAppAudit      
   SELECT GETDATE(),           -- ProcessDate  datetime,      
     @UserName,           -- UserName  varchar(30),      
     @ParentRec,           -- ParentRecID  varchar(40),      
     'Check Processing',         -- ProcessHdr  varchar(40),      
     140,            -- ProcessStepID int,      
     'Payment Process Loop',        -- ProcessStepName  varchar(40),      
     '',             -- ProcessValue varchar(100),      
     'Payment Process Loop Completed'     -- ProcessResult varchar(100)      
  END      
       
  -- Final Checks      
  -- Calculate the remaining balance on the payment entered by the user.      
      
  IF (@ErrLog = 1)    
  BEGIN       
   INSERT INTO ESC_CashAppAudit      
   SELECT GETDATE(),           -- ProcessDate  datetime,      
     @UserName,           -- UserName  varchar(30),      
     @ParentRec,           -- ParentRecID  varchar(40),      
     'Check Processing',         -- ProcessHdr  varchar(40),      
     148,            -- ProcessStepID int,      
     'Payment Process Loop',        -- ProcessStepName  varchar(40),      
     convert(varchar,@PytAmt),       -- ProcessValue varchar(100),      
     'Payment Amount'         -- ProcessResult varchar(100)      
  END      
        
  IF (@ErrLog = 1)      
  BEGIN       
   INSERT INTO ESC_CashAppAudit      
   SELECT GETDATE(),           -- ProcessDate  datetime,      
     @UserName,           -- UserName  varchar(30),      
     @ParentRec,           -- ParentRecID  varchar(40),      
     'Check Processing',         -- ProcessHdr  varchar(40),      
     149,            -- ProcessStepID int,      
     'Payment Process Loop',        -- ProcessStepName  varchar(40),      
     convert(varchar,isnull(sum(PytApp),0)),    -- ProcessValue varchar(100),      
     'Total CR Applied'         -- ProcessResult varchar(100)      
   FROM #ESC_CashAppInvDet      
   WHERE ParentRecID = @ParentRec      
   AND  ApplyType = 2      
  END      
        
  SELECT @RemBal = @PytAmtEntered + ISNULL(SUM(PytApp),0)       
  FROM #ESC_CashAppInvDet      
  WHERE ParentRecID = @ParentRec      
  AND  ApplyType = 2      
      
  IF (@ErrLog = 1)      
  BEGIN       
   INSERT INTO ESC_CashAppAudit      
   SELECT GETDATE(),           -- ProcessDate  datetime,      
     @UserName,           -- UserName  varchar(30),      
     @ParentRec,           -- ParentRecID  varchar(40),      
     'Check Processing',         -- ProcessHdr  varchar(40),      
     150,            -- ProcessStepID int,      
     'Payment Process Loop',        -- ProcessStepName  varchar(40),      
     convert(varchar,isnull(@RemBal,0)),     -- ProcessValue varchar(100),      
     'Remaining Cash Receipt Balance'     -- ProcessResult varchar(100)      
  END      
       
  UPDATE ESC_CashAppHdr      
  SET  RemBalance = @RemBal,    
    RemChkBal = @RemBal  -- 08/27/2012 BNM - resolve issue 781, Manual cash application, update remaining check balance        
  WHERE ParentRecID = @ParentRec      
      
  IF (@ErrLog = 1)      
  BEGIN       
   INSERT INTO ESC_CashAppAudit      
   SELECT GETDATE(),           -- ProcessDate  datetime,      
     @UserName,           -- UserName  varchar(30),      
     @ParentRec,           -- ParentRecID  varchar(40),      
     'Additional Processing',       -- ProcessHdr  varchar(40),      
     151,            -- ProcessStepID int,      
     'Getting Remaining Balance',      -- ProcessStepName  varchar(40),      
     convert(varchar,RemBalance ),   -- ProcessValue varchar(100),      
     'Cash Receipt Remaining Balance'     -- ProcessResult varchar(100)      
   FROM ESC_CashAppHdr      
   WHERE ParentRecID = @ParentRec      
  END      
         
  -- Push the transactions to the final table.      
  IF (@ErrLog = 1)      
  BEGIN       
   INSERT INTO ESC_CashAppAudit      
   SELECT GETDATE(),           -- ProcessDate  datetime,      
     @UserName,           -- UserName  varchar(30),      
     @ParentRec,           -- ParentRecID  varchar(40),      
     'Move Data',          -- ProcessHdr  varchar(40),      
     160,            -- ProcessStepID int,      
     'Copy data to tables',         -- ProcessStepName  varchar(40),      
     '',             -- ProcessValue varchar(100),      
     'Inserting records to static tables'    -- ProcessResult varchar(100)      
  END      
       
  BEGIN TRAN CashLive      
      
  INSERT INTO ESC_CashAppDet      
  SELECT ParentRecID,      
    PayerCustCode,      
    CustCode,      
    UserName,      
    SeqID,      
    TrxNum,      
    DocNum,      
    DocType,      
    DocDate,      
    DocDue,      
    DocAmt,      
    DocBal,      
    AmtApplied,      
    IncludeInPyt      
  FROM #ESC_CashAppDet    
  WHERE DocBal <> 0 -- v1.6  
        
    
  IF (@@ERROR <> 0)       
   ROLLBACK TRAN CashLive      
      
  IF (@ErrLog = 1)      
  BEGIN       
   INSERT INTO ESC_CashAppAudit      
   SELECT GETDATE(),           -- ProcessDate  datetime,      
     @UserName,           -- UserName  varchar(30),      
     @ParentRec,           -- ParentRecID  varchar(40),      
     'Move Data',          -- ProcessHdr  varchar(40),      
     170,            -- ProcessStepID int,      
     'Payment Process',         -- ProcessStepName  varchar(40),      
     convert(varchar,count(*)),       -- ProcessValue varchar(100),      
     'ESC_CashAppDet records processed'     -- ProcessResult varchar(100)      
   FROM #ESC_CashAppDet      
  END      
      
  INSERT INTO  ESC_CashAppInvDet      
  SELECT ParentRecID,      
    SeqID,      
    PytTrx,      
    PytDoc,      
    PytApp,      
    InvDoc,      
    ApplyType      
  FROM #ESC_CashAppInvDet        
      
  IF (@@ERROR <> 0)       
   ROLLBACK TRAN CashLive      
      
  IF (@ErrLog = 1)      
  BEGIN       
   INSERT INTO ESC_CashAppAudit      
   SELECT GETDATE(),           -- ProcessDate  datetime,      
     @UserName,           -- UserName  varchar(30),      
     @ParentRec,           -- ParentRecID  varchar(40),      
     'Move Data',          -- ProcessHdr  varchar(40),      
     180,            -- ProcessStepID int,      
     'Payment Process',         -- ProcessStepName  varchar(40),      
     convert(varchar,count(*)),       -- ProcessValue varchar(100),      
     '#ESC_CashAppInvDet records processed'     -- ProcessResult varchar(100)      
   FROM #ESC_CashAppInvDet      
  END      
      
  COMMIT TRAN CashLive      
      
  IF (@ErrLog = 1)      
  BEGIN         
   INSERT INTO ESC_CashAppAudit      
   SELECT GETDATE(),        -- ProcessDate  datetime,      
     @UserName,        -- UserName  varchar(30),      
     @ParentRec,        -- ParentRecID  varchar(40),      
     'Payment Processing',     -- ProcessHdr  varchar(40),      
     190,          -- ProcessStepID int,      
     'Process Complete',      -- ProcessStepName  varchar(40),      
     '',          -- ProcessValue varchar(100),      
     ''          -- ProcessResult varchar(100)      
  END      
     
   
  SELECT @RecCount = COUNT(*) FROM #ESC_CashAppDet WHERE DocBal <> 0 -- v1.6    
  SELECT @ErrMsg = 'Processing Complete! ' + CAST(@RecCount as Varchar) + ' Records Loaded'        RETURN       
 END      
 ELSE      
 BEGIN      
  SELECT @ErrMsg = 'No Valid Payers!'      
  RETURN      
 END      
    
END      
GO
GRANT EXECUTE ON  [dbo].[ESC_GetCVOPaymentDetails_sp] TO [public]
GO
