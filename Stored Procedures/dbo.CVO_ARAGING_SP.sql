SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

  
/******************************* EPICOR SOFTWARE CORP *************************************************  
CREATED BY:  ALEX AVERBUKH  
CREATED IN:  NOV 2011  
PURPOSE:  CLIENT WOULD LIKE A CUSTOM EXPLORER VIEW FOR AR AGING  
EDITS:   20111220_bjb  to move aging buckets  
    20120120_bjb  to correct credit aging  
    20120328_bjb to corect open amounts  
    20120605 - tag - rewrite to match C&C summary Aging numbers, misc. updates  
    20130529 - tag - change join on artrx to an outer join.  writeoff's don't have artrx  
    20131101 - tag - retrofit cvo changes into this version.  Rolling 12 month sales and 
                     changing dates from int to datetime  
                     
 EXEC CVO_ARAGING_SP ''

'where CUST_CODE LIKE ''000500'''  
  
EXEC CVO_ARAGING_SP 'where CUST_CODE LIKE ''000111'''  
EXEC cc_summary_aging_sp '000567',4,1,'CVO','CVO',0

*******************************************************************************************************/  
-- v1.0 CB 23/07/2013 - Issue #927 - Buying Group Switching   
-- v1.1 CB 03/10/2013 - Issue #927 - Buying Group Switching - Deal with non BG customers
-- v1.2 CB 07/11/2013 - Fixes & Performance
-- v1.3 CB 15/11/2013 - Fix for non bg parent
-- v1.4 CB 18/11/2013 - Fix aging brackets for payments
-- v1.5 CB 21/11/2013 - Need to include RB orders when the customer has no relationship with a parent
-- v1.6 CB 25/11/2013 - Major rewrite to use C&C logic so as to match the aging buckets
-- v1.7 CB 09/12/2013 - Issue when customer is added and removed from buying group
-- v1.8 CB 13/01/2013 - Further fix to v1.7
-- v1.9 CB 26/02/2014 - Further fix to v1.7
-- v2.0 CB 12/03/2014 - Fix to checking balance - Allow for float values
-- v2.1 CB 13/03/2014 - Fix issue with due dates
-- v2.2 CB 28/03/2013 - Fix issue with customer records
-- v3.0 CB 10/06/2014 - ReWrite of BG data
-- v3.1 CB 12/03/2015 - Issue #1469 - Deal with finance and late charges and chargebacks
-- v3.2 CB 06/05/2015 - Fix issue with duplicate transactions
-- v3.3 CB 07/06/2016 - Fix bug with void records and duplicate doc numbers
-- v3.4 TG 4/24/2017 - change from cvo_csbm_shipto to cvo_sbm_details

CREATE PROCEDURE [dbo].[CVO_ARAGING_SP] (@WHERECLAUSE VARCHAR(1024))  
AS      
DECLARE @CUSTOMER_CODE  VARCHAR(8),       
  @DATE_TYPE_PARM  TINYINT,            
  @AGEBRK_USER_ID  INT,      
  @ALL_ORG_FLAG  SMALLINT,        
  @FROM_ORG   VARCHAR(30),      
  @TO_ORG    VARCHAR(30),      
  @CURRYRSTART  DATETIME,      
  @CURRYREND   DATETIME,      
  @LASTYRSTART  DATETIME,      
  @LASTYREND   DATETIME,      
  @R12START DATETIME,    
  @CUST    INT,      
  @SQL    VARCHAR(4000)      
      
      
DECLARE @date int, @date_rec int      
      
SELECT @AGEBRK_USER_ID = 1,      
  @ALL_ORG_FLAG = 1,        
  @FROM_ORG = 'CVO',      
  @TO_ORG = 'CVO'      
      
SELECT  @CURRYRSTART = CONVERT(DATETIME, '1/1/'+CAST(YEAR(GETDATE()) AS VARCHAR)),      
  @CURRYREND = CONVERT(DATETIME, '12/31/'+CAST(YEAR(GETDATE()) AS VARCHAR)),      
  @LASTYRSTART = CONVERT(DATETIME, '1/1/'+CAST(YEAR(GETDATE())-1 AS VARCHAR)),      
     @LASTYREND = CONVERT(DATETIME, '12/31/'+CAST(YEAR(GETDATE())-1 AS VARCHAR)),    
     @r12start = dateadd(yy,-1,dateadd(dd, datediff(dd,0,getdate()), 0))    
      
