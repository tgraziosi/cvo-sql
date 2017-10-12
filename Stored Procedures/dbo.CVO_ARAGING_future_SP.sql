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

                     
 EXEC CVO_ARAGING_future_SP ''

'where CUST_CODE LIKE ''000500'''  
  
EXEC CVO_ARAGING_future_SP 'where CUST_CODE LIKE ''000500'''  

EXEC cc_summary_aging_sp '039226',4,1,'CVO','CVO',0

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
-- v3.4 TG 4/24/2017 - use cvo_sbm_details instead of cvo_csbm_shipto
-- v3.4 CB 06/10/2017 - BG Performance

-- tag - 3/13/2017 - Future aging - cash forecast

CREATE PROCEDURE [dbo].[CVO_ARAGING_future_SP]
    (
      @WHERECLAUSE VARCHAR(1024)
    )
AS
    DECLARE @CUSTOMER_CODE VARCHAR(8) ,
        @DATE_TYPE_PARM TINYINT ,
        @AGEBRK_USER_ID INT ,
        @ALL_ORG_FLAG SMALLINT ,
        @FROM_ORG VARCHAR(30) ,
        @TO_ORG VARCHAR(30) ,
        @CURRYRSTART DATETIME ,
        @CURRYREND DATETIME ,
        @LASTYRSTART DATETIME ,
        @LASTYREND DATETIME ,
        @R12START DATETIME ,
        @CUST INT ,
        @SQL VARCHAR(4000);      
      
      
    DECLARE @date INT ,
        @date_rec INT;      
      
    SELECT  @AGEBRK_USER_ID = 1 ,
            @ALL_ORG_FLAG = 1 ,
            @FROM_ORG = 'CVO' ,
            @TO_ORG = 'CVO';      
      
    SELECT  @CURRYRSTART = CONVERT(DATETIME, '1/1/'
            + CAST(YEAR(GETDATE()) AS VARCHAR)) ,
            @CURRYREND = CONVERT(DATETIME, '12/31/'
            + CAST(YEAR(GETDATE()) AS VARCHAR)) ,
            @LASTYRSTART = CONVERT(DATETIME, '1/1/'
            + CAST(YEAR(GETDATE()) - 1 AS VARCHAR)) ,
            @LASTYREND = CONVERT(DATETIME, '12/31/'
            + CAST(YEAR(GETDATE()) - 1 AS VARCHAR)) ,
            @R12START = DATEADD(yy, -1,
                                DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0));    
      
    BEGIN -- CVO_ARAGING_SP DATA      
      
        SET NOCOUNT ON;      
        DECLARE @DATE_ASOF INT ,
            @PRECISION_HOME SMALLINT ,
            @HOME_SYMBOL VARCHAR(8) ,
            @HOME_CURRENCY VARCHAR(8) ,
            @MULTI_CURRENCY_FLAG SMALLINT ,
            @DATE_TYPE_STRING VARCHAR(25);      
      
        IF ( SELECT ib_flag
             FROM   dbo.glco
           ) = 0
            SELECT  @ALL_ORG_FLAG = 1;      
       
        SET @WHERECLAUSE = REPLACE(@WHERECLAUSE, ' AND ', '');      
    
        IF ( CHARINDEX('DATE_TYPE=', @WHERECLAUSE) <> 0 )
            BEGIN       
                SET @WHERECLAUSE = REPLACE(@WHERECLAUSE, 'DATE_TYPE=', '');      
                SET @DATE_TYPE_PARM = SUBSTRING(@WHERECLAUSE,
                                                LEN(@WHERECLAUSE), 1);      
                SET @WHERECLAUSE = LEFT(@WHERECLAUSE, LEN(@WHERECLAUSE) - 1);      
            END;      
        ELSE
            BEGIN      
                SELECT  @DATE_TYPE_PARM = 4; -- default to due_date      
            END;       
    
        IF ( CHARINDEX('DATE_ASOF=', @WHERECLAUSE) = 0 )
            BEGIN       
                SELECT  @DATE_ASOF = DATEDIFF(DD, '1/1/1753',
                                              CONVERT(DATETIME, GETDATE()))
                        + 639906;      
            END;       
        ELSE
            BEGIN      
                SET @WHERECLAUSE = REPLACE(@WHERECLAUSE, 'DATE_ASOF=', '');      
                SELECT  @DATE_ASOF = SUBSTRING(@WHERECLAUSE,
                                               LEN(@WHERECLAUSE) - 5,
                                               LEN(@WHERECLAUSE)); -- julian date      
                SET @WHERECLAUSE = LEFT(@WHERECLAUSE, LEN(@WHERECLAUSE) - 6);      
            END;       
          
        SELECT  @CUST = 0;      
        IF ( CHARINDEX('CUST_CODE', @WHERECLAUSE) <> 0 )
            BEGIN      
                SET @WHERECLAUSE = REPLACE(@WHERECLAUSE, 'CUST_CODE',
                                           'CUSTOMER_CODE');       
                SELECT  @CUST = 1;      
            END;       
         
        IF @DATE_TYPE_PARM = 1
            SELECT  @DATE_TYPE_STRING = 'DOCUMENT DATE';      
        IF @DATE_TYPE_PARM = 2
            SELECT  @DATE_TYPE_STRING = 'APPLY DATE';      
        IF @DATE_TYPE_PARM = 3
            SELECT  @DATE_TYPE_STRING = 'AGING DATE';      
        IF @DATE_TYPE_PARM = 4
            SELECT  @DATE_TYPE_STRING = 'DUE DATE';      
      
          
        SELECT  @PRECISION_HOME = curr_precision ,
                @MULTI_CURRENCY_FLAG = multi_currency_flag ,
                @HOME_CURRENCY = home_currency ,
                @HOME_SYMBOL = symbol
        FROM    dbo.glcurr_vw (NOLOCK) ,
                dbo.glco (NOLOCK)
        WHERE   home_currency = currency_code;      
      
        IF ( OBJECT_ID('tempdb.dbo.#artrxage_tmp') IS NOT NULL )
            DROP TABLE #artrxage_tmp;      
      
        CREATE TABLE #ARTRXAGE_TMP
            (
              TRX_TYPE SMALLINT NULL ,
              TRX_CTRL_NUM VARCHAR(16) NULL ,
              DOC_CTRL_NUM VARCHAR(16) NULL ,
              APPLY_TO_NUM VARCHAR(16) NULL ,
              APPLY_TRX_TYPE SMALLINT NULL ,
              SUB_APPLY_NUM VARCHAR(16) NULL ,
              SUB_APPLY_TYPE SMALLINT NULL ,
              TERRITORY_CODE VARCHAR(8) NULL ,
              DATE_DOC INT NULL ,
              DATE_DUE INT NULL ,
              DATE_AGING INT NULL ,
              DATE_APPLIED INT NULL ,
              AMOUNT FLOAT NULL ,
              on_acct FLOAT NULL ,
              AMT_AGE_BRACKET1 FLOAT NULL ,
              AMT_AGE_BRACKET2 FLOAT NULL ,
              AMT_AGE_BRACKET3 FLOAT NULL ,
              AMT_AGE_BRACKET4 FLOAT NULL ,
              AMT_AGE_BRACKET5 FLOAT NULL ,
              AMT_AGE_BRACKET6 FLOAT NULL ,
              NAT_CUR_CODE VARCHAR(8) NULL ,
              RATE_HOME FLOAT NULL ,
              RATE_TYPE VARCHAR(8) NULL ,
              CUSTOMER_CODE VARCHAR(8) NULL ,
              PAYER_CUST_CODE VARCHAR(8) NULL ,
              TRX_TYPE_CODE VARCHAR(8) NULL ,
              REF_ID INT NULL ,
              CUST_PO_NUM VARCHAR(20) NULL ,
              PAID_FLAG SMALLINT NULL ,
              RATE_OPER FLOAT NULL ,
              ORG_ID VARCHAR(30) ,
              date_required INT ,
              amt_age_bracket0 FLOAT ,
              on_acct_flag INT ,
              amt_paid FLOAT ,
              order_ctrl_num VARCHAR(16) ,
              parent VARCHAR(10)
            ); -- v1.1      
      
      
 -- v3.4 CREATE INDEX #ARTRXAGE_IDX ON #ARTRXAGE_TMP   (customer_code, doc_ctrl_num)      
 -- v3.4 create index #artrxage_idx1 on #artrxage_tmp (amount)         
      
        IF ( OBJECT_ID('tempdb.dbo.#age_summary') IS NOT NULL )
            DROP TABLE #AGE_SUMMARY;      
      
        CREATE TABLE #AGE_SUMMARY
            (
              CUSTOMER_CODE VARCHAR(8) NULL ,
              AMOUNT FLOAT NULL ,
              amt_age_bracket0 FLOAT NULL ,
              AMT_AGE_BRACKET1 FLOAT NULL ,
              AMT_AGE_BRACKET2 FLOAT NULL ,
              AMT_AGE_BRACKET3 FLOAT NULL ,
              AMT_AGE_BRACKET4 FLOAT NULL ,
              AMT_AGE_BRACKET5 FLOAT NULL ,
              AMT_AGE_BRACKET6 FLOAT NULL
            );       
     
        CREATE INDEX #AGE_SUMMARY_IDX ON #AGE_SUMMARY (CUSTOMER_CODE);      
      
        IF ( OBJECT_ID('tempdb.dbo.#Final') IS NOT NULL )
            DROP TABLE #FINAL;      
     
        CREATE TABLE #FINAL
            (
              CUSTOMER_CODE VARCHAR(8) NULL ,
              ADDR_SORT1 VARCHAR(40) NULL ,
              attn_email VARCHAR(255) NULL ,   --v1.1      
              SALESPERSON_CODE VARCHAR(8) NULL ,
              TERRITORY_CODE VARCHAR(8) NULL ,
              ADDRESS_NAME VARCHAR(40) NULL ,
              BG_Code VARCHAR(8) NULL ,
              BG_Name VARCHAR(40) NULL ,
              PRICE_CODE VARCHAR(8) NULL ,
              AVGDAYSLATE SMALLINT NULL ,
              BAL FLOAT NULL ,
              FUT FLOAT NULL ,
              CUR FLOAT NULL ,
              AR30 FLOAT NULL ,
              AR60 FLOAT NULL ,
              AR90 FLOAT NULL ,
              AR120 FLOAT NULL ,
              AR150 FLOAT NULL ,
              CREDIT_LIMIT FLOAT NULL ,
              ONORDER FLOAT NULL ,
              LPMTDT INT NULL ,
              AMOUNT FLOAT NULL ,
              YTDCREDS FLOAT NULL ,
              YTDSALES FLOAT NULL ,
              LYRSALES FLOAT NULL ,
              HOLD VARCHAR(5) NULL ,
              r12sales FLOAT NULL
            ); -- 101613      
    
        CREATE INDEX #FINAL_IDX ON #FINAL (CUSTOMER_CODE);      
       
        IF ( OBJECT_ID('tempdb.dbo.#non_zero_records') IS NOT NULL )
            DROP TABLE #NON_ZERO_RECORDS;      
     
        CREATE TABLE #NON_ZERO_RECORDS
            (
              DOC_CTRL_NUM VARCHAR(16) ,
              TRX_TYPE SMALLINT ,
              CUSTOMER_CODE VARCHAR(8) ,
              TOTAL FLOAT
            );      
    
    
 -- v1.1 Start    
        CREATE TABLE #cust
            (
              parent VARCHAR(10) ,
              child VARCHAR(10)
            );    

	-- WORKING TABLE
        IF OBJECT_ID('tempdb..#bg_data') IS NOT NULL
            DROP TABLE #bg_data;

        CREATE TABLE #bg_data
            (
              doc_ctrl_num VARCHAR(16) ,
              order_ctrl_num VARCHAR(16) ,
              customer_code VARCHAR(10) ,
              doc_date_int INT ,
              doc_date VARCHAR(10) ,
              parent VARCHAR(10)
            );

		-- Call BG Data Proc
	-- v3.4	EXEC cvo_bg_get_document_data_sp
		-- v3.4 Start
		INSERT	#bg_data 
		SELECT	*
		FROM	cvo_artrxage (NOLOCK) 
		-- v3.4 End

        CREATE INDEX #bg_data_ind122 ON #bg_data (customer_code, doc_ctrl_num);

	-- v2.2 Start
        INSERT  #cust
                SELECT	DISTINCT
                        parent ,
                        customer_code
                FROM    #bg_data;
	-- v2.2 End


        IF ( @CUST = 1 )
            BEGIN    
                SET @WHERECLAUSE = REPLACE(@WHERECLAUSE, ' LIKE ',
                                           ' NOT LIKE ');     
                SET @WHERECLAUSE = REPLACE(@WHERECLAUSE, ' CUSTOMER_CODE ',
                                           ' PARENT ');     
                SET @SQL = ' DELETE #cust ' + @WHERECLAUSE;    
                EXEC (@SQL);    
            END;         


        INSERT  #ARTRXAGE_TMP
                SELECT DISTINCT
                        A.trx_type ,
                        A.trx_ctrl_num ,
                        A.doc_ctrl_num ,
                        A.apply_to_num ,
                        A.apply_trx_type ,
                        A.sub_apply_num ,
                        A.sub_apply_type ,
                        A.territory_code ,
                        A.date_doc ,
                        A.date_due ,
                        ( 1 + SIGN(SIGN(A.ref_id) - 1) ) * A.date_aging
                        + ABS(SIGN(SIGN(A.ref_id) - 1)) * A.date_doc ,
                        A.date_applied ,
                        A.amount ,
                        0 ,
                        0 ,
                        0 ,
                        0 ,
                        0 ,
                        0 ,
                        0 ,
                        A.nat_cur_code ,
                        A.rate_home ,
                        '' ,
                        A.customer_code ,
                        A.payer_cust_code ,
                        '' ,
                        A.ref_id ,
                        '' ,
                        '' ,
                        A.rate_oper ,
                        A.org_id ,
                        0 ,
                        0 ,
                        0 ,
                        0 ,
                        A.order_ctrl_num ,
                        '' -- v1.1       
                FROM    dbo.artrxage A ( NOLOCK )
                        INNER JOIN #cust C ON A.customer_code = C.child;    
 
		CREATE INDEX #ARTRXAGE_IDX ON #ARTRXAGE_TMP   (customer_code, doc_ctrl_num) -- v3.4     
		 create index #artrxage_idx1 on #artrxage_tmp (amount) -- v3.4   

 -- v1.1 Start    
        UPDATE  a
        SET     a.parent = b.parent
        FROM    #ARTRXAGE_TMP a
                JOIN #bg_data b ON a.CUSTOMER_CODE = b.customer_code
                                   AND a.DOC_CTRL_NUM = b.doc_ctrl_num;	

        UPDATE  a
        SET     a.parent = b.parent
        FROM    #ARTRXAGE_TMP a
                JOIN #bg_data b ON a.CUSTOMER_CODE = b.customer_code
                                   AND a.DOC_CTRL_NUM = b.order_ctrl_num;	

  
        UPDATE  #ARTRXAGE_TMP
        SET     parent = CUSTOMER_CODE
        WHERE   parent = '';    
     
    
        IF ( @CUST = 1 )
            BEGIN    
                SET @SQL = ' DELETE #ARTRXAGE_TMP ' + @WHERECLAUSE;    
                EXEC (@SQL);    
            END;    
  
      
        CREATE TABLE #dates
            (
              date_start INT ,
              date_end INT ,
              bucket VARCHAR(25)
            );      
      
        SELECT  @DATE_TYPE_PARM = 4;      
      
        DECLARE @e_age_bracket_1 SMALLINT ,
            @e_age_bracket_2 SMALLINT ,
            @e_age_bracket_3 SMALLINT ,
            @e_age_bracket_4 SMALLINT ,
            @e_age_bracket_5 SMALLINT ,
            @b_age_bracket_1 SMALLINT ,
            @b_age_bracket_2 SMALLINT ,
            @b_age_bracket_3 SMALLINT ,
            @b_age_bracket_4 SMALLINT ,
            @b_age_bracket_5 SMALLINT ,
            @b_age_bracket_6 SMALLINT ,
            @detail_count INT ,
            @last_doc VARCHAR(16) ,
            @date_doc INT ,
            @date_due INT ,
            @terms_code VARCHAR(8) ,
            @last_check VARCHAR(16) ,
            @last_cust VARCHAR(8) ,
            @balance FLOAT ,
            @stat_seq INT;      
      
        SELECT  @DATE_ASOF = DATEDIFF(dd, '1/1/1753',
                                      CONVERT(DATETIME, GETDATE())) + 639906;      
      
        --SELECT  @e_age_bracket_1 = age_bracket1 ,
        --        @e_age_bracket_2 = age_bracket2 ,
        --        @e_age_bracket_3 = age_bracket3 ,
        --        @e_age_bracket_4 = age_bracket4 ,
        --        @e_age_bracket_5 = age_bracket5
        --FROM    dbo.arco (NOLOCK); -- v1.0     
      
        --SELECT  @b_age_bracket_2 = @e_age_bracket_1 + 1 ,
        --        @b_age_bracket_3 = @e_age_bracket_2 + 1 ,
        --        @b_age_bracket_4 = @e_age_bracket_3 + 1 ,
        --        @b_age_bracket_5 = @e_age_bracket_4 + 1 ,
        --        @b_age_bracket_6 = @e_age_bracket_5 + 1;       
      
      
        --SELECT  @e_age_bracket_1 = 30 ,
        --        @e_age_bracket_2 = 60 ,
        --        @e_age_bracket_3 = 90 ,
        --        @e_age_bracket_4 = 120 ,
        --        @e_age_bracket_5 = 150;      
      
      
        --SELECT  @b_age_bracket_1 = 1 ,
        --        @b_age_bracket_2 = 31 ,
        --        @b_age_bracket_3 = 61 ,
        --        @b_age_bracket_4 = 91 ,
        --        @b_age_bracket_5 = 121 ,
        --        @b_age_bracket_6 = 151;      
      
        CREATE TABLE #invoices
            (
              customer_code VARCHAR(8) ,
              doc_ctrl_num VARCHAR(16) NULL ,
              date_doc INT NULL ,
              trx_type INT NULL ,
              amt_net FLOAT NULL ,
              amt_paid_to_date FLOAT NULL ,
              balance FLOAT NULL ,
              on_acct_flag SMALLINT NULL ,
              nat_cur_code VARCHAR(8) NULL ,
              apply_to_num VARCHAR(16) NULL ,
              sub_apply_num VARCHAR(16) NULL ,
              trx_type_code VARCHAR(8) NULL ,
              trx_ctrl_num VARCHAR(16) NULL ,
              status_code VARCHAR(5) NULL ,
              status_date INT NULL ,
              cust_po_num VARCHAR(20) NULL ,
              age_bucket SMALLINT NULL ,
              date_due INT NULL ,
              date_aging INT NULL ,
              date_applied INT NULL ,
              order_ctrl_num VARCHAR(16) NULL ,
              artrx_doc_ctrl_num VARCHAR(16) NULL ,
              org_id VARCHAR(30) NULL ,
              parent VARCHAR(10) NULL ,
              amt_age_bracket0 FLOAT NULL ,
              AMT_AGE_BRACKET1 FLOAT NULL ,
              AMT_AGE_BRACKET2 FLOAT NULL ,
              AMT_AGE_BRACKET3 FLOAT NULL ,
              AMT_AGE_BRACKET4 FLOAT NULL ,
              AMT_AGE_BRACKET5 FLOAT NULL ,
              AMT_AGE_BRACKET6 FLOAT NULL
            );      
       
        INSERT  #invoices
                ( customer_code ,
                  doc_ctrl_num ,
                  balance
                )
                SELECT  a.CUSTOMER_CODE ,
                        a.APPLY_TO_NUM ,
                        SUM(a.AMOUNT)
                FROM    #ARTRXAGE_TMP a
                GROUP BY a.CUSTOMER_CODE ,
                        a.APPLY_TO_NUM
                HAVING  ABS(SUM(a.AMOUNT)) > 0.001;      
  
	-- v3.1
        INSERT  #invoices
                ( customer_code ,
                  doc_ctrl_num ,
                  balance
                )
                SELECT  a.CUSTOMER_CODE ,
                        a.DOC_CTRL_NUM ,
                        SUM(a.AMOUNT)
                FROM    #ARTRXAGE_TMP a
                WHERE   ( LEFT(a.DOC_CTRL_NUM, 3) = 'FIN'
                          OR LEFT(a.DOC_CTRL_NUM, 4) = 'LATE'
                        )
                        AND a.PAID_FLAG = 0
                GROUP BY a.CUSTOMER_CODE ,
                        a.DOC_CTRL_NUM
                HAVING  ABS(SUM(a.AMOUNT)) > 0.001;    
	-- v3.1


        CREATE INDEX #invoices_idx1 ON #invoices(customer_code, doc_ctrl_num );      
    
        UPDATE  #invoices
        SET     amt_net = h.amt_net ,
                amt_paid_to_date = h.amt_paid_to_date ,
                balance = h.amt_net - h.amt_paid_to_date ,
                date_doc = a.DATE_DOC ,
                date_due = a.DATE_DUE ,
                date_aging = ( 1 + SIGN(SIGN(a.REF_ID) - 1) ) * a.DATE_AGING
                + ABS(SIGN(SIGN(a.REF_ID) - 1)) * a.DATE_DOC ,
                date_applied = a.DATE_APPLIED ,
                trx_type = a.TRX_TYPE ,
                nat_cur_code = a.NAT_CUR_CODE ,
                apply_to_num = a.APPLY_TO_NUM ,
                sub_apply_num = a.SUB_APPLY_NUM ,
                trx_ctrl_num = a.TRX_CTRL_NUM ,
                cust_po_num = a.CUST_PO_NUM ,
                on_acct_flag = 0 ,
                order_ctrl_num = h.order_ctrl_num ,
                org_id = a.ORG_ID ,
                parent = a.parent
        FROM    #ARTRXAGE_TMP a ,
                #invoices i ,
                dbo.artrx h ( NOLOCK )
        WHERE   a.DOC_CTRL_NUM = i.doc_ctrl_num
                AND a.CUSTOMER_CODE = i.customer_code
                AND a.DOC_CTRL_NUM = h.doc_ctrl_num;    
      
        DELETE  #invoices
        WHERE   trx_type > 2031
                AND trx_type NOT IN ( 2061, 2071 ); --v3.1     
       
 -- v2.0 DELETE #invoices where ABS(balance) < 0.01        
        DELETE  #invoices
        WHERE   ABS(balance) < 0.001; -- v2.0        
          
        CREATE TABLE #open
            (
              customer_code VARCHAR(8) ,
              doc_ctrl_num VARCHAR(16) NULL ,
              amt_net FLOAT NULL
            );      
      
        INSERT  #open
                SELECT  a.CUSTOMER_CODE ,
                        a.APPLY_TO_NUM ,
                        SUM(a.AMOUNT)
                FROM    #ARTRXAGE_TMP a
                        JOIN #cust x -- v1.4  
                        ON a.CUSTOMER_CODE = x.child -- v1.4  
                        LEFT JOIN #invoices i -- v1.4  
                        ON a.APPLY_TO_NUM = i.doc_ctrl_num -- v1.4  
                WHERE   i.doc_ctrl_num IS NULL
                GROUP BY a.CUSTOMER_CODE ,
                        a.APPLY_TO_NUM
                HAVING  ABS(SUM(a.AMOUNT)) > 0.000001;       
      
        CREATE INDEX #open_idx1 ON #open( doc_ctrl_num);      
       
        INSERT  #invoices
                ( customer_code ,
                  doc_ctrl_num ,
                  amt_net ,
                  amt_paid_to_date ,
                  date_doc ,
                  date_due ,
                  date_aging ,
                  date_applied ,
                  trx_type ,
                  nat_cur_code ,
                  apply_to_num ,
                  sub_apply_num ,
                  trx_ctrl_num ,
                  cust_po_num ,
                  on_acct_flag ,
                  order_ctrl_num ,
                  artrx_doc_ctrl_num ,
                  org_id ,
                  parent
                )
                SELECT  a.CUSTOMER_CODE ,
                        a.DOC_CTRL_NUM ,
                        h.amt_net ,
                        h.amt_paid_to_date ,
                        h.date_doc ,
                        a.DATE_DUE ,
                        ( 1 + SIGN(SIGN(a.REF_ID) - 1) ) * a.DATE_AGING
                        + ABS(SIGN(SIGN(a.REF_ID) - 1)) * a.DATE_DOC ,
                        h.date_applied ,
                        h.trx_type ,
                        h.nat_cur_code ,
                        a.APPLY_TO_NUM ,
                        a.SUB_APPLY_NUM ,
                        h.trx_ctrl_num ,
                        h.cust_po_num ,
                        0 ,
                        h.order_ctrl_num ,
                        a.DOC_CTRL_NUM ,
                        a.ORG_ID ,
                        a.parent
                FROM    #ARTRXAGE_TMP a ,
                        #open o ,
                        dbo.artrx h ( NOLOCK ) ,
                        #cust c -- v1.4       
                WHERE   h.paid_flag = 0
                        AND h.trx_type IN ( 2021, 2031 )
                        AND a.DOC_CTRL_NUM = o.doc_ctrl_num
                        AND a.CUSTOMER_CODE = c.child -- v1.4   
                        AND a.TRX_CTRL_NUM = h.trx_ctrl_num      
    
 -- update invoice hold status using cte instead of in document loop      
 ;
        WITH    cte
                  AS ( SELECT   MAX(sequence_num) seq ,
                                doc_ctrl_num ,
                                customer_code ,
                                status_code ,
                                date
                       FROM     dbo.cc_inv_status_hist (NOLOCK) -- v1.0      
                       WHERE    clear_date IS NULL
                       GROUP BY doc_ctrl_num ,
                                customer_code ,
                                status_code ,
                                date
                     )
            UPDATE  i
            SET     i.status_code = cte.status_code ,
                    i.status_date = cte.date
            FROM    #invoices i ,
                    cte
            WHERE   i.doc_ctrl_num = cte.doc_ctrl_num
                    AND i.customer_code = cte.customer_code;      
    
 -- update amount paid to date      
        UPDATE  #invoices
        SET     amt_paid_to_date = ( amt_net - balance ) * -1
        WHERE   trx_type IN ( 2021, 2031 );      
              
        SELECT  CUSTOMER_CODE ,
                DOC_CTRL_NUM ,
                'true_amount' = SUM(AMOUNT)
        INTO    #cm
        FROM    #ARTRXAGE_TMP
        WHERE   PAID_FLAG = 0
                AND TRX_TYPE IN ( 2111, 2161 )
                AND REF_ID < 1
        GROUP BY CUSTOMER_CODE ,
                DOC_CTRL_NUM
        HAVING  ABS(SUM(AMOUNT)) > 0.0001;     
  
        INSERT  #invoices
                ( customer_code ,
                  doc_ctrl_num ,
                  date_doc ,
                  trx_type ,
                  amt_net ,
                  amt_paid_to_date ,
                  on_acct_flag ,
                  nat_cur_code ,
                  apply_to_num ,
                  sub_apply_num ,
                  trx_ctrl_num ,
                  date_due ,
                  date_aging ,
                  date_applied ,
                  order_ctrl_num ,
                  artrx_doc_ctrl_num ,
                  org_id ,
                  parent
                )
                SELECT  a.CUSTOMER_CODE ,
                        a.DOC_CTRL_NUM ,
                        a.DATE_DOC ,
                        a.TRX_TYPE ,
                        a.AMOUNT ,
                        a.amt_paid ,
                        1 ,
                        a.NAT_CUR_CODE ,
                        a.APPLY_TO_NUM ,
                        a.SUB_APPLY_NUM ,
                        a.TRX_CTRL_NUM ,
                        a.DATE_DUE ,
                        date_aging = ( 1 + SIGN(SIGN(a.REF_ID) - 1) )
                        * a.DATE_AGING + ABS(SIGN(SIGN(a.REF_ID) - 1))
                        * a.DATE_DOC ,
                        a.DATE_APPLIED ,
                        a.order_ctrl_num ,
                        a.DOC_CTRL_NUM ,
                        a.ORG_ID ,
                        a.parent
                FROM    #ARTRXAGE_TMP a ,
                        #cm c
                WHERE   a.CUSTOMER_CODE = c.CUSTOMER_CODE
                        AND a.TRX_TYPE IN ( 2111, 2161 )
                        AND ( a.AMOUNT > 0.000001
                              OR a.AMOUNT < -0.000001
                            )
                        AND a.APPLY_TO_NUM = a.DOC_CTRL_NUM
                        AND a.PAID_FLAG = 0
                        AND a.REF_ID = 0
                        AND a.DOC_CTRL_NUM = c.DOC_CTRL_NUM
                        AND ISNULL(DATALENGTH(RTRIM(LTRIM(c.DOC_CTRL_NUM))), 0) > 0;      
  
        DROP TABLE #cm;      
  
        DELETE  #invoices
        WHERE   trx_type IS NULL;  
  
        UPDATE  #invoices
        SET     cust_po_num = h.cust_po_num
        FROM    #invoices i ,
                dbo.artrx h ( NOLOCK )
        WHERE   i.doc_ctrl_num = h.doc_ctrl_num
                AND i.customer_code = h.customer_code;      

	-- v3.3 Start
    
        DELETE  a
        FROM    #invoices a
                JOIN #ARTRXAGE_TMP b ON a.doc_ctrl_num = b.DOC_CTRL_NUM
                                        AND a.customer_code = b.CUSTOMER_CODE
        WHERE   b.APPLY_TRX_TYPE = 2031
                AND b.TRX_TYPE = 2112
                AND a.on_acct_flag = 1
                AND a.trx_type NOT IN ( 2161, 2111 );
	
        DELETE  a
        FROM    #invoices a
                JOIN dbo.artrx b ( NOLOCK ) ON a.doc_ctrl_num = b.doc_ctrl_num
                                           AND a.customer_code = b.customer_code
        WHERE   b.void_flag = 1
                AND a.trx_type IN ( 2111, 2161 );              


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
        SET     trx_type_code = artrxtyp.trx_type_code
        FROM    #invoices ,
                dbo.artrxtyp (NOLOCK)
        WHERE   artrxtyp.trx_type = #invoices.trx_type      
           
   -- Update on account balances      
       
   ;
        WITH    cte
                  AS ( SELECT   SUM(a.AMOUNT) bal ,
                                a.DOC_CTRL_NUM ,
                                a.CUSTOMER_CODE
                       FROM     #ARTRXAGE_TMP a ,
                                #invoices i
                       WHERE    a.DOC_CTRL_NUM = i.artrx_doc_ctrl_num
                                AND a.CUSTOMER_CODE = i.customer_code
                                AND a.REF_ID < 1
                       GROUP BY a.DOC_CTRL_NUM ,
                                a.CUSTOMER_CODE
                     )
            UPDATE  i
            SET     i.balance = cte.bal
            FROM    #invoices i ,
                    cte
            WHERE   i.doc_ctrl_num = cte.DOC_CTRL_NUM
                    AND i.customer_code = cte.CUSTOMER_CODE
                    AND i.on_acct_flag = 1;      
   
      
 --PJC 20120405      
 --DECLARE @date int      
      
        SELECT  @last_cust = MIN(customer_code)
        FROM    #invoices;      
        WHILE ( @last_cust IS NOT NULL )
            BEGIN      
                SELECT  @last_doc = MIN(doc_ctrl_num)
                FROM    #invoices
                WHERE   trx_type IN ( 2112, 2113, 2121 )
                        AND customer_code = @last_cust;      
      
                WHILE ( @last_doc IS NOT NULL )
                    BEGIN      
                        SELECT  @date = date_doc
                        FROM    #invoices
                        WHERE   doc_ctrl_num = @last_doc
                                AND trx_type = 2111
                                AND customer_code = @last_cust;      
          
                        UPDATE  #invoices
                        SET     date_doc = @date
                        WHERE   doc_ctrl_num = @last_doc
                                AND customer_code = @last_cust;      
      
                        SELECT  @last_doc = MIN(doc_ctrl_num)
                        FROM    #invoices
                        WHERE   doc_ctrl_num = @last_doc
                                AND trx_type IN ( 2112, 2113, 2121 )
                                AND customer_code = @last_cust;      
                    END;      
                SELECT  @last_cust = MIN(customer_code)
                FROM    #invoices
                WHERE   customer_code > @last_cust;      
            END;      
       
      
        SELECT  @last_cust = MIN(customer_code)
        FROM    #invoices;      
        WHILE ( @last_cust IS NOT NULL )
            BEGIN      
                SELECT  @last_doc = MIN(doc_ctrl_num)
                FROM    #invoices
                WHERE   on_acct_flag = 1 -- v2.1 AND date_due = 0 
                        AND customer_code = @last_cust;      
                WHILE ( @last_doc IS NOT NULL )
                    BEGIN      
                        SELECT  @date_doc = MIN(date_doc)
                        FROM    #invoices
                        WHERE   doc_ctrl_num = @last_doc
                                AND customer_code = @last_cust;      
       
                        SELECT  @terms_code = terms_code,
								@date_due = date_due -- tag
                        FROM    dbo.artrx (NOLOCK)
                        WHERE   doc_ctrl_num = @last_doc
                                AND customer_code = @last_cust;      
   /* PJC 042413 - get terms code from customer when terms code is blank */      
                        IF ( @terms_code = ''
                             OR @terms_code IS NULL
                           )
						begin
								SELECT  @terms_code = terms_code
								FROM    dbo.arcust (NOLOCK)
								WHERE   customer_code = @last_cust;      
            
							IF ( SELECT ISNULL(DATALENGTH(LTRIM(RTRIM(@terms_code))),
											   0)
							   ) = 0
								SELECT  @terms_code = terms_code
								FROM    dbo.arcust (NOLOCK)
								WHERE   customer_code = @last_cust;      
      
							EXEC dbo.CVO_CalcDueDate_sp @last_cust, @date_doc,
								@date_due OUTPUT, @terms_code;  
						end    
  
   /* PJC 042413 - use doc date if due date is blank */      
                        IF ( @date_due = 0
                             OR @date_due IS NULL
                           )
                            SELECT  @date_due = @date_doc;      
          
                        UPDATE  #invoices
                        SET     date_due = @date_due ,
                                date_aging = @date_due
                        WHERE   doc_ctrl_num = @last_doc
                                AND trx_type <> 2031
                                AND customer_code = @last_cust;      
      
                        SELECT  @last_doc = MIN(doc_ctrl_num)
                        FROM    #invoices       
