SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[cc_summary_aging_sp]   
 @customer_code  varchar(8),   
 @date_type_parm  varchar(2)  = '4',      
 @all_org_flag   smallint = 0,    
 @from_org varchar(30) = '',  
 @to_org varchar(30) = '',  
 @balance   float   = NULL OUTPUT,
 @checking int = 0   
  
AS  
 BEGIN  
  
 SET NOCOUNT ON  
  
 IF ( SELECT ib_flag FROM glco (NOLOCK) ) = 0  -- v1.0
  SELECT @all_org_flag = 1  
  
 SELECT @date_type_parm = 4  
  
 DECLARE @date_asof  int,  
      @precision_home  smallint,  
     @symbol   varchar(8),  
     @home_currency  varchar(8),  
     @multi_currency_flag smallint,  
     @date_type_string varchar(14),  
     @date_type_conv  tinyint,  
     @last_doc varchar(16),   
     @date_doc int,   
     @date_due int,   
     @terms_code varchar(8),   
     @date int,   
     @date_rec int,  
     @month int,  
     @apply varchar(16),  
     @last_cust varchar(8),  
     @is_child smallint  
  
  
  DECLARE @relation_code varchar(10)  
    
  SELECT @relation_code = credit_check_rel_code  
  FROM arco (NOLOCK)  
  
  
  SELECT @is_child = 0  
  
  SELECT  @date_asof   = DATEDIFF(dd, "1/1/1753", CONVERT(datetime, getdate())) + 639906  
  
  SELECT @date_type_conv = convert(tinyint,@date_type_parm)  
  
  
  IF @date_type_conv = 1  
   SELECT @date_type_string = "Document Date"  
  ELSE IF @date_type_conv = 2  
   SELECT @date_type_string = "Applied Date"  
  ELSE IF @date_type_conv = 3  
   SELECT @date_type_string = "Aging Date"  
  ELSE IF @date_type_conv = 4  
   SELECT @date_type_string = "Due Date"  
  
    
  SELECT @precision_home  = curr_precision,  
   @multi_currency_flag  = multi_currency_flag,  
   @home_currency   = home_currency,  
   @symbol   = symbol  
  FROM glcurr_vw (NOLOCK), glco (NOLOCK) -- v1.0
  WHERE glco.home_currency  = glcurr_vw.currency_code  
   
  
 CREATE TABLE #customers( customer_code varchar(8) )  
  
 INSERT #customers  
 SELECT @customer_code  
  
  