BEGIN -- CVO_ARAGING_SP DATA      
      
 SET NOCOUNT ON      
 DECLARE @DATE_ASOF  INT,      
   @PRECISION_HOME  SMALLINT,      
   @HOME_SYMBOL   VARCHAR(8),      
   @HOME_CURRENCY  VARCHAR(8),      
   @MULTI_CURRENCY_FLAG SMALLINT,      
   @DATE_TYPE_STRING VARCHAR(25)      
      
 IF ( SELECT IB_FLAG FROM GLCO ) = 0      
  SELECT @ALL_ORG_FLAG = 1      
       
 SET @WHERECLAUSE = REPLACE(@WHERECLAUSE,' AND ','')      
    
 if (charindex ('DATE_TYPE=',@WHERECLAUSE) <> 0 )      
 BEGIN       
  SET @WHERECLAUSE = REPLACE(@WHERECLAUSE,'DATE_TYPE=','')      
  SET @DATE_TYPE_PARM = SUBSTRING(@WHERECLAUSE,len(@whereclause),1)      
  SET @WHERECLAUSE = left(@WHERECLAUSE, LEN(@WHERECLAUSE)-1)      
 END      
 ELSE     
 BEGIN      
  SELECT @DATE_TYPE_PARM = 4 -- default to due_date      
 END       
    
 if ( charindex ('DATE_ASOF=',@WHERECLAUSE) = 0 )      
 BEGIN       
  SELECT  @DATE_ASOF = DATEDIFF(DD, '1/1/1753', CONVERT(DATETIME, GETDATE())) + 639906      
 END       
 ELSE      
 BEGIN      
  SET @WHERECLAUSE = REPLACE(@WHERECLAUSE,'DATE_ASOF=','')      
  SELECT @DATE_ASOF = SUBSTRING(@WHERECLAUSE,len(@whereclause)-5,LEN(@WHERECLAUSE)) -- julian date      
        SET @WHERECLAUSE = left(@WHERECLAUSE, LEN(@WHERECLAUSE)-6)      
 END       
          
 select @cust = 0      
 IF (CHARINDEX ('CUST_CODE',@WHERECLAUSE) <> 0 )      
 BEGIN      
  SET @WHERECLAUSE = REPLACE(@WHERECLAUSE,'CUST_CODE','CUSTOMER_CODE')       
  select @cust = 1      
 END       
         
 IF @DATE_TYPE_PARM = 1      
  SELECT @DATE_TYPE_STRING = 'DOCUMENT DATE'      
 IF @DATE_TYPE_PARM = 2      
  SELECT @DATE_TYPE_STRING = 'APPLY DATE'      
 IF @DATE_TYPE_PARM = 3      
  SELECT @DATE_TYPE_STRING = 'AGING DATE'      
 IF @DATE_TYPE_PARM = 4      
  SELECT @DATE_TYPE_STRING = 'DUE DATE'      
      
          
 SELECT @PRECISION_HOME  = CURR_PRECISION,      
   @MULTI_CURRENCY_FLAG  = MULTI_CURRENCY_FLAG,      
   @HOME_CURRENCY   = HOME_CURRENCY,      
   @HOME_SYMBOL   = SYMBOL      
 FROM GLCURR_VW (NOLOCK), GLCO (NOLOCK)      
 WHERE GLCO.HOME_CURRENCY  = GLCURR_VW.CURRENCY_CODE      
      
 if(object_id('tempdb.dbo.#artrxage_tmp') is not null)      
  drop table #artrxage_tmp      
      
 CREATE TABLE #ARTRXAGE_TMP      
 (      
  TRX_TYPE   SMALLINT NULL,       
  TRX_CTRL_NUM   VARCHAR(16) NULL,       
  DOC_CTRL_NUM   VARCHAR(16) NULL,       
  APPLY_TO_NUM   VARCHAR(16) NULL,       
  APPLY_TRX_TYPE   SMALLINT NULL,       
  SUB_APPLY_NUM   VARCHAR(16) NULL,       
  SUB_APPLY_TYPE   SMALLINT NULL,       
  TERRITORY_CODE   VARCHAR(8) NULL,       
  DATE_DOC   INT  NULL,       
  DATE_DUE   INT  NULL,       
  DATE_AGING   INT  NULL,       
  DATE_APPLIED   INT  NULL,       
  AMOUNT    FLOAT  NULL,      
  on_acct   float  null,       
  AMT_AGE_BRACKET1 FLOAT  NULL,       
  AMT_AGE_BRACKET2  FLOAT  NULL,      
  AMT_AGE_BRACKET3 FLOAT  NULL,      
  AMT_AGE_BRACKET4 FLOAT  NULL,      
  AMT_AGE_BRACKET5 FLOAT  NULL,      
  AMT_AGE_BRACKET6 FLOAT  NULL,         
  NAT_CUR_CODE   VARCHAR(8) NULL,       
  RATE_HOME   FLOAT  NULL,       
  RATE_TYPE   VARCHAR(8) NULL,       
  CUSTOMER_CODE   VARCHAR(8) NULL,       
  PAYER_CUST_CODE  VARCHAR(8) NULL,       
  TRX_TYPE_CODE   VARCHAR(8) NULL,       
  REF_ID    INT  NULL,      
  CUST_PO_NUM  VARCHAR(20) NULL,      
  PAID_FLAG  SMALLINT NULL,      
  RATE_OPER   FLOAT  NULL ,      
  ORG_ID   VARCHAR(30),       
  date_required int,      
  amt_age_bracket0 float,
  on_acct_flag int,
  amt_paid float,
  order_ctrl_num varchar(16),    
  parent varchar(10)) -- v1.1      
      
      
 CREATE INDEX #ARTRXAGE_IDX ON #ARTRXAGE_TMP   (customer_code, doc_ctrl_num)      
 create index #artrxage_idx1 on #artrxage_tmp (amount)      
      
 if(object_id('tempdb.dbo.#age_summary') is not null)      
  drop TABLE #AGE_SUMMARY      
      
 CREATE TABLE #AGE_SUMMARY      
 (     
  CUSTOMER_CODE  VARCHAR(8) NULL,      
  AMOUNT   FLOAT NULL,      
  amt_age_bracket0 float null,      
  AMT_AGE_BRACKET1 FLOAT NULL,      
  AMT_AGE_BRACKET2 FLOAT NULL,      
  AMT_AGE_BRACKET3 FLOAT NULL,      
  AMT_AGE_BRACKET4 FLOAT NULL,      
  AMT_AGE_BRACKET5 FLOAT NULL,      
  AMT_AGE_BRACKET6 FLOAT NULL)       
     
 CREATE INDEX #AGE_SUMMARY_IDX ON #AGE_SUMMARY (customer_code)      
      
 if(object_id('tempdb.dbo.#Final') is not null)      
  drop TABLE #FINAL      
     
 CREATE TABLE #FINAL      
 (      
  CUSTOMER_CODE  VARCHAR(8) NULL,      
  ADDR_SORT1   VARCHAR(40) NULL,      
  attn_email   varchar(255) NULL,   --v1.1      
  SALESPERSON_CODE VARCHAR(8) NULL,      
  TERRITORY_CODE  VARCHAR(8) NULL,      
  ADDRESS_NAME  VARCHAR(40) NULL,      
  BG_Code    varchar(8) NULL,      
  BG_Name    varchar(40) NULL,      
  PRICE_CODE   VARCHAR(8) NULL,      
  AVGDAYSLATE   SMALLINT NULL,      
  BAL     FLOAT  NULL,      
  FUT     FLOAT  NULL,      
  CUR     FLOAT  NULL,      
  AR30    FLOAT  NULL,      
  AR60    FLOAT  NULL,      
  AR90    FLOAT  NULL,      
  AR120    FLOAT  NULL,      
  AR150    FLOAT  NULL,      
  CREDIT_LIMIT  FLOAT  NULL,      
  ONORDER    FLOAT  NULL,      
  LPMTDT    INT   NULL,      
  AMOUNT    FLOAT  NULL,      
  YTDCREDS   FLOAT  NULL,      
  YTDSALES   FLOAT  NULL,      
  LYRSALES   FLOAT  NULL,      
  HOLD    VARCHAR(5) NULL,    
  r12sales float null) -- 101613      
    
 CREATE INDEX #FINAL_IDX ON #FINAL (customer_code)      
       
 if(object_id('tempdb.dbo.#non_zero_records') is not null)      
  drop TABLE #NON_ZERO_RECORDS      
     
 CREATE TABLE #NON_ZERO_RECORDS      
 (      
  DOC_CTRL_NUM   VARCHAR(16),       
  TRX_TYPE   SMALLINT,       
  CUSTOMER_CODE   VARCHAR(8),       
  TOTAL    FLOAT)      
    
    
 -- v1.1 Start    
 CREATE TABLE #cust (parent varchar(10), child varchar(10))    

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
	EXEC cvo_bg_get_document_data_sp
   
	CREATE INDEX #bg_data_ind122 ON #bg_data (customer_code, doc_ctrl_num)

	-- v2.2 Start
	INSERT	#cust
	SELECT	DISTINCT parent, customer_code
	FROM	#bg_data
	-- v2.2 End


 IF (@Cust = 1)    
 BEGIN    
  SET @WHERECLAUSE = REPLACE(@WHERECLAUSE,' LIKE ',' NOT LIKE ')     
  SET @WHERECLAUSE = REPLACE(@WHERECLAUSE,' CUSTOMER_CODE ',' PARENT ')     
  SET @SQL = ' DELETE #cust ' + @WHERECLAUSE    
  EXEC (@SQL)    
 END         


 INSERT #ARTRXAGE_TMP       
 SELECT DISTINCT A.TRX_TYPE,       
   A.TRX_CTRL_NUM,       
   A.DOC_CTRL_NUM,       
   A.APPLY_TO_NUM,       
   A.APPLY_TRX_TYPE,       
   A.SUB_APPLY_NUM,       
   A.SUB_APPLY_TYPE,       
   A.TERRITORY_CODE,       
   A.DATE_DOC,       
   A.DATE_DUE,       
   (1+ sign(sign(a.ref_id) - 1))*a.date_aging + abs(sign(sign(a.ref_id)-1))*a.date_doc,           
   A.DATE_APPLIED,       
   A.AMOUNT,      
   0,      
   0,      
   0,      
   0,      
   0,      
   0,      
   0,      
   A.NAT_CUR_CODE,       
   A.RATE_HOME,       
   '',       
   A.CUSTOMER_CODE,       
   A.PAYER_CUST_CODE,       
   '',       
   A.REF_ID,      
   '',      
   '',      
   A.RATE_OPER,      
   A.ORG_ID,      
   0,      
   0, 0, 0, a.order_ctrl_num, '' -- v1.1       
 FROM ARTRXAGE A (NOLOCK)      
 inner join #cust C 
 ON a.customer_code = c.child    
 
   
 -- v1.1 Start    
 UPDATE a    
 SET  parent = b.parent    
 FROM #ARTRXAGE_TMP a    
 JOIN #bg_data b    
 ON   a.customer_code = b.customer_code
 AND  a.doc_ctrl_num = b.doc_ctrl_num	