-- v2.1   WHERE doc_ctrl_num = 'ON ACCT'      
                        WHERE   doc_ctrl_num > @last_doc -- v2.1     
-- v2.1   AND date_due = 0      
                                AND customer_code = @last_cust
                                AND on_acct_flag = 1;      
                    END;      
                SELECT  @last_cust = MIN(customer_code)
                FROM    #invoices
                WHERE   customer_code > @last_cust;      
            END;      
   

   
        -- EXEC cvo_set_bucket_sp;    
		
        EXEC dbo.cvo_set_bucket_future_sp;  
  

 --PJC 042513 - the stored procedure is messing up the dates      
        UPDATE  #invoices
        SET     date_due = date_doc
        WHERE   date_due < 639906
                AND date_doc > 639906;      
  
         
    
        UPDATE  #invoices
        SET     amt_age_bracket0 = CASE WHEN ( CASE WHEN @DATE_TYPE_PARM = 4
                                                    THEN date_due -- most common
                                                    WHEN @DATE_TYPE_PARM = 1
                                                    THEN date_doc
                                                    WHEN @DATE_TYPE_PARM = 2
                                                    THEN date_applied
                                                    WHEN @DATE_TYPE_PARM = 3
                                                    THEN date_aging
                                                    ELSE 0
                                               END ) >= ( SELECT
                                                              date_end
                                                          FROM
                                                              #dates
                                                          WHERE
                                                              bucket = 'future'
                                                        ) THEN balance
                                        ELSE 0
                                   END ,
                AMT_AGE_BRACKET1 = CASE WHEN ( CASE WHEN @DATE_TYPE_PARM = 4
                                                    THEN date_due
                                                    WHEN @DATE_TYPE_PARM = 2
                                                    THEN date_applied
                                                    WHEN @DATE_TYPE_PARM = 3
                                                    THEN date_aging
                                                    WHEN @DATE_TYPE_PARM = 1
                                                    THEN date_doc
                                                    ELSE 0
                                               END ) BETWEEN ( SELECT
                                                              date_start
                                                              FROM
                                                              #dates
                                                              WHERE
                                                              bucket = '1-30'
                                                             )
                                                     AND     ( SELECT
                                                              date_end
                                                              FROM
                                                              #dates
                                                              WHERE
                                                              bucket = '1-30'
                                                             ) THEN balance
                                        ELSE 0
                                   END ,
                AMT_AGE_BRACKET2 = CASE WHEN ( CASE WHEN @DATE_TYPE_PARM = 4
                                                    THEN date_due
                                                    WHEN @DATE_TYPE_PARM = 2
                                                    THEN date_applied
                                                    WHEN @DATE_TYPE_PARM = 3
                                                    THEN date_aging
                                                    WHEN @DATE_TYPE_PARM = 1
                                                    THEN date_doc
                                                    ELSE 0
                                               END ) BETWEEN ( SELECT
                                                              date_start
                                                              FROM
                                                              #dates
                                                              WHERE
                                                              bucket = '31-60'
                                                             )
                                                     AND     ( SELECT
                                                              date_end
                                                              FROM
                                                              #dates
                                                              WHERE
                                                              bucket = '31-60'
                                                             ) THEN balance
                                        ELSE 0
                                   END ,
                AMT_AGE_BRACKET3 = CASE WHEN ( CASE WHEN @DATE_TYPE_PARM = 4
                                                    THEN date_due
                                                    WHEN @DATE_TYPE_PARM = 2
                                                    THEN date_applied
                                                    WHEN @DATE_TYPE_PARM = 3
                                                    THEN date_aging
                                                    WHEN @DATE_TYPE_PARM = 1
                                                    THEN date_doc
                                                    ELSE 0
                                               END ) BETWEEN ( SELECT
                                                              date_start
                                                              FROM
                                                              #dates
                                                              WHERE
                                                              bucket = '61-90'
                                                             )
                                                     AND     ( SELECT
                                                              date_end
                                                              FROM
                                                              #dates
                                                              WHERE
                                                              bucket = '61-90'
                                                             ) THEN balance
                                        ELSE 0
                                   END ,
                AMT_AGE_BRACKET4 = CASE WHEN ( CASE WHEN @DATE_TYPE_PARM = 4
                                                    THEN date_due
                                                    WHEN @DATE_TYPE_PARM = 2
                                                    THEN date_applied
                                                    WHEN @DATE_TYPE_PARM = 3
                                                    THEN date_aging
                                                    WHEN @DATE_TYPE_PARM = 1
                                                    THEN date_doc
                                                    ELSE 0
                                               END ) BETWEEN ( SELECT
                                                              date_start
                                                              FROM
                                                              #dates
                                                              WHERE
                                                              bucket = '91-120'
                                                             )
                                                     AND     ( SELECT
                                                              date_end
                                                              FROM
                                                              #dates
                                                              WHERE
                                                              bucket = '91-120'
                                                             ) THEN balance
                                        ELSE 0
                                   END ,
                AMT_AGE_BRACKET5 = CASE WHEN ( CASE WHEN @DATE_TYPE_PARM = 4
                                                    THEN date_due
                                                    WHEN @DATE_TYPE_PARM = 2
                                                    THEN date_applied
                                                    WHEN @DATE_TYPE_PARM = 3
                                                    THEN date_aging
                                                    WHEN @DATE_TYPE_PARM = 1
                                                    THEN date_doc
                                                    ELSE 0
                                               END ) >= ( SELECT
                                                              date_start
                                                          FROM
                                                              #dates
                                                          WHERE
                                                              bucket = '121-150'
                                                        ) THEN balance
                                        ELSE 0
                                   END ,
                AMT_AGE_BRACKET6 = balance
        FROM    #invoices;   
 
  
 -- v3.2 Start
        SELECT DISTINCT
                *
        INTO    #invoices2
        FROM    #invoices;

        TRUNCATE TABLE #invoices;

        INSERT  #invoices
                SELECT  *
                FROM    #invoices2;

        DROP TABLE #invoices2;
    
 -- v3.2 End

        INSERT  #AGE_SUMMARY
                SELECT  parent ,
                        SUM(balance) ,
                        SUM(amt_age_bracket0) ,
                        SUM(AMT_AGE_BRACKET1) ,
                        SUM(AMT_AGE_BRACKET2) ,
                        SUM(AMT_AGE_BRACKET3) ,
                        SUM(AMT_AGE_BRACKET4) ,
                        SUM(AMT_AGE_BRACKET5) ,
                        SUM(AMT_AGE_BRACKET6)
                FROM    #invoices
                GROUP BY parent;    
 -- v1.1 End      
    
    
