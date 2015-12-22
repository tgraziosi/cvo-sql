SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 12/03/2012 - Issue #1177 - aging incorrect  
  
CREATE PROCEDURE [dbo].[cc_print_statement_range_sp] @all_cust_flag    varchar(3) = '1',  
                       @from_cust     varchar(8) = '',  
                       @to_cust      varchar(8) = '',  
                       @print_company_info varchar(3) = '0',  
                       @print_terms    varchar(3) = '0',  
                       @co_tel_no     varchar(40) = '',  
                       @co_fax_no     varchar(40) = '',  
  
                       @date_type_conv   varchar(3) = '4',  
                       @all_org_flag   varchar(3) = '1',    
                       @from_org varchar(30) = '',  
                       @to_org varchar(30) = '',  
                       @display_org varchar(3) = '0',  
                    @user_name varchar(30) = '',  
                    @company_db varchar(30) = ''  
    
  
AS  
 SET NOCOUNT ON  
 IF EXISTS (SELECT name FROM sysobjects WHERE name = 'sm_login_sp' ) EXEC sm_login_sp @user_name, @company_db  
   
  
  
 DECLARE   @date_asof      int,  
       @e_age_bracket_1   smallint,  
       @e_age_bracket_2   smallint,  
       @e_age_bracket_3   smallint,  
       @e_age_bracket_4   smallint,  
       @e_age_bracket_5   smallint,  
  
       @b_age_bracket_1 smallint,  
       @b_age_bracket_2   smallint,  
       @b_age_bracket_3   smallint,  
       @b_age_bracket_4   smallint,  
       @b_age_bracket_5   smallint,  
       @b_age_bracket_6   smallint,  
       @precision_home    smallint,  
       @symbol        varchar(8),  
       @home_currency    varchar(8),  
       @multi_currency_flag smallint,  
       @last_cust      varchar(8),  
       @balance        float,  
       @on_acct        float,  
       @bucket1        float,  
       @bucket2        float,  
       @bucket3        float,  
       @bucket4        float,  
       @bucket5        float,  
       @bucket6        float,  
  
       @bucket0       float  
  
  
  SELECT @date_type_conv = 4  
  
  
 SELECT  @date_asof   = DATEDIFF(dd, '1/1/1753', CONVERT(datetime, getdate())) + 639906  
  
    
 SELECT @precision_home  = curr_precision,  
     @multi_currency_flag  = multi_currency_flag,  
     @home_currency   = home_currency,  
     @symbol   = symbol  
 FROM glcurr_vw, glco  
 WHERE glco.home_currency  = glcurr_vw.currency_code  
   
  
  
 SELECT  @e_age_bracket_1  = age_bracket1,  
     @e_age_bracket_2  = age_bracket2,  
     @e_age_bracket_3  = age_bracket3,  
     @e_age_bracket_4  = age_bracket4,  
     @e_age_bracket_5  = age_bracket5   
 FROM arco  
  
  
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
 ( customer_code   varchar(8),  
  doc_ctrl_num    varchar(16)  NULL,  
  
  date_doc      int      NULL,  
  date_due   int,   
  date_aging   int,   
  date_applied   int,   
  trx_type      int      NULL,  
  amt_net      float     NULL,  
  amt_paid_to_date float     NULL,  
  balance      float     NULL,  
  on_acct_flag    smallint    NULL,  
  price_code     varchar(8)   NULL,  
  territory_code   varchar(8)   NULL,  
  nat_cur_code   varchar(8)   NULL,  
  trx_type_code   varchar(8)   NULL,  
  trx_ctrl_num   varchar(16)  NULL,  
  cust_po_num    varchar(20)  NULL,  
  symbol      varchar(8)  NULL,  
  curr_precision  smallint   NULL,  
  amt_on_acct    float     NULL,  
  currency_mask   varchar(100) NULL,  
  total_balance   float     NULL,  
  on_acct      float     NULL,  
  bucket1      float     NULL,  
  bucket2      float     NULL,  
  bucket3      float     NULL,  
  bucket4      float     NULL,  
  bucket5      float     NULL,  
  bucket6      float     NULL,  
  attention_phone  varchar(40)  NULL,  
  attention_name  varchar(40)  NULL,  
  db_num      varchar(20)   NULL,  
  customer_name   varchar(40)  NULL,  
  addr1       varchar(40)  NULL,  
  addr2       varchar(40)  NULL,  
  addr3       varchar(40)  NULL,  
  addr4       varchar(40)  NULL,  
  addr5       varchar(40)  NULL,  
  addr6       varchar(40)  NULL,  
  terms       varchar(40)  NULL,  
  credit_limit   float     NULL,  
  company_name   varchar(40)  NULL,  
  co_addr1     varchar(40)  NULL,  
  co_addr2     varchar(40)  NULL,  
  co_addr3     varchar(40)  NULL,  
  co_addr4     varchar(40)  NULL,  
  co_addr5     varchar(40)  NULL,  
  co_addr6     varchar(40)  NULL,  
  co_tel_no     varchar(40)  NULL,  
  co_fax_no     varchar(40)  NULL,  
  bucket1_str    varchar(40)  NULL,  
  bucket2_str    varchar(40)  NULL,  
  bucket3_str    varchar(40)  NULL,  
  bucket4_str    varchar(40)  NULL,  
  bucket5_str    varchar(40)  NULL,  
  bucket6_str    varchar(40)  NULL,  
  org_id varchar(30) NULL,  
  
  date_required int NULL,  
  bucket0 float NULL,  
  bucket0_str varchar(40) NULL )  
    
  CREATE TABLE #artrxage_tmp  
  (  
   trx_type   smallint,   
   trx_ctrl_num   varchar(16),   
   doc_ctrl_num   varchar(16),   
   apply_to_num   varchar(16),   
   apply_trx_type   smallint,   
   sub_apply_num   varchar(16),   
   sub_apply_type   smallint,   
   territory_code   varchar(8),   
  
   date_doc   int,   
   date_due   int,   
   date_aging   int,   
   date_applied   int,   
   amount    float,   
   on_acct   float,  
   amt_age_bracket1 float,   
   amt_age_bracket2  float,  
   amt_age_bracket3 float,  
   amt_age_bracket4 float,  
   amt_age_bracket5 float,  
   amt_age_bracket6 float,     
   nat_cur_code   varchar(8),   
   rate_home   float,   
   rate_type   varchar(8),   
   customer_code   varchar(8),   
   payer_cust_code  varchar(8),   
   trx_type_code   varchar(8),   
   ref_id    int ,  
   org_id varchar(30) NULL,  
  
   date_required int,  
   amt_age_bracket0 float )  
  
  
  
  
 CREATE TABLE #invoices_details  
 ( customer_code   varchar(8),  
  doc_ctrl_num    varchar(16)  NULL,  
  
  date_doc   int,   
  date_due   int,   
  date_aging   int,   
  date_applied   int,   
  trx_type      int      NULL,  
  amt_net      float     NULL,  
  amt_paid_to_date float     NULL,  
  balance      float     NULL,  
  on_acct_flag    smallint    NULL,  
  price_code     varchar(8)   NULL,  
  territory_code   varchar(8)   NULL,  
  nat_cur_code   varchar(8)   NULL,  
  trx_type_code   varchar(8)   NULL,  
  trx_ctrl_num   varchar(16)  NULL,  
  cust_po_num    varchar(20)  NULL,  
  symbol      varchar(8)  NULL,  
  curr_precision  smallint   NULL,  
  amt_on_acct    float     NULL,  
  currency_mask   varchar(100) NULL,  
  org_id varchar(30) NULL  
  )  
  
  
 CREATE TABLE #final  
 ( customer_code   varchar(8),  
  doc_ctrl_num    varchar(16)  NULL,  
  
  date_doc   int,   
  date_due   int,   
  date_aging   int,   
  date_applied   int,   
  trx_type      int      NULL,  
  amt_net      float     NULL,  
  amt_paid_to_date float     NULL,  
  balance      float     NULL,  
  on_acct_flag    smallint    NULL,  
  price_code     varchar(8)   NULL,  
  territory_code   varchar(8)   NULL,  
  nat_cur_code   varchar(8)   NULL,  
  trx_type_code   varchar(8)   NULL,  
  trx_ctrl_num   varchar(16)  NULL,  
  cust_po_num    varchar(20)  NULL,  
  symbol      varchar(8)  NULL,  
  curr_precision  smallint   NULL,  
  amt_on_acct    float     NULL,  
  currency_mask   varchar(100) NULL,  
  total_balance   float     NULL,  
  on_acct      float     NULL,  
  bucket1      float     NULL,  
  bucket2      float     NULL,  
  bucket3      float     NULL,  
  bucket4      float     NULL,  
  bucket5      float     NULL,  
  bucket6      float     NULL,  
  attention_phone  varchar(40)  NULL,  
  attention_name  varchar(40)  NULL,  
  db_num      varchar(20)   NULL,  
  customer_name   varchar(40)  NULL,  
  addr1       varchar(40)  NULL,  
  addr2       varchar(40)  NULL,  
  addr3       varchar(40)  NULL,  
  addr4       varchar(40)  NULL,  
  addr5       varchar(40)  NULL,  
  addr6       varchar(40)  NULL,  
  terms       varchar(40)  NULL,  
  credit_limit   float     NULL,  
  company_name   varchar(40)  NULL,  
  co_addr1     varchar(40)  NULL,  
  co_addr2     varchar(40)  NULL,  
  co_addr3     varchar(40)  NULL,  
  co_addr4     varchar(40)  NULL,  
  co_addr5     varchar(40)  NULL,  
  co_addr6     varchar(40)  NULL,  
  co_tel_no     varchar(40)  NULL,  
  co_fax_no     varchar(40)  NULL,  
  bucket1_str    varchar(40)  NULL,  
  bucket2_str    varchar(40)  NULL,  
  bucket3_str    varchar(40)  NULL,  
  bucket4_str    varchar(40)  NULL,  
  bucket5_str    varchar(40)  NULL,  
  bucket6_str    varchar(40)  NULL,  
  org_id varchar(30) NULL,  
  
  date_required int NULL,  
  bucket0 float NULL,  
  bucket0_str    varchar(40) NULL )  
  