UPDATE a    
 SET  parent = b.parent    
 FROM #ARTRXAGE_TMP a    
 JOIN #bg_data b    
 ON   a.customer_code = b.customer_code
 AND  a.doc_ctrl_num = b.order_ctrl_num	

  
 UPDATE #ARTRXAGE_TMP    
 SET  parent = customer_code    
 WHERE parent = ''    
     
    
 IF (@Cust = 1)    
 BEGIN    
  SET @SQL = ' DELETE #ARTRXAGE_TMP ' + @WHERECLAUSE    
  EXEC (@SQL)    
 END    
  
      
 CREATE TABLE #dates      
 ( date_start int,      
 date_end int,      
 bucket varchar(25) )      
      
 SELECT @DATE_TYPE_PARM = 4      
      
 DECLARE      
  @e_age_bracket_1 smallint,      
  @e_age_bracket_2 smallint,      
  @e_age_bracket_3 smallint,      
  @e_age_bracket_4 smallint,      
  @e_age_bracket_5 smallint,         
  @b_age_bracket_1 smallint,      
  @b_age_bracket_2 smallint,      
  @b_age_bracket_3 smallint,      
  @b_age_bracket_4 smallint,      
  @b_age_bracket_5 smallint,      
  @b_age_bracket_6 smallint,         
  @detail_count int,      
  @last_doc varchar(16),      
  @date_doc int,       
  @date_due int,       
  @terms_code varchar(8),      
  @last_check varchar(16),      
  @last_cust varchar(8),      
  @balance float,      
  @stat_seq int      
      
 SELECT  @date_asof = DATEDIFF(dd, '1/1/1753', CONVERT(datetime, getdate())) + 639906      
      
 SELECT  @e_age_bracket_1  = age_bracket1,      
   @e_age_bracket_2  = age_bracket2,      
   @e_age_bracket_3  = age_bracket3,      
   @e_age_bracket_4  = age_bracket4,      
   @e_age_bracket_5  = age_bracket5       
 FROM arco (NOLOCK) -- v1.0     
      
 SELECT  @b_age_bracket_2  = @e_age_bracket_1 + 1,      
   @b_age_bracket_3  = @e_age_bracket_2 + 1,      
   @b_age_bracket_4  = @e_age_bracket_3 + 1,      
   @b_age_bracket_5  = @e_age_bracket_4 + 1,      
   @b_age_bracket_6  = @e_age_bracket_5 + 1       
      
      
 SELECT  @e_age_bracket_1  = 30,      
   @e_age_bracket_2  = 60,      
   @e_age_bracket_3  = 90,      
   @e_age_bracket_4  = 120,      
   @e_age_bracket_5  = 150      
      
      
 SELECT  @b_age_bracket_1  = 1,      
   @b_age_bracket_2  = 31,      
   @b_age_bracket_3  = 61,      
   @b_age_bracket_4  = 91,      
   @b_age_bracket_5  = 121,      
   @b_age_bracket_6  = 151      
      
 CREATE TABLE #invoices      
 ( customer_code    varchar(8),      
  doc_ctrl_num     varchar(16) NULL,      
  date_doc       int   NULL,      
  trx_type       int   NULL,      
  amt_net       float   NULL,      
  amt_paid_to_date  float   NULL,      
  balance       float   NULL,      
  on_acct_flag     smallint  NULL,      
  nat_cur_code    varchar(8)  NULL,      
  apply_to_num     varchar(16)  NULL,      
  sub_apply_num    varchar(16)  NULL,      
  trx_type_code    varchar(8)  NULL,      
  trx_ctrl_num    varchar(16)  NULL,      
  status_code     varchar(5)  NULL,      
  status_date     int   NULL,      
  cust_po_num     varchar(20)  NULL,      
  age_bucket     smallint NULL,      
  date_due      int  NULL,      
  date_aging     int  NULL,      
  date_applied    int  NULL,      
  order_ctrl_num   varchar(16) NULL,      
  artrx_doc_ctrl_num  varchar(16) NULL,      
  org_id       varchar(30) NULL,
  parent		varchar(10) NULL,
  amt_age_bracket0 float null,      
  AMT_AGE_BRACKET1 FLOAT NULL,      
  AMT_AGE_BRACKET2 FLOAT NULL,      
  AMT_AGE_BRACKET3 FLOAT NULL,      
  AMT_AGE_BRACKET4 FLOAT NULL,      
  AMT_AGE_BRACKET5 FLOAT NULL,      
  AMT_AGE_BRACKET6 FLOAT NULL)      
       
  INSERT #invoices (customer_code, doc_ctrl_num, balance)      
  SELECT  a.customer_code,      
     a.apply_to_num ,       
     SUM(a.amount)       
   FROM #artrxage_tmp  a    
   GROUP BY a.customer_code,a.apply_to_num      
   HAVING ABS(SUM(a.amount)) > 0.001      
  
	-- v3.1
	INSERT #invoices (customer_code, doc_ctrl_num, balance)    
	SELECT  a.customer_code,    
			a.doc_ctrl_num,     
			SUM(a.amount)     
	FROM	#artrxage_tmp  a 
	WHERE	(LEFT(a.doc_ctrl_num,3) = 'FIN' OR LEFT(a.doc_ctrl_num,4) = 'LATE')
	AND		a.paid_flag = 0	 
	GROUP BY a.customer_code,a.doc_ctrl_num    
	HAVING ABS(SUM(a.amount)) > 0.001    
	-- v3.1


    CREATE INDEX #invoices_idx1 ON #invoices(customer_code, doc_ctrl_num )      
    
    UPDATE  #invoices      
    SET amt_net      = h.amt_net,      
   amt_paid_to_date  = h.amt_paid_to_date,      
   balance      = h.amt_net - h.amt_paid_to_date,      
   date_doc      = a.date_doc,      
   date_due      = a.date_due,      
   date_aging     = (1+ sign(sign(a.ref_id) - 1))*a.date_aging + abs(sign(sign(a.ref_id)-1))*a.date_doc,       
   date_applied    = a.date_applied,      
   trx_type      = a.trx_type,      
   nat_cur_code    = a.nat_cur_code,      
   apply_to_num    = a.apply_to_num,      
   sub_apply_num   = a.sub_apply_num,       
   trx_ctrl_num    = a.trx_ctrl_num,      
   cust_po_num    = a.cust_po_num,      
   on_acct_flag    = 0,      
   order_ctrl_num   = h.order_ctrl_num,      
   org_id       = a.org_id,
	parent = a.parent    
    FROM  #artrxage_tmp a, #invoices i, artrx h (NOLOCK)     
    WHERE  a.doc_ctrl_num = i.doc_ctrl_num      
    AND  a.customer_code = i.customer_code      
    AND  a.doc_ctrl_num = h.doc_ctrl_num    
      
 DELETE #invoices where trx_type > 2031 AND trx_type NOT IN (2061,2071) --v3.1     
       
 -- v2.0 DELETE #invoices where ABS(balance) < 0.01        