--select * from #age_summary        
--select * from #artrxage_tmp where AMT_AGE_BRACKET1 <> 0  
  
--select * from #invoices  
      
        INSERT  INTO #FINAL
                ( CUSTOMER_CODE ,
                  ADDR_SORT1 ,
                  attn_email ,     --v1.1      
                  SALESPERSON_CODE ,
                  TERRITORY_CODE ,
                  ADDRESS_NAME ,
                  BG_Code ,
                  BG_Name ,
                  PRICE_CODE ,
                  BAL ,
                  FUT ,
                  CUR ,
                  AR30 ,
                  AR60 ,
                  AR90 ,
                  AR120 ,
                  AR150 ,
                  CREDIT_LIMIT ,
                  ONORDER ,
                  YTDCREDS ,
                  YTDSALES ,
                  LYRSALES ,
                  r12sales      
                )
                SELECT  A.CUSTOMER_CODE ,
                        M.addr_sort1 ,
                        ISNULL(M.attention_email, '') attention_email ,   --v1.1      
                        M.salesperson_code ,
                        M.territory_code ,
                        M.address_name ,
                        ISNULL(na.parent, '') AS BG_Code ,
                        ISNULL(c.customer_name, '') AS BG_Name ,
                        M.price_code ,
                        A.AMOUNT , -- bal      
                        A.amt_age_bracket0 , -- fut  
                        0 ,
                        A.AMT_AGE_BRACKET1 , -- 1-30       
                        A.AMT_AGE_BRACKET2 ,  -- 31-60    
                        A.AMT_AGE_BRACKET3 ,   -- 61-90   
                        A.AMT_AGE_BRACKET4 ,     -- 91-120 
                        A.AMT_AGE_BRACKET5 ,     -- over 120   
                        -- A.AMT_AGE_BRACKET6 ,  -- balance    
                        M.credit_limit ,
                        0 ,
                        0 ,
                        0 ,
                        0 ,
                        0
                FROM    #AGE_SUMMARY A
                        LEFT OUTER JOIN dbo.armaster_all M ( NOLOCK ) ON A.CUSTOMER_CODE = M.customer_code
                        LEFT OUTER JOIN dbo.arnarel na ( NOLOCK ) ON A.CUSTOMER_CODE = na.child
                        LEFT OUTER JOIN dbo.arcust c ( NOLOCK ) ON na.parent = c.customer_code
                WHERE   M.address_type = 0;      
       
        UPDATE  #FINAL
        SET     YTDCREDS = ISNULL(( SELECT  SUM(areturns)
                                    -- FROM    dbo.cvo_csbm_shipto
									FROM	dbo.cvo_sbm_details
                                    WHERE   customer = f.customer_code
                                            AND yyyymmdd >= @CURRYRSTART
                                  ), 0) ,
                YTDSALES = ISNULL(( SELECT  SUM(anet)
                                    -- FROM    dbo.cvo_csbm_shipto
									FROM	dbo.cvo_sbm_details
                                    WHERE   customer = f.customer_code
                                            AND yyyymmdd >= @CURRYRSTART
                                  ), 0) ,
                LYRSALES = ISNULL(( SELECT  SUM(anet)
                                    -- FROM    dbo.cvo_csbm_shipto
									FROM	dbo.cvo_sbm_details 
                                    WHERE   customer = f.customer_code
                                            AND yyyymmdd BETWEEN @LASTYRSTART AND @LASTYREND
                                  ), 0) ,
                r12sales = ISNULL(( SELECT  SUM(anet)
                                    FROM    dbo.cvo_sbm_details
                                    WHERE   customer = f.customer_code
                                            AND yyyymmdd >= @R12START
                                  ), 0)
        FROM    #FINAL F;     
      
      
 --ON ORDER      
        IF ( OBJECT_ID('tempdb.dbo.#onord') IS NOT NULL )
            DROP TABLE #onord;      
        SELECT  cust_code ,
                ISNULL(SUM(CASE WHEN type = 'I'
                                THEN ( total_amt_order + tot_ord_tax
                                       - tot_ord_disc + tot_ord_freight )
                                ELSE ( ( total_amt_order * -1 )
                                       + ( tot_ord_tax * -1 ) - ( tot_ord_disc
                                                              * -1 )
                                       + ( tot_ord_freight * -1 ) )
                           END), 0) AS onord
        INTO    #ONORD
        FROM    dbo.orders_all (NOLOCK)
        WHERE   status NOT IN ( 'R', 'S', 'T' )
                AND UPPER(status) IN ( SELECT   UPPER(status_code)
                                       FROM     dbo.cc_ord_status
                                       WHERE    use_flag = 1 )
                AND void = 'N'
        GROUP BY cust_code;     
       
        UPDATE  #FINAL
        SET     ONORDER = ONORD
        FROM    #FINAL F ,
                #ONORD D
        WHERE   F.CUSTOMER_CODE = D.cust_code;      
       
 --HOLD      
        UPDATE  #FINAL
        SET     HOLD = C.status_code
        FROM    #FINAL F ,
                dbo.cc_cust_status_hist C
        WHERE   F.CUSTOMER_CODE = C.customer_code
                AND C.clear_date IS NULL;      
      
      
 --AVGDAYSLATE      
       
        IF ( OBJECT_ID('tempdb.dbo.#avg') IS NOT NULL )
            DROP TABLE #avg;      
        SELECT  A.customer_code ,
                SUM(@DATE_ASOF - A.date_due) / COUNT(*) AS AVGDAYSLATE
        INTO    #AVG
        FROM    dbo.artrx A ,
                #FINAL F
        WHERE   A.trx_type = '2031'
                AND @DATE_ASOF > A.date_due
                AND A.customer_code = F.CUSTOMER_CODE      
 -- and a.customer_code = @last_customer      
        GROUP BY A.customer_code;      
       
        UPDATE  F
        SET     F.AVGDAYSLATE = A.AVGDAYSLATE
        FROM    #AVG A ,
                #FINAL F
        WHERE   A.customer_code = F.CUSTOMER_CODE;      
      