-- v1.4 Start
-- IF ( SELECT COUNT(*) FROM arnarel  (NOLOCK) WHERE parent IN ( SELECT customer_code FROM #customers ) AND relation_code = @relation_code) > 0  -- v1.0 
--  INSERT #customers   
--  SELECT child   
--  FROM arnarel (NOLOCK) -- v1.0  
--  WHERE parent IN ( SELECT customer_code FROM #customers )   
--  AND relation_code = @relation_code  
  

--	INSERT #customers
--	SELECT child FROM dbo.f_cvo_get_buying_group_child_list(@customer_code,CONVERT(varchar(10),GETDATE(),121))
  
-- v1.4  
  
  
  
  
 IF ( SELECT COUNT(*) FROM arnarel (NOLOCK) WHERE child = @customer_code ) > 0  -- v1.0
  SELECT @is_child = 1  
  
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
   ref_id    int,  
   org_id      varchar(30),  
   date_required int,  
   amt_age_bracket0 float)  
  
  
    
  CREATE TABLE #non_zero_records  
  ( doc_ctrl_num   varchar(16),   
   trx_type   smallint,   
   customer_code   varchar(8),   
   total    float )  
   
  CREATE TABLE #dates  
  ( date_start int,  
   date_end int,  
   bucket varchar(25) )  
  
  

  IF @all_org_flag = 1  
   INSERT #non_zero_records  
   SELECT  apply_to_num ,   
    apply_trx_type,   
    customer_code,   
    SUM(amount)   
   FROM  artrxage (NOLOCK) -- v1.0 
   WHERE  customer_code IN ( SELECT customer_code FROM #customers )  
   GROUP BY customer_code, apply_to_num, apply_trx_type   
   HAVING ABS(SUM(amount)) > 0.0000001   
  ELSE  
   INSERT #non_zero_records  
   SELECT  apply_to_num ,   
    apply_trx_type,   
    customer_code,   
    SUM(amount)   
   FROM  artrxage  (NOLOCK) -- v1.0
   WHERE  customer_code IN ( SELECT customer_code FROM #customers )  
   AND org_id BETWEEN @from_org AND @to_org  
   GROUP BY customer_code, apply_to_num, apply_trx_type   
   HAVING ABS(SUM(amount)) > 0.0000001   
  
-- v1.3 Start
/*
  
 
   
  
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
    a.date_due,  
--    (1+ sign(sign(a.ref_id) - 1))*a.date_due + abs(sign(sign(a.ref_id)-1))*a.date_doc,   
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
  
    0,  
    0  
   FROM  artrxage a (NOLOCK) ,#non_zero_records i  -- v1.0
   WHERE a.customer_code IN ( SELECT customer_code FROM #customers )  
   AND  a.apply_to_num = i.doc_ctrl_num   
   AND  a.apply_trx_type = i.trx_type   
   AND  a.customer_code = i.customer_code   
  
  
  -- v1.2 Start
	UPDATE	a
	SET		date_due = CASE WHEN b.date_due = 0 THEN b.date_applied ELSE b.date_due END
	FROM	#artrxage_tmp a
	JOIN	artrxage b (NOLOCK)
	ON		a.trx_ctrl_num = b.trx_ctrl_num
	AND		a.apply_to_num = b.apply_to_num
	AND		a.apply_trx_type = b.apply_trx_type
	AND		a.customer_code = b.customer_code
	WHERE	a.date_due = 0
	AND		a.amount < 0
  
	UPDATE	a
	SET		date_due = CASE WHEN b.date_due = 0 THEN b.date_doc ELSE b.date_due END
	FROM	#artrxage_tmp a
	JOIN	artrxage b (NOLOCK)
	ON		a.trx_ctrl_num = b.trx_ctrl_num
	AND		a.apply_to_num = b.apply_to_num
	AND		a.apply_trx_type = b.apply_trx_type
	AND		a.customer_code = b.customer_code
	WHERE	a.date_due = 0
	AND		a.amount > 0
  
  
  /*
  
  
  SELECT @last_cust = MIN(customer_code) FROM #artrxage_tmp  
  WHILE ( @last_cust IS NOT NULL )  
   BEGIN  
    SELECT @last_doc = MIN(apply_to_num )   
    FROM #artrxage_tmp   
    WHERE date_due = 0  
    AND customer_code = @last_cust  
    WHILE ( @last_doc IS NOT NULL )  
     BEGIN  
      SELECT @date_doc = MIN(date_doc)  
      FROM #artrxage_tmp  
      WHERE doc_ctrl_num = @last_doc  
      AND customer_code = @last_cust  
      
      SELECT @terms_code = terms_code   
      FROM artrx (NOLOCK) -- v1.0  
      WHERE doc_ctrl_num = @last_doc  
       AND customer_code = @last_cust  
  
      IF ( SELECT ISNULL(DATALENGTH(LTRIM(RTRIM(@terms_code))), 0)) = 0   
       SELECT @terms_code = terms_code FROM arcust WHERE customer_code = @last_cust  
      
      EXEC CVO_CalcDueDate_sp @last_cust, @date_doc, @date_due OUTPUT, @terms_code  
      
      UPDATE #artrxage_tmp   
      SET date_due = @date_due,  
        date_aging = @date_due,  
        date_required = @date_due  
      WHERE apply_to_num = @last_doc  
      AND trx_type <> 2031  
       AND customer_code = @last_cust  
      
      SELECT @last_doc = MIN(apply_to_num )   
      FROM #artrxage_tmp   
      WHERE apply_to_num > @last_doc   
      AND date_due = 0  
       AND customer_code = @last_cust  
     END  
    SELECT @last_cust = MIN(customer_code)   
    FROM #artrxage_tmp   
    WHERE customer_code > @last_cust  
   END  
  
  
  SELECT @last_cust = MIN(customer_code) FROM #artrxage_tmp  
  WHILE ( @last_cust IS NOT NULL )  
   BEGIN  
    SELECT @last_doc = MIN(doc_ctrl_num )   
    FROM #artrxage_tmp   
    WHERE trx_type IN (2112,2113,2121)  
    AND customer_code = @last_cust  
    WHILE ( @last_doc IS NOT NULL )  
     BEGIN  
      SELECT @apply = MIN(apply_to_num)   
      FROM #artrxage_tmp   
      WHERE doc_ctrl_num = @last_doc  
      AND customer_code = @last_cust  
      WHILE ( @apply IS NOT NULL )  
       BEGIN  
-- v1.1 Start

--        DELETE #artrxage_tmp  
--        WHERE doc_ctrl_num = @last_doc  
--        AND apply_to_num = @apply  
--        AND customer_code = @last_cust  
--/* PJC 031713 - exclude CM type transaction*/  
--        AND trx_type <> 2161  
-- v1.1 End
  
      
        SELECT @apply = MIN(apply_to_num)   
        FROM #artrxage_tmp   
        WHERE doc_ctrl_num = @last_doc  
        AND apply_to_num > @apply  
        AND customer_code = @last_cust  
       END  
      SELECT @last_doc = MIN(doc_ctrl_num )   
      FROM #artrxage_tmp   
      WHERE doc_ctrl_num > @last_doc   
      AND trx_type IN (2112,2113,2121)  
      AND customer_code = @last_cust  
     END  
    SELECT @last_cust = MIN(customer_code)   
    FROM #artrxage_tmp   
    WHERE customer_code > @last_cust  
   END  
--select * from #artrxage_tmp  
  
--PJC 20120405  
  
  SELECT @last_cust = MIN(customer_code) FROM #artrxage_tmp  
  WHILE ( @last_cust IS NOT NULL )  
   BEGIN  
    SELECT @last_doc = MIN(doc_ctrl_num )   
    FROM #artrxage_tmp   
    WHERE trx_type IN (2112,2113,2121)  
    AND customer_code = @last_cust  
    WHILE ( @last_doc IS NOT NULL )  
     BEGIN  
      SELECT @date = date_doc  
      FROM #artrxage_tmp  
      WHERE doc_ctrl_num = @last_doc  
      AND trx_type IN (2112,2113,2121)  
      AND customer_code = @last_cust  
      
      UPDATE #artrxage_tmp   
      SET date_doc = @date,  
       date_required = @date  
      WHERE doc_ctrl_num = @last_doc  
      AND customer_code = @last_cust  
       
      SELECT @last_doc = MIN(doc_ctrl_num )   
      FROM #artrxage_tmp   
      WHERE doc_ctrl_num > @last_doc   
      AND trx_type IN (2112,2113,2121)  
      AND customer_code = @last_cust  
     END  
    SELECT @last_cust = MIN(customer_code)   
    FROM #artrxage_tmp   
    WHERE customer_code > @last_cust  
   END  
  
  
  
  
  
  SELECT @last_cust = MIN(customer_code) FROM #artrxage_tmp  
  WHILE ( @last_cust IS NOT NULL )  
   BEGIN  
    SELECT @last_doc =   
    MIN(apply_to_num )   
    FROM #artrxage_tmp   
    where trx_type = 2031  
    AND customer_code = @last_cust  
    WHILE ( @last_doc IS NOT NULL )  
     BEGIN  
      SELECT @date = date_due  
      FROM #artrxage_tmp  
      WHERE doc_ctrl_num = @last_doc  
      AND trx_type = 2031  
      AND customer_code = @last_cust  
      
      UPDATE #artrxage_tmp   
      SET date_due = @date  
      WHERE apply_to_num = @last_doc  
      AND trx_type <> 2031  
      AND customer_code = @last_cust  
       
      SELECT @last_doc = MIN(apply_to_num )   
      FROM #artrxage_tmp   
      WHERE apply_to_num > @last_doc   
      AND trx_type = 2031  
      AND customer_code = @last_cust  
     END  
    SELECT @last_cust = MIN(customer_code)   
    FROM #artrxage_tmp   
    WHERE customer_code > @last_cust  
   END  
      
  UPDATE #artrxage_tmp   
  SET trx_type_code = b.trx_type_code   
  FROM artrxtyp b   
  WHERE #artrxage_tmp.trx_type = b.trx_type  
  
  
--select * from #artrxage_tmp  
  
  
  */
-- v1.2 End
  
    
  
   
  UPDATE #artrxage_tmp  
   SET amount = (SELECT ROUND(amount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home))  
  
    
    
  UPDATE #artrxage_tmp  
  SET  on_acct = amount  
  WHERE  ref_id < 1  
  AND  trx_type in (2111,2161, 2112, 2113, 2121)  
  
*/


 CREATE TABLE #ab (
	customer_code		varchar(10),
	doc_ctrl_num		varchar(16),
	date_doc			datetime,
	trx_type			int,
	amt_net				float,
	amt_paid_to_date	float,
	balance				float,
	on_acct_flag		varchar(10),
	nat_cur_code		varchar(8),
	apply_to_num		varchar(16),
	trx_type_code		varchar(20),
	trx_ctrl_num		varchar(16),
	status_code			varchar(20) NULL,
	status_date			datetime NULL,
	comment				varchar(255) NULL,
	age_bucket			int,
	date_due			datetime,
	order_ctrl_num		varchar(20) NULL,
	comment_count		int,
	[rowcount]			int)

 
	exec cc_open_inv_sp @customer_code,1,1,@date_type_parm,1,@from_org,@to_org,1


INSERT #artrxage_tmp
SELECT trx_type,     
   trx_ctrl_num,     
   doc_ctrl_num,     
   apply_to_num,     
   0,     
   '',     
   0,     
   '',     
   DATEDIFF(dd, '1/1/1753', date_doc) + 639906,     
   DATEDIFF(dd, '1/1/1753', date_due) + 639906,     
   0,     
   0,     
   balance ,     
   CASE WHEN on_acct_flag <> '' THEN balance ELSE 0 END ,    
   0,     
   0,    
   0,    
   0,    
   0,    
   0,       
   nat_cur_code,     
   1,     
   '',     
   customer_code,     
   '',     
   trx_type_code,     
   0,    
   '',    
   0,    
   0
	from #ab 
    
	DROP TABLE #ab
-- v1.3 End

  EXEC cvo_set_bucket_sp  
   
     
  
  UPDATE #artrxage_tmp  
  SET amt_age_bracket1 = amount  
  WHERE date_due BETWEEN ( SELECT date_start FROM #dates   
         WHERE bucket = 'current' )   
         AND ( SELECT date_end FROM #dates   
         WHERE bucket = 'current' )  
  
  UPDATE #artrxage_tmp  
  SET amt_age_bracket2 = amount  
  WHERE date_due BETWEEN ( SELECT date_start FROM #dates   
         WHERE bucket = '1-30' )   
         AND ( SELECT date_end FROM #dates   
         WHERE bucket = '1-30' )  
  
  UPDATE #artrxage_tmp  
  SET amt_age_bracket3 = amount  
  WHERE date_due BETWEEN ( SELECT date_start FROM #dates   
         WHERE bucket = '31-60' )   
         AND ( SELECT date_end FROM #dates   
         WHERE bucket = '31-60' )  
  
  UPDATE #artrxage_tmp  
  SET amt_age_bracket4 = amount  
  WHERE date_due BETWEEN ( SELECT date_start FROM #dates   
         WHERE bucket = '61-90' )   
         AND ( SELECT date_end FROM #dates   
         WHERE bucket = '61-90' )  
--select * from #artrxage_tmp   
--WHERE date_due BETWEEN ( SELECT date_start FROM #dates   
--         WHERE bucket = '61-90' )   
--         AND ( SELECT date_end FROM #dates   
--         WHERE bucket = '61-90' )  
  UPDATE #artrxage_tmp  
  SET amt_age_bracket5 = amount  
  WHERE date_due BETWEEN ( SELECT date_start FROM #dates   
         WHERE bucket = '91-120' )   
         AND ( SELECT date_end FROM #dates   
         WHERE bucket = '91-120' )  
  
  
  
  
  
  
  UPDATE #artrxage_tmp  
  SET amt_age_bracket6 = amount  
  WHERE date_due < ( SELECT date_start FROM #dates WHERE bucket = '91-120' )  
  
  UPDATE #artrxage_tmp  
  SET amt_age_bracket0 = amount  
  WHERE date_due > ( SELECT date_end FROM #dates WHERE bucket = 'future' )  
  
	-- v1.6 Start
	IF (@checking = 1)
	BEGIN
		DELETE #artrxage_tmp WHERE LEFT(doc_ctrl_num,3) = 'FIN'
		DELETE #artrxage_tmp WHERE LEFT(doc_ctrl_num,2) = 'CB'
	END
	-- v1.6 End
  
  
  
  
  
  IF @balance IS NULL  
   BEGIN  
--    IF ( @is_child = 0 ) -- v1.5  
     BEGIN  
      SELECT  'amount' = STR(SUM(amount),30,6),  
       'on_acct' = STR(SUM(on_acct),30,6),  
       'amt_age_bracket1' = STR(SUM(amt_age_bracket1),30,6),  
       'amt_age_bracket2' = STR(SUM(amt_age_bracket2),30,6),  
       'amt_age_bracket3' = STR(SUM(amt_age_bracket3),30,6),  
       'amt_age_bracket4' = STR(SUM(amt_age_bracket4),30,6),  
       'amt_age_bracket5' = STR(SUM(amt_age_bracket5),30,6),  
       'amt_age_bracket6' = STR(SUM(amt_age_bracket6),30,6),  
       'home_currency' = @home_currency,  
       'amt_age_bracket0' = STR(SUM(amt_age_bracket0),30,6)  
      FROM  #artrxage_tmp   
--   GROUP BY customer_code  
     END  
--    ELSE  -- v1.5   Start
--     BEGIN  
--      SELECT  'amount' = 0,  
--       'on_acct' = 0,  
--       'amt_age_bracket1' = 0,  
--       'amt_age_bracket2' = 0,  
--       'amt_age_bracket3' = 0,  
--       'amt_age_bracket4' = 0,  
--       'amt_age_bracket5' = 0,  
--       'amt_age_bracket6' = 0,  
--       'home_currency' = @home_currency,  
--       'amt_age_bracket0' = 0  
--      FROM  #artrxage_tmp   
--     END  -- -- v1.5  End
   END  
  ELSE  
   SELECT  @balance = SUM(amount)  
   FROM  #artrxage_tmp   
--   GROUP BY customer_code  
  
  
  
  
  DROP TABLE #artrxage_tmp     
  DROP TABLE #non_zero_records   
  
END   
GO
GRANT EXECUTE ON  [dbo].[cc_summary_aging_sp] TO [public]
GO