DELETE #invoices where ABS(balance) < 0.001 -- v2.0        
          
 CREATE TABLE #open      
 ( customer_code varchar(8),      
  doc_ctrl_num  varchar(16) NULL,      
  amt_net    float   NULL)      
      
   INSERT #open      
   SELECT a.customer_code,      
     a.apply_to_num,       
     SUM(a.amount)        
   FROM #artrxage_tmp a      
   JOIN #cust x -- v1.4  
   ON  a.customer_code = x.child -- v1.4  
   LEFT JOIN #invoices i -- v1.4  
   ON  a.apply_to_num = i.doc_ctrl_num -- v1.4  
   WHERE i.doc_ctrl_num IS NULL  
   GROUP BY a.customer_code, a.apply_to_num      
   HAVING ABS(SUM(a.amount)) > 0.000001       
      
 CREATE INDEX #open_idx1 ON #open( doc_ctrl_num)      
       
   INSERT #invoices       
   ( customer_code,      
      doc_ctrl_num,       
      amt_net,       
      amt_paid_to_date,      
    date_doc,      
      date_due,      
      date_aging,      
      date_applied,      
      trx_type,      
      nat_cur_code,      
      apply_to_num,      
      sub_apply_num,       
      trx_ctrl_num,      
      cust_po_num,      
      on_acct_flag,      
      order_ctrl_num,      
      artrx_doc_ctrl_num,      
      org_id,
	  parent )      
     SELECT a.customer_code,      
      a.doc_ctrl_num,       
      h.amt_net,       
      h.amt_paid_to_date,      
       h.date_doc,      
      a.date_due,      
      (1+ sign(sign(a.ref_id) - 1))*a.date_aging + abs(sign(sign(a.ref_id)-1))*a.date_doc,       
      h.date_applied,      
      h.trx_type,      
      h.nat_cur_code,      
      a.apply_to_num,      
      a.sub_apply_num,       
      h.trx_ctrl_num,      
      h.cust_po_num,      
      0,      
      h.order_ctrl_num,      
      a.doc_ctrl_num,      
      a.org_id,
	  a.parent          
     FROM  #artrxage_tmp a, #open o, artrx h (NOLOCK), #cust c -- v1.4       
     WHERE  h.paid_flag = 0      
     AND h.trx_type in (2021,2031)      
     AND  a.doc_ctrl_num = o.doc_ctrl_num      
     AND  a.customer_code = c.child -- v1.4   
     AND  a.trx_ctrl_num = h.trx_ctrl_num      
    
 -- update invoice hold status using cte instead of in document loop      
 ;with cte as       
 (select max(sequence_num) seq, doc_ctrl_num, customer_code, status_code, date      
 from cc_inv_status_hist (NOLOCK) -- v1.0      
 where clear_date is null      
 group by doc_ctrl_num, customer_code, status_code, date)      
 UPDATE  i SET   i.status_code = cte.status_code,      
  i.status_date = cte.date      
  FROM   #invoices i, cte      
  WHERE  i.doc_ctrl_num = cte.doc_ctrl_num      
  AND   i.customer_code = cte.customer_code      
    
 -- update amount paid to date      
    UPDATE  #invoices      
 SET   amt_paid_to_date = (amt_net-balance) * -1      
 WHERE trx_type in (2021,2031)      
              
   SELECT customer_code,      
     doc_ctrl_num,       
     'true_amount' = SUM(amount)      
   INTO #cm       
   FROM #artrxage_tmp       
   WHERE paid_flag = 0      
   AND  trx_type in (2111,2161)      
   AND  ref_id < 1      
   GROUP BY customer_code,doc_ctrl_num      
   HAVING ABS(SUM(amount)) > 0.0001     
  
   INSERT #invoices ( customer_code,      
     doc_ctrl_num,      
     date_doc,      
     trx_type,      
     amt_net,      
     amt_paid_to_date,      
     on_acct_flag,      
     nat_cur_code,      
     apply_to_num,      
     sub_apply_num,      
     trx_ctrl_num,      
     date_due,      
     date_aging,      
     date_applied,      
     order_ctrl_num,      
     artrx_doc_ctrl_num,      
     org_id,
	 parent )      
   SELECT  a.customer_code,      
      a.doc_ctrl_num,      
     date_doc,      
     trx_type,      
     a.amount,      
     amt_paid,      
     1,       
     nat_cur_code,      
     apply_to_num,      
     sub_apply_num,       
     trx_ctrl_num,      
     a.date_due,      
     date_aging = (1+ sign(sign(a.ref_id) - 1))*a.date_aging + abs(sign(sign(a.ref_id)-1))*a.date_doc,       
     date_applied,      
     order_ctrl_num,      
     a.doc_ctrl_num,      
     a.org_id,
	  a.parent      
   FROM  #artrxage_tmp a, #cm c      
   WHERE  a.customer_code = c.customer_code      
   AND  trx_type in (2111,2161)       
   AND  (amount > 0.000001 or amount < -0.000001 )      
   AND  a.apply_to_num = a.doc_ctrl_num      
   AND  paid_flag = 0      
   AND  ref_id = 0      
   AND  a.doc_ctrl_num = c.doc_ctrl_num      
   AND  ISNULL(DATALENGTH(RTRIM(LTRIM(c.doc_ctrl_num))), 0 ) > 0      
  
   DROP TABLE #cm      
  
 DELETE #invoices WHERE trx_type IS NULL  
  
   UPDATE  #invoices       
   SET  cust_po_num = h.cust_po_num      
   FROM #invoices i, artrx h (NOLOCK)      
   WHERE i.doc_ctrl_num = h.doc_ctrl_num      
   AND  i.customer_code = h.customer_code      

	-- v3.3 Start
    
	DELETE  a 
	FROM	#invoices a
	JOIN	#artrxage_tmp b
	ON		a.doc_ctrl_num = b.doc_ctrl_num     
	AND		a.customer_code = b.customer_code 
	WHERE	b.apply_trx_type = 2031       
	AND		b.trx_type = 2112 
	AND		a.on_acct_flag = 1      
	AND		a.trx_type NOT IN ( 2161, 2111)
	
	DELETE  a
	FROM	#invoices  a
	JOIN	artrx b (NOLOCK)
	ON		a.doc_ctrl_num = b.doc_ctrl_num
	AND		a.customer_code = b.customer_code
	WHERE	b.void_flag = 1          
	AND		a.trx_type in (2111,2161)              