--      
        DECLARE @date_entered INT ,
            @last_customer VARCHAR(10) , 
--@last_check varchar(16), 
            @last_amt FLOAT;    
    
        SELECT  @last_customer = MIN(CUSTOMER_CODE)
        FROM    #FINAL;      
        WHILE ( @last_customer IS NOT NULL )
            BEGIN      
-- tag - last payment and date - simple version      
--          
                SELECT  @date_entered = MAX(date_entered)
                FROM    dbo.artrx
                WHERE   customer_code = @last_customer
                        AND trx_type = 2111
                        AND void_flag = 0
                        AND payment_type <> 3;     
    
                SELECT  @last_check = doc_ctrl_num ,
                        @last_amt = amt_net
                FROM    dbo.artrx
                WHERE   customer_code = @last_customer
                        AND trx_type = 2111
                        AND void_flag = 0
                        AND payment_type <> 3
                        AND date_entered = @date_entered
                ORDER BY trx_ctrl_num DESC;    
    
                UPDATE  F
                SET     F.LPMTDT = @date_entered ,
                        F.AMOUNT = @last_amt
                FROM    #FINAL F
                WHERE   F.CUSTOMER_CODE = @last_customer;    
      
                SELECT  @last_customer = MIN(CUSTOMER_CODE)
                FROM    #FINAL
                WHERE   CUSTOMER_CODE > @last_customer;      
        
            END;      
      
 
      
        SELECT  CUST_CODE = CUSTOMER_CODE ,
                [KEY] = ADDR_SORT1 ,
                attn_email ,
                SLS = SALESPERSON_CODE ,
                TERR = tr.TERRITORY_CODE ,    
                tr.region AS REGION ,
                NAME = ADDRESS_NAME ,
                BG_Code ,
                BG_Name ,
                TMS = PRICE_CODE ,
                r12sales , -- 101613    
                AVGDAYSLATE ,
                BAL ,
                FUT ,
                CUR ,
                AR30 ,
                AR60 ,
                AR90 ,
                AR120 ,
                AR150 ,
                CREDIT_LIMIT ,
                ONORDER ,    
   --LPMTDT,    
                CONVERT(DATETIME, DATEADD(d, LPMTDT - 711858, '1/1/1950'), 101) lpmtdt ,
                AMOUNT ,
                YTDCREDS ,
                YTDSALES ,
                LYRSALES ,
                HOLD ,
                CONVERT(VARCHAR, DATEADD(d, @DATE_ASOF - 711858, '1/1/1950'), 101) AS date_asof ,    
--   @date_asof as date_asof,    
                @DATE_TYPE_STRING AS date_type_string ,
                @DATE_TYPE_PARM AS date_type
        FROM    #FINAL
		JOIN 
		(SELECT DISTINCT TERRITORY_CODE, dbo.calculate_region_fn(TERRITORY_CODE) region 
		FROM #final
		) tr ON tr.TERRITORY_CODE = #final.TERRITORY_CODE;       
      
-- DROP TABLE #ARTRXAGE_TMP       
-- DROP TABLE #AGE_SUMMARY      
-- DROP TABLE #NON_ZERO_RECORDS       
        DROP TABLE #FINAL;      
        DROP TABLE #ONORD;      
-- DROP TABLE #CRED      
-- DROP TABLE #SALES      
-- DROP TABLE #LSALES      
-- DROP TABLE #CHECK_DATA      
-- DROP TABLE #TEMP2      
-- DROP TABLE #TEMP3      
-- DROP TABLE #LPMTDT      
        DROP TABLE #AVG;      
      
 -- v1.1 Start    
        DROP TABLE #cust;    
        DROP TABLE #bg_data;    
 -- v1.1 End    
    
        SET NOCOUNT OFF;       
    END; -- CVO_ARAGING_SP DATA       



GO