-- v1.0 Start
	CREATE TABLE #brackets (
		amount		float,
		on_acct		float,
		b1			float,
		b2			float,
		b3			float,
		b4			float,
		b5			float,
		b6			float,
		home_curr	varchar(8),
		b0			float)
-- v1.0 End

 CREATE TABLE #non_zero_records  
 (  
  doc_ctrl_num   varchar(16) NULL,   
  trx_type   smallint NULL,   
  customer_code   varchar(8) NULL,   
  total    float  NULL  
 )  
  
 INSERT #non_zero_records  
 SELECT  apply_to_num ,   
     apply_trx_type,   
     customer_code,   
     SUM(amount)   
 FROM   artrxage  
 WHERE  customer_code BETWEEN @from_cust AND @to_cust  
 GROUP BY customer_code, apply_to_num, apply_trx_type  
 HAVING ABS(SUM(amount)) > 0.0000001  
  
  
IF @all_org_flag = '1'  
 INSERT #invoices  ( customer_code )  
 SELECT DISTINCT customer_code  
 FROM  artrx   
 WHERE  paid_flag = 0  
 AND trx_type in (2021,2031)  
 AND customer_code BETWEEN @from_cust AND @to_cust  
  
 AND customer_code IN ( SELECT customer_code FROM #non_zero_records )  
ELSE  
 INSERT #invoices   
 ( customer_code  
 )  
 SELECT DISTINCT customer_code  
 FROM  artrx   
 WHERE  paid_flag = 0  
 AND trx_type in (2021,2031)  
 AND customer_code BETWEEN @from_cust AND @to_cust  
 AND org_id BETWEEN @from_org AND @to_org  
  
 AND customer_code IN ( SELECT customer_code FROM #non_zero_records )  
  
  
  
 UPDATE #invoices  
 SET   symbol = g.symbol,  
     curr_precision = g.curr_precision,  
     currency_mask = g.currency_mask  
 FROM  #invoices t, glcurr_vw g  
 WHERE  nat_cur_code = currency_code  
  
  
 UPDATE #invoices  
 SET  company_name =  a.company_name,   
    co_addr1 = a.addr1,  
    co_addr2 = a.addr2,  
    co_addr3 = a.addr3,  
    co_addr4 = a.addr4,  
    co_addr5 = a.addr5,  
    co_addr6 = a.addr6,  
    bucket1_str = CONVERT(varchar(6), age_bracket1),  
    bucket2_str = CONVERT(varchar(6), age_bracket1 + 1) + ' To ' + CONVERT(varchar(6), age_bracket2),  
    bucket3_str = CONVERT(varchar(6), age_bracket2 + 1) + ' To ' + CONVERT(varchar(6), age_bracket3),  
    bucket4_str = CONVERT(varchar(6), age_bracket3 + 1) + ' To ' + CONVERT(varchar(6), age_bracket4),  
    bucket5_str = CONVERT(varchar(6), age_bracket4 + 1) + ' To ' + CONVERT(varchar(6), age_bracket5),  
    bucket6_str = 'Over ' + CONVERT(varchar(6), age_bracket5 )  
   
 FROM arco a  
  
  
 UPDATE #invoices  
 SET  bucket0_str = 'Future',  
    bucket1_str = 'Current',  
    bucket2_str = '1 To 30 Days Over',  
    bucket3_str = '31 To 60 Days Over',  
    bucket4_str = '61 To 90 Days Over',  
    bucket5_str = '91 To 120 Days Over',  
    bucket6_str = '120 + Days Over'   
  
 UPDATE  #invoices   
 SET   customer_name = c.customer_name,  
     attention_name = c.attention_name,  
     attention_phone = c.attention_phone,  
     addr1 = c.addr1,  
     addr2 = c.addr2,  
     addr3 = c.addr3,  
     addr4 = c.addr4,  
     addr5 = c.addr5,  
     addr6 = c.addr6,  
     terms = terms_desc,  
     db_num = c.db_num,  
     credit_limit = c.credit_limit  
 FROM   #invoices i, arcust c, arterms t  
 WHERE  i.customer_code =  c.customer_code  
 AND   c.terms_code = t.terms_code  
  
  
  
 SELECT @last_cust = MIN(customer_code) FROM #invoices  
 WHILE ( @last_cust IS NOT NULL )  
  BEGIN  
  
   TRUNCATE TABLE #artrxage_tmp  
  
     
  INSERT #artrxage_tmp   
   SELECT a.trx_type,   
    a.trx_ctrl_num,   
    a.doc_ctrl_num,   
    a.apply_to_num,   
    a.apply_trx_type,   
    a.sub_apply_num,   
    a.sub_apply_type,   
    a.territory_code,   
    a.date_doc,   
    (1+ sign(sign(a.ref_id) - 1))*a.date_due + abs(sign(sign(a.ref_id)-1))*a.date_doc,   
    (1+ sign(sign(a.ref_id) - 1))*a.date_aging + abs(sign(sign(a.ref_id)-1))*a.date_doc,   
    a.date_applied,   
    a.amount,  
    0,  
    0,  
    0,  
    0,  
    0,  
    0,  
    0,  
    a.nat_cur_code,   
    a.rate_home,   
    ' ',   
    a.customer_code,   
    a.payer_cust_code,   
    ' ',   
    a.ref_id,  
    a.org_id,  
  
    h.date_required,  
    0  
   FROM  artrxage a, artrx_all h  
   WHERE a.customer_code = @last_cust  
  
   AND a.doc_ctrl_num IN ( SELECT doc_ctrl_num FROM #non_zero_records )  
  
   AND  a.trx_ctrl_num = h.trx_ctrl_num  
  
IF @all_org_flag = '0'  
 DELETE #artrxage_tmp  
 WHERE org_id NOT BETWEEN @from_org AND @to_org  
  
  
     
   IF @date_type_conv = '1'  
    UPDATE #artrxage_tmp   
    SET   date_doc = i.date_doc  
    FROM  #artrxage_tmp , #artrxage_tmp i  
    WHERE  #artrxage_tmp.doc_ctrl_num NOT IN ( SELECT b.apply_to_num  
                          FROM #artrxage_tmp b  
                          WHERE b.doc_ctrl_num = b.apply_to_num)  
    AND   #artrxage_tmp.apply_to_num = i.doc_ctrl_num  
    AND   #artrxage_tmp.date_aging = i.date_aging  
    
     
   IF @date_type_conv = '2'  
    UPDATE #artrxage_tmp   
    SET   date_applied = i.date_applied  
    FROM   #artrxage_tmp , #artrxage_tmp i  
    WHERE  #artrxage_tmp.doc_ctrl_num NOT IN ( SELECT b.apply_to_num  
                          FROM #artrxage_tmp b  
                          WHERE b.doc_ctrl_num = b.apply_to_num)  
    AND   #artrxage_tmp.apply_to_num = i.doc_ctrl_num  
    AND   #artrxage_tmp.date_aging = i.date_aging  
    
    
     
   UPDATE #artrxage_tmp   
   SET date_due = b.date_due  
   FROM #artrxage_tmp , #artrxage_tmp b  
   WHERE #artrxage_tmp.trx_ctrl_num = b.trx_ctrl_num  
   AND #artrxage_tmp.ref_id = -1  
   AND b.ref_id = 0  
   AND #artrxage_tmp.date_due = 0  
     
   UPDATE #artrxage_tmp   
   SET date_doc = b.date_doc  
   FROM #artrxage_tmp , #artrxage_tmp b  
   WHERE #artrxage_tmp.trx_ctrl_num = b.trx_ctrl_num  
   AND #artrxage_tmp.ref_id = -1  
   AND b.ref_id = 0  
   AND #artrxage_tmp.date_doc = 0  
     
   UPDATE #artrxage_tmp   
   SET date_aging = b.date_aging  
   FROM #artrxage_tmp , #artrxage_tmp b  
   WHERE #artrxage_tmp.trx_ctrl_num = b.trx_ctrl_num  
   AND #artrxage_tmp.ref_id = -1  
   AND b.ref_id = 0  
   AND #artrxage_tmp.date_aging = 0  
     
   UPDATE #artrxage_tmp   
   SET date_applied = b.date_applied  
   FROM #artrxage_tmp , #artrxage_tmp b  
   WHERE #artrxage_tmp.trx_ctrl_num = b.trx_ctrl_num  
   AND #artrxage_tmp.ref_id = -1  
   AND b.ref_id = 0  
   AND #artrxage_tmp.date_applied = 0  
  
      
   UPDATE #artrxage_tmp  
   SET amount = (SELECT ROUND(amount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home))  
  
       
     
   UPDATE #artrxage_tmp  
   SET  on_acct = amount  
   WHERE  ref_id < 1  
     
   AND  trx_type in (2111,2161, 2112, 2113, 2121)  
  
  
   IF @date_type_conv = '1'  
    BEGIN   
  
     UPDATE #artrxage_tmp  
     SET  amt_age_bracket0 = amount  
     WHERE  (@date_asof - date_doc) < @b_age_bracket_1  
     AND ref_id > 0  
  
     UPDATE #artrxage_tmp  
      SET  amt_age_bracket1 = amount  
  
      WHERE  (@date_asof - date_doc) >= @b_age_bracket_1  
      AND  (@date_asof - date_doc) <= @e_age_bracket_1  
      AND ref_id > 0  
   
     UPDATE  #artrxage_tmp  
      SET  amt_age_bracket2 = amount  
      WHERE  (@date_asof - date_doc) >= @b_age_bracket_2   
      AND  (@date_asof - date_doc) <= @e_age_bracket_2  
      AND ref_id > 0  
   
     UPDATE #artrxage_tmp  
      SET  amt_age_bracket3 = amount  
      WHERE  (@date_asof - date_doc) >= @b_age_bracket_3   
      AND  (@date_asof - date_doc) <= @e_age_bracket_3  
      AND ref_id > 0  
   
     UPDATE #artrxage_tmp  
      SET  amt_age_bracket4 = amount  
      WHERE  (@date_asof - date_doc) >= @b_age_bracket_4   
      AND  (@date_asof - date_doc) <= @e_age_bracket_4  
      AND ref_id > 0  
   
     UPDATE #artrxage_tmp  
      SET  amt_age_bracket5 = amount  
      WHERE  (@date_asof - date_doc) >= @b_age_bracket_5   
      AND  (@date_asof - date_doc) <= @e_age_bracket_5  
      AND ref_id > 0  
     
     UPDATE #artrxage_tmp  
      SET  amt_age_bracket6 = amount  
      WHERE  (@date_asof - date_doc) >= @b_age_bracket_6  
      AND ref_id > 0  
    END  
   
   IF @date_type_conv = '2'  
    BEGIN   
  
     UPDATE #artrxage_tmp  
     SET  amt_age_bracket0 = amount  
     WHERE  (@date_asof - date_applied) < @b_age_bracket_1  
     AND ref_id > 0  
  
     UPDATE #artrxage_tmp  
     SET  amt_age_bracket1 = amount  
  
     WHERE  (@date_asof - date_applied) >= @b_age_bracket_1  
     AND  (@date_asof - date_applied) <= @e_age_bracket_1  
     AND ref_id > 0  
   
     UPDATE  #artrxage_tmp  
      SET  amt_age_bracket2 = amount  
      WHERE  (@date_asof - date_applied) >= @b_age_bracket_2   
      AND  (@date_asof - date_applied) <= @e_age_bracket_2  
      AND ref_id > 0  
   
     UPDATE #artrxage_tmp  
      SET  amt_age_bracket3 = amount  
      WHERE  (@date_asof - date_applied) >= @b_age_bracket_3   
      AND  (@date_asof - date_applied) <= @e_age_bracket_3  
      AND ref_id > 0  
   
     UPDATE #artrxage_tmp  
      SET  amt_age_bracket4 = amount  
      WHERE  (@date_asof - date_applied) >= @b_age_bracket_4   
      AND  (@date_asof - date_applied) <= @e_age_bracket_4  
      AND ref_id > 0  
   
     UPDATE #artrxage_tmp  
      SET  amt_age_bracket5 = amount  
      WHERE  (@date_asof - date_applied) >= @b_age_bracket_5   
      AND  (@date_asof - date_applied) <= @e_age_bracket_5  
      AND ref_id > 0  
     
     UPDATE #artrxage_tmp  
      SET  amt_age_bracket6 = amount  
      WHERE  (@date_asof - date_applied) >= @b_age_bracket_6  
      AND ref_id > 0  
    END  
   
   IF @date_type_conv = '3'  
    BEGIN   
  
     UPDATE #artrxage_tmp  
     SET  amt_age_bracket0 = amount  
     WHERE  (@date_asof - date_aging) < @b_age_bracket_1  
     AND ref_id > 0  
  
     UPDATE #artrxage_tmp  
     SET  amt_age_bracket1 = amount  
  
     WHERE  (@date_asof - date_aging) >= @b_age_bracket_1  
     AND  (@date_asof - date_aging) <= @e_age_bracket_1  
     AND ref_id > 0  
   
     UPDATE  #artrxage_tmp  
      SET  amt_age_bracket2 = amount  
      WHERE  (@date_asof - date_aging) >= @b_age_bracket_2   
      AND  (@date_asof - date_aging) <= @e_age_bracket_2  
      AND ref_id > 0  
   
     UPDATE #artrxage_tmp  
      SET  amt_age_bracket3 = amount  
      WHERE  (@date_asof - date_aging) >= @b_age_bracket_3   
      AND  (@date_asof - date_aging) <= @e_age_bracket_3  
      AND ref_id > 0  
   
     UPDATE #artrxage_tmp  
      SET  amt_age_bracket4 = amount  
      WHERE  (@date_asof - date_aging) >= @b_age_bracket_4   
      AND  (@date_asof - date_aging) <= @e_age_bracket_4  
      AND ref_id > 0  
   
     UPDATE #artrxage_tmp  
      SET  amt_age_bracket5 = amount  
      WHERE  (@date_asof - date_aging) >= @b_age_bracket_5   
      AND  (@date_asof - date_aging) <= @e_age_bracket_5  
      AND ref_id > 0  
     
     UPDATE #artrxage_tmp  
      SET  amt_age_bracket6 = amount  
      WHERE  (@date_asof - date_aging) >= @b_age_bracket_6  
      AND ref_id > 0  
    END  
   
   IF @date_type_conv = '4'  
    BEGIN   
  
     UPDATE #artrxage_tmp  
     SET  amt_age_bracket0 = amount  
     WHERE  (@date_asof - date_due) < @b_age_bracket_1  
     AND ref_id > 0  
  
     UPDATE #artrxage_tmp  
     SET  amt_age_bracket1 = amount  
  
     WHERE  (@date_asof - date_due) >= @b_age_bracket_1  
     AND  (@date_asof - date_due) <= @e_age_bracket_1  
     AND ref_id > 0  
   
     UPDATE  #artrxage_tmp  
      SET  amt_age_bracket2 = amount  
      WHERE  (@date_asof - date_due) >= @b_age_bracket_2   
      AND  (@date_asof - date_due) <= @e_age_bracket_2  
      AND ref_id > 0  
   
     UPDATE #artrxage_tmp  
      SET  amt_age_bracket3 = amount  
      WHERE  (@date_asof - date_due) >= @b_age_bracket_3   
      AND  (@date_asof - date_due) <= @e_age_bracket_3  
      AND ref_id > 0  
   
     UPDATE #artrxage_tmp  
      SET  amt_age_bracket4 = amount  
      WHERE  (@date_asof - date_due) >= @b_age_bracket_4   
      AND  (@date_asof - date_due) <= @e_age_bracket_4  
      AND ref_id > 0  
   
     UPDATE #artrxage_tmp  
      SET  amt_age_bracket5 = amount  
      WHERE  (@date_asof - date_due) >= @b_age_bracket_5   
      AND  (@date_asof - date_due) <= @e_age_bracket_5  
      AND ref_id > 0  
     
     UPDATE #artrxage_tmp  
      SET  amt_age_bracket6 = amount  
      WHERE  (@date_asof - date_due) >= @b_age_bracket_6  
      AND ref_id > 0  
    END  
  
-- v1.0 Start
	DELETE #brackets

	INSERT #brackets
	EXEC cc_summary_aging_sp @last_cust, @date_type_conv, 1, 'CVO', 'CVO'
  
	SELECT	@balance = STR(SUM(amount),30,6),  
			@on_acct = STR(SUM(on_acct),30,6)
	FROM	#artrxage_tmp    

	SELECT	@bucket1 = STR(b1,30,6),  
			@bucket2 = STR(b2,30,6),  
			@bucket3 = STR(b3,30,6),  
			@bucket4 = STR(b4,30,6),  
			@bucket5 = STR(b5,30,6),  
			@bucket6 = STR(b6,30,6),  
			@bucket0 = STR(b0,30,6)
	FROM	#brackets


/*
   SELECT @balance = STR(SUM(amount),30,6),  
       @on_acct = STR(SUM(on_acct),30,6),  
       @bucket1 = STR(SUM(amt_age_bracket1),30,6),  
       @bucket2 = STR(SUM(amt_age_bracket2),30,6),  
       @bucket3 = STR(SUM(amt_age_bracket3),30,6),  
       @bucket4 = STR(SUM(amt_age_bracket4),30,6),  
       @bucket5 = STR(SUM(amt_age_bracket5),30,6),  
       @bucket6 = STR(SUM(amt_age_bracket6),30,6),  
  
       @bucket0 = STR(SUM(amt_age_bracket0),30,6)  
   FROM  #artrxage_tmp    
*/
-- v1.0 End
    
   UPDATE #invoices  
   SET   total_balance = @balance,  
       on_acct = @on_acct,  
       bucket1 = @bucket1,  
       bucket2 = @bucket2,  
       bucket3 = @bucket3,  
       bucket4 = @bucket4,  
       bucket5 = @bucket5,  
       bucket6 = @bucket6,  
  
       bucket0 = @bucket0  
   WHERE  customer_code = @last_cust   
  
   SELECT @last_cust = MIN(customer_code) FROM #invoices WHERE customer_code > @last_cust  
  END  
  
  
 SELECT @last_cust = MIN(customer_code) FROM #invoices  
 WHILE ( @last_cust IS NOT NULL )  
  BEGIN  
     
    
   INSERT #invoices_details   
   ( customer_code,  
    doc_ctrl_num,  
    date_doc,  
    date_due,  
    date_aging,  
    date_applied,  
    trx_type,  
    amt_net,  
    amt_paid_to_date,  
    balance,  
    on_acct_flag,  
    price_code,  
    territory_code,  
    nat_cur_code,  
    trx_ctrl_num,  
    cust_po_num,  
    org_id  
   )  
   SELECT customer_code,  
       doc_ctrl_num,  
       date_doc,  
       date_due,  
       date_aging,  
       date_applied,  
       trx_type,  
       amt_net,  
       amt_paid_to_date * -1,  
       amt_net + ( amt_paid_to_date * - 1 ),  
       0,  
       price_code,  
       territory_code,  
       nat_cur_code,  
       trx_ctrl_num,  
       cust_po_num,  
       org_id  
   FROM  artrx   
   WHERE  paid_flag = 0  
   AND trx_type in (2021,2031)  
   AND  customer_code = @last_cust   
  
   AND void_flag = 0  
  
   AND doc_ctrl_num IN ( SELECT doc_ctrl_num FROM #non_zero_records )  
    
    
    
    
   INSERT #invoices_details  
   ( customer_code,  
    doc_ctrl_num,  
    date_doc,  
    date_due,  
    date_aging,  
    date_applied,  
    trx_type,  
    amt_net,  
    amt_paid_to_date,  
    balance,  
    on_acct_flag,  
    price_code,  
    territory_code,  
    nat_cur_code,  
    trx_ctrl_num,  
    cust_po_num,  
    amt_on_acct,  
    org_id  
   )  
   SELECT  h.customer_code,  
       h.doc_ctrl_num,  
       h.date_doc,  
       h.date_due,  
       h.date_aging,  
       h.date_applied,  
       a.trx_type,  
       amt_net * - 1,  
       amt_paid_to_date ,  
       amt_on_acct * -1,  
       1,  
       h.price_code,  
       h.territory_code,  
       h.nat_cur_code,  
       h.trx_ctrl_num,  
       h.cust_po_num,  
       h.amt_on_acct * -1,  
       h.org_id  
   FROM  artrx h, artrxage a  
   WHERE  h.customer_code = @last_cust   
  
   AND    h.trx_type in (2111,2161)   
    AND  amt_on_acct > 0   
   AND  h.paid_flag = 0  
   AND  ref_id = 0  
   AND h.trx_ctrl_num = a.trx_ctrl_num  
  
   AND h.void_flag = 0  
  
   AND h.customer_code = a.customer_code  
  
   AND h.doc_ctrl_num IN ( SELECT doc_ctrl_num FROM #non_zero_records )  
  
  
IF @all_org_flag = '0'  
 DELETE #invoices_details  
 WHERE org_id NOT BETWEEN @from_org AND @to_org  
    
    
    
    
   UPDATE  #invoices_details  
   SET   #invoices_details.trx_type_code = artrxtyp.trx_type_code  
   FROM   #invoices_details,artrxtyp  
   WHERE  artrxtyp.trx_type = #invoices_details.trx_type  
    
   UPDATE  #invoices_details  
   SET   trx_type_code = 'CRMEMO'  
   WHERE  trx_type = 2161  
    
     
    
   UPDATE #invoices_details  
   SET   symbol = g.symbol,  
       curr_precision = g.curr_precision,  
       currency_mask = g.currency_mask  
   FROM  #invoices_details t, glcurr_vw g  
   WHERE  nat_cur_code = currency_code  
    
    
   UPDATE  #invoices_details  
   SET   amt_net = ROUND(amt_net, curr_precision),  
       amt_paid_to_date = ROUND(amt_paid_to_date, curr_precision),  
       amt_on_acct = ROUND(amt_on_acct, curr_precision),  
       balance = ROUND(balance, curr_precision)  
  
   SELECT @last_cust = MIN(customer_code) FROM #invoices WHERE customer_code > @last_cust  
  END  
  
   INSERT #final  
   ( customer_code,  
    doc_ctrl_num,  
    date_doc,  
    date_due,  
    date_aging,  
    date_applied,  
    trx_type,  
    amt_net,  
    amt_paid_to_date,  
    balance,  
    on_acct_flag,  
    price_code,  
    territory_code,  
    nat_cur_code,  
    trx_type_code,  
    trx_ctrl_num,  
    cust_po_num,  
    symbol,  
    curr_precision,  
    amt_on_acct,  
    currency_mask,  
    org_id  
   )  
   SELECT  customer_code,  
       doc_ctrl_num,  
       date_doc,  
       date_due,  
       date_aging,  
       date_applied,  
       trx_type,  
       amt_net,  
       amt_paid_to_date,  
       balance,  
       on_acct_flag,  
       price_code,  
       territory_code,  
       nat_cur_code,  
       trx_type_code,  
       trx_ctrl_num,  
       cust_po_num,  
       symbol,  
       curr_precision,  
       amt_on_acct,  
       currency_mask,  
       org_id  
   FROM  #invoices_details  
  
UPDATE #final  
SET   total_balance = i.total_balance,  
  on_acct = i.on_acct,  
  bucket1 = i.bucket1,  
  bucket2 = i.bucket2,  
  bucket3 = i.bucket3,  
  bucket4 = i.bucket4,  
  bucket5 = i.bucket5,  
  bucket6 = i.bucket6,  
  attention_phone = i.attention_phone,  
  attention_name = i.attention_name,  
  db_num = i.db_num,  
  customer_name  = i.customer_name,  
  addr1  = i.addr1,  
  addr2  = i.addr2,  
  addr3  = i.addr3,  
  addr4  = i.addr4,  
  addr5  = i.addr5,  
  addr6  = i.addr6,  
  terms  = i.terms,  
  credit_limit = i.credit_limit,  
  company_name = i.company_name,  
  co_addr1 = i.co_addr1,  
  co_addr2 = i.co_addr2,  
  co_addr3 = i.co_addr3,  
  co_addr4 = i.co_addr4,  
  co_addr5 = i.co_addr5,  
  co_addr6 = i.co_addr6,  
  co_tel_no = i.co_tel_no,  
  co_fax_no = i.co_fax_no,  
  bucket1_str = i.bucket1_str,  
  bucket2_str = i.bucket2_str,  
  bucket3_str = i.bucket3_str,  
  bucket4_str = i.bucket4_str,  
  bucket5_str = i.bucket5_str,  
  bucket6_str = i.bucket6_str,  
  
  bucket0 = i.bucket0,  
  bucket0_str = i.bucket0_str  
 FROM #final f, #invoices i  
 WHERE f.customer_code = i.customer_code  
  
  
  
 SELECT  'CustCode' = customer_code,  
     'CustName' = customer_name,  
     'attName' = attention_name,  
     'phone' = attention_phone,  
     'addr1' = addr1,  
     'addr2' = addr2,  
     'addr3' = addr3,  
     'addr4' = addr4,  
     'addr5' = addr5,  
     'addr6' = addr6,  
     'terms' = terms,  
     'creditLimit' = credit_limit,  
     'age_balance' = total_balance,  
     'onAcct' = on_acct,  
     'b1' = bucket1,  
     'b2' = bucket2,  
     'b3' = bucket3,  
     'b4' = bucket4,  
     'b5' = bucket5,  
     'b6' = bucket6,  
     'b1Str' = bucket1_str,  
     'b2Str' = bucket2_str,  
     'b3Str' = bucket3_str,  
     'b4Str' = bucket4_str,  
     'b5Str' = bucket5_str,  
     'b6Str' = bucket6_str,  
     'company' = company_name,  
     symbol,  
     curr_precision,  
     currency_mask,  
     'CoAddr1' = co_addr1,  
     'CoAddr2' = co_addr2,  
     'CoAddr3' = co_addr3,  
     'CoAddr4' = co_addr4,  
     'CoAddr5' = co_addr5,  
     'CoAddr6' = co_addr6,  
     'PrintCompany' = @print_company_info,  
     'PrintTerms' = @print_terms,  
     'CoTel' = @co_tel_no,  
     'CoFax' = @co_fax_no,  
     'DbNum' = db_num,  
     'HomeCurr' = @home_currency,  
     doc_ctrl_num,  
     'docdate' = case when date_doc > 639906 then convert(datetime, dateadd(dd, date_doc - 639906, '1/1/1753')) else date_doc end,  
     trx_type,   
     amt_net,  
     amt_paid_to_date,  
     balance,  
     amt_on_acct,  
     price_code,  
     territory_code,  
     nat_cur_code,  
     trx_type_code,  
     cust_po_num,  
     'duedate' = case when date_due > 639906 then convert(datetime, dateadd(dd, date_due - 639906, '1/1/1753')) else date_due end,  
     'agedate' = case when date_aging > 639906 then convert(datetime, dateadd(dd, date_aging - 639906, '1/1/1753')) else date_aging end,  
     'applydate' = case when date_applied > 639906 then convert(datetime, dateadd(dd, date_applied - 639906, '1/1/1753')) else date_applied end,  
     'all_org_flag' = @all_org_flag,  
     'from_org' = @from_org,  
     'to_org' = @to_org,  
     'display_org' = @display_org,  
  
     bucket0,  
     bucket0_str  
 FROM  #final  
 ORDER BY customer_code, on_acct_flag DESC, trx_type_code, date_doc, trx_ctrl_num   
  
  
 DROP TABLE #artrxage_tmp  
 DROP TABLE #invoices  
 DROP TABLE #invoices_details  
  
 SET NOCOUNT OFF  
  
GO
GRANT EXECUTE ON  [dbo].[cc_print_statement_range_sp] TO [public]
GO