/*
   DELETE  #invoices      
   WHERE  doc_ctrl_num in (SELECT a.doc_ctrl_num       
   FROM  #artrxage_tmp a, #invoices i       
   WHERE  a.apply_trx_type = 2031       
   AND  a.trx_type = 2112      
   AND  a.customer_code = i.customer_code )      
   AND on_acct_flag = 1      
   AND trx_type NOT IN ( 2161, 2111)      
        
   DELETE #invoices       
   WHERE doc_ctrl_num in ( SELECT a.doc_ctrl_num       
   FROM artrx a (NOLOCK), #invoices i       
   WHERE a.void_flag = 1          
   AND a.customer_code = i.customer_code )      
   AND trx_type in (2111,2161)   
*/
	-- v3.3 End    
        
   UPDATE  #invoices      
   SET  #invoices.trx_type_code = artrxtyp.trx_type_code      
   FROM  #invoices, artrxtyp (NOLOCK)     
   WHERE  artrxtyp.trx_type = #invoices.trx_type      
           
   -- Update on account balances      
       
   ; with cte as        
   ( select sum(amount) bal, a.doc_ctrl_num, a.customer_code      
      from #artrxage_tmp a, #invoices i       
      where a.doc_ctrl_num = i.artrx_doc_ctrl_num      
      and a.customer_code = i.customer_code      
      and ref_id < 1      
      group by a.doc_ctrl_num, a.customer_code      
     )      
  
   update i set i.balance = cte.bal      
   from #invoices i, cte      
   where i.doc_ctrl_num = cte.doc_ctrl_num and i.customer_code = cte.customer_code      
   and i.on_acct_flag = 1      
   
      
 --PJC 20120405      
 --DECLARE @date int      
      
 SELECT @last_cust = MIN(customer_code) FROM #invoices      
 WHILE ( @last_cust IS NOT NULL )      
 BEGIN      
  SELECT @last_doc = MIN(doc_ctrl_num ) FROM #invoices WHERE trx_type IN (2112,2113,2121) AND customer_code = @last_cust      
      
  WHILE ( @last_doc IS NOT NULL )      
  BEGIN      
   SELECT @date = date_doc      
   FROM #invoices      
   WHERE doc_ctrl_num = @last_doc      
   AND trx_type = 2111      
   AND customer_code = @last_cust      
          
   UPDATE #invoices      
   SET date_doc = @date      
   WHERE doc_ctrl_num = @last_doc      
   AND customer_code = @last_cust      
      
   SELECT @last_doc = MIN(doc_ctrl_num )       
   FROM #invoices      
   WHERE doc_ctrl_num = @last_doc       
   AND trx_type IN (2112,2113,2121)      
   AND customer_code = @last_cust      
  END      
  SELECT @last_cust = MIN(customer_code) FROM #invoices WHERE customer_code > @last_cust      
 END      
       
      
 SELECT @last_cust = MIN(customer_code) FROM #invoices      
 WHILE ( @last_cust IS NOT NULL )      
 BEGIN      
  SELECT @last_doc = MIN(doc_ctrl_num ) FROM #invoices WHERE on_acct_flag = 1 -- v2.1 AND date_due = 0 
															AND customer_code = @last_cust      
  WHILE ( @last_doc IS NOT NULL )      
  BEGIN      
   SELECT @date_doc = MIN(date_doc)      
   FROM #invoices      
   WHERE doc_ctrl_num = @last_doc      
   AND customer_code = @last_cust      
       
      SELECT @terms_code = terms_code, @date_due = date_due
	   FROM artrx (NOLOCK) WHERE doc_ctrl_num = @last_doc AND customer_code = @last_cust      
   /* PJC 042413 - get terms code from customer when terms code is blank */      
   IF ( @terms_code = '' OR @terms_code IS NULL )      
    SELECT @terms_code = terms_code from arcust (NOLOCK) where customer_code = @last_cust      
     begin      
	   IF ( SELECT ISNULL(DATALENGTH(LTRIM(RTRIM(@terms_code))), 0)) = 0       
		SELECT @terms_code = terms_code FROM arcust (NOLOCK) WHERE customer_code = @last_cust      
      
	   EXEC CVO_CalcDueDate_sp @last_cust, @date_doc, @date_due OUTPUT, @terms_code      
		end
   /* PJC 042413 - use doc date if due date is blank */      
   IF ( @date_due = 0 or @date_due IS NULL )      
    SELECT @date_due = @date_doc      
          
   UPDATE #invoices       
   SET  date_due = @date_due,      
     date_aging = @date_due      
   WHERE doc_ctrl_num = @last_doc      
   AND  trx_type <> 2031      
   AND  customer_code = @last_cust      
      
   SELECT @last_doc = MIN(doc_ctrl_num )      
   FROM #invoices       
-- v2.1   WHERE doc_ctrl_num = 'ON ACCT'      
   WHERE doc_ctrl_num > @last_doc -- v2.1     
-- v2.1   AND date_due = 0      
   AND customer_code = @last_cust      
   AND on_acct_flag = 1      
  END      
  SELECT @last_cust = MIN(customer_code) FROM #invoices WHERE customer_code > @last_cust      
 END      
   

   
 EXEC cvo_set_bucket_sp      
  

    
 --PJC 042513 - the stored procedure is messing up the dates      
 update #invoices set date_due = date_doc where date_due < 639906 and date_doc > 639906      
  
         
  
       
 IF @DATE_TYPE_PARM = 1  -- date_doc      
  BEGIN      
      
      
   UPDATE #invoices      
    SET AMT_AGE_BRACKET0 = CASE WHEN (date_doc)       
    > ( select date_end from #dates       
    where bucket = 'future' )       
    THEN balance ELSE 0 END,      
    AMT_AGE_BRACKET1 = CASE WHEN (DATE_DOC)       
    between ( select date_start from #dates       
    where bucket = 'current' )       
    and (select date_end from #dates       
    where bucket = 'current')       
    THEN balance ELSE 0 END,      
       AMT_AGE_BRACKET2 = case when (date_doc)      
    between ( select date_start from #dates       
    where bucket = '1-30' )       
       and ( select date_end from #dates       
    where bucket = '1-30')       
    then balance else 0 end,      
       AMT_AGE_BRACKET3 = case when (DATE_DOC)       
    between ( select date_start from #dates       
    where bucket = '31-60' )       
       and ( select date_end from #dates       
    where bucket = '31-60')       
    then balance else 0 end,      
    AMT_AGE_BRACKET4 = case when (DATE_DOC)       
    between ( select date_start from #dates       
    where bucket = '61-90' )       
       and ( select date_end from #dates       
    where bucket = '61-90')       
    then balance else 0 end,      
       AMT_AGE_BRACKET5 = case when (DATE_DOC)       
    between ( select date_start from #dates       
    where bucket = '91-120' )       
       and ( select date_end from #dates       
    where bucket = '91-120')      
    then balance else 0 end,      
     AMT_AGE_BRACKET6 = CASE WHEN (DATE_DOC)       
    <= ( select date_end from #dates       
    where bucket = '121-150' )       
       then balance else 0 end      
   FROM #invoices   
 
  end      
      
 IF @DATE_TYPE_PARM = 2  -- date_applied      
  BEGIN       
         
   UPDATE #invoices      
    SET AMT_AGE_BRACKET0 = CASE WHEN (date_APPLIED)       
    > ( select date_end from #dates       
    where bucket = 'future' )       
    THEN balance ELSE 0 END,      
       AMT_AGE_BRACKET1 = CASE WHEN (date_APPLIED)       
    between ( select date_start from #dates       
    where bucket = 'current' )       
    and (select date_end from #dates       
    where bucket = 'current')       
    THEN balance ELSE 0 END,      
      AMT_AGE_BRACKET2 = case when (date_APPLIED)      
    between ( select date_start from #dates       
    where bucket = '1-30' )       
       and ( select date_end from #dates       
    where bucket = '1-30')       
    then balance else 0 end,      
     AMT_AGE_BRACKET3 = case when (date_APPLIED)       
    between ( select date_start from #dates       
    where bucket = '31-60' )       
       and ( select date_end from #dates       
    where bucket = '31-60')       
    then balance else 0 end,      
     AMT_AGE_BRACKET4 = case when (date_APPLIED)       
    between ( select date_start from #dates       
    where bucket = '61-90' )       
       and ( select date_end from #dates       
    where bucket = '61-90')       
    then balance else 0 end,      
     AMT_AGE_BRACKET5 = case when (date_APPLIED)       
    between ( select date_start from #dates       
    where bucket = '91-120' )       
       and ( select date_end from #dates       
    where bucket = '91-120')      
    then balance else 0 end,      
     AMT_AGE_BRACKET6 = CASE WHEN (date_APPLIED)       
    <=  ( select date_end from #dates       
    where bucket = '121-150' )       
       then balance else 0 end      
   FROM #invoices          
  end      
 IF @DATE_TYPE_PARM = 3 -- date_aging      
  BEGIN       
   UPDATE #invoices      
    SET AMT_AGE_BRACKET0 = CASE WHEN (DATE_AGING)       
    > ( select date_end from #dates       
    where bucket = 'future' )       
    THEN balance ELSE 0 END,      
      AMT_AGE_BRACKET1 = CASE WHEN (DATE_AGING)       
    between ( select date_start from #dates       
    where bucket = 'current' )       
    and (select date_end from #dates       
    where bucket = 'current')       
    THEN balance ELSE 0 END,      
      AMT_AGE_BRACKET2 = case when (DATE_AGING)      
    between ( select date_start from #dates       
    where bucket = '1-30' )       
       and ( select date_end from #dates       
    where bucket = '1-30')       
    then balance else 0 end,      
     AMT_AGE_BRACKET3 = case when (DATE_AGING)       
    between ( select date_start from #dates       
    where bucket = '31-60' )       
       and ( select date_end from #dates       
    where bucket = '31-60')       
    then balance else 0 end,      
     AMT_AGE_BRACKET4 = case when (DATE_AGING)       
    between ( select date_start from #dates       
    where bucket = '61-90' )       
       and ( select date_end from #dates       
    where bucket = '61-90')       
    then balance else 0 end,      
     AMT_AGE_BRACKET5 = case when (DATE_AGING)       
    between ( select date_start from #dates       
    where bucket = '91-120' )       
       and ( select date_end from #dates       
    where bucket = '91-120')      
    then balance else 0 end,      
     AMT_AGE_BRACKET6 = CASE WHEN (DATE_AGING)       
    <=  ( select date_end from #dates       
    where bucket = '121-150' )       
       then balance else 0 end      
   FROM #invoices       
  end      
 IF @DATE_TYPE_PARM = 4 -- date_due      
  BEGIN       
   UPDATE #invoices      
    SET AMT_AGE_BRACKET0 = CASE WHEN (DATE_DUE)       
    > ( select date_start from #dates       
    where bucket = 'future' )       
    THEN balance ELSE 0 END,      
     AMT_AGE_BRACKET1 = CASE WHEN (DATE_DUE)       
    between ( select date_start from #dates       
    where bucket = 'current' )       
    and (select date_end from #dates       
    where bucket = 'current')       
    THEN balance ELSE 0 END,      
     AMT_AGE_BRACKET2 = case when (DATE_DUE)      
    between ( select date_start from #dates       
    where bucket = '1-30' )       
       and ( select date_end from #dates       
    where bucket = '1-30')       
    then balance else 0 end,      
     AMT_AGE_BRACKET3 = case when (DATE_DUE)       
    between ( select date_start from #dates       
    where bucket = '31-60' )       
       and ( select date_end from #dates       
    where bucket = '31-60')       
    then balance else 0 end,      
    AMT_AGE_BRACKET4 = case when (DATE_DUE)       
    between ( select date_start from #dates       
    where bucket = '61-90' )       
       and ( select date_end from #dates       
    where bucket = '61-90')       
    then balance else 0 end,      
    AMT_AGE_BRACKET5 = case when (DATE_DUE)       
    between ( select date_start from #dates       
    where bucket = '91-120' )       
       and ( select date_end from #dates       
    where bucket = '91-120')      
    then balance else 0 end,      
    AMT_AGE_BRACKET6 = CASE WHEN (DATE_DUE)       
    <=  ( select date_end from #dates       
    where bucket = '121-150' )       
       then balance else 0 end      
   FROM #invoices      
  end      
   
 -- v3.2 Start
 SELECT DISTINCT * INTO #invoices2
 FROM	#invoices

 TRUNCATE TABLE #invoices

 INSERT #invoices
 SELECT * FROM #invoices2

 DROP TABLE #invoices2
    
 -- v3.2 End

 INSERT #AGE_SUMMARY      
 SELECT  PARENT,       
   SUM(balance),      
   sum(amt_age_bracket0),      
   SUM(AMT_AGE_BRACKET1),      
   SUM(AMT_AGE_BRACKET2),      
   SUM(AMT_AGE_BRACKET3),      
   SUM(AMT_AGE_BRACKET4),      
   SUM(AMT_AGE_BRACKET5),      
   SUM(AMT_AGE_BRACKET6)      
 FROM #invoices       
 GROUP BY PARENT    
 -- v1.1 End      
    
    
--select * from #age_summary        
--select * from #artrxage_tmp where AMT_AGE_BRACKET1 <> 0  
  
--select * from #invoices  
      
 INSERT INTO #FINAL      
 (      
  CUSTOMER_CODE,      
  ADDR_SORT1,      
  attn_email,     --v1.1      
  SALESPERSON_CODE,      
  TERRITORY_CODE,      
  ADDRESS_NAME,      
  BG_CODE,      
  BG_NAME,      
  PRICE_CODE,      
  BAL,      
  FUT,      
  CUR,      
  AR30,      
  AR60,      
  AR90,      
  AR120,      
  ar150,      
  CREDIT_LIMIT,      
  ONORDER,      
  YTDCREDS,      
  YTDSALES,      
  LYRSALES,    
  r12sales      
 )      
 SELECT        
  A.CUSTOMER_CODE,      
  M.ADDR_SORT1,      
  isnull(M.attention_email,'') attention_email,   --v1.1      
  M.SALESPERSON_CODE,      
  M.TERRITORY_CODE,      
  M.ADDRESS_NAME,      
  IsNull(na.parent,'') as BG_Code,      
  IsNull(c.customer_name,'') as BG_Name,      
  M.PRICE_CODE,      
  A.AMOUNT, -- bal      
  a.amt_age_bracket0, -- fut      
  A.AMT_AGE_BRACKET1, -- cur      
  A.AMT_AGE_BRACKET2, -- 1-30      
  A.AMT_AGE_BRACKET3, -- 31-60      
  A.AMT_AGE_BRACKET4, -- 61-90      
  A.AMT_AGE_BRACKET5, -- 91-120      
  A.AMT_AGE_BRACKET6, -- over 120       
  M.CREDIT_LIMIT,      
  0, 0, 0, 0, 0      
 FROM #AGE_SUMMARY A      
 LEFT OUTER JOIN ARMASTER_ALL M (NOLOCK) ON A.CUSTOMER_CODE = M.CUSTOMER_CODE      
 LEFT OUTER JOIN arnarel na (NOLOCK) ON A.CUSTOMER_CODE = na.child      
 LEFT OUTER JOIN arcust c (NOLOCK) ON na.parent = c.customer_code      
 WHERE M.ADDRESS_TYPE = 0      
       
 UPDATE #FINAL     
 SET     
 YTDCREDS = isnull((select sum(areturns) from dbo.cvo_sbm_details AS sd where    
    customer = f.customer_code and yyyymmdd >=@curryrstart), 0),    
 YTDSALES = isnull((select sum(anet) from dbo.cvo_sbm_details AS sd2 where    
    customer = f.customer_code and yyyymmdd >=@curryrstart), 0),    
 LYRSALES = isnull((select sum(anet) from dbo.cvo_sbm_details AS sd3 where    
    customer = f.customer_code and yyyymmdd  BETWEEN @LASTYRSTART AND @LASTYREND), 0),    
 r12Sales = isnull((select sum(anet) from cvo_sbm_details where    
     customer = f.customer_code and yyyymmdd >=@r12Start), 0)    
 from #final F     
      
      
 --ON ORDER      
 if(object_id('tempdb.dbo.#onord') is not null) drop table #onord      
 SELECT CUST_CODE,     
 ISNULL(SUM (CASE WHEN type = 'I' THEN     
     (total_amt_order + tot_ord_tax - tot_ord_disc + tot_ord_freight)     
  ELSE ((total_amt_order * -1) + (tot_ord_tax * -1)     
      - (tot_ord_disc * -1) + (tot_ord_freight * -1)) END) , 0 ) as onord    
 INTO #ONORD    
 FROM ORDERS_ALL (NOLOCK)    
    WHERE status NOT IN ( 'R', 'S', 'T' )     
    AND UPPER( status ) IN ( SELECT UPPER( status_code ) FROM cc_ord_status WHERE use_flag = 1 )     
    AND void = 'N'     
 GROUP BY CUST_CODE     
       
 UPDATE #FINAL SET ONORDER = ONORD      
 FROM #FINAL F, #ONORD D      
 WHERE F.CUSTOMER_CODE = D.CUST_CODE      
       
 --HOLD      
 UPDATE #FINAL SET HOLD = C.STATUS_CODE      
 FROM #FINAL F, CC_CUST_STATUS_HIST C      
 WHERE F.CUSTOMER_CODE = C.CUSTOMER_CODE       
 AND C.CLEAR_DATE IS NULL      
      
      
 --AVGDAYSLATE      
       
 if(object_id('tempdb.dbo.#avg') is not null) drop table #avg      
  SELECT A.CUSTOMER_CODE, SUM(@date_asof - A.DATE_DUE)/COUNT(*) AS AVGDAYSLATE       
 INTO #AVG      
 FROM ARTRX A, #FINAL F      
 WHERE A.TRX_TYPE = '2031'      
 AND @DATE_ASOF > A.DATE_DUE      
 AND A.CUSTOMER_CODE = F.CUSTOMER_CODE      
 -- and a.customer_code = @last_customer      
 GROUP BY A.CUSTOMER_CODE      
       
 UPDATE F      
 SET AVGDAYSLATE = A.AVGDAYSLATE      
 FROM #AVG A, #FINAL F      
 WHERE A.CUSTOMER_CODE = F.CUSTOMER_CODE      
      
--      
 declare @date_entered int, @last_customer varchar(10), 
--@last_check varchar(16), 
@last_amt float    
    
 select @last_customer = min(customer_code) from #final      
 While (@last_customer is not null )      
 begin      
-- tag - last payment and date - simple version      
--          
        SELECT @date_entered = MAX( date_entered )     
     FROM artrx    
    
     WHERE customer_code = @last_customer    
     AND trx_type = 2111    
     AND void_flag = 0    
     AND payment_type <> 3     
    
        SELECT @last_check = doc_ctrl_num,    
         @last_amt = amt_net    
     FROM artrx    
     WHERE customer_code = @last_customer    
    
     AND trx_type = 2111    
     AND void_flag = 0    
     AND payment_type <> 3     
     AND date_entered = @date_entered    
     ORDER BY trx_ctrl_num DESC    
    
  update F set lpmtdt = @date_entered, amount = @last_amt      
  from #final F      
  where f.customer_code = @last_customer    
      
  select @last_customer = min(customer_code) from #final      
  where customer_code > @last_customer      
        
 end      
      
     
      
 SELECT       
   CUST_CODE = CUSTOMER_CODE,    
   [KEY] = ADDR_SORT1,    
   attn_email,    
   SLS = SALESPERSON_CODE,    
   TERR = #final.TERRITORY_CODE,    
   -- 11/1/2013    
   tr.region AS REGION,    
   NAME = ADDRESS_NAME,    
   BG_CODE,    
   BG_NAME,    
   TMS = PRICE_CODE,    
   r12sales, -- 101613    
   AVGDAYSLATE,    
   BAL,    
   FUT,    
   CUR,    
   AR30,    
   AR60,    
   AR90,    
   AR120,    
   AR150,    
   CREDIT_LIMIT,    
   ONORDER,    
   --LPMTDT,    
   convert(datetime,dateadd(d,LPMTDT-711858,'1/1/1950'),101) lpmtdt,                  AMOUNT,    
   YTDCREDS,    
   YTDSALES,    
   LYRSALES,    
   HOLD,     
   convert(varchar,dateadd(d,@date_asof-711858,'1/1/1950'),101) as date_asof,    
--   @date_asof as date_asof,    
   @DATE_TYPE_STRING as date_type_string,    
   @DATE_TYPE_parm as date_type    
 FROM #FINAL
 JOIN
 (SELECT DISTINCT territory_code, dbo.calculate_region_fn(territory_code) region FROM #final
 ) tr ON tr.TERRITORY_CODE = #FINAL.TERRITORY_CODE       
      
-- DROP TABLE #ARTRXAGE_TMP       
-- DROP TABLE #AGE_SUMMARY      
-- DROP TABLE #NON_ZERO_RECORDS       
 DROP TABLE #FINAL      
 DROP TABLE #ONORD      
-- DROP TABLE #CRED      
-- DROP TABLE #SALES      
-- DROP TABLE #LSALES      
-- DROP TABLE #CHECK_DATA      
-- DROP TABLE #TEMP2      
-- DROP TABLE #TEMP3      
-- DROP TABLE #LPMTDT      
 DROP TABLE #AVG      
      
 -- v1.1 Start    
 DROP TABLE #cust    
 DROP TABLE #bg_data    
 -- v1.1 End    
    
 SET NOCOUNT off       
end -- CVO_ARAGING_SP DATA       

GO

GRANT EXECUTE ON  [dbo].[CVO_ARAGING_SP] TO [public]
GO
